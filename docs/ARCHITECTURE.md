# Arquitectura del Sistema — Caribbean Fest

## 1. Visión general

Plataforma cliente-servidor multiplataforma. Una sola base de código Flutter sirve a tres
perfiles (Administrador, Juez/Árbitro, Público), contra una API NestJS que expone REST para
operaciones CRUD y un canal WebSocket (Socket.IO) para el scoring y los tableros en vivo.

```
┌──────────────────────────────────────────────────────────────────┐
│  Flutter  (Web · Android · iOS)                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐   │
│  │ Admin shell  │  │ Juez shell   │  │ Público (sin login)    │   │
│  └──────────────┘  └──────────────┘  └────────────────────────┘   │
└──────────────┬───────────────────────────────┬────────────────────┘
               │ REST + JWT                     │ WebSocket (Socket.IO)
        ┌──────▼────────────────────────────────▼───────┐
        │              API Gateway (NestJS)              │
        │  Helmet · CORS · Rate-limit · JWT Guard · RBAC │
        ├────────────────────────────────────────────────┤
        │  Módulos de dominio                            │
        │  auth · tournaments · categories · clubs       │
        │  teams · players · staff · venues · referees   │
        │  matches · scoring(WS) · standings · stats     │
        │  brackets · fixtures · payments · reports      │
        │  announcements · notifications · audit         │
        └──────┬──────────────────┬──────────────┬───────┘
        ┌──────▼──────┐    ┌───────▼──────┐  ┌────▼────────┐
        │ PostgreSQL  │    │   Redis      │  │  Amazon S3  │
        │  (Prisma)   │    │ cache + WS   │  │ logos/docs  │
        └─────────────┘    │ pub/sub      │  └─────────────┘
                           └──────────────┘
        FCM (push)  ·  AWS ECS/Fargate  ·  CloudFront (Flutter Web)
```

## 2. Decisiones clave

- **Monorepo** (`backend/`, `mobile/`, `infra/`, `docs/`) para compartir tipos y versionar junto.
- **Prisma** sobre PostgreSQL: migraciones versionadas, queries parametrizadas (anti SQL-injection
  por defecto), tipos generados que consumen los DTOs de NestJS.
- **RBAC** por roles (`ADMIN`, `REFEREE`, `CLUB`) + recurso. El público no autentica: endpoints
  `GET` públicos cacheados en CloudFront/Redis.
- **Scoring en tiempo real**: el juez emite eventos punto-a-punto por WebSocket; el servidor es la
  fuente de verdad (valida reglas de voleibol), persiste y reenvía (broadcast) por sala
  `match:{id}` y `tournament:{id}`. El recálculo de la tabla se dispara al cerrar cada set/partido.
- **Redis adapter** de Socket.IO para escalar el gateway horizontalmente (varias instancias).

## 3. Modelo de datos (ERD)

El ERD es el archivo `backend/prisma/schema.prisma` (fuente de verdad ejecutable). Resumen:

```
User ──< RefereeProfile                       Tournament ──< Category
User ──< ClubMembership >── Club               Tournament ──< Venue ──< Court
Club ──< Team >── Category                     Tournament ──< Announcement
Team ──< Player                                Tournament ──< Match
Team ──< StaffMember                           Match ──< MatchSet
Team ──< TournamentRegistration >── Tournament Match ──< MatchEvent (stats por jugador)
Team ──< Standing >── Group                    Match >── Court, RefereeAssignment
Category ──< Group ──< Standing                Bracket ──< BracketNode (>── Match)
Club/Team ──< Payment                          AuditLog (transversal)
```

### Reglas de negocio núcleo

**Sistema de puntos FIVB** (tabla de posiciones):

| Resultado            | Ganador | Perdedor |
|----------------------|:-------:|:--------:|
| 3-0 / 3-1            |    3    |    0     |
| 3-2                  |    2    |    1     |

Criterios de desempate (en orden): puntos → nº de victorias → set ratio
(sets a favor / sets en contra) → point ratio (puntos a favor / en contra) → resultado directo.

**Validación de set de voleibol:** un set se gana con ≥25 puntos y ≥2 de diferencia
(15 en el set decisivo / 5º). Un partido es al mejor de 5 sets (gana quien llega a 3).
Estos invariantes los valida el servidor, nunca el cliente.

## 4. Sistemas de competencia soportados

Round robin (todos contra todos), grupos + eliminación, eliminación simple, eliminación doble,
cuadrangulares, hexagonales y formato personalizado. Cada formato implementa la interfaz
`FixtureGenerator` (estrategia) que produce los `Match` y, si aplica, la estructura `Bracket`.

## 5. Seguridad

- JWT access (corto) + refresh (rotación). Contraseñas con `argon2`.
- RBAC con `@Roles()` + `RolesGuard`; ownership checks por recurso.
- Helmet (cabeceras), CORS por allowlist, rate-limiting (`@nestjs/throttler`).
- Anti SQL-injection: Prisma parametriza; sin SQL crudo salvo `\$queryRaw` tipado.
- XSS: la API es JSON puro; Flutter no inyecta HTML. Sanitización de campos de texto libre.
- CSRF: tokens en `Authorization: Bearer` (no cookies) ⇒ superficie CSRF mínima; si se usan
  cookies para refresh, `SameSite=strict` + doble envío.
- `AuditLog` registra acciones sensibles (crear/editar/eliminar torneo, cerrar partido, pagos).

## 6. Escalabilidad (>10.000 usuarios concurrentes)

El 99% de la carga es **lectura pública** (resultados/tablas en vivo). Estrategia:

1. **Stateless API** en AWS ECS/Fargate con autoscaling por CPU/conexiones; detrás de ALB.
2. **CDN (CloudFront)** sirve el Flutter Web y cachea respuestas `GET` públicas (TTL corto +
   invalidación al cerrar partido).
3. **Redis**: cache de tablas/calendarios y **adapter de Socket.IO** para broadcast entre
   instancias (pub/sub). Las salas por torneo limitan el fan-out.
4. **PostgreSQL** con réplicas de lectura para las consultas públicas; escrituras (scoring) van al
   primario. Pool con PgBouncer.
5. **Tablas materializadas / Standing precalculado**: la posición no se computa por request; se
   recalcula al cerrar cada set y se cachea.
6. **Backpressure en WebSocket**: el cliente del juez agrupa eventos; el público recibe deltas.

## 7. Entregables y su mapeo

| # | Entregable                  | Dónde vive                                   |
|---|-----------------------------|----------------------------------------------|
| 1 | Arquitectura                | este documento                               |
| 2 | ERD                         | `backend/prisma/schema.prisma`               |
| 3 | UML / 4 | Wireframes / 5 | Flujo | `docs/` (por elaborar)                       |
| 6 | APIs REST                   | `backend/src/modules/**/controller.ts`       |
| 7 | Estructura de carpetas      | `README.md`                                  |
| 8 | Backend                     | `backend/`                                   |
| 9 | Frontend                    | `mobile/`                                    |
| 11| Dockerización / 12 CI-CD    | `infra/`                                      |
| 13| Manual técnico / 14 usuario | `docs/`                                       |
| 15| Escalabilidad               | sección 6                                    |
```
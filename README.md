# Caribbean Fest — Gestión de Torneos de Voleibol

Plataforma integral para administrar torneos de voleibol (regionales, nacionales e
internacionales) con scoring en tiempo real, tablas de posiciones automáticas (sistema FIVB),
llaves eliminatorias y consulta pública en vivo.

Multiplataforma desde una sola base de código: **Web + Android + iOS**.

## Stack

| Capa            | Tecnología                                  |
|-----------------|---------------------------------------------|
| Frontend        | Flutter (Web + Android + iOS)               |
| Backend         | NestJS (Node.js + TypeScript)               |
| Base de datos   | PostgreSQL + Prisma ORM                     |
| Tiempo real     | Socket.IO (WebSocket)                        |
| Cache / WS scale| Redis                                       |
| Auth            | JWT (access + refresh) + RBAC               |
| Archivos        | Amazon S3                                    |
| Push            | Firebase Cloud Messaging                    |
| Infra           | Docker, AWS, CI/CD (GitHub Actions)         |

## Estructura del monorepo

```
caribbean-fest/
├── backend/          # API NestJS + WebSocket gateway
│   ├── prisma/       # schema.prisma  (= ERD del sistema)
│   └── src/
│       ├── modules/  # auth, tournaments, teams, players, matches, scoring, standings, ...
│       └── common/   # guards, decorators, filters, dominio compartido
├── mobile/           # App Flutter (admin · juez · público)
├── docs/             # ARCHITECTURE.md, diagramas, manuales
└── infra/            # docker-compose, Dockerfiles, CI/CD
```

## Estado de construcción (incremental)

- [x] Arquitectura del sistema — `docs/ARCHITECTURE.md`
- [x] Modelo de datos / ERD — `backend/prisma/schema.prisma`
- [x] Motor de dominio: scoring + tabla FIVB — `backend/src/modules/standings`
- [x] API REST + Auth/RBAC
- [x] Gateway WebSocket (scoring en vivo)
- [x] Generador de fixtures
- [x] CRUD de admin (torneos, equipos, jugadores, árbitros)
- [x] Verificación E2E contra Postgres real — `backend/scripts/verify-e2e.ts`
- [x] App Flutter (3 perfiles + scoring en vivo) — `mobile/`
- [x] Dockerización — `infra/`, `backend/Dockerfile`
- [x] Estadísticas por jugador (MVP, anotador, atacante, bloqueador, servidor)
- [ ] Eliminación doble + formato personalizado
- [ ] Reportes PDF/Excel/CSV
- [ ] Push notifications (FCM)
- [ ] CI/CD, manuales

## Cómo correr (backend, cuando esté listo el módulo de API)

```bash
cd backend
npm install
cp .env.example .env          # configura DATABASE_URL, JWT_SECRET, etc.
npx prisma migrate dev        # crea el esquema en PostgreSQL
npm run start:dev
```

# 🚀 Publicar Caribbean Fest (gratis / bajo costo)

Arquitectura recomendada (capa gratuita):

| Componente | Servicio | Costo |
|---|---|---|
| Base de datos (PostgreSQL) | **Neon** (neon.tech) | Gratis, persistente |
| Backend (NestJS + WebSocket) | **Render** (render.com) | Gratis (con "cold start") |
| Frontend (Flutter web) | **Netlify** o **Cloudflare Pages** | Gratis |

> **Cold start:** el plan gratis de Render duerme el backend tras ~15 min sin uso; la
> primera petición tarda ~30–50 s en despertar. Para evitarlo: plan Starter de Render (~$7/mes).

---

## 0) Subir el código a GitHub
```bash
cd "Caribbean Fest App"
git init
git add .
git commit -m "Caribbean Fest"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/caribbean-fest.git
git push -u origin main
```

## 1) Base de datos — Neon
1. Crea cuenta en **https://neon.tech** → New Project (región cercana).
2. Copia la **connection string** (formato `postgresql://user:pass@...neon.tech/db?sslmode=require`).

## 2) Backend — Render
1. **https://render.com** → New → **Blueprint** → conecta tu repo (detecta `render.yaml`).
2. En el servicio `caribbean-fest-api`, define las variables marcadas `sync: false`:
   - `DATABASE_URL` = la cadena de **Neon**.
   - `CORS_ORIGINS` = por ahora `*` (luego la cambias por la URL del frontend).
3. Deploy. Al terminar tendrás una URL tipo `https://caribbean-fest-api.onrender.com`.
4. Verifica: abre `https://caribbean-fest-api.onrender.com/api/tournaments` → debe responder `[]`.

### Crear el administrador y datos demo (una vez)
Desde tu PC, apuntando a Neon:
```bash
cd backend
# PowerShell:  $env:DATABASE_URL="postgresql://...neon..."
# bash:        export DATABASE_URL="postgresql://...neon..."
npm run seed
```
Esto crea `admin@caribbeanfest.com` / `Password123!`. **Cambia esa contraseña** después.

## 3) Frontend — Flutter web → Netlify
Compila apuntando al backend de Render:
```bash
cd mobile
flutter build web --release --dart-define=API_BASE_URL=https://caribbean-fest-api.onrender.com
```
Sube la carpeta `mobile/build/web`:
- **Fácil:** netlify.com → "Add new site" → "Deploy manually" → arrastra `build/web`.
- **CLI:** `npx netlify-cli deploy --prod --dir=build/web`

Obtendrás una URL tipo `https://caribbean-fest.netlify.app`.

> Alternativas equivalentes (gratis): **Cloudflare Pages** (`npx wrangler pages deploy build/web`)
> o **Firebase Hosting** (`firebase deploy`).

## 4) Cerrar el CORS (recomendado)
En Render, cambia `CORS_ORIGINS` de `*` a tu URL exacta del frontend:
```
CORS_ORIGINS=https://caribbean-fest.netlify.app
```
Guarda → Render redespliega. Listo: la app es pública. 🎉

---

## Notas
- **WebSocket en vivo:** funciona sobre HTTPS (wss) automáticamente en Render. Con el plan
  gratis, si el backend duerme, la reconexión ocurre al despertar.
- **Migraciones:** el `startCommand` aplica el esquema con `prisma db push` en cada deploy
  (idempotente). Para producción seria, migra a `prisma migrate deploy` con migraciones versionadas.
- **Seguridad:** el registro público (`/auth/register`) solo crea cuentas de **club**;
  ADMIN/REFEREE no se pueden auto-asignar (admins por seed, árbitros desde el panel admin).
- **Dominio propio:** Netlify y Render permiten dominios personalizados gratis (tú pones el dominio).
- **Costo si creces:** Render Starter ~$7/mes (sin cold start) + Neon escala por uso. Frontend sigue gratis.

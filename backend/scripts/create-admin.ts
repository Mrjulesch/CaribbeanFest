/**
 * Crea (o actualiza) la cuenta de administrador SIN borrar datos ni añadir demo.
 * Ideal para producción. Lee la conexión de DATABASE_URL y permite definir
 * credenciales por variables de entorno.
 *
 * Uso (PowerShell, apuntando a la BD de producción):
 *   $env:DATABASE_URL="postgresql://...neon..."
 *   $env:ADMIN_EMAIL="tu@correo.com"; $env:ADMIN_PASSWORD="UnaClaveFuerte123"
 *   npm run create:admin
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  const email = process.env.ADMIN_EMAIL ?? 'admin@caribbeanfest.com';
  const password = process.env.ADMIN_PASSWORD ?? 'Password123!';
  const fullName = process.env.ADMIN_NAME ?? 'Administrador';

  const passwordHash = await argon2.hash(password);
  const user = await prisma.user.upsert({
    where: { email },
    create: { email, passwordHash, fullName, role: 'ADMIN' },
    update: { passwordHash, role: 'ADMIN' },
  });

  console.log(`✅ Admin listo: ${user.email} (rol ${user.role})`);
  console.log('   Inicia sesión en la app con ese correo y la contraseña indicada.');
}

main()
  .catch((e) => {
    console.error('❌ Error:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

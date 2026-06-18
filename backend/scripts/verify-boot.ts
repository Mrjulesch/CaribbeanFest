/**
 * Verifica que TODA la aplicación arranca: el grafo de inyección de dependencias
 * de los 11 módulos se instancia correctamente contra un Postgres real (embebido).
 * No expone HTTP — solo valida que el wiring de NestJS no tiene errores de DI.
 *
 * Ejecutar:  npm run verify:boot
 */
import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import { AppModule } from '../src/app.module';

async function loadEmbeddedPostgres(): Promise<any> {
  const mod = await (eval('import("embedded-postgres")') as Promise<any>);
  return mod.default ?? mod;
}

async function main() {
  const dataDir = path.join(__dirname, '..', '.pgtmp-boot');
  fs.rmSync(dataDir, { recursive: true, force: true });

  const EmbeddedPostgres = await loadEmbeddedPostgres();
  const pg = new EmbeddedPostgres({
    databaseDir: dataDir,
    user: 'postgres',
    password: 'postgres',
    port: 55433,
    persistent: false,
  });

  console.log('▶ Inicializando PostgreSQL embebido…');
  await pg.initialise();
  await pg.start();
  await pg.createDatabase('caribbean_fest');

  const url = 'postgresql://postgres:postgres@localhost:55433/caribbean_fest?schema=public';
  process.env.DATABASE_URL = url;
  // FCM intencionalmente sin credenciales → debe entrar en "modo log".

  console.log('▶ Aplicando esquema Prisma…');
  execSync('npx prisma db push --skip-generate --accept-data-loss', {
    stdio: 'inherit',
    env: { ...process.env, DATABASE_URL: url },
  });

  console.log('▶ Arrancando el contexto NestJS (todos los módulos)…');
  Logger.overrideLogger(['warn', 'error', 'log']);
  const app = await NestFactory.createApplicationContext(AppModule, { bufferLogs: false });
  await app.init();

  console.log('✅ La aplicación arrancó: grafo de DI de los 11 módulos válido.');

  await app.close();
  await pg.stop();
  fs.rmSync(dataDir, { recursive: true, force: true });
}

main().catch((e) => {
  console.error('❌ Falló el arranque:', e);
  process.exit(1);
});

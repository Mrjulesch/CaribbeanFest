/**
 * Verificación end-to-end SIN instalar nada: levanta un PostgreSQL embebido temporal,
 * aplica el esquema Prisma, ejecuta el seed (que genera fixture, simula un partido y
 * recalcula la tabla) y comprueba que los resultados son correctos. Al terminar, apaga
 * y borra el Postgres temporal.
 *
 * Ejecutar:  npm run verify:e2e
 */
import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import { PrismaClient } from '@prisma/client';
import { seed } from '../prisma/seed';

// embedded-postgres es ESM-only: lo cargamos con import() dinámico desde CommonJS.
async function loadEmbeddedPostgres(): Promise<any> {
  const mod = await (eval('import("embedded-postgres")') as Promise<any>);
  return mod.default ?? mod;
}

const PORT = 55432;
const DB = 'caribbean_fest';

async function main() {
  const dataDir = path.join(__dirname, '..', '.pgtmp');
  fs.rmSync(dataDir, { recursive: true, force: true });

  const EmbeddedPostgres = await loadEmbeddedPostgres();
  const pg = new EmbeddedPostgres({
    databaseDir: dataDir,
    user: 'postgres',
    password: 'postgres',
    port: PORT,
    persistent: false,
  });

  console.log('▶ Inicializando PostgreSQL embebido…');
  await pg.initialise();
  await pg.start();
  await pg.createDatabase(DB);

  const url = `postgresql://postgres:postgres@localhost:${PORT}/${DB}?schema=public`;
  process.env.DATABASE_URL = url;

  console.log('▶ Aplicando esquema Prisma (db push)…');
  execSync('npx prisma db push --skip-generate --accept-data-loss', {
    stdio: 'inherit',
    env: { ...process.env, DATABASE_URL: url },
  });

  const prisma = new PrismaClient({ datasources: { db: { url } } });

  let failures = 0;
  const assert = (cond: boolean, msg: string) => {
    console.log(`${cond ? '✓' : '✗'} ${msg}`);
    if (!cond) failures++;
  };

  try {
    console.log('▶ Ejecutando seed (torneo + fixture + partido + tabla)…');
    const r = await seed(prisma);

    // Round robin de 4 equipos → 6 partidos (C(4,2))
    assert(r.matches === 6, `fixture genera 6 partidos (got ${r.matches})`);

    const standings = await prisma.standing.findMany({
      orderBy: { rank: 'asc' },
      include: { team: { select: { name: true } } },
    });
    console.log(
      '   Tabla:',
      standings.map((s) => `${s.rank}.${s.team.name} ${s.points}pt(${s.won}-${s.lost})`).join('  '),
    );

    const leader = standings[0];
    assert(leader.points === 3, `líder tiene 3 puntos por victoria 3-0 (got ${leader.points})`);
    assert(leader.won === 1 && leader.played === 1, 'líder: 1 PJ, 1 PG');
    assert(leader.setsFor === 3 && leader.setsAgainst === 0, 'líder: sets 3-0');

    const finished = await prisma.match.count({ where: { status: 'FINISHED' } });
    assert(finished === 1, `1 partido finalizado (got ${finished})`);

    const assignments = await prisma.refereeAssignment.count();
    assert(assignments === 1, 'árbitro asignado al partido');

    const players = await prisma.player.count();
    assert(players === 24, `24 jugadores (4 equipos × 6) (got ${players})`);
  } finally {
    await prisma.$disconnect();
    await pg.stop();
    fs.rmSync(dataDir, { recursive: true, force: true });
  }

  if (failures > 0) {
    console.error(`\n❌ ${failures} verificación(es) fallaron`);
    process.exit(1);
  }
  console.log('\n✅ Verificación E2E completa: el backend funciona contra PostgreSQL real.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

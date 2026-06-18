/**
 * Seed de datos de ejemplo. Crea un torneo completo, genera el fixture, simula un
 * partido arbitrado y recalcula la tabla FIVB. Sirve como datos de demo y como
 * verificación end-to-end de que el esquema y la lógica funcionan contra Postgres.
 *
 * Ejecutar:  npm run seed   (requiere DATABASE_URL apuntando a un Postgres)
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';
import { roundRobinRounds } from '../src/modules/fixtures/round-robin';
import { scheduleRounds } from '../src/modules/fixtures/scheduler';
import { computeStandings, FinishedMatch } from '../src/modules/standings/standings.calculator';

export async function seed(prisma: PrismaClient) {
  // Limpieza idempotente (orden por dependencias)
  await prisma.matchSet.deleteMany();
  await prisma.refereeAssignment.deleteMany();
  await prisma.standing.deleteMany();
  await prisma.match.deleteMany();
  await prisma.player.deleteMany();
  await prisma.staffMember.deleteMany();
  await prisma.team.deleteMany();
  await prisma.group.deleteMany();
  await prisma.court.deleteMany();
  await prisma.venue.deleteMany();
  await prisma.category.deleteMany();
  await prisma.tournament.deleteMany();
  await prisma.club.deleteMany();
  await prisma.refereeProfile.deleteMany();
  await prisma.user.deleteMany();

  // Usuarios
  const passwordHash = await argon2.hash('Password123!');
  const admin = await prisma.user.create({
    data: { email: 'admin@caribbeanfest.com', passwordHash, fullName: 'Admin Principal', role: 'ADMIN' },
  });
  const refereeUser = await prisma.user.create({
    data: { email: 'juez@caribbeanfest.com', passwordHash, fullName: 'Carlos Árbitro', role: 'REFEREE' },
  });
  const referee = await prisma.refereeProfile.create({
    data: { userId: refereeUser.id, license: 'FIVB-001', level: 'Nacional' },
  });

  // Torneo + categoría + sede
  const tournament = await prisma.tournament.create({
    data: {
      name: 'Caribbean Fest 2026',
      startDate: new Date('2026-07-01'),
      endDate: new Date('2026-07-10'),
      isPublished: true,
    },
  });
  const category = await prisma.category.create({
    data: { tournamentId: tournament.id, name: 'Libre', gender: 'MALE', format: 'ROUND_ROBIN' },
  });
  const venue = await prisma.venue.create({
    data: { tournamentId: tournament.id, name: 'Coliseo Central', address: 'Av. Principal 100' },
  });
  const court1 = await prisma.court.create({ data: { venueId: venue.id, name: 'Cancha 1' } });
  const court2 = await prisma.court.create({ data: { venueId: venue.id, name: 'Cancha 2' } });

  // Clubes + equipos + jugadores
  const teamNames = ['Tiburones', 'Huracanes', 'Piratas', 'Corsarios'];
  const teams: { id: string }[] = [];
  for (const name of teamNames) {
    const club = await prisma.club.create({ data: { name: `Club ${name}`, city: 'Cartagena', country: 'Colombia' } });
    const team = await prisma.team.create({
      data: { name, clubId: club.id, categoryId: category.id, coachName: `DT ${name}` },
    });
    for (let i = 1; i <= 6; i++) {
      await prisma.player.create({
        data: { teamId: team.id, fullName: `${name} Jugador ${i}`, jerseyNumber: i, position: 'OUTSIDE_HITTER' },
      });
    }
    teams.push(team);
  }

  // Fixture round robin
  const teamIds = teams.map((t) => t.id);
  const rounds = roundRobinRounds(teamIds);
  const scheduled = scheduleRounds(rounds, {
    startDate: new Date('2026-07-01'),
    courtIds: [court1.id, court2.id],
    slotMinutes: 90,
    firstSlotHour: 9,
    slotsPerDay: 6,
  });
  await prisma.match.createMany({
    data: scheduled.map((m) => ({
      tournamentId: tournament.id,
      categoryId: category.id,
      homeTeamId: m.home,
      awayTeamId: m.away,
      courtId: m.courtId,
      scheduledAt: m.scheduledAt,
      status: 'SCHEDULED' as const,
    })),
  });

  // Simula un partido arbitrado: el primero termina 3-0
  const first = await prisma.match.findFirstOrThrow({ where: { categoryId: category.id }, orderBy: { scheduledAt: 'asc' } });
  await prisma.refereeAssignment.create({ data: { matchId: first.id, refereeId: referee.id, role: 'first' } });
  const setScores = [
    { setNumber: 1, homePoints: 25, awayPoints: 20 },
    { setNumber: 2, homePoints: 25, awayPoints: 18 },
    { setNumber: 3, homePoints: 25, awayPoints: 22 },
  ];
  for (const s of setScores) {
    await prisma.matchSet.create({ data: { matchId: first.id, ...s, isFinished: true } });
  }
  await prisma.match.update({
    where: { id: first.id },
    data: { homeSetsWon: 3, awaySetsWon: 0, status: 'FINISHED' },
  });

  // Recalcula tabla FIVB y persiste
  const finishedMatches = await prisma.match.findMany({
    where: { categoryId: category.id, status: 'FINISHED' },
    include: { sets: true },
  });
  const finished: FinishedMatch[] = finishedMatches.map((m) => ({
    homeTeamId: m.homeTeamId!,
    awayTeamId: m.awayTeamId!,
    sets: m.sets.map((s) => ({ setNumber: s.setNumber, homePoints: s.homePoints, awayPoints: s.awayPoints })),
  }));
  const table = computeStandings(finished, teamIds);
  await prisma.$transaction(
    table.map((r) =>
      prisma.standing.upsert({
        where: { teamId: r.teamId },
        create: { ...rowData(r) },
        update: { ...rowData(r) },
      }),
    ),
  );

  return { admin: admin.email, tournament: tournament.name, teams: teams.length, matches: scheduled.length, table };
}

function rowData(r: ReturnType<typeof computeStandings>[number]) {
  return {
    teamId: r.teamId,
    played: r.played,
    won: r.won,
    lost: r.lost,
    points: r.points,
    setsFor: r.setsFor,
    setsAgainst: r.setsAgainst,
    pointsFor: r.pointsFor,
    pointsAgainst: r.pointsAgainst,
    rank: r.rank,
  };
}

// Permite ejecutarlo directamente (npm run seed)
if (require.main === module) {
  const prisma = new PrismaClient();
  seed(prisma)
    .then((r) => {
      // eslint-disable-next-line no-console
      console.log('Seed completado:', JSON.stringify(r, null, 2));
    })
    .catch((e) => {
      // eslint-disable-next-line no-console
      console.error(e);
      process.exit(1);
    })
    .finally(() => prisma.$disconnect());
}

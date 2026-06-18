import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { computeStandings, FinishedMatch } from './standings.calculator';

@Injectable()
export class StandingsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Tabla pública de una categoría (lectura). */
  async forCategory(categoryId: string) {
    return this.prisma.standing.findMany({
      where: { team: { categoryId } },
      include: { team: { select: { id: true, name: true } } },
      orderBy: [{ points: 'desc' }, { won: 'desc' }],
    });
  }

  /**
   * Recalcula y persiste la tabla de una categoría a partir de los partidos terminados.
   * Se dispara cuando un partido se cierra (desde ScoringService / MatchesService).
   */
  async recalculate(categoryId: string) {
    const [category, teams, matches] = await Promise.all([
      this.prisma.category.findUnique({ where: { id: categoryId }, select: { bestOf: true } }),
      this.prisma.team.findMany({ where: { categoryId }, select: { id: true } }),
      this.prisma.match.findMany({
        where: { categoryId, status: 'FINISHED', homeTeamId: { not: null }, awayTeamId: { not: null } },
        include: { sets: true },
      }),
    ]);

    const finished: FinishedMatch[] = matches.map((m) => ({
      homeTeamId: m.homeTeamId!,
      awayTeamId: m.awayTeamId!,
      sets: m.sets.map((s) => ({
        setNumber: s.setNumber,
        homePoints: s.homePoints,
        awayPoints: s.awayPoints,
      })),
    }));

    const rows = computeStandings(
      finished,
      teams.map((t) => t.id),
      category?.bestOf ?? 5,
    );

    // upsert por equipo dentro de una transacción
    await this.prisma.$transaction(
      rows.map((r) =>
        this.prisma.standing.upsert({
          where: { teamId: r.teamId },
          create: {
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
          },
          update: {
            played: r.played,
            won: r.won,
            lost: r.lost,
            points: r.points,
            setsFor: r.setsFor,
            setsAgainst: r.setsAgainst,
            pointsFor: r.pointsFor,
            pointsAgainst: r.pointsAgainst,
            rank: r.rank,
          },
        }),
      ),
    );

    return rows;
  }
}

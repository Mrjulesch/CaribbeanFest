import { BadRequestException, Injectable } from '@nestjs/common';
import { CompetitionFormat } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { roundRobinRounds, splitIntoGroups, Pairing } from './round-robin';
import { buildSingleElimination } from './elimination';
import { scheduleRounds, ScheduleOptions } from './scheduler';

export interface GenerateOptions {
  groupCount?: number; // para GROUPS_PLAYOFF
  startDate: string; // ISO
  slotMinutes?: number;
  firstSlotHour?: number;
  slotsPerDay?: number;
}

@Injectable()
export class FixturesService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Genera el fixture de una categoría según su formato configurado, persistiendo
   * los Match (y grupos/cuadro cuando aplica). Idempotente por categoría: borra el
   * fixture previo de la categoría antes de regenerar.
   */
  async generate(categoryId: string, opts: GenerateOptions) {
    const category = await this.prisma.category.findUnique({
      where: { id: categoryId },
      include: { teams: { select: { id: true } }, tournament: { include: { venues: { include: { courts: true } } } } },
    });
    if (!category) throw new BadRequestException('Categoría no encontrada');

    const teamIds = category.teams.map((t) => t.id);
    if (teamIds.length < 2) throw new BadRequestException('La categoría necesita al menos 2 equipos');

    const courtIds = category.tournament.venues.flatMap((v) => v.courts.map((c) => c.id));
    if (courtIds.length === 0) throw new BadRequestException('El torneo no tiene canchas configuradas');

    const schedule: ScheduleOptions = {
      startDate: new Date(opts.startDate),
      courtIds,
      slotMinutes: opts.slotMinutes ?? 90,
      firstSlotHour: opts.firstSlotHour ?? 9,
      slotsPerDay: opts.slotsPerDay ?? 6,
    };

    // Limpia fixture anterior de la categoría.
    await this.prisma.match.deleteMany({ where: { categoryId } });

    switch (category.format) {
      case CompetitionFormat.ROUND_ROBIN:
      case CompetitionFormat.QUADRANGULAR:
      case CompetitionFormat.HEXAGONAL:
        return this.persistRoundRobin(category.tournamentId, categoryId, teamIds, schedule);

      case CompetitionFormat.GROUPS_PLAYOFF:
        return this.persistGroups(category.tournamentId, categoryId, teamIds, opts.groupCount ?? 2, schedule);

      case CompetitionFormat.SINGLE_ELIM:
        return this.persistSingleElimination(category.tournamentId, categoryId, teamIds, schedule);

      case CompetitionFormat.DOUBLE_ELIM:
      case CompetitionFormat.CUSTOM:
        throw new BadRequestException(
          `Formato ${category.format} aún no implementado (próximo incremento)`,
        );
    }
  }

  // ── Round robin (incluye cuadrangular/hexagonal) ───────────────────────────
  private async persistRoundRobin(
    tournamentId: string,
    categoryId: string,
    teamIds: string[],
    schedule: ScheduleOptions,
  ) {
    const rounds = roundRobinRounds(teamIds);
    const scheduled = scheduleRounds(rounds, schedule);
    return this.createMatches(tournamentId, categoryId, scheduled);
  }

  // ── Fase de grupos ─────────────────────────────────────────────────────────
  private async persistGroups(
    tournamentId: string,
    categoryId: string,
    teamIds: string[],
    groupCount: number,
    schedule: ScheduleOptions,
  ) {
    const groups = splitIntoGroups(teamIds, groupCount);
    let created = 0;

    for (let g = 0; g < groups.length; g++) {
      const group = await this.prisma.group.create({
        data: { categoryId, name: `Grupo ${String.fromCharCode(65 + g)}` },
      });
      // Asigna los equipos al grupo.
      await this.prisma.team.updateMany({
        where: { id: { in: groups[g] } },
        data: { groupId: group.id },
      });
      const rounds = roundRobinRounds(groups[g]);
      const scheduled = scheduleRounds(rounds, schedule);
      const res = await this.createMatches(tournamentId, categoryId, scheduled);
      created += res.created;
    }
    return { created, groups: groups.length };
  }

  // ── Eliminación simple ───────────────────────────────────────────────────────
  private async persistSingleElimination(
    tournamentId: string,
    categoryId: string,
    teamIds: string[],
    schedule: ScheduleOptions,
  ) {
    const bracket = await this.prisma.bracket.upsert({
      where: { categoryId },
      create: { categoryId },
      update: {},
    });
    const rounds = buildSingleElimination(teamIds);

    let created = 0;
    let slot = 0;
    // Creamos los nodos por ronda; encadenamos ganador → siguiente nodo.
    let prevNodeIds: string[] = [];

    for (let r = 0; r < rounds.length; r++) {
      const round = rounds[r];
      const nodeIds: string[] = [];

      for (const s of round.slots) {
        // Solo la primera ronda tiene equipos concretos; el resto se llena al avanzar.
        const hasTeams = s.homeTeamId || s.awayTeamId;
        const match = await this.prisma.match.create({
          data: {
            tournamentId,
            categoryId,
            homeTeamId: s.homeTeamId,
            awayTeamId: s.awayTeamId,
            courtId: schedule.courtIds[created % schedule.courtIds.length],
            scheduledAt: hasTeams ? scheduleSlotDate(slot++, schedule) : null,
            status: 'SCHEDULED',
          },
        });
        const node = await this.prisma.bracketNode.create({
          data: { bracketId: bracket.id, round: round.round, position: s.position, matchId: match.id },
        });
        nodeIds.push(node.id);
        if (hasTeams) created++;
      }

      // Encadena: el nodo i de la ronda previa avanza al nodo floor(i/2) de esta.
      if (prevNodeIds.length > 0) {
        for (let i = 0; i < prevNodeIds.length; i++) {
          await this.prisma.bracketNode.update({
            where: { id: prevNodeIds[i] },
            data: { nextNodeId: nodeIds[Math.floor(i / 2)] },
          });
        }
      }
      prevNodeIds = nodeIds;
    }

    return { created, rounds: rounds.length, bracketId: bracket.id };
  }

  private async createMatches(
    tournamentId: string,
    categoryId: string,
    scheduled: { home: string; away: string; courtId: string; scheduledAt: Date }[],
  ) {
    await this.prisma.match.createMany({
      data: scheduled.map((m) => ({
        tournamentId,
        categoryId,
        homeTeamId: m.home,
        awayTeamId: m.away,
        courtId: m.courtId,
        scheduledAt: m.scheduledAt,
        status: 'SCHEDULED' as const,
      })),
    });
    return { created: scheduled.length };
  }
}

// Helper local para fechas del cuadro eliminatorio (mismo cálculo que el scheduler).
function scheduleSlotDate(slot: number, o: ScheduleOptions): Date {
  const day = Math.floor(slot / o.slotsPerDay);
  const slotInDay = slot % o.slotsPerDay;
  const d = new Date(o.startDate);
  d.setDate(d.getDate() + day);
  d.setHours(o.firstSlotHour, 0, 0, 0);
  d.setMinutes(d.getMinutes() + slotInDay * o.slotMinutes);
  return d;
}

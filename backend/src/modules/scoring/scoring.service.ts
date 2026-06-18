import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { StandingsService } from '../standings/standings.service';
import { NotificationsService } from '../notifications/notifications.service';
import { isValidSetScore, matchOutcome, setWinner } from '../standings/volleyball-rules';

export interface SetScoreInput {
  matchId: string;
  setNumber: number; // 1..5
  homePoints: number;
  awayPoints: number;
  finishSet?: boolean; // el árbitro confirma el cierre del set
}

export interface EditSetInput {
  setNumber: number;
  homePoints: number;
  awayPoints: number;
}

@Injectable()
export class ScoringService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly standings: StandingsService,
    private readonly notifications: NotificationsService,
  ) {}

  /**
   * Registra/actualiza el marcador de un set. El servidor es la fuente de verdad:
   * valida la jugada, persiste, recalcula el agregado de sets del partido y, si el
   * partido quedó decidido, lo cierra y recalcula la tabla de posiciones.
   * Devuelve el estado completo del partido para difundir por WebSocket.
   */
  async recordSetScore(input: SetScoreInput) {
    if (!isValidSetScore(input)) {
      throw new BadRequestException('Marcador de set inválido');
    }

    const match = await this.prisma.match.findUnique({
      where: { id: input.matchId },
      include: { sets: true, category: { select: { bestOf: true } } },
    });
    if (!match) throw new BadRequestException('Partido no encontrado');
    if (match.status === 'FINISHED') {
      throw new BadRequestException('El partido ya está finalizado');
    }
    const bestOf = match.category?.bestOf ?? 5;

    // Si el árbitro confirma el cierre, el set debe tener un ganador válido (25/15, +2)
    if (input.finishSet && setWinner(input, bestOf) === null) {
      throw new BadRequestException('El set aún no tiene un ganador válido (25/15 y +2)');
    }

    await this.prisma.matchSet.upsert({
      where: { matchId_setNumber: { matchId: input.matchId, setNumber: input.setNumber } },
      create: {
        matchId: input.matchId,
        setNumber: input.setNumber,
        homePoints: input.homePoints,
        awayPoints: input.awayPoints,
        isFinished: !!input.finishSet,
      },
      update: {
        homePoints: input.homePoints,
        awayPoints: input.awayPoints,
        isFinished: !!input.finishSet,
      },
    });

    return this.refreshMatchAggregate(input.matchId);
  }

  /** El árbitro confirma la finalización del encuentro. */
  async finalizeMatch(matchId: string, notes?: string) {
    const state = await this.refreshMatchAggregate(matchId, { force: true, notes });
    return state;
  }

  /**
   * Edita el marcador completo de un partido (corrección administrativa), incluso si
   * ya estaba finalizado: reemplaza los sets, recalcula el resultado según el formato
   * (best-of-3 / best-of-5) y actualiza la tabla de posiciones.
   */
  async editMatch(matchId: string, sets: EditSetInput[]) {
    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: { category: { select: { bestOf: true } } },
    });
    if (!match) throw new NotFoundException('Partido no encontrado');
    const bestOf = match.category?.bestOf ?? 5;

    for (const s of sets) {
      if (!isValidSetScore(s, bestOf)) {
        throw new BadRequestException(`Marcador inválido en el set ${s.setNumber}`);
      }
    }

    // Reemplaza por completo los sets del partido.
    await this.prisma.matchSet.deleteMany({ where: { matchId } });
    for (const s of sets) {
      await this.prisma.matchSet.create({
        data: {
          matchId,
          setNumber: s.setNumber,
          homePoints: s.homePoints,
          awayPoints: s.awayPoints,
          isFinished: setWinner(s, bestOf) !== null,
        },
      });
    }

    const updated = await this.refreshMatchAggregate(matchId);
    // Tras una edición siempre recalculamos la tabla (aunque ya estuviera FINISHED).
    await this.standings.recalculate(match.categoryId);
    return updated;
  }

  /**
   * Recalcula sets ganados y estado del partido a partir de los sets persistidos.
   * Si está decidido (alguien llegó a 3 sets) marca FINISHED y recalcula la tabla.
   */
  private async refreshMatchAggregate(
    matchId: string,
    opts: { force?: boolean; notes?: string } = {},
  ) {
    const match = await this.prisma.match.findUniqueOrThrow({
      where: { id: matchId },
      include: {
        sets: { orderBy: { setNumber: 'asc' } },
        category: { select: { bestOf: true } },
      },
    });
    const bestOf = match.category?.bestOf ?? 5;

    const outcome = matchOutcome(
      match.sets.map((s) => ({
        setNumber: s.setNumber,
        homePoints: s.homePoints,
        awayPoints: s.awayPoints,
      })),
      bestOf,
    );

    const willFinish = outcome.isComplete || opts.force === true;
    const status = willFinish ? 'FINISHED' : 'LIVE';

    const updated = await this.prisma.match.update({
      where: { id: matchId },
      data: {
        homeSetsWon: outcome.homeSetsWon,
        awaySetsWon: outcome.awaySetsWon,
        status,
        notes: opts.notes ?? match.notes,
      },
      include: { sets: { orderBy: { setNumber: 'asc' } } },
    });

    // Disparadores de push según la transición de estado.
    if (match.status !== 'LIVE' && status === 'LIVE') {
      void this.notifications.notifyMatchStart(matchId);
    }
    if (match.status !== 'FINISHED' && status === 'FINISHED') {
      await this.standings.recalculate(match.categoryId);
      void this.notifications.notifyMatchFinished(matchId);
    }

    return updated;
  }
}

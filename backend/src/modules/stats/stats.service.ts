import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RecordEventDto } from './dto/record-event.dto';
import {
  computeLeaders,
  computePlayerStats,
  PlayerEvent,
} from './stats.calculator';

@Injectable()
export class StatsService {
  constructor(private readonly prisma: PrismaService) {}

  /** El árbitro registra un evento de estadística durante el partido. */
  async recordEvent(matchId: string, dto: RecordEventDto) {
    const match = await this.prisma.match.findUnique({ where: { id: matchId }, select: { id: true } });
    if (!match) throw new BadRequestException('Partido no encontrado');

    return this.prisma.matchEvent.create({
      data: {
        matchId,
        teamId: dto.teamId,
        playerId: dto.playerId,
        type: dto.type,
        setNumber: dto.setNumber,
      },
    });
  }

  /** Carga los eventos de una categoría y los agrega por jugador. */
  private async eventsForCategory(categoryId: string): Promise<PlayerEvent[]> {
    const rows = await this.prisma.matchEvent.findMany({
      where: { match: { categoryId }, playerId: { not: null } },
      include: {
        player: { select: { fullName: true } },
        team: { select: { name: true } },
      },
    });
    return rows.map((r) => ({
      playerId: r.playerId!,
      playerName: r.player?.fullName,
      teamName: r.team?.name,
      type: r.type as PlayerEvent['type'],
    }));
  }

  /** Tabla completa de estadísticas por jugador (ordenada por MVP score). */
  async playerStats(categoryId: string) {
    return computePlayerStats(await this.eventsForCategory(categoryId));
  }

  /** Líderes de la categoría: MVP, máximo anotador, mejor atacante/bloqueador/servidor. */
  async leaders(categoryId: string) {
    const stats = computePlayerStats(await this.eventsForCategory(categoryId));
    return computeLeaders(stats);
  }

  /** Estadísticas agregadas de un jugador concreto (todas sus categorías). */
  async forPlayer(playerId: string) {
    const rows = await this.prisma.matchEvent.findMany({
      where: { playerId },
      include: { player: { select: { fullName: true } }, team: { select: { name: true } } },
    });
    const events: PlayerEvent[] = rows.map((r) => ({
      playerId,
      playerName: r.player?.fullName,
      teamName: r.team?.name,
      type: r.type as PlayerEvent['type'],
    }));
    const [stat] = computePlayerStats(events);
    return stat ?? null;
  }
}

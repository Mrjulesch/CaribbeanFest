import { Injectable, NotFoundException } from '@nestjs/common';
import { MatchStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class MatchesService {
  constructor(private readonly prisma: PrismaService) {}

  /** Listado público filtrable por torneo/categoría/estado (calendario y resultados). */
  list(filter: { tournamentId?: string; categoryId?: string; status?: MatchStatus }) {
    return this.prisma.match.findMany({
      where: {
        tournamentId: filter.tournamentId,
        categoryId: filter.categoryId,
        status: filter.status,
      },
      include: {
        homeTeam: { select: { id: true, name: true } },
        awayTeam: { select: { id: true, name: true } },
        court: { select: { id: true, name: true, venue: { select: { name: true } } } },
        sets: { orderBy: { setNumber: 'asc' } },
      },
      orderBy: { scheduledAt: 'asc' },
    });
  }

  async getOrThrow(id: string) {
    const match = await this.prisma.match.findUnique({
      where: { id },
      include: {
        homeTeam: { select: { id: true, name: true } },
        awayTeam: { select: { id: true, name: true } },
        court: { select: { id: true, name: true, venue: { select: { name: true } } } },
        sets: { orderBy: { setNumber: 'asc' } },
        assignments: true,
      },
    });
    if (!match) throw new NotFoundException('Partido no encontrado');
    return match;
  }

  /** Partidos asignados a un árbitro, resueltos por el id de USUARIO autenticado
   *  (la asignación apunta al perfil de árbitro, cuyo userId es este). */
  assignedTo(userId: string) {
    return this.prisma.match.findMany({
      where: { assignments: { some: { referee: { userId } } } },
      include: {
        homeTeam: { select: { id: true, name: true } },
        awayTeam: { select: { id: true, name: true } },
        court: { select: { id: true, name: true, venue: { select: { name: true } } } },
        sets: { orderBy: { setNumber: 'asc' } },
      },
      orderBy: { scheduledAt: 'asc' },
    });
  }
}

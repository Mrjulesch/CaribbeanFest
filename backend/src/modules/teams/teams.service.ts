import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateClubDto,
  CreatePlayerDto,
  CreateStaffDto,
  CreateTeamDto,
} from './dto/team.dto';

@Injectable()
export class TeamsService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Clubes ───────────────────────────────────────────────────────────────────
  createClub(dto: CreateClubDto) {
    return this.prisma.club.create({ data: dto });
  }

  listClubs() {
    return this.prisma.club.findMany({ orderBy: { name: 'asc' } });
  }

  // ── Equipos ──────────────────────────────────────────────────────────────────
  createTeam(clubId: string, dto: CreateTeamDto) {
    return this.prisma.team.create({
      data: {
        clubId,
        name: dto.name,
        categoryId: dto.categoryId,
        coachName: dto.coachName,
        delegateName: dto.delegateName,
      },
    });
  }

  async getTeam(id: string) {
    const team = await this.prisma.team.findUnique({
      where: { id },
      include: { players: true, staff: true, club: true, category: true },
    });
    if (!team) throw new NotFoundException('Equipo no encontrado');
    return team;
  }

  /** Equipos de una categoría (consulta pública). Incluye el conteo de jugadores. */
  listByCategory(categoryId: string) {
    return this.prisma.team.findMany({
      where: { categoryId },
      include: {
        club: { select: { name: true, crestUrl: true } },
        _count: { select: { players: true } },
      },
      orderBy: { name: 'asc' },
    });
  }

  removeTeam(id: string) {
    return this.prisma.team.delete({ where: { id } });
  }

  // ── Jugadores ─────────────────────────────────────────────────────────────────
  /** Máximo de jugadores inscritos por equipo (reglamento). */
  static readonly MAX_PLAYERS = 14;

  async addPlayer(teamId: string, dto: CreatePlayerDto) {
    const count = await this.prisma.player.count({ where: { teamId } });
    if (count >= TeamsService.MAX_PLAYERS) {
      throw new BadRequestException(
        `Límite de ${TeamsService.MAX_PLAYERS} jugadores por equipo alcanzado`,
      );
    }
    return this.prisma.player.create({
      data: {
        teamId,
        fullName: dto.fullName,
        photoUrl: dto.photoUrl,
        document: dto.document,
        birthDate: dto.birthDate ? new Date(dto.birthDate) : undefined,
        position: dto.position,
        jerseyNumber: dto.jerseyNumber,
        heightCm: dto.heightCm,
        weightKg: dto.weightKg,
      },
    });
  }

  removePlayer(id: string) {
    return this.prisma.player.delete({ where: { id } });
  }

  // ── Cuerpo técnico ──────────────────────────────────────────────────────────────
  addStaff(teamId: string, dto: CreateStaffDto) {
    return this.prisma.staffMember.create({ data: { teamId, ...dto } });
  }
}

import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateCategoryDto,
  CreateCourtDto,
  CreateTournamentDto,
  CreateVenueDto,
  UpdateTournamentDto,
} from './dto/tournament.dto';

@Injectable()
export class TournamentsService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Torneos ────────────────────────────────────────────────────────────────
  create(dto: CreateTournamentDto) {
    return this.prisma.tournament.create({
      data: {
        name: dto.name,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        logoUrl: dto.logoUrl,
        rulebookUrl: dto.rulebookUrl,
        paymentLink: dto.paymentLink,
      },
    });
  }

  /** Listado público: solo torneos publicados, salvo que se pida lo contrario. */
  list(onlyPublished = true) {
    return this.prisma.tournament.findMany({
      where: onlyPublished ? { isPublished: true } : undefined,
      orderBy: { startDate: 'desc' },
      include: { categories: true },
    });
  }

  async get(id: string) {
    const t = await this.prisma.tournament.findUnique({
      where: { id },
      include: {
        categories: true,
        venues: { include: { courts: true } },
      },
    });
    if (!t) throw new NotFoundException('Torneo no encontrado');
    return t;
  }

  async update(id: string, dto: UpdateTournamentDto) {
    await this.assertExists(id);
    return this.prisma.tournament.update({
      where: { id },
      data: {
        ...dto,
        startDate: dto.startDate ? new Date(dto.startDate) : undefined,
        endDate: dto.endDate ? new Date(dto.endDate) : undefined,
      },
    });
  }

  async remove(id: string) {
    await this.assertExists(id);
    await this.prisma.tournament.delete({ where: { id } });
    return { deleted: true };
  }

  // ── Categorías ───────────────────────────────────────────────────────────────
  async addCategory(tournamentId: string, dto: CreateCategoryDto) {
    await this.assertExists(tournamentId);
    return this.prisma.category.create({
      data: {
        tournamentId,
        name: dto.name,
        gender: dto.gender,
        format: dto.format ?? 'ROUND_ROBIN',
        bestOf: dto.bestOf ?? 5,
      },
    });
  }

  removeCategory(categoryId: string) {
    return this.prisma.category.delete({ where: { id: categoryId } });
  }

  // ── Escenarios (sedes + canchas) ──────────────────────────────────────────────
  async addVenue(tournamentId: string, dto: CreateVenueDto) {
    await this.assertExists(tournamentId);
    return this.prisma.venue.create({
      data: { tournamentId, name: dto.name, address: dto.address },
    });
  }

  addCourt(venueId: string, dto: CreateCourtDto) {
    return this.prisma.court.create({ data: { venueId, name: dto.name } });
  }

  private async assertExists(id: string) {
    const exists = await this.prisma.tournament.findUnique({ where: { id }, select: { id: true } });
    if (!exists) throw new NotFoundException('Torneo no encontrado');
  }
}

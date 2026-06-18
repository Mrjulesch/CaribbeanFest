import { Injectable, NotFoundException } from '@nestjs/common';
import { RegistrationStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateRegistrationDto } from './dto/registration.dto';

@Injectable()
export class RegistrationsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Envío público de una inscripción (queda PENDIENTE de validación). */
  create(dto: CreateRegistrationDto) {
    return this.prisma.registration.create({
      data: {
        tournamentId: dto.tournamentId,
        categoryId: dto.categoryId,
        teamName: dto.teamName,
        clubName: dto.clubName,
        city: dto.city,
        contactName: dto.contactName,
        contactEmail: dto.contactEmail,
        contactPhone: dto.contactPhone,
        players: dto.players as object[],
      },
    });
  }

  /** Listado para la organización (filtrable por estado). */
  list(status?: RegistrationStatus) {
    return this.prisma.registration.findMany({
      where: status ? { status } : undefined,
      orderBy: { createdAt: 'desc' },
    });
  }

  /** Acepta: materializa Club + Team + Players y marca ACCEPTED. */
  async accept(id: string) {
    const r = await this.prisma.registration.findUnique({ where: { id } });
    if (!r) throw new NotFoundException('Inscripción no encontrada');
    if (r.status === 'ACCEPTED') return r;

    const club = await this.prisma.club.create({
      data: { name: r.clubName ?? r.teamName, city: r.city },
    });
    const team = await this.prisma.team.create({
      data: { clubId: club.id, name: r.teamName, categoryId: r.categoryId },
    });

    const players = Array.isArray(r.players) ? (r.players as any[]) : [];
    for (const p of players.slice(0, 14)) {
      await this.prisma.player.create({
        data: {
          teamId: team.id,
          fullName: String(p.fullName ?? 'Jugador'),
          document: p.document ? String(p.document) : undefined,
          jerseyNumber: typeof p.jerseyNumber === 'number' ? p.jerseyNumber : undefined,
        },
      });
    }

    return this.prisma.registration.update({
      where: { id },
      data: { status: 'ACCEPTED', reviewedAt: new Date() },
    });
  }

  /** Rechaza la inscripción con una nota opcional. */
  async reject(id: string, notes?: string) {
    const r = await this.prisma.registration.findUnique({ where: { id } });
    if (!r) throw new NotFoundException('Inscripción no encontrada');
    return this.prisma.registration.update({
      where: { id },
      data: { status: 'REJECTED', reviewedAt: new Date(), notes },
    });
  }
}

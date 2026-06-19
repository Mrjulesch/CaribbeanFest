import { Injectable, NotFoundException } from '@nestjs/common';
import { RegistrationStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { MailService } from '../mail/mail.service';
import { CreateRegistrationDto } from './dto/registration.dto';

@Injectable()
export class RegistrationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mail: MailService,
  ) {}

  /**
   * Aprueba la inscripción: envía al delegado el correo de aceptación con el link
   * de pago externo. NO inscribe al equipo todavía (eso ocurre al confirmar el pago
   * con accept()), por lo que el equipo aún no entra a los fixtures.
   */
  async approve(id: string, paymentLink?: string) {
    const r = await this.prisma.registration.findUnique({ where: { id } });
    if (!r) throw new NotFoundException('Inscripción no encontrada');

    const html = `
      <h2>¡Inscripción aceptada! 🏐</h2>
      <p>Hola ${r.contactName}, tu equipo <b>${r.teamName}</b> fue aceptado en Caribbean Fest.</p>
      ${paymentLink ? `<p>Para confirmar tu cupo, realiza el pago aquí:</p>
        <p><a href="${paymentLink}" style="background:#0A4FA0;color:#fff;padding:10px 18px;border-radius:6px;text-decoration:none">Pagar inscripción</a></p>
        <p>O copia este enlace: ${paymentLink}</p>` : ''}
      <p>Una vez confirmemos el pago, tu equipo quedará inscrito en el fixture.</p>
      <p>— Organización Caribbean Fest</p>`;

    await this.mail.send(r.contactEmail, 'Aceptación de inscripción · Caribbean Fest', html);

    return this.prisma.registration.update({
      where: { id },
      data: { paymentLink: paymentLink ?? null, approvalSentAt: new Date() },
    });
  }

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

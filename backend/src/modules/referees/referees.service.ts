import { BadRequestException, ConflictException, Injectable } from '@nestjs/common';
import * as argon2 from 'argon2';
import { PrismaService } from '../../prisma/prisma.service';
import { AssignRefereeDto, CreateRefereeDto, CreateRefereeProfileDto } from './dto/referee.dto';

@Injectable()
export class RefereesService {
  constructor(private readonly prisma: PrismaService) {}

  /** Crea el perfil de árbitro a partir de un usuario con rol REFEREE. */
  async createProfile(dto: CreateRefereeProfileDto) {
    const user = await this.prisma.user.findUnique({ where: { id: dto.userId } });
    if (!user || user.role !== 'REFEREE') {
      throw new BadRequestException('El usuario no existe o no tiene rol de árbitro');
    }
    return this.prisma.refereeProfile.create({
      data: { userId: dto.userId, license: dto.license, level: dto.level },
    });
  }

  /** Crea de una sola vez la cuenta (rol REFEREE) y el perfil del árbitro. */
  async createReferee(dto: CreateRefereeDto) {
    const exists = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (exists) throw new ConflictException('El correo ya está registrado');

    const passwordHash = await argon2.hash(dto.password);
    const user = await this.prisma.user.create({
      data: { email: dto.email, passwordHash, fullName: dto.fullName, role: 'REFEREE' },
    });
    return this.prisma.refereeProfile.create({
      data: { userId: user.id, license: dto.license, level: dto.level },
      include: { user: { select: { fullName: true, email: true } } },
    });
  }

  list() {
    return this.prisma.refereeProfile.findMany({
      include: {
        user: { select: { fullName: true, email: true } },
        _count: { select: { assignments: true } },
      },
    });
  }

  /** Asignaciones de un partido (con datos del árbitro). */
  assignmentsForMatch(matchId: string) {
    return this.prisma.refereeAssignment.findMany({
      where: { matchId },
      include: { referee: { include: { user: { select: { fullName: true } } } } },
    });
  }

  /** Asigna un árbitro a un partido (rol arbitral). */
  assign(matchId: string, dto: AssignRefereeDto) {
    return this.prisma.refereeAssignment.create({
      data: { matchId, refereeId: dto.refereeId, role: dto.role ?? 'first' },
    });
  }

  unassign(matchId: string, refereeId: string) {
    return this.prisma.refereeAssignment.delete({
      where: { matchId_refereeId: { matchId, refereeId } },
    });
  }
}

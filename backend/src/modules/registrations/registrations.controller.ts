import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { RegistrationStatus, Role } from '@prisma/client';
import { RegistrationsService } from './registrations.service';
import { ApproveRegistrationDto, CreateRegistrationDto, RejectRegistrationDto } from './dto/registration.dto';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';

@Controller('registrations')
export class RegistrationsController {
  constructor(private readonly registrations: RegistrationsService) {}

  /** Inscripción pública de un equipo (sin login). */
  @Public() @Post()
  create(@Body() dto: CreateRegistrationDto) {
    return this.registrations.create(dto);
  }

  /** La organización revisa las inscripciones. */
  @Roles(Role.ADMIN) @Get()
  list(@Query('status') status?: RegistrationStatus) {
    return this.registrations.list(status);
  }

  /** Envía el correo de aceptación + link de pago (no inscribe aún). */
  @Roles(Role.ADMIN) @Post(':id/approve')
  approve(@Param('id') id: string, @Body() dto: ApproveRegistrationDto) {
    return this.registrations.approve(id, dto.paymentLink);
  }

  @Roles(Role.ADMIN) @Post(':id/accept')
  accept(@Param('id') id: string) {
    return this.registrations.accept(id);
  }

  @Roles(Role.ADMIN) @Post(':id/reject')
  reject(@Param('id') id: string, @Body() dto: RejectRegistrationDto) {
    return this.registrations.reject(id, dto.notes);
  }
}

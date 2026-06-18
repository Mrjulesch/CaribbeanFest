import { Body, Controller, Param, Post } from '@nestjs/common';
import { Role } from '@prisma/client';
import { NotificationsService } from './notifications.service';
import { AnnouncementDto, FollowDto, RegisterDeviceDto } from './dto/notifications.dto';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  /** El público registra su token de dispositivo para recibir push. */
  @Public() @Post('devices')
  register(@Body() dto: RegisterDeviceDto) {
    return this.notifications.registerDevice(dto.token, dto.platform);
  }

  /** Seguir un equipo o torneo favorito (suscripción a topic FCM). */
  @Public() @Post('follow')
  follow(@Body() dto: FollowDto) {
    return this.notifications.follow(dto.token, dto.kind, dto.id);
  }

  @Public() @Post('unfollow')
  unfollow(@Body() dto: FollowDto) {
    return this.notifications.unfollow(dto.token, dto.kind, dto.id);
  }

  /** Comunicado oficial: lo persiste y envía push a los seguidores del torneo. */
  @Roles(Role.ADMIN) @Post('tournaments/:tournamentId/announcements')
  announce(@Param('tournamentId') tournamentId: string, @Body() dto: AnnouncementDto) {
    return this.notifications.publishAnnouncement(tournamentId, dto.title, dto.body);
  }
}

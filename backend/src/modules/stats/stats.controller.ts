import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { Role } from '@prisma/client';
import { StatsService } from './stats.service';
import { RecordEventDto } from './dto/record-event.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { Public } from '../../common/decorators/public.decorator';

@Controller('stats')
export class StatsController {
  constructor(private readonly stats: StatsService) {}

  /** El árbitro (o admin) registra un evento de estadística. */
  @Roles(Role.REFEREE, Role.ADMIN)
  @Post('matches/:matchId/events')
  record(@Param('matchId') matchId: string, @Body() dto: RecordEventDto) {
    return this.stats.recordEvent(matchId, dto);
  }

  // Consultas públicas
  @Public() @Get('category/:categoryId/players')
  players(@Param('categoryId') categoryId: string) {
    return this.stats.playerStats(categoryId);
  }

  @Public() @Get('category/:categoryId/leaders')
  leaders(@Param('categoryId') categoryId: string) {
    return this.stats.leaders(categoryId);
  }

  @Public() @Get('player/:playerId')
  player(@Param('playerId') playerId: string) {
    return this.stats.forPlayer(playerId);
  }
}

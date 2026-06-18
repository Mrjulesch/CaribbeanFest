import { Controller, Get, Param, Query } from '@nestjs/common';
import { MatchStatus, Role } from '@prisma/client';
import { MatchesService } from './matches.service';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';

@Controller('matches')
export class MatchesController {
  constructor(private readonly matches: MatchesService) {}

  @Public()
  @Get()
  list(
    @Query('tournamentId') tournamentId?: string,
    @Query('categoryId') categoryId?: string,
    @Query('status') status?: MatchStatus,
  ) {
    return this.matches.list({ tournamentId, categoryId, status });
  }

  /** Partidos asignados al árbitro autenticado. */
  @Roles(Role.REFEREE, Role.ADMIN)
  @Get('assigned/me')
  assigned(@CurrentUser() user: AuthUser) {
    return this.matches.assignedTo(user.id);
  }

  @Public()
  @Get(':id')
  get(@Param('id') id: string) {
    return this.matches.getOrThrow(id);
  }
}

import { Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { Role } from '@prisma/client';
import { RefereesService } from './referees.service';
import { AssignRefereeDto, CreateRefereeDto, CreateRefereeProfileDto } from './dto/referee.dto';
import { Roles } from '../../common/decorators/roles.decorator';

@Controller('referees')
export class RefereesController {
  constructor(private readonly referees: RefereesService) {}

  @Roles(Role.ADMIN) @Post()
  createProfile(@Body() dto: CreateRefereeProfileDto) {
    return this.referees.createProfile(dto);
  }

  /** Crea cuenta + perfil de árbitro de una vez. */
  @Roles(Role.ADMIN) @Post('full')
  createReferee(@Body() dto: CreateRefereeDto) {
    return this.referees.createReferee(dto);
  }

  @Roles(Role.ADMIN) @Get()
  list() {
    return this.referees.list();
  }

  /** Asignaciones de un partido. */
  @Roles(Role.ADMIN) @Get('matches/:matchId')
  forMatch(@Param('matchId') matchId: string) {
    return this.referees.assignmentsForMatch(matchId);
  }

  @Roles(Role.ADMIN) @Post('matches/:matchId/assign')
  assign(@Param('matchId') matchId: string, @Body() dto: AssignRefereeDto) {
    return this.referees.assign(matchId, dto);
  }

  @Roles(Role.ADMIN) @Delete('matches/:matchId/referee/:refereeId')
  unassign(@Param('matchId') matchId: string, @Param('refereeId') refereeId: string) {
    return this.referees.unassign(matchId, refereeId);
  }
}

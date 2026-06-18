import { Body, Controller, Delete, Get, Param, Post, Query } from '@nestjs/common';
import { Role } from '@prisma/client';
import { TeamsService } from './teams.service';
import {
  CreateClubDto,
  CreatePlayerDto,
  CreateStaffDto,
  CreateTeamDto,
} from './dto/team.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { Public } from '../../common/decorators/public.decorator';

@Controller()
export class TeamsController {
  constructor(private readonly teams: TeamsService) {}

  // ── Clubes (admin crea; un club también puede inscribirse) ──────────────────
  @Roles(Role.ADMIN, Role.CLUB) @Post('clubs')
  createClub(@Body() dto: CreateClubDto) {
    return this.teams.createClub(dto);
  }

  @Public() @Get('clubs')
  listClubs() {
    return this.teams.listClubs();
  }

  // ── Equipos ───────────────────────────────────────────────────────────────────
  @Roles(Role.ADMIN, Role.CLUB) @Post('clubs/:clubId/teams')
  createTeam(@Param('clubId') clubId: string, @Body() dto: CreateTeamDto) {
    return this.teams.createTeam(clubId, dto);
  }

  @Public() @Get('teams')
  listByCategory(@Query('categoryId') categoryId: string) {
    return this.teams.listByCategory(categoryId);
  }

  @Public() @Get('teams/:id')
  getTeam(@Param('id') id: string) {
    return this.teams.getTeam(id);
  }

  @Roles(Role.ADMIN, Role.CLUB) @Delete('teams/:id')
  removeTeam(@Param('id') id: string) {
    return this.teams.removeTeam(id);
  }

  // ── Jugadores ──────────────────────────────────────────────────────────────────
  @Roles(Role.ADMIN, Role.CLUB) @Post('teams/:teamId/players')
  addPlayer(@Param('teamId') teamId: string, @Body() dto: CreatePlayerDto) {
    return this.teams.addPlayer(teamId, dto);
  }

  @Roles(Role.ADMIN, Role.CLUB) @Delete('players/:id')
  removePlayer(@Param('id') id: string) {
    return this.teams.removePlayer(id);
  }

  // ── Cuerpo técnico ───────────────────────────────────────────────────────────────
  @Roles(Role.ADMIN, Role.CLUB) @Post('teams/:teamId/staff')
  addStaff(@Param('teamId') teamId: string, @Body() dto: CreateStaffDto) {
    return this.teams.addStaff(teamId, dto);
  }
}

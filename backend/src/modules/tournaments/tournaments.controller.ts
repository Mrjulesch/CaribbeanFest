import { Body, Controller, Delete, Get, Param, Patch, Post } from '@nestjs/common';
import { Role } from '@prisma/client';
import { TournamentsService } from './tournaments.service';
import {
  CreateCategoryDto,
  CreateCourtDto,
  CreateTournamentDto,
  CreateVenueDto,
  UpdateTournamentDto,
} from './dto/tournament.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { Public } from '../../common/decorators/public.decorator';

@Controller('tournaments')
export class TournamentsController {
  constructor(private readonly tournaments: TournamentsService) {}

  // Consulta pública
  @Public() @Get()
  list() {
    return this.tournaments.list(true);
  }

  /** Admin: lista TODOS los torneos, incluidos los borradores (no publicados).
   *  Debe declararse antes de ':id' para no ser capturado por esa ruta. */
  @Roles(Role.ADMIN) @Get('all')
  listAll() {
    return this.tournaments.list(false);
  }

  @Public() @Get(':id')
  get(@Param('id') id: string) {
    return this.tournaments.get(id);
  }

  // Administración
  @Roles(Role.ADMIN) @Post()
  create(@Body() dto: CreateTournamentDto) {
    return this.tournaments.create(dto);
  }

  @Roles(Role.ADMIN) @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateTournamentDto) {
    return this.tournaments.update(id, dto);
  }

  @Roles(Role.ADMIN) @Delete(':id')
  remove(@Param('id') id: string) {
    return this.tournaments.remove(id);
  }

  @Roles(Role.ADMIN) @Post(':id/categories')
  addCategory(@Param('id') id: string, @Body() dto: CreateCategoryDto) {
    return this.tournaments.addCategory(id, dto);
  }

  @Roles(Role.ADMIN) @Delete('categories/:categoryId')
  removeCategory(@Param('categoryId') categoryId: string) {
    return this.tournaments.removeCategory(categoryId);
  }

  @Roles(Role.ADMIN) @Post(':id/venues')
  addVenue(@Param('id') id: string, @Body() dto: CreateVenueDto) {
    return this.tournaments.addVenue(id, dto);
  }

  @Roles(Role.ADMIN) @Post('venues/:venueId/courts')
  addCourt(@Param('venueId') venueId: string, @Body() dto: CreateCourtDto) {
    return this.tournaments.addCourt(venueId, dto);
  }
}

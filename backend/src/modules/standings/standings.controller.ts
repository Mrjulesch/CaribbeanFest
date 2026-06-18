import { Controller, Get, Param } from '@nestjs/common';
import { StandingsService } from './standings.service';
import { Public } from '../../common/decorators/public.decorator';

@Controller('standings')
export class StandingsController {
  constructor(private readonly standings: StandingsService) {}

  /** Consulta pública de la tabla de posiciones de una categoría. */
  @Public()
  @Get('category/:categoryId')
  forCategory(@Param('categoryId') categoryId: string) {
    return this.standings.forCategory(categoryId);
  }
}

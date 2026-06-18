import { Body, Controller, Param, Put } from '@nestjs/common';
import { Role } from '@prisma/client';
import { ScoringService } from './scoring.service';
import { EditScoreDto } from './dto/edit-score.dto';
import { Roles } from '../../common/decorators/roles.decorator';

@Controller('scoring')
export class ScoringController {
  constructor(private readonly scoring: ScoringService) {}

  /**
   * Edita el marcador completo de un partido (corrección administrativa),
   * incluso si ya estaba finalizado. Recalcula resultado y tabla.
   */
  @Roles(Role.ADMIN, Role.REFEREE)
  @Put('matches/:matchId')
  edit(@Param('matchId') matchId: string, @Body() dto: EditScoreDto) {
    return this.scoring.editMatch(matchId, dto.sets);
  }
}

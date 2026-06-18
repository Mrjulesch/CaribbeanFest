import { Body, Controller, Param, Post } from '@nestjs/common';
import { Role } from '@prisma/client';
import { FixturesService } from './fixtures.service';
import { GenerateFixtureDto } from './dto/generate-fixture.dto';
import { Roles } from '../../common/decorators/roles.decorator';

@Controller('fixtures')
export class FixturesController {
  constructor(private readonly fixtures: FixturesService) {}

  /** Genera (o regenera) el fixture de una categoría. Solo administradores. */
  @Roles(Role.ADMIN)
  @Post('category/:categoryId/generate')
  generate(@Param('categoryId') categoryId: string, @Body() dto: GenerateFixtureDto) {
    return this.fixtures.generate(categoryId, dto);
  }
}

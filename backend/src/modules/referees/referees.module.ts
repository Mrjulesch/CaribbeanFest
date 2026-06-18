import { Module } from '@nestjs/common';
import { RefereesService } from './referees.service';
import { RefereesController } from './referees.controller';

@Module({
  controllers: [RefereesController],
  providers: [RefereesService],
  exports: [RefereesService],
})
export class RefereesModule {}

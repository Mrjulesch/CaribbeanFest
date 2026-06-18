import { Module } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { ReportsController } from './reports.controller';
import { StandingsModule } from '../standings/standings.module';
import { StatsModule } from '../stats/stats.module';

@Module({
  imports: [StandingsModule, StatsModule],
  controllers: [ReportsController],
  providers: [ReportsService],
})
export class ReportsModule {}

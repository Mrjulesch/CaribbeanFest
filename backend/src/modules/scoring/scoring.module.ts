import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ScoringService } from './scoring.service';
import { ScoringGateway } from './scoring.gateway';
import { ScoringController } from './scoring.controller';
import { StandingsModule } from '../standings/standings.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [StandingsModule, NotificationsModule, JwtModule.register({})],
  controllers: [ScoringController],
  providers: [ScoringService, ScoringGateway],
  exports: [ScoringService],
})
export class ScoringModule {}

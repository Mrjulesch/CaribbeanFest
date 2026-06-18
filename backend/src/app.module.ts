import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { MatchesModule } from './modules/matches/matches.module';
import { StandingsModule } from './modules/standings/standings.module';
import { ScoringModule } from './modules/scoring/scoring.module';
import { FixturesModule } from './modules/fixtures/fixtures.module';
import { TournamentsModule } from './modules/tournaments/tournaments.module';
import { TeamsModule } from './modules/teams/teams.module';
import { RefereesModule } from './modules/referees/referees.module';
import { StatsModule } from './modules/stats/stats.module';
import { ReportsModule } from './modules/reports/reports.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { RegistrationsModule } from './modules/registrations/registrations.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RolesGuard } from './common/guards/roles.guard';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 120 }]),
    PrismaModule,
    AuthModule,
    MatchesModule,
    StandingsModule,
    ScoringModule,
    FixturesModule,
    TournamentsModule,
    TeamsModule,
    RefereesModule,
    StatsModule,
    ReportsModule,
    NotificationsModule,
    RegistrationsModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AppModule {}

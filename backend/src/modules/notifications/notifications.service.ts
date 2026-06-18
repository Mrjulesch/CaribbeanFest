import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { FcmService } from './fcm.service';
import {
  announcementMessage,
  matchFinishedMessage,
  matchStartMessage,
  scheduleChangeMessage,
  topicFor,
  MatchInfo,
} from './notification-messages';

/**
 * Orquesta las notificaciones de dominio: decide a qué topics enviar cada evento.
 * Topics: tournament_{id}, match_{id}, team_{homeId}, team_{awayId}.
 */
@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmService,
  ) {}

  // ── Registro de dispositivos / seguir favoritos ───────────────────────────────
  registerDevice(token: string, platform?: string) {
    return this.prisma.deviceToken.upsert({
      where: { token },
      create: { token, platform },
      update: { platform },
    });
  }

  /** Seguir un equipo/torneo: suscribe el token al topic correspondiente. */
  async follow(token: string, kind: 'team' | 'tournament', id: string) {
    await this.registerDevice(token);
    await this.fcm.subscribe([token], topicFor(kind, id));
    return { following: topicFor(kind, id) };
  }

  async unfollow(token: string, kind: 'team' | 'tournament', id: string) {
    await this.fcm.unsubscribe([token], topicFor(kind, id));
    return { unfollowed: topicFor(kind, id) };
  }

  // ── Eventos de partido ─────────────────────────────────────────────────────────
  async notifyMatchStart(matchId: string) {
    const m = await this.matchInfo(matchId);
    if (!m) return;
    await this.fcm.sendToTopics(this.matchTopics(m), matchStartMessage(m.info));
  }

  async notifyMatchFinished(matchId: string) {
    const m = await this.matchInfo(matchId);
    if (!m) return;
    await this.fcm.sendToTopics(this.matchTopics(m), matchFinishedMessage(m.info));
  }

  async notifyScheduleChange(matchId: string) {
    const m = await this.matchInfo(matchId);
    if (!m) return;
    await this.fcm.sendToTopics(this.matchTopics(m), scheduleChangeMessage(m.info));
  }

  // ── Comunicados oficiales ────────────────────────────────────────────────────────
  async publishAnnouncement(tournamentId: string, title: string, body: string) {
    const ann = await this.prisma.announcement.create({
      data: { tournamentId, title, body },
    });
    await this.fcm.sendToTopic(topicFor('tournament', tournamentId), announcementMessage(tournamentId, title, body));
    return ann;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────────
  private async matchInfo(matchId: string) {
    const m = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        homeTeam: { select: { id: true, name: true } },
        awayTeam: { select: { id: true, name: true } },
        court: { select: { name: true } },
      },
    });
    if (!m) return null;
    const info: MatchInfo = {
      id: m.id,
      homeTeam: m.homeTeam?.name,
      awayTeam: m.awayTeam?.name,
      homeSetsWon: m.homeSetsWon,
      awaySetsWon: m.awaySetsWon,
      court: m.court?.name,
      scheduledAt: m.scheduledAt ? new Date(m.scheduledAt).toLocaleString('es') : undefined,
    };
    return { info, tournamentId: m.tournamentId, homeId: m.homeTeamId, awayId: m.awayTeamId };
  }

  private matchTopics(m: { tournamentId: string; homeId: string | null; awayId: string | null; info: MatchInfo }) {
    const topics = [topicFor('tournament', m.tournamentId), topicFor('match', m.info.id)];
    if (m.homeId) topics.push(topicFor('team', m.homeId));
    if (m.awayId) topics.push(topicFor('team', m.awayId));
    return topics;
  }
}

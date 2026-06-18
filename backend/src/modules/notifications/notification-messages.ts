/**
 * Construcción de los mensajes push. Puro y testeable: separa el "qué se dice"
 * del "cómo se envía" (FcmService). Los datos (`data`) viajan como strings para que
 * la app pueda navegar al recurso correcto al tocar la notificación.
 */
export interface PushMessage {
  title: string;
  body: string;
  data: Record<string, string>;
}

export interface MatchInfo {
  id: string;
  homeTeam?: string;
  awayTeam?: string;
  homeSetsWon?: number;
  awaySetsWon?: number;
  court?: string;
  scheduledAt?: string;
}

const vs = (m: MatchInfo) => `${m.homeTeam ?? '?'} vs ${m.awayTeam ?? '?'}`;

export function matchStartMessage(m: MatchInfo): PushMessage {
  return {
    title: '¡Comienza el partido!',
    body: `${vs(m)} está en juego${m.court ? ` · ${m.court}` : ''}`,
    data: { type: 'MATCH_START', matchId: m.id },
  };
}

export function matchFinishedMessage(m: MatchInfo): PushMessage {
  return {
    title: 'Resultado final',
    body: `${vs(m)}: ${m.homeSetsWon ?? 0}-${m.awaySetsWon ?? 0}`,
    data: { type: 'MATCH_FINISHED', matchId: m.id },
  };
}

export function scheduleChangeMessage(m: MatchInfo): PushMessage {
  return {
    title: 'Cambio de horario',
    body: `${vs(m)} se jugará ${m.scheduledAt ?? 'en nueva fecha'}${m.court ? ` · ${m.court}` : ''}`,
    data: { type: 'SCHEDULE_CHANGE', matchId: m.id },
  };
}

export function announcementMessage(tournamentId: string, title: string, body: string): PushMessage {
  return {
    title,
    body,
    data: { type: 'ANNOUNCEMENT', tournamentId },
  };
}

/** Topic FCM válido para un recurso (caracteres permitidos: [a-zA-Z0-9-_.~%]). */
export function topicFor(kind: 'team' | 'tournament' | 'match', id: string): string {
  return `${kind}_${id.replace(/[^a-zA-Z0-9\-_.~%]/g, '')}`;
}

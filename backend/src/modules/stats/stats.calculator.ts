/**
 * Agregación de estadísticas por jugador a partir de eventos de partido.
 * Puro y testeable. Los eventos los registra el árbitro durante el encuentro.
 *
 * Tipos de evento:
 *   ATTACK     → punto de ataque (remate)
 *   BLOCK      → punto de bloqueo
 *   SERVE_ACE  → punto directo de saque (ace)
 *   POINT      → punto genérico (cuando no se detalla la acción)
 *   ERROR      → error propio (resta para el MVP)
 */
export type EventType = 'ATTACK' | 'BLOCK' | 'SERVE_ACE' | 'POINT' | 'ERROR';

export interface PlayerEvent {
  playerId: string;
  playerName?: string;
  teamName?: string;
  type: EventType;
}

export interface PlayerStat {
  playerId: string;
  playerName?: string;
  teamName?: string;
  points: number; // anotaciones totales (ATTACK + BLOCK + SERVE_ACE + POINT)
  attacks: number;
  blocks: number;
  aces: number;
  errors: number;
  mvpScore: number;
}

/** Puntúa el aporte global de un jugador (premia bloqueos/aces, penaliza errores). */
export function mvpScore(s: { points: number; blocks: number; aces: number; errors: number }): number {
  return s.points + 0.5 * s.blocks + 0.5 * s.aces - 0.5 * s.errors;
}

export function computePlayerStats(events: PlayerEvent[]): PlayerStat[] {
  const map = new Map<string, PlayerStat>();

  for (const e of events) {
    const s =
      map.get(e.playerId) ??
      {
        playerId: e.playerId,
        playerName: e.playerName,
        teamName: e.teamName,
        points: 0,
        attacks: 0,
        blocks: 0,
        aces: 0,
        errors: 0,
        mvpScore: 0,
      };

    switch (e.type) {
      case 'ATTACK':
        s.attacks++;
        s.points++;
        break;
      case 'BLOCK':
        s.blocks++;
        s.points++;
        break;
      case 'SERVE_ACE':
        s.aces++;
        s.points++;
        break;
      case 'POINT':
        s.points++;
        break;
      case 'ERROR':
        s.errors++;
        break;
    }
    map.set(e.playerId, s);
  }

  const stats = [...map.values()];
  for (const s of stats) s.mvpScore = mvpScore(s);
  return stats.sort((a, b) => b.mvpScore - a.mvpScore);
}

export interface Leaders {
  mvp: PlayerStat | null;
  topScorer: PlayerStat | null; // máximo anotador
  bestAttacker: PlayerStat | null;
  bestBlocker: PlayerStat | null;
  bestServer: PlayerStat | null;
}

/** Selecciona los líderes por categoría a partir de las estadísticas agregadas. */
export function computeLeaders(stats: PlayerStat[]): Leaders {
  if (stats.length === 0) {
    return { mvp: null, topScorer: null, bestAttacker: null, bestBlocker: null, bestServer: null };
  }
  const top = (key: (s: PlayerStat) => number) =>
    stats.reduce((best, s) => (key(s) > key(best) ? s : best), stats[0]);

  return {
    mvp: top((s) => s.mvpScore),
    topScorer: top((s) => s.points),
    bestAttacker: top((s) => s.attacks),
    bestBlocker: top((s) => s.blocks),
    bestServer: top((s) => s.aces),
  };
}

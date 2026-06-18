/**
 * Reglas de voleibol y sistema de puntos FIVB.
 * Funciones puras, sin dependencias de framework ni base de datos: la fuente de verdad
 * de los invariantes del deporte. Se prueban de forma aislada y las usa el servidor para
 * validar todo lo que reportan los jueces (el cliente nunca decide el resultado).
 */

export interface SetScore {
  setNumber: number;
  homePoints: number;
  awayPoints: number;
}

export const POINTS_TO_WIN_SET = 25;
export const POINTS_TO_WIN_DECIDER = 15; // set decisivo (último posible)
export const MIN_LEAD = 2;
export const DEFAULT_BEST_OF = 5;

/** Formato del partido: best-of-3 (2 de 3) o best-of-5 (3 de 5). */
export function setsToWin(bestOf: number): number {
  return bestOf <= 3 ? 2 : 3;
}

/** Número máximo de sets posibles según el formato. */
export function maxSets(bestOf: number): number {
  return bestOf <= 3 ? 3 : 5;
}

/** Puntos necesarios para ganar un set; el set decisivo (último) es a 15. */
export function pointsTarget(setNumber: number, bestOf: number = DEFAULT_BEST_OF): number {
  return setNumber >= maxSets(bestOf) ? POINTS_TO_WIN_DECIDER : POINTS_TO_WIN_SET;
}

/**
 * ¿El set está terminado de forma válida? Requiere alcanzar el objetivo
 * (25, o 15 en el decisivo) y ganar por al menos 2 de diferencia.
 * Devuelve 'home' | 'away' | null (aún no hay ganador válido).
 */
export function setWinner(set: SetScore, bestOf: number = DEFAULT_BEST_OF): 'home' | 'away' | null {
  const target = pointsTarget(set.setNumber, bestOf);
  const { homePoints: h, awayPoints: a } = set;
  if (h >= target && h - a >= MIN_LEAD) return 'home';
  if (a >= target && a - h >= MIN_LEAD) return 'away';
  return null;
}

/** Valida que un marcador de set sea alcanzable (no negativo, no absurdo). */
export function isValidSetScore(set: SetScore, bestOf: number = DEFAULT_BEST_OF): boolean {
  return (
    Number.isInteger(set.homePoints) &&
    Number.isInteger(set.awayPoints) &&
    set.homePoints >= 0 &&
    set.awayPoints >= 0 &&
    set.setNumber >= 1 &&
    set.setNumber <= maxSets(bestOf)
  );
}

export interface MatchOutcome {
  homeSetsWon: number;
  awaySetsWon: number;
  /** null mientras el partido no esté decidido (nadie llegó a 3 sets). */
  winner: 'home' | 'away' | null;
  isComplete: boolean;
}

/** Calcula el marcador de sets y el ganador del partido a partir de sets terminados. */
export function matchOutcome(sets: SetScore[], bestOf: number = DEFAULT_BEST_OF): MatchOutcome {
  const need = setsToWin(bestOf);
  let homeSetsWon = 0;
  let awaySetsWon = 0;
  for (const set of sets) {
    const w = setWinner(set, bestOf);
    if (w === 'home') homeSetsWon++;
    else if (w === 'away') awaySetsWon++;
  }
  const winner = homeSetsWon >= need ? 'home' : awaySetsWon >= need ? 'away' : null;
  return { homeSetsWon, awaySetsWon, winner, isComplete: winner !== null };
}

export interface FivbPoints {
  home: number;
  away: number;
}

/**
 * Sistema de puntos FIVB para la tabla. El partido "cerrado" (el perdedor llegó
 * al penúltimo set posible) reparte 2-1; en cualquier otro caso 3-0.
 *   best-of-5: 3-0/3-1 → 3/0 ; 3-2 → 2/1
 *   best-of-3: 2-0 → 3/0 ; 2-1 → 2/1
 */
export function fivbPoints(
  homeSetsWon: number,
  awaySetsWon: number,
  bestOf: number = DEFAULT_BEST_OF,
): FivbPoints {
  const winnerIsHome = homeSetsWon > awaySetsWon;
  const loserSets = Math.min(homeSetsWon, awaySetsWon);
  const isClose = loserSets === setsToWin(bestOf) - 1; // 3-2 (bo5) o 2-1 (bo3)
  const winnerPts = isClose ? 2 : 3;
  const loserPts = isClose ? 1 : 0;
  return winnerIsHome
    ? { home: winnerPts, away: loserPts }
    : { home: loserPts, away: winnerPts };
}

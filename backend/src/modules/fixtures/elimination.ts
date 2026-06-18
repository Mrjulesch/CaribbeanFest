/**
 * Eliminación simple: construcción del cuadro (bracket) con siembra estándar y byes.
 * Puro y testeable. Produce una estructura por rondas que la capa de persistencia
 * convierte en Match + BracketNode encadenados.
 */
export interface BracketSlot {
  position: number;
  homeTeamId: string | null; // null = por definir (ganador de ronda previa) o bye
  awayTeamId: string | null;
}

export interface BracketRound {
  round: string; // "R16" | "QF" | "SF" | "F" | "R32"...
  slots: BracketSlot[];
}

/** Potencia de 2 igual o mayor a n. */
function nextPow2(n: number): number {
  let p = 1;
  while (p < n) p *= 2;
  return p;
}

/** Etiqueta de ronda según cuántos partidos tiene. */
export function roundLabel(matchesInRound: number): string {
  switch (matchesInRound) {
    case 1:
      return 'F';
    case 2:
      return 'SF';
    case 4:
      return 'QF';
    case 8:
      return 'R16';
    default:
      return `R${matchesInRound * 2}`;
  }
}

/**
 * Orden de siembra clásico para un cuadro de tamaño `size` (potencia de 2):
 * empareja al mejor sembrado contra el peor. Devuelve los índices de siembra (1-based)
 * en el orden en que se colocan en el cuadro.
 */
export function seedOrder(size: number): number[] {
  let order = [1, 2];
  while (order.length < size) {
    const n = order.length * 2;
    const next: number[] = [];
    for (const s of order) {
      next.push(s);
      next.push(n + 1 - s);
    }
    order = next;
  }
  return order;
}

/**
 * Construye el cuadro completo. `teamIds` se asume ya ordenado por siembra
 * (1º sembrado primero). Los equipos sin rival reciben bye (avanzan solos).
 */
export function buildSingleElimination(teamIds: string[]): BracketRound[] {
  if (teamIds.length < 2) return [];

  const size = nextPow2(teamIds.length);
  const order = seedOrder(size);

  // Colocamos equipos según siembra; las posiciones sin equipo son byes (null).
  const seeded: (string | null)[] = order.map((seed) => teamIds[seed - 1] ?? null);

  const rounds: BracketRound[] = [];
  const firstRoundMatches = size / 2;

  // Primera ronda
  const firstSlots: BracketSlot[] = [];
  for (let i = 0; i < firstRoundMatches; i++) {
    firstSlots.push({
      position: i,
      homeTeamId: seeded[i * 2],
      awayTeamId: seeded[i * 2 + 1],
    });
  }
  rounds.push({ round: roundLabel(firstRoundMatches), slots: firstSlots });

  // Rondas siguientes: equipos por definir (se llenan al avanzar ganadores).
  let matchesInRound = firstRoundMatches / 2;
  while (matchesInRound >= 1) {
    const slots: BracketSlot[] = [];
    for (let i = 0; i < matchesInRound; i++) {
      slots.push({ position: i, homeTeamId: null, awayTeamId: null });
    }
    rounds.push({ round: roundLabel(matchesInRound), slots });
    matchesInRound /= 2;
  }

  return rounds;
}

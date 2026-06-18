/**
 * Cálculo de la tabla de posiciones a partir de los partidos terminados de un grupo.
 * Pura y testeable: la capa NestJS (StandingsService) lee los Match de Prisma, llama a
 * esto y persiste el resultado en la tabla `Standing` (precalculada para lectura rápida).
 */
import { fivbPoints, matchOutcome, SetScore } from './volleyball-rules';

export interface FinishedMatch {
  homeTeamId: string;
  awayTeamId: string;
  sets: SetScore[];
}

export interface StandingRow {
  teamId: string;
  played: number;
  won: number;
  lost: number;
  points: number; // puntos FIVB
  setsFor: number;
  setsAgainst: number;
  pointsFor: number; // puntos de juego anotados (rallies)
  pointsAgainst: number;
  rank: number;
}

type Acc = Omit<StandingRow, 'rank'>;

function emptyRow(teamId: string): Acc {
  return {
    teamId,
    played: 0,
    won: 0,
    lost: 0,
    points: 0,
    setsFor: 0,
    setsAgainst: 0,
    pointsFor: 0,
    pointsAgainst: 0,
  };
}

const setRatio = (r: Acc) => (r.setsAgainst === 0 ? r.setsFor : r.setsFor / r.setsAgainst);
const pointRatio = (r: Acc) => (r.pointsAgainst === 0 ? r.pointsFor : r.pointsFor / r.pointsAgainst);

/**
 * Construye la tabla ordenada. `teamIds` asegura que aparezcan también los equipos
 * sin partidos jugados todavía.
 */
export function computeStandings(
  matches: FinishedMatch[],
  teamIds: string[],
  bestOf: number = 5,
): StandingRow[] {
  const table = new Map<string, Acc>();
  for (const id of teamIds) table.set(id, emptyRow(id));

  const ensure = (id: string) => {
    if (!table.has(id)) table.set(id, emptyRow(id));
    return table.get(id)!;
  };

  // resultado directo: clave `${a}|${b}` → ganador
  const head2head = new Map<string, string>();

  for (const m of matches) {
    const outcome = matchOutcome(m.sets, bestOf);
    if (!outcome.isComplete) continue; // solo partidos cerrados cuentan

    const home = ensure(m.homeTeamId);
    const away = ensure(m.awayTeamId);
    const pts = fivbPoints(outcome.homeSetsWon, outcome.awaySetsWon, bestOf);

    home.played++;
    away.played++;
    home.setsFor += outcome.homeSetsWon;
    home.setsAgainst += outcome.awaySetsWon;
    away.setsFor += outcome.awaySetsWon;
    away.setsAgainst += outcome.homeSetsWon;
    home.points += pts.home;
    away.points += pts.away;

    for (const s of m.sets) {
      home.pointsFor += s.homePoints;
      home.pointsAgainst += s.awayPoints;
      away.pointsFor += s.awayPoints;
      away.pointsAgainst += s.homePoints;
    }

    if (outcome.winner === 'home') {
      home.won++;
      away.lost++;
      head2head.set(`${m.homeTeamId}|${m.awayTeamId}`, m.homeTeamId);
    } else {
      away.won++;
      home.lost++;
      head2head.set(`${m.homeTeamId}|${m.awayTeamId}`, m.awayTeamId);
    }
  }

  const rows = [...table.values()];

  // Desempate FIVB: puntos → victorias → set ratio → point ratio → resultado directo
  rows.sort((a, b) => {
    if (b.points !== a.points) return b.points - a.points;
    if (b.won !== a.won) return b.won - a.won;
    const sr = setRatio(b) - setRatio(a);
    if (Math.abs(sr) > 1e-9) return sr;
    const pr = pointRatio(b) - pointRatio(a);
    if (Math.abs(pr) > 1e-9) return pr;
    // resultado directo (solo válido entre dos equipos empatados)
    const w = head2head.get(`${a.teamId}|${b.teamId}`) ?? head2head.get(`${b.teamId}|${a.teamId}`);
    if (w === a.teamId) return -1;
    if (w === b.teamId) return 1;
    return 0;
  });

  return rows.map((r, i) => ({ ...r, rank: i + 1 }));
}

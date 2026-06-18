import { fivbPoints, matchOutcome, setWinner } from './volleyball-rules';
import { computeStandings, FinishedMatch } from './standings.calculator';

describe('volleyball-rules', () => {
  it('valida el ganador de un set normal (25, +2)', () => {
    expect(setWinner({ setNumber: 1, homePoints: 25, awayPoints: 22 })).toBe('home');
    expect(setWinner({ setNumber: 1, homePoints: 24, awayPoints: 26 })).toBe('away');
    expect(setWinner({ setNumber: 1, homePoints: 25, awayPoints: 24 })).toBeNull(); // falta +2
  });

  it('el 5º set se gana a 15', () => {
    expect(setWinner({ setNumber: 5, homePoints: 15, awayPoints: 13 })).toBe('home');
    expect(setWinner({ setNumber: 5, homePoints: 14, awayPoints: 12 })).toBeNull();
  });

  it('resuelve el ganador del partido al mejor de 5', () => {
    const sets = [
      { setNumber: 1, homePoints: 25, awayPoints: 22 },
      { setNumber: 2, homePoints: 18, awayPoints: 25 },
      { setNumber: 3, homePoints: 25, awayPoints: 20 },
      { setNumber: 4, homePoints: 25, awayPoints: 18 },
    ];
    const o = matchOutcome(sets);
    expect(o).toMatchObject({ homeSetsWon: 3, awaySetsWon: 1, winner: 'home', isComplete: true });
  });

  it('aplica el sistema de puntos FIVB', () => {
    expect(fivbPoints(3, 0)).toEqual({ home: 3, away: 0 });
    expect(fivbPoints(3, 1)).toEqual({ home: 3, away: 0 });
    expect(fivbPoints(3, 2)).toEqual({ home: 2, away: 1 });
    expect(fivbPoints(2, 3)).toEqual({ home: 1, away: 2 });
  });
});

describe('computeStandings', () => {
  it('ordena por puntos y aplica desempates', () => {
    const matches: FinishedMatch[] = [
      // A vence a B 3-0
      {
        homeTeamId: 'A',
        awayTeamId: 'B',
        sets: [
          { setNumber: 1, homePoints: 25, awayPoints: 20 },
          { setNumber: 2, homePoints: 25, awayPoints: 18 },
          { setNumber: 3, homePoints: 25, awayPoints: 22 },
        ],
      },
      // C vence a B 3-2
      {
        homeTeamId: 'C',
        awayTeamId: 'B',
        sets: [
          { setNumber: 1, homePoints: 25, awayPoints: 20 },
          { setNumber: 2, homePoints: 20, awayPoints: 25 },
          { setNumber: 3, homePoints: 25, awayPoints: 18 },
          { setNumber: 4, homePoints: 18, awayPoints: 25 },
          { setNumber: 5, homePoints: 15, awayPoints: 12 },
        ],
      },
    ];
    const table = computeStandings(matches, ['A', 'B', 'C']);
    expect(table[0].teamId).toBe('A'); // 3 pts, 3-0
    expect(table[0].points).toBe(3);
    expect(table[1].teamId).toBe('C'); // 2 pts, 3-2
    expect(table[1].points).toBe(2);
    expect(table[2].teamId).toBe('B'); // 1 pt (perdió un 3-2)
    expect(table[2].played).toBe(2);
  });
});

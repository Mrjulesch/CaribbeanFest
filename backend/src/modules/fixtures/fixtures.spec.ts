import { roundRobinRounds, splitIntoGroups } from './round-robin';
import { buildSingleElimination, seedOrder, roundLabel } from './elimination';
import { scheduleRounds } from './scheduler';

describe('round robin', () => {
  it('genera N-1 jornadas con N par y todos juegan una vez por jornada', () => {
    const rounds = roundRobinRounds(['A', 'B', 'C', 'D']);
    expect(rounds).toHaveLength(3); // 4 equipos → 3 jornadas
    for (const r of rounds) {
      const teams = r.flatMap((p) => [p.home, p.away]);
      expect(new Set(teams).size).toBe(teams.length); // sin repetidos en la jornada
    }
  });

  it('cada par de equipos se enfrenta exactamente una vez', () => {
    const teams = ['A', 'B', 'C', 'D', 'E']; // impar → maneja bye
    const rounds = roundRobinRounds(teams);
    const seen = new Set<string>();
    let count = 0;
    for (const r of rounds) {
      for (const p of r) {
        const key = [p.home, p.away].sort().join('-');
        expect(seen.has(key)).toBe(false);
        seen.add(key);
        count++;
      }
    }
    expect(count).toBe((teams.length * (teams.length - 1)) / 2); // C(5,2) = 10
  });

  it('reparte equipos en grupos equilibrados', () => {
    const groups = splitIntoGroups(['A', 'B', 'C', 'D', 'E', 'F'], 2);
    expect(groups).toHaveLength(2);
    expect(groups[0]).toHaveLength(3);
    expect(groups[1]).toHaveLength(3);
  });
});

describe('eliminación simple', () => {
  it('siembra empareja al mejor contra el peor', () => {
    expect(seedOrder(4)).toEqual([1, 4, 2, 3]);
    expect(seedOrder(8)).toEqual([1, 8, 4, 5, 2, 7, 3, 6]);
  });

  it('etiqueta las rondas correctamente', () => {
    expect(roundLabel(1)).toBe('F');
    expect(roundLabel(2)).toBe('SF');
    expect(roundLabel(4)).toBe('QF');
    expect(roundLabel(8)).toBe('R16');
  });

  it('construye un cuadro de 8 con 3 rondas (QF, SF, F)', () => {
    const bracket = buildSingleElimination(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']);
    expect(bracket.map((r) => r.round)).toEqual(['QF', 'SF', 'F']);
    expect(bracket[0].slots).toHaveLength(4);
    expect(bracket[2].slots).toHaveLength(1);
    // 1º sembrado (A) abre el cuadro contra el 8º (H)
    expect(bracket[0].slots[0]).toMatchObject({ homeTeamId: 'A', awayTeamId: 'H' });
  });

  it('da bye cuando el número de equipos no es potencia de 2', () => {
    const bracket = buildSingleElimination(['A', 'B', 'C', 'D', 'E', 'F']); // size 8
    const firstRound = bracket[0].slots;
    const byes = firstRound.filter((s) => !s.homeTeamId || !s.awayTeamId);
    expect(byes.length).toBeGreaterThan(0);
  });
});

describe('scheduler', () => {
  it('no asigna dos partidos a la misma cancha y hora', () => {
    const rounds = roundRobinRounds(['A', 'B', 'C', 'D']);
    const scheduled = scheduleRounds(rounds, {
      startDate: new Date('2026-07-01T00:00:00Z'),
      courtIds: ['court1', 'court2'],
      slotMinutes: 90,
      firstSlotHour: 9,
      slotsPerDay: 6,
    });
    const seen = new Set<string>();
    for (const m of scheduled) {
      const key = `${m.courtId}@${m.scheduledAt.toISOString()}`;
      expect(seen.has(key)).toBe(false);
      seen.add(key);
    }
  });

  it('no agenda a un equipo en dos partidos a la misma hora', () => {
    const rounds = roundRobinRounds(['A', 'B', 'C', 'D', 'E', 'F']);
    const scheduled = scheduleRounds(rounds, {
      startDate: new Date('2026-07-01T00:00:00Z'),
      courtIds: ['c1', 'c2', 'c3'],
      slotMinutes: 90,
      firstSlotHour: 9,
      slotsPerDay: 8,
    });
    const byTime = new Map<string, string[]>();
    for (const m of scheduled) {
      const t = m.scheduledAt.toISOString();
      const teams = byTime.get(t) ?? [];
      teams.push(m.home, m.away);
      byTime.set(t, teams);
    }
    for (const teams of byTime.values()) {
      expect(new Set(teams).size).toBe(teams.length);
    }
  });
});

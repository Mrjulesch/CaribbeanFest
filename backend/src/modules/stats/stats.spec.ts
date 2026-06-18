import { computePlayerStats, computeLeaders, mvpScore, PlayerEvent } from './stats.calculator';

describe('stats.calculator', () => {
  const events: PlayerEvent[] = [
    // Jugador A: gran atacante
    ...Array(10).fill({ playerId: 'A', playerName: 'Ana', type: 'ATTACK' }),
    ...Array(2).fill({ playerId: 'A', playerName: 'Ana', type: 'ERROR' }),
    // Jugador B: bloqueador
    ...Array(3).fill({ playerId: 'B', playerName: 'Beto', type: 'ATTACK' }),
    ...Array(6).fill({ playerId: 'B', playerName: 'Beto', type: 'BLOCK' }),
    // Jugador C: servidor
    ...Array(5).fill({ playerId: 'C', playerName: 'Carla', type: 'SERVE_ACE' }),
    ...Array(2).fill({ playerId: 'C', playerName: 'Carla', type: 'POINT' }),
  ];

  it('agrega puntos por tipo de acción', () => {
    const stats = computePlayerStats(events);
    const a = stats.find((s) => s.playerId === 'A')!;
    expect(a.attacks).toBe(10);
    expect(a.points).toBe(10);
    expect(a.errors).toBe(2);

    const b = stats.find((s) => s.playerId === 'B')!;
    expect(b.blocks).toBe(6);
    expect(b.points).toBe(9); // 3 ataques + 6 bloqueos
  });

  it('calcula el MVP score premiando bloqueos/aces y penalizando errores', () => {
    expect(mvpScore({ points: 10, blocks: 0, aces: 0, errors: 2 })).toBe(9); // 10 - 1
    expect(mvpScore({ points: 9, blocks: 6, aces: 0, errors: 0 })).toBe(12); // 9 + 3
  });

  it('elige los líderes correctos por categoría', () => {
    const leaders = computeLeaders(computePlayerStats(events));
    expect(leaders.bestAttacker?.playerId).toBe('A'); // 10 ataques
    expect(leaders.bestBlocker?.playerId).toBe('B'); // 6 bloqueos
    expect(leaders.bestServer?.playerId).toBe('C'); // 5 aces
    expect(leaders.topScorer?.playerId).toBe('A'); // 10 puntos
    // MVP: B con 9 + 3 = 12 supera a A con 10 - 1 = 9
    expect(leaders.mvp?.playerId).toBe('B');
  });

  it('maneja categorías sin eventos', () => {
    const leaders = computeLeaders([]);
    expect(leaders.mvp).toBeNull();
    expect(leaders.topScorer).toBeNull();
  });
});

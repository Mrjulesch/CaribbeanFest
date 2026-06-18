/**
 * Round robin (todos contra todos) por el método del círculo.
 * Puro y testeable. Cubre también cuadrangulares (4 equipos) y hexagonales (6).
 *
 * Devuelve una lista de jornadas; cada jornada es un conjunto de enfrentamientos
 * que pueden jugarse en paralelo (ningún equipo aparece dos veces en la misma jornada).
 */
export interface Pairing {
  home: string;
  away: string;
}

const BYE = '__BYE__';

export function roundRobinRounds(teamIds: string[]): Pairing[][] {
  const teams = [...teamIds];
  if (teams.length < 2) return [];

  // Si el número de equipos es impar, añadimos un "bye" para que cada jornada cuadre.
  if (teams.length % 2 !== 0) teams.push(BYE);

  const n = teams.length;
  const totalRounds = n - 1;
  const half = n / 2;

  const fixed = teams[0];
  let rotating = teams.slice(1);
  const rounds: Pairing[][] = [];

  for (let r = 0; r < totalRounds; r++) {
    const arr = [fixed, ...rotating];
    const pairs: Pairing[] = [];

    for (let i = 0; i < half; i++) {
      const a = arr[i];
      const b = arr[n - 1 - i];
      if (a === BYE || b === BYE) continue;
      // Alternamos localía por jornada para repartir partidos de local/visitante.
      pairs.push(r % 2 === 0 ? { home: a, away: b } : { home: b, away: a });
    }

    rounds.push(pairs);
    // Rotación: el último pasa al frente, el resto se desplaza.
    rotating = [rotating[rotating.length - 1], ...rotating.slice(0, rotating.length - 1)];
  }

  return rounds;
}

/** Reparte equipos en `groupCount` grupos de forma equilibrada (serpenteado). */
export function splitIntoGroups(teamIds: string[], groupCount: number): string[][] {
  const groups: string[][] = Array.from({ length: groupCount }, () => []);
  teamIds.forEach((id, i) => {
    // serpenteo: 0,1,2,2,1,0,0,1,2... para equilibrar siembra
    const cycle = Math.floor(i / groupCount);
    const pos = i % groupCount;
    const g = cycle % 2 === 0 ? pos : groupCount - 1 - pos;
    groups[g].push(id);
  });
  return groups;
}

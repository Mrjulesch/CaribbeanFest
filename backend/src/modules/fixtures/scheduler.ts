/**
 * Asignación de horarios y canchas a las jornadas de un round robin.
 * Puro y testeable. Garantiza:
 *  - Ninguna cancha con dos partidos a la vez.
 *  - Ningún equipo con dos partidos a la misma hora (las jornadas ya traen equipos únicos).
 *  - Descanso natural: una jornada no empieza hasta que cabe en las canchas disponibles.
 */
import { Pairing } from './round-robin';

export interface ScheduleOptions {
  startDate: Date;
  courtIds: string[];
  slotMinutes: number; // duración estimada por franja (ej. 90)
  firstSlotHour: number; // hora de inicio diaria (ej. 9 = 9:00)
  slotsPerDay: number; // cuántas franjas por día
}

export interface ScheduledMatch {
  home: string;
  away: string;
  courtId: string;
  scheduledAt: Date;
}

export function scheduleRounds(rounds: Pairing[][], opts: ScheduleOptions): ScheduledMatch[] {
  const { courtIds, slotMinutes, firstSlotHour, slotsPerDay } = opts;
  if (courtIds.length === 0) throw new Error('Se requiere al menos una cancha');

  const out: ScheduledMatch[] = [];
  let baseSlot = 0;

  for (const round of rounds) {
    round.forEach((pairing, j) => {
      const slot = baseSlot + Math.floor(j / courtIds.length);
      const courtId = courtIds[j % courtIds.length];
      out.push({
        home: pairing.home,
        away: pairing.away,
        courtId,
        scheduledAt: slotToDate(slot, opts),
      });
    });
    // La siguiente jornada arranca tras consumir las franjas que necesitó esta.
    baseSlot += Math.ceil(round.length / courtIds.length);
  }

  return out;

  function slotToDate(slot: number, o: ScheduleOptions): Date {
    const day = Math.floor(slot / slotsPerDay);
    const slotInDay = slot % slotsPerDay;
    const d = new Date(o.startDate);
    d.setDate(d.getDate() + day);
    d.setHours(firstSlotHour, 0, 0, 0);
    d.setMinutes(d.getMinutes() + slotInDay * slotMinutes);
    return d;
  }
}

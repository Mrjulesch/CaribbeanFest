import {
  matchStartMessage,
  matchFinishedMessage,
  scheduleChangeMessage,
  announcementMessage,
  topicFor,
} from './notification-messages';

describe('notification-messages', () => {
  const match = {
    id: 'm1',
    homeTeam: 'Tiburones',
    awayTeam: 'Huracanes',
    homeSetsWon: 3,
    awaySetsWon: 1,
    court: 'Cancha 1',
  };

  it('mensaje de inicio de partido', () => {
    const msg = matchStartMessage(match);
    expect(msg.title).toContain('Comienza');
    expect(msg.body).toContain('Tiburones vs Huracanes');
    expect(msg.data).toEqual({ type: 'MATCH_START', matchId: 'm1' });
  });

  it('mensaje de resultado final con marcador', () => {
    const msg = matchFinishedMessage(match);
    expect(msg.body).toContain('3-1');
    expect(msg.data.type).toBe('MATCH_FINISHED');
  });

  it('mensaje de cambio de horario', () => {
    const msg = scheduleChangeMessage({ ...match, scheduledAt: '2026-07-02 10:00' });
    expect(msg.title).toContain('Cambio de horario');
    expect(msg.data.type).toBe('SCHEDULE_CHANGE');
  });

  it('mensaje de comunicado', () => {
    const msg = announcementMessage('t1', 'Aviso', 'Se suspende la jornada');
    expect(msg.title).toBe('Aviso');
    expect(msg.data).toEqual({ type: 'ANNOUNCEMENT', tournamentId: 't1' });
  });

  it('genera topics FCM válidos', () => {
    expect(topicFor('team', 'abc-123')).toBe('team_abc-123');
    expect(topicFor('match', 'm/1 con espacios')).toBe('match_m1conespacios');
  });
});

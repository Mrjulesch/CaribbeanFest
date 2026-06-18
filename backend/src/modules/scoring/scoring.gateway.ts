import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { JwtService } from '@nestjs/jwt';
import { Server, Socket } from 'socket.io';
import { ScoringService, SetScoreInput } from './scoring.service';

/**
 * Gateway de scoring en tiempo real.
 *
 * - El público se une a salas `match:{id}` y recibe `match:state` en cada cambio.
 * - El árbitro autenticado (rol REFEREE/ADMIN) emite `score:update` y `match:finalize`.
 *
 * Para escalar a varias instancias, se conecta el adapter de Redis de Socket.IO
 * (ver docs/ARCHITECTURE.md §6) — el código de salas no cambia.
 */
@WebSocketGateway({ cors: { origin: true }, namespace: '/live' })
export class ScoringGateway implements OnGatewayConnection {
  @WebSocketServer() server!: Server;

  constructor(
    private readonly scoring: ScoringService,
    private readonly jwt: JwtService,
  ) {}

  handleConnection(client: Socket) {
    // Autenticación opcional: el público se conecta sin token (solo lectura).
    const token = client.handshake.auth?.token as string | undefined;
    if (token) {
      try {
        const payload = this.jwt.verify(token, { secret: process.env.JWT_SECRET ?? 'dev-secret' });
        client.data.user = { id: payload.sub, role: payload.role };
      } catch {
        client.data.user = null;
      }
    }
  }

  /** Cualquier cliente (incluido el público) se suscribe a un partido. */
  @SubscribeMessage('match:join')
  join(@ConnectedSocket() client: Socket, @MessageBody() matchId: string) {
    client.join(`match:${matchId}`);
    return { joined: matchId };
  }

  @SubscribeMessage('match:leave')
  leave(@ConnectedSocket() client: Socket, @MessageBody() matchId: string) {
    client.leave(`match:${matchId}`);
    return { left: matchId };
  }

  /** Solo árbitros/admin pueden reportar marcador. */
  @SubscribeMessage('score:update')
  async onScore(@ConnectedSocket() client: Socket, @MessageBody() data: SetScoreInput) {
    this.assertReferee(client);
    const state = await this.scoring.recordSetScore(data);
    this.server.to(`match:${data.matchId}`).emit('match:state', state);
    return { ok: true };
  }

  @SubscribeMessage('match:finalize')
  async onFinalize(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; notes?: string },
  ) {
    this.assertReferee(client);
    const state = await this.scoring.finalizeMatch(data.matchId, data.notes);
    this.server.to(`match:${data.matchId}`).emit('match:state', state);
    return { ok: true };
  }

  private assertReferee(client: Socket) {
    const role = client.data.user?.role;
    if (role !== 'REFEREE' && role !== 'ADMIN') {
      throw new Error('No autorizado: se requiere rol de árbitro');
    }
  }
}

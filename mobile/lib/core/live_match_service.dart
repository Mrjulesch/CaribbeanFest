import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'config.dart';
import '../models/models.dart';

/// Conexión Socket.IO a una sala de partido. El público recibe `match:state`
/// en cada cambio; el árbitro además emite `score:update` / `match:finalize`.
class LiveMatchService {
  LiveMatchService(this.matchId, {this.authToken});

  final String matchId;
  final String? authToken;
  io.Socket? _socket;

  void connect({required void Function(Match) onState}) {
    final socket = io.io(
      AppConfig.liveSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth(authToken != null ? {'token': authToken} : {})
          .build(),
    );

    socket.onConnect((_) => socket.emit('match:join', matchId));
    socket.on('match:state', (data) {
      if (data is Map) onState(Match.fromJson(Map<String, dynamic>.from(data)));
    });

    socket.connect();
    _socket = socket;
  }

  /// (Solo árbitro) reporta el marcador de un set.
  void updateScore({
    required int setNumber,
    required int homePoints,
    required int awayPoints,
    bool finishSet = false,
  }) {
    _socket?.emit('score:update', {
      'matchId': matchId,
      'setNumber': setNumber,
      'homePoints': homePoints,
      'awayPoints': awayPoints,
      'finishSet': finishSet,
    });
  }

  /// (Solo árbitro) confirma la finalización del encuentro.
  void finalizeMatch({String? notes}) {
    _socket?.emit('match:finalize', {'matchId': matchId, 'notes': notes});
  }

  void dispose() {
    _socket?.emit('match:leave', matchId);
    _socket?.dispose();
    _socket = null;
  }
}

final liveMatchServiceProvider =
    Provider.family<LiveMatchService, ({String matchId, String? token})>(
  (ref, args) => LiveMatchService(args.matchId, authToken: args.token),
);

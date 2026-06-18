import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/live_match_service.dart';
import '../../models/models.dart';
import '../../widgets/responsive_center.dart';

/// Pantalla de arbitraje: el juez registra puntos por set en tiempo real.
/// Cada cambio se emite por WebSocket; el servidor valida y devuelve el estado.
class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  LiveMatchService? _live;
  Match? _match;
  int _currentSet = 1;
  int _home = 0;
  int _away = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await ref.read(tokenStorageProvider).accessToken;
    try {
      final data = await ref.read(apiClientProvider).get('/matches/${widget.matchId}');
      final m = Match.fromJson(data as Map<String, dynamic>);
      _syncFromMatch(m);
    } catch (_) {}

    _live = LiveMatchService(widget.matchId, authToken: token);
    _live!.connect(onState: (m) {
      if (mounted) setState(() => _match = m);
    });
  }

  void _syncFromMatch(Match m) {
    // Coloca el set actual en el primer set sin terminar, o el siguiente.
    final openSet = m.sets.where((s) => !s.isFinished).toList();
    setState(() {
      _match = m;
      if (openSet.isNotEmpty) {
        _currentSet = openSet.first.setNumber;
        _home = openSet.first.homePoints;
        _away = openSet.first.awayPoints;
      } else {
        _currentSet = m.sets.length + 1;
        _home = 0;
        _away = 0;
      }
    });
  }

  @override
  void dispose() {
    _live?.dispose();
    super.dispose();
  }

  void _push({bool finishSet = false}) {
    _live?.updateScore(
      setNumber: _currentSet,
      homePoints: _home,
      awayPoints: _away,
      finishSet: finishSet,
    );
  }

  void _adjust(bool home, int delta) {
    setState(() {
      if (home) {
        _home = (_home + delta).clamp(0, 99);
      } else {
        _away = (_away + delta).clamp(0, 99);
      }
    });
    _push();
  }

  Future<void> _finishSet() async {
    _push(finishSet: true);
    // Tras cerrar el set, preparamos el siguiente.
    setState(() {
      _currentSet += 1;
      _home = 0;
      _away = 0;
    });
  }

  Future<void> _finalize() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar partido'),
        content: const Text('¿Confirmas el cierre del encuentro? No podrás volver a editarlo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finalizar')),
        ],
      ),
    );
    if (ok == true) {
      _live?.finalizeMatch();
      if (mounted) context.go('/referee');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _match;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/referee')),
        title: Text('Arbitraje · Set $_currentSet'),
        actions: [
          IconButton(tooltip: 'Finalizar partido', icon: const Icon(Icons.flag), onPressed: _finalize),
        ],
      ),
      body: m == null
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveCenter(
              maxWidth: 760,
              child: Column(
              children: [
                const SizedBox(height: 12),
                Text('${m.homeSetsWon} - ${m.awaySetsWon}  (sets)', style: const TextStyle(fontSize: 16)),
                const Divider(),
                Expanded(
                  child: Row(
                    children: [
                      _TeamScorer(
                        name: m.homeTeam?.name ?? 'Local',
                        points: _home,
                        onAdd: () => _adjust(true, 1),
                        onSub: () => _adjust(true, -1),
                      ),
                      const VerticalDivider(width: 1),
                      _TeamScorer(
                        name: m.awayTeam?.name ?? 'Visitante',
                        points: _away,
                        onAdd: () => _adjust(false, 1),
                        onSub: () => _adjust(false, -1),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: _finishSet,
                    icon: const Icon(Icons.done_all),
                    label: const Text('Cerrar set'),
                  ),
                ),
              ],
            ),
            ),
    );
  }
}

class _TeamScorer extends StatelessWidget {
  const _TeamScorer({required this.name, required this.points, required this.onAdd, required this.onSub});
  final String name;
  final int points;
  final VoidCallback onAdd;
  final VoidCallback onSub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('$points', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(iconSize: 36, onPressed: onSub, icon: const Icon(Icons.remove)),
              const SizedBox(width: 16),
              IconButton.filled(iconSize: 36, onPressed: onAdd, icon: const Icon(Icons.add)),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/live_match_service.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

/// Vista pública de un partido en vivo. Se suscribe a la sala por WebSocket y
/// actualiza el marcador al instante cuando el árbitro reporta.
class LiveMatchScreen extends ConsumerStatefulWidget {
  const LiveMatchScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  LiveMatchService? _live;
  Match? _match;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _live = LiveMatchService(widget.matchId);
    _live!.connect(onState: (m) => setState(() => _match = m));
  }

  Future<void> _loadInitial() async {
    try {
      final data = await ref.read(apiClientProvider).get('/matches/${widget.matchId}');
      setState(() => _match = Match.fromJson(data as Map<String, dynamic>));
    } catch (_) {/* la actualización en vivo llegará por socket */}
  }

  @override
  void dispose() {
    _live?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _match;
    return AppScaffold(
      title: 'Partido',
      showBack: true,
      body: m == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  if (m.isLive)
                    const Chip(
                      avatar: Icon(Icons.circle, color: Colors.red, size: 12),
                      label: Text('EN VIVO'),
                    ),
                  const SizedBox(height: 16),
                  _ScoreHeader(match: m),
                  if (m.court != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.place, size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(m.court!.label, style: const TextStyle(color: Colors.blueGrey)),
                      ],
                    ),
                  ],
                  if (m.streamUrl != null && m.streamUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      icon: const Icon(Icons.live_tv),
                      label: const Text('Ver en vivo'),
                      onPressed: () => launchUrl(Uri.parse(m.streamUrl!), mode: LaunchMode.externalApplication),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('Sets', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...m.sets.map((s) => ListTile(
                        dense: true,
                        leading: Text('Set ${s.setNumber}'),
                        title: Text('${s.homePoints}  -  ${s.awayPoints}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18)),
                        trailing: s.isFinished
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.timelapse, color: Colors.orange),
                      )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: Text(match.homeTeam?.name ?? '?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Text('${match.homeSetsWon}  -  ${match.awaySetsWon}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Expanded(child: Text(match.awayTeam?.name ?? '?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ],
    );
  }
}

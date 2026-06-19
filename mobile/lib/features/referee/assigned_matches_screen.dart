import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/repositories.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';
import '../admin/admin_dialogs.dart';

/// Panel del árbitro: ve sus partidos asignados por estado, arbitra en vivo
/// y corrige marcadores. Autogestión completa de sus encuentros.
class AssignedMatchesScreen extends ConsumerWidget {
  const AssignedMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(assignedMatchesProvider);
    final auth = ref.watch(authControllerProvider);
    final df = DateFormat('d MMM · HH:mm', 'es');

    return AppScaffold(
      title: 'Panel del árbitro',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(assignedMatchesProvider),
        ),
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) context.go('/');
          },
        ),
      ],
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (list) {
          final live = list.where((m) => m.isLive).toList();
          final upcoming = list.where((m) => m.status == 'SCHEDULED' || m.status == 'SUSPENDED').toList();
          final finished = list.where((m) => m.isFinished).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(assignedMatchesProvider),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _ProfileHeader(email: auth.user?.email ?? 'Árbitro', total: list.length),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Aún no tienes partidos asignados.\nEl administrador te asignará encuentros.',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                  ),
                if (live.isNotEmpty) ...[
                  _section('🔴 En vivo'),
                  ...live.map((m) => _MatchCard(match: m, df: df)),
                ],
                if (upcoming.isNotEmpty) ...[
                  _section('Próximos'),
                  ...upcoming.map((m) => _MatchCard(match: m, df: df)),
                ],
                if (finished.isNotEmpty) ...[
                  _section('Finalizados'),
                  ...finished.map((m) => _MatchCard(match: m, df: df)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.email, required this.total});
  final String email;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 26, child: Icon(Icons.sports, size: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Árbitro', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$total partido(s) asignado(s)', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match, required this.df});
  final Match match;
  final DateFormat df;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiClientProvider);
    return Card(
      child: ListTile(
        title: Text('${match.homeTeam?.name ?? "?"} vs ${match.awayTeam?.name ?? "?"}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text([
              match.scheduledAt != null ? df.format(match.scheduledAt!) : 'Por programar',
              if (match.court != null) match.court!.label,
            ].join(' · ')),
            if (match.isFinished || match.isLive)
              Text('Marcador: ${match.homeSetsWon}-${match.awaySetsWon} (sets)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        isThreeLine: true,
        trailing: match.isFinished
            ? OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Corregir'),
                onPressed: () => _editScore(context, ref, api),
              )
            : FilledButton.tonalIcon(
                icon: const Icon(Icons.sports_volleyball, size: 16),
                label: Text(match.isLive ? 'Continuar' : 'Arbitrar'),
                onPressed: () => context.go('/referee/score/${match.id}'),
              ),
      ),
    );
  }

  Future<void> _editScore(BuildContext context, WidgetRef ref, ApiClient api) async {
    final initial = {for (final s in match.sets) s.setNumber: [s.homePoints, s.awayPoints]};
    final sets = await showEditScoreDialog(context, maxSets: 5, initial: initial);
    if (sets == null) return;
    try {
      await api.raw.put('/scoring/matches/${match.id}', data: {'sets': sets});
      ref.invalidate(assignedMatchesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marcador corregido')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

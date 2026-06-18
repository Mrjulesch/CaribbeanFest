import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/repositories.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';
import 'admin_dialogs.dart';

/// Partidos de una categoría con asignación de árbitros y edición de marcador.
class AdminMatchesScreen extends ConsumerWidget {
  const AdminMatchesScreen({super.key, required this.categoryId, this.bestOf = 5});
  final String categoryId;
  final int bestOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider(categoryId));
    final df = DateFormat('d MMM HH:mm', 'es');

    return AppScaffold(
      title: 'Partidos y árbitros',
      showBack: true,
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Sin partidos. Genera el fixture primero.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: list.map((m) => _MatchTile(match: m, df: df, categoryId: categoryId, bestOf: bestOf)).toList(),
          );
        },
      ),
    );
  }
}

class _MatchTile extends ConsumerWidget {
  const _MatchTile({required this.match, required this.df, required this.categoryId, required this.bestOf});
  final Match match;
  final DateFormat df;
  final String categoryId;
  final int bestOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(matchAssignmentsProvider(match.id));
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
            Text(
              match.isFinished
                  ? 'Final: ${match.homeSetsWon}-${match.awaySetsWon} (sets)'
                  : (match.isLive ? '🔴 EN VIVO ${match.homeSetsWon}-${match.awaySetsWon}' : 'Programado'),
              style: const TextStyle(fontSize: 12),
            ),
            assignments.when(
              loading: () => const Text('…', style: TextStyle(fontSize: 12)),
              error: (_, __) => const SizedBox.shrink(),
              data: (names) => Text(
                names.isEmpty ? 'Sin árbitro asignado' : '🟢 ${names.join(", ")}',
                style: TextStyle(fontSize: 12, color: names.isEmpty ? Colors.orange : Colors.green),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) {
            if (v == 'assign') _assign(context, ref, api);
            if (v == 'edit') _editScore(context, ref, api);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'assign', child: ListTile(leading: Icon(Icons.sports), title: Text('Asignar árbitro'))),
            PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.scoreboard), title: Text('Editar marcador'))),
          ],
        ),
      ),
    );
  }

  Future<void> _editScore(BuildContext context, WidgetRef ref, ApiClient api) async {
    final initial = {for (final s in match.sets) s.setNumber: [s.homePoints, s.awayPoints]};
    final maxSets = bestOf == 3 ? 3 : 5;
    final sets = await showEditScoreDialog(context, maxSets: maxSets, initial: initial);
    if (sets == null) return;
    try {
      await api.raw.put('/scoring/matches/${match.id}', data: {'sets': sets});
      ref.invalidate(matchesProvider(categoryId)); // refresca el marcador
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marcador actualizado')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _assign(BuildContext context, WidgetRef ref, ApiClient api) async {
    final referees = await ref.read(refereesProvider.future);
    if (!context.mounted) return;
    if (referees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay árbitros. Crea uno en "Árbitros" primero.')),
      );
      return;
    }
    final refId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Asignar árbitro'),
        children: referees
            .map((r) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, r.id),
                  child: ListTile(leading: const Icon(Icons.person), title: Text(r.name)),
                ))
            .toList(),
      ),
    );
    if (refId == null) return;
    try {
      await api.post('/referees/matches/${match.id}/assign', data: {'refereeId': refId});
      ref.invalidate(matchAssignmentsProvider(match.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Árbitro asignado')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

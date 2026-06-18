import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/repositories.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/share_tournament.dart';

/// Detalle de un torneo: lista sus categorías (rama + formato).
class TournamentDetailScreen extends ConsumerWidget {
  const TournamentDetailScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentProvider(tournamentId));

    return AppScaffold(
      title: 'Torneo',
      showBack: true,
      actions: [
        IconButton(
          tooltip: 'Compartir',
          icon: const Icon(Icons.share),
          onPressed: () => showShareTournamentDialog(
            context,
            tournamentId: tournamentId,
            tournamentName: tournament.asData?.value.name,
          ),
        ),
      ],
      body: tournament.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => const Center(
            child: Text('Error al cargar el torneo', style: TextStyle(color: Colors.white))),
        data: (t) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(t.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Categorías',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            ...t.categories.map(
              (c) => Card(
                child: ListTile(
                  leading: Icon(c.gender == 'MALE' ? Icons.male : Icons.female),
                  title: Text(c.name),
                  subtitle: Text('${c.genderLabel} · ${c.format}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/category/${c.id}'),
                ),
              ),
            ),
            if (t.categories.isEmpty)
              const Text('Sin categorías configuradas', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/repositories.dart';
import '../../widgets/app_scaffold.dart';

/// Pantalla pública de inicio: lista de torneos. No requiere login.
class TournamentsScreen extends ConsumerWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(tournamentsProvider);
    final df = DateFormat('d MMM y', 'es');

    return AppScaffold(
      title: 'Caribbean Fest',
      actions: [
        IconButton(
          tooltip: 'Acceso',
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => context.go('/login'),
        ),
      ],
      body: tournaments.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => _ErrorView(message: 'No se pudieron cargar los torneos', onRetry: () => ref.invalidate(tournamentsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Aún no hay torneos publicados',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tournamentsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final t = list[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.emoji_events_outlined)),
                    title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${df.format(t.startDate)} — ${df.format(t.endDate)}\n${t.categories.length} categorías'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/tournament/${t.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.white),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

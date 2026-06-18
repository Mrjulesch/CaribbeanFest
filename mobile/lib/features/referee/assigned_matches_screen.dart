import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth_controller.dart';
import '../../core/repositories.dart';
import '../../widgets/responsive_center.dart';

/// Partidos asignados al árbitro autenticado.
class AssignedMatchesScreen extends ConsumerWidget {
  const AssignedMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(assignedMatchesProvider);
    final df = DateFormat('d MMM HH:mm', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis partidos'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: matches.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Error al cargar tus partidos')),
          data: (list) {
            if (list.isEmpty) return const Center(child: Text('No tienes partidos asignados'));
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final m = list[i];
                return Card(
                  child: ListTile(
                    title: Text('${m.homeTeam?.name ?? "?"} vs ${m.awayTeam?.name ?? "?"}'),
                    subtitle: Text([
                      m.scheduledAt != null ? df.format(m.scheduledAt!) : 'Por programar',
                      if (m.court != null) m.court!.label,
                    ].join(' · ')),
                    trailing: FilledButton.tonal(
                      onPressed: m.isFinished ? null : () => context.go('/referee/score/${m.id}'),
                      child: Text(m.isFinished ? 'Finalizado' : 'Arbitrar'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/repositories.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';
import 'admin_dialogs.dart';

/// Gestión de equipos y jugadores de una categoría.
class AdminTeamsScreen extends ConsumerWidget {
  const AdminTeamsScreen({super.key, required this.categoryId});
  final String categoryId;

  void _snack(BuildContext c, String msg) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsByCategoryProvider(categoryId));
    final api = ref.read(apiClientProvider);

    Future<void> refresh() async => ref.invalidate(teamsByCategoryProvider(categoryId));

    return AppScaffold(
      title: 'Equipos',
      showBack: true,
      actions: [
        TextButton.icon(
          onPressed: () => AppScaffold.goBack(context),
          icon: const Icon(Icons.check, color: Colors.white),
          label: const Text('Guardar y continuar', style: TextStyle(color: Colors.white)),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.group_add),
        label: const Text('Equipo'),
        onPressed: () async {
          final d = await showFormDialog(context, title: 'Nuevo equipo', fields: [
            FieldSpec('team', 'Nombre del equipo'),
            FieldSpec('club', 'Nombre del club'),
            FieldSpec('city', 'Ciudad (opcional)'),
            FieldSpec('coach', 'Entrenador (opcional)'),
          ]);
          if (d == null || d['team']!.isEmpty || d['club']!.isEmpty) return;
          try {
            // 1) Crear club  2) Crear equipo en la categoría.
            final club = await api.post('/clubs', data: {'name': d['club'], 'city': d['city']});
            await api.post('/clubs/${club['id']}/teams',
                data: {'name': d['team'], 'categoryId': categoryId, 'coachName': d['coach']});
            await refresh();
            if (context.mounted) _snack(context, 'Equipo "${d['team']}" creado');
          } catch (e) {
            if (context.mounted) _snack(context, 'Error: $e');
          }
        },
      ),
      body: teams.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Sin equipos. Usa el botón "Equipo" para añadir.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: list.map((t) => _teamCard(context, ref, api, t)).toList(),
          );
        },
      ),
    );
  }

  Widget _teamCard(BuildContext context, WidgetRef ref, ApiClient api, TeamRef team) {
    const maxPlayers = 14;
    final full = team.playerCount >= maxPlayers;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.shield)),
        title: Text(team.name),
        subtitle: Text('${team.playerCount}/$maxPlayers jugadores',
            style: TextStyle(color: full ? Colors.red : null)),
        trailing: FilledButton.tonalIcon(
          icon: const Icon(Icons.person_add, size: 18),
          label: Text(full ? 'Completo' : 'Jugador'),
          onPressed: full
              ? null
              : () async {
                  final d = await showFormDialog(context, title: 'Nuevo jugador · ${team.name}', fields: [
                    FieldSpec('fullName', 'Nombre completo'),
                    FieldSpec('jerseyNumber', 'Dorsal (1-99)', keyboard: TextInputType.number),
                  ]);
                  if (d == null || d['fullName']!.isEmpty) return;
                  final body = <String, dynamic>{'fullName': d['fullName']};
                  final jersey = int.tryParse(d['jerseyNumber'] ?? '');
                  if (jersey != null) body['jerseyNumber'] = jersey;
                  try {
                    await api.post('/teams/${team.id}/players', data: body);
                    ref.invalidate(teamsByCategoryProvider(categoryId)); // refresca el conteo n/14
                    if (context.mounted) _snack(context, 'Jugador añadido a ${team.name}');
                  } catch (e) {
                    if (context.mounted) _snack(context, 'Error: $e');
                  }
                },
        ),
      ),
    );
  }
}

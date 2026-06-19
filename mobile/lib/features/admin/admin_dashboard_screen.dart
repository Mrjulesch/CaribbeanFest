import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/repositories.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/share_tournament.dart';
import 'admin_dialogs.dart';

/// Panel de administración: lista torneos, permite crearlos y entrar a su gestión.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(adminTournamentsProvider);
    final api = ref.read(apiClientProvider);

    void snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    void refreshAll() {
      ref.invalidate(adminTournamentsProvider); // listado admin (incluye borradores)
      ref.invalidate(tournamentsProvider); // listado público
    }

    Future<void> createTournament() async {
      final d = await showCreateTournamentDialog(context);
      if (d == null) return;
      try {
        final t = await api.post('/tournaments', data: d);
        refreshAll();
        if (context.mounted) {
          snack('Torneo "${d['name']}" creado');
          context.push('/admin/tournament/${t['id']}'); // entra a gestionarlo (apila → "atrás" vuelve aquí)
        }
      } catch (e) {
        if (context.mounted) snack('Error: $e');
      }
    }

    Future<void> editTournament(String id, String name, DateTime start, DateTime end) async {
      final d = await showEditTournamentDialog(context, name: name, start: start, end: end);
      if (d == null) return;
      try {
        await api.raw.patch('/tournaments/$id', data: d);
        refreshAll();
        if (context.mounted) snack('Torneo actualizado');
      } catch (e) {
        if (context.mounted) snack('Error: $e');
      }
    }

    Future<void> deleteTournament(String id, String name) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar torneo'),
          content: Text('¿Eliminar "$name" y todos sus datos (categorías, equipos, partidos)? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      try {
        await api.raw.delete('/tournaments/$id');
        refreshAll();
        if (context.mounted) snack('Torneo "$name" eliminado');
      } catch (e) {
        if (context.mounted) snack('Error: $e');
      }
    }

    Future<void> togglePublish(String id, bool publish) async {
      try {
        await api.raw.patch('/tournaments/$id', data: {'isPublished': publish});
        refreshAll();
        if (context.mounted) snack(publish ? 'Torneo publicado' : 'Torneo despublicado');
      } catch (e) {
        if (context.mounted) snack('Error: $e');
      }
    }

    return AppScaffold(
      title: 'Administración',
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
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo torneo'),
        onPressed: createTournament,
      ),
      body: tournaments.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.admin_panel_settings),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        'Crea un torneo, añade categorías, sedes y equipos, y genera los fixtures.'),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.sports),
                    label: const Text('Árbitros'),
                    onPressed: () => context.push('/admin/referees'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('Inscripciones'),
                    onPressed: () => context.push('/admin/registrations'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Mensajes'),
                    onPressed: () => context.push('/admin/messages'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Torneos',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            const SizedBox(height: 4),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aún no hay torneos. Crea el primero con el botón de abajo.',
                    style: TextStyle(color: Colors.white)),
              ),
            ...list.map((t) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(t.name),
                    subtitle: Row(
                      children: [
                        Text('${t.categories.length} categorías'),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(t.isPublished ? 'Publicado' : 'Borrador',
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: t.isPublished ? Colors.green.shade100 : Colors.orange.shade100,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    onTap: () => context.push('/admin/tournament/${t.id}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'manage') context.push('/admin/tournament/${t.id}');
                        if (v == 'edit') editTournament(t.id, t.name, t.startDate, t.endDate);
                        if (v == 'publish') togglePublish(t.id, !t.isPublished);
                        if (v == 'share') {
                          showShareTournamentDialog(context,
                              tournamentId: t.id, tournamentName: t.name, isPublished: t.isPublished);
                        }
                        if (v == 'delete') deleteTournament(t.id, t.name);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'manage', child: ListTile(leading: Icon(Icons.settings), title: Text('Gestionar'))),
                        const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Editar'))),
                        PopupMenuItem(
                          value: 'publish',
                          child: ListTile(
                            leading: Icon(t.isPublished ? Icons.visibility_off : Icons.public),
                            title: Text(t.isPublished ? 'Despublicar' : 'Publicar'),
                          ),
                        ),
                        const PopupMenuItem(
                            value: 'share',
                            child: ListTile(leading: Icon(Icons.share), title: Text('Compartir link'))),
                        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Eliminar'))),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

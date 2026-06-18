import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/repositories.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';
import 'admin_dialogs.dart';

/// Gestión de un torneo: categorías, sedes/canchas y generación de fixtures.
class AdminManageScreen extends ConsumerWidget {
  const AdminManageScreen({super.key, required this.tournamentId});
  final String tournamentId;

  void _snack(BuildContext c, String msg) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action, String okMsg) async {
    try {
      await action();
      ref.invalidate(tournamentProvider(tournamentId));
      if (context.mounted) _snack(context, okMsg);
    } catch (e) {
      if (context.mounted) _snack(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentProvider(tournamentId));
    final api = ref.read(apiClientProvider);

    return AppScaffold(
      title: 'Gestión del torneo',
      showBack: true,
      body: tournament.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (t) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _header(t.name),
            // ── Categorías ──────────────────────────────────────────────
            _sectionCard(
              title: 'Categorías',
              onAdd: () async {
                final d = await showCreateCategoryDialog(context);
                if (d == null) return;
                final payload = {
                  'name': d['name'],
                  'gender': d['gender'],
                  'format': d['format'],
                  'bestOf': int.tryParse(d['bestOf'] ?? '5') ?? 5,
                };
                await _run(context, ref, () => api.post('/tournaments/$tournamentId/categories', data: payload),
                    'Categoría "${d['name']}" creada');
              },
              children: t.categories.isEmpty
                  ? [const ListTile(title: Text('Sin categorías. Añade una para empezar.'))]
                  : t.categories.map((c) => _categoryTile(context, ref, api, c)).toList(),
            ),
            // ── Sedes y canchas ─────────────────────────────────────────
            _sectionCard(
              title: 'Sedes y canchas',
              onAdd: () async {
                final d = await showFormDialog(context,
                    title: 'Nueva sede', fields: [FieldSpec('name', 'Nombre de la sede'), FieldSpec('address', 'Dirección (opcional)')]);
                if (d == null || d['name']!.isEmpty) return;
                await _run(context, ref, () => api.post('/tournaments/$tournamentId/venues', data: d), 'Sede creada');
              },
              children: t.venues.isEmpty
                  ? [const ListTile(title: Text('Sin sedes. Añade una y sus canchas (necesario para fixtures).'))]
                  : t.venues.map((v) => _venueTile(context, ref, api, v)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String name) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(name,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      );

  Widget _sectionCard({required String title, required VoidCallback onAdd, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: FilledButton.tonalIcon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Añadir')),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _categoryTile(BuildContext context, WidgetRef ref, ApiClient api, Category c) {
    return ListTile(
      leading: Icon(c.gender == 'MALE' ? Icons.male : Icons.female),
      title: Text(c.name),
      subtitle: Text('${c.genderLabel} · ${c.format} · ${c.bestOfLabel}'),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Equipos',
            icon: const Icon(Icons.groups),
            onPressed: () => context.push('/admin/category/${c.id}/teams'),
          ),
          IconButton(
            tooltip: 'Partidos y árbitros',
            icon: const Icon(Icons.sports),
            onPressed: () => context.push('/admin/category/${c.id}/matches?bestOf=${c.bestOf}'),
          ),
          IconButton(
            tooltip: 'Generar fixture',
            icon: const Icon(Icons.auto_awesome_motion),
            onPressed: () async {
              final iso = await pickDateIso(context);
              if (iso == null) return;
              final body = <String, dynamic>{'startDate': iso};
              if (c.format == 'GROUPS_PLAYOFF') body['groupCount'] = 2;
              await _run(context, ref, () => api.post('/fixtures/category/${c.id}/generate', data: body),
                  'Fixture generado para ${c.name}');
            },
          ),
        ],
      ),
    );
  }

  Widget _venueTile(BuildContext context, WidgetRef ref, ApiClient api, Venue v) {
    return ExpansionTile(
      leading: const Icon(Icons.stadium),
      title: Text(v.name),
      subtitle: Text('${v.courts.length} cancha(s)'),
      children: [
        ...v.courts.map((court) => ListTile(
              dense: true,
              leading: const Icon(Icons.sports_volleyball, size: 18),
              title: Text(court.name),
            )),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Añadir cancha'),
          onTap: () async {
            final d = await showFormDialog(context, title: 'Nueva cancha', fields: [FieldSpec('name', 'Nombre (ej. Cancha 1)')]);
            if (d == null || d['name']!.isEmpty) return;
            await _run(context, ref, () => api.post('/tournaments/venues/${v.id}/courts', data: d), 'Cancha añadida');
          },
        ),
      ],
    );
  }
}

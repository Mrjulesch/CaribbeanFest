import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/repositories.dart';
import '../../widgets/app_scaffold.dart';

/// Revisión de inscripciones: la organización acepta o rechaza solicitudes.
class AdminRegistrationsScreen extends ConsumerWidget {
  const AdminRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(registrationsProvider('PENDING'));
    final api = ref.read(apiClientProvider);

    void snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    Future<void> act(String id, String action) async {
      try {
        await api.post('/registrations/$id/$action');
        ref.invalidate(registrationsProvider('PENDING'));
        if (context.mounted) snack(action == 'accept' ? 'Inscripción aceptada' : 'Inscripción rechazada');
      } catch (e) {
        if (context.mounted) snack('Error: $e');
      }
    }

    return AppScaffold(
      title: 'Inscripciones',
      showBack: true,
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No hay inscripciones pendientes.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: list.map((r) => _card(context, r as Map<String, dynamic>, act)).toList(),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> r, Future<void> Function(String, String) act) {
    final players = (r['players'] as List?) ?? [];
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.how_to_reg),
        title: Text(r['teamName'] as String? ?? 'Equipo'),
        subtitle: Text('${players.length} jugadores · ${r['contactName'] ?? ''}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          _row('Club', r['clubName'] as String? ?? '—'),
          _row('Ciudad', r['city'] as String? ?? '—'),
          _row('Contacto', '${r['contactName'] ?? ''} · ${r['contactEmail'] ?? ''} · ${r['contactPhone'] ?? ''}'),
          const Divider(),
          const Align(alignment: Alignment.centerLeft, child: Text('Jugadores', style: TextStyle(fontWeight: FontWeight.bold))),
          ...players.map((p) {
            final m = p as Map<String, dynamic>;
            final parts = [
              if (m['jerseyNumber'] != null) '#${m['jerseyNumber']}',
              m['fullName'] ?? '',
              if (m['document'] != null) 'CC ${m['document']}',
              if (m['age'] != null) '${m['age']} años',
              if (m['eps'] != null && '${m['eps']}'.isNotEmpty) 'EPS ${m['eps']}',
            ];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(parts.join(' · '), style: const TextStyle(fontSize: 13)),
            );
          }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                onPressed: () => act(r['id'] as String, 'reject'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Aceptar'),
                onPressed: () => act(r['id'] as String, 'accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ]),
      );
}

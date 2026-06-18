import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/repositories.dart';
import '../../widgets/app_scaffold.dart';
import 'admin_dialogs.dart';

/// Gestión de árbitros: crear cuentas de juez y listarlas.
class AdminRefereesScreen extends ConsumerWidget {
  const AdminRefereesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referees = ref.watch(refereesProvider);
    final api = ref.read(apiClientProvider);

    void snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    return AppScaffold(
      title: 'Árbitros',
      showBack: true,
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(refereesProvider),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Árbitro'),
        onPressed: () async {
          final d = await showFormDialog(context, title: 'Nuevo árbitro', fields: [
            FieldSpec('fullName', 'Nombre completo'),
            FieldSpec('email', 'Correo (será su usuario)'),
            FieldSpec('password', 'Contraseña (mín. 8)'),
            FieldSpec('license', 'Licencia (opcional)'),
          ]);
          if (d == null || d['fullName']!.isEmpty || d['email']!.isEmpty || (d['password']?.length ?? 0) < 8) {
            if (context.mounted) snack('Completa nombre, correo y contraseña (mín. 8).');
            return;
          }
          try {
            await api.post('/referees/full', data: {
              'fullName': d['fullName'],
              'email': d['email'],
              'password': d['password'],
              if (d['license']!.isNotEmpty) 'license': d['license'],
            });
            ref.invalidate(refereesProvider);
            if (context.mounted) snack('Árbitro "${d['fullName']}" creado');
          } catch (e) {
            if (context.mounted) snack('Error: $e');
          }
        },
      ),
      body: referees.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Sin árbitros. Crea uno con el botón "Árbitro".',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: list
                .map((r) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.sports)),
                        title: Text(r.name),
                        subtitle: Text([
                          r.license != null ? 'Licencia: ${r.license}' : 'Sin licencia',
                          '${r.assignmentCount} partido(s) asignado(s)',
                        ].join(' · ')),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/repositories.dart';
import '../../widgets/app_scaffold.dart';

/// Bandeja de mensajes recibidos por el formulario "Contáctanos".
class AdminMessagesScreen extends ConsumerWidget {
  const AdminMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(contactMessagesProvider);
    final df = DateFormat('d MMM y · HH:mm', 'es');

    return AppScaffold(
      title: 'Mensajes',
      showBack: true,
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(contactMessagesProvider),
        ),
      ],
      body: messages.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No hay mensajes todavía.', style: TextStyle(color: Colors.white, fontSize: 16)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: list.map((raw) {
              final m = raw as Map<String, dynamic>;
              final date = m['createdAt'] != null ? df.format(DateTime.parse(m['createdAt'] as String)) : '';
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.mail_outline)),
                  title: Text('${m['name'] ?? ''}  ·  ${m['email'] ?? ''}'),
                  subtitle: Text('${m['message'] ?? ''}\n$date'),
                  isThreeLine: true,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

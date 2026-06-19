import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'contact_form.dart';

/// Pie de página con el formulario "Contáctanos" y datos de la organización.
class AppFooter extends ConsumerWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_volleyball, color: Colors.white70, size: 28),
          const SizedBox(height: 8),
          const Text('Caribbean Fest',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Gestión de torneos de voleibol',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.mail_outline),
            label: const Text('Contáctanos'),
            onPressed: () => showContactDialog(context, ref),
          ),
          const SizedBox(height: 16),
          Text('© $year Caribbean Fest · Todos los derechos reservados',
              style: const TextStyle(color: Colors.white60, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

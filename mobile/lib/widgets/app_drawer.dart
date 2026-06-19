import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth_controller.dart';
import 'contact_form.dart';

/// Barra de navegación lateral. Muestra enlaces según el rol autenticado.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    void go(String route) {
      Navigator.of(context).pop(); // cierra el drawer
      context.go(route);
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF06203A), Color(0xFF0A4FA0)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.sports_volleyball, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text('Caribbean Fest',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Gestión de torneos de voleibol',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Torneos'),
            onTap: () => go('/'),
          ),
          ListTile(
            leading: const Icon(Icons.how_to_reg),
            title: const Text('Inscribir equipo'),
            onTap: () => go('/inscripcion'),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Contáctanos'),
            onTap: () {
              Navigator.of(context).pop(); // cierra el drawer
              showContactDialog(context, ref);
            },
          ),
          if (!auth.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Iniciar sesión'),
              onTap: () => go('/login'),
            ),
          if (auth.isAuthenticated && auth.user!.isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Administración'),
              onTap: () => go('/admin'),
            ),
          if (auth.isAuthenticated && auth.user!.isReferee)
            ListTile(
              leading: const Icon(Icons.sports_outlined),
              title: const Text('Mis partidos'),
              onTap: () => go('/referee'),
            ),
          if (auth.isAuthenticated) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ],
      ),
    );
  }
}

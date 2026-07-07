import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth_controller.dart';
import 'app_background.dart';
import 'app_drawer.dart';
import 'contact_form.dart';
import 'responsive_center.dart';

/// Scaffold compartido: fondo de voleibol, AppBar con degradado, barra lateral de
/// navegación visible en pantallas anchas, menú lateral (Drawer) en móvil y una
/// flecha "atrás" que siempre funciona.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBack = false,
    this.bottom,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBack;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;

  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_volleyball, size: 22),
            const SizedBox(width: 8),
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: actions,
        bottom: bottom,
        // Degradado en la barra superior → más vistosa y visible.
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF06203A), Color(0xFF0A4FA0), Color(0xFF12B0E8)],
            ),
          ),
        ),
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Atrás',
                onPressed: () => goBack(context),
              )
            : null,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: floatingActionButton,
      body: AppBackground(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide) const _SideNav(),
            Expanded(child: ResponsiveCenter(child: body)),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, {this.route, this.contact = false});
  final IconData icon;
  final String label;
  final String? route;
  final bool contact;
}

/// Barra de navegación lateral (visible en pantallas anchas). Cambia según el rol.
class _SideNav extends ConsumerWidget {
  const _SideNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final loc = GoRouterState.of(context).matchedLocation;

    final items = <_NavItem>[
      const _NavItem(Icons.emoji_events, 'Torneos', route: '/'),
      const _NavItem(Icons.how_to_reg, 'Inscribir', route: '/inscripcion'),
      if (auth.isAuthenticated && auth.user!.isAdmin)
        const _NavItem(Icons.admin_panel_settings, 'Admin', route: '/admin'),
      if (auth.isAuthenticated && auth.user!.isReferee)
        const _NavItem(Icons.sports, 'Partidos', route: '/referee'),
      if (!auth.isAuthenticated) const _NavItem(Icons.login, 'Entrar', route: '/login'),
      const _NavItem(Icons.mail_outline, 'Contacto', contact: true),
    ];

    int sel = items.indexWhere((it) => it.route != null && (loc == it.route || (it.route != '/' && loc.startsWith(it.route!))));
    if (sel < 0) sel = 0;

    return NavigationRail(
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      selectedIndex: sel,
      labelType: NavigationRailLabelType.all,
      indicatorColor: Colors.white.withValues(alpha: 0.20),
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: const IconThemeData(color: Colors.white70),
      selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Icon(Icons.sports_volleyball, color: Colors.white, size: 30),
      ),
      destinations: items
          .map((it) => NavigationRailDestination(icon: Icon(it.icon), label: Text(it.label)))
          .toList(),
      onDestinationSelected: (i) {
        final it = items[i];
        if (it.contact) {
          showContactDialog(context, ref);
        } else if (it.route != null) {
          context.go(it.route!);
        }
      },
    );
  }
}

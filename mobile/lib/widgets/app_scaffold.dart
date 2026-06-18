import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_background.dart';
import 'app_drawer.dart';
import 'responsive_center.dart';

/// Scaffold compartido: aplica el fondo de voleibol, la barra lateral (Drawer)
/// y una flecha de "atrás" que funciona siempre (pop si hay historial, si no
/// vuelve al inicio).
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        bottom: bottom,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Atrás',
                onPressed: () => goBack(context),
              )
            : null,
      ),
      // Sin flecha atrás, el Drawer hace que aparezca el ícono de menú (≡).
      drawer: const AppDrawer(),
      floatingActionButton: floatingActionButton,
      // Fondo a pantalla completa; el contenido se centra y limita en pantallas anchas.
      body: AppBackground(child: ResponsiveCenter(child: body)),
    );
  }
}

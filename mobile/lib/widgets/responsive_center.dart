import 'package:flutter/material.dart';

/// Centra el contenido con un ancho máximo en pantallas grandes (desktop, iPad,
/// tablets) y lo deja a todo el ancho en móviles. Es la pieza que hace la app
/// responsiva sin tocar cada pantalla.
///
/// Breakpoints de referencia: teléfono < 600 · tablet 600–1024 · desktop > 1024.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 900});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // En móvil ocupa todo; en pantallas anchas se limita y centra.
    final horizontalPadding = width > maxWidth ? (width - maxWidth) / 2 : 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: child,
    );
  }
}

/// Helpers de breakpoint reutilizables.
class Breakpoints {
  static bool isPhone(BuildContext c) => MediaQuery.sizeOf(c).width < 600;
  static bool isTablet(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    return w >= 600 && w <= 1024;
  }

  static bool isDesktop(BuildContext c) => MediaQuery.sizeOf(c).width > 1024;

  /// Columnas sugeridas para grillas de tarjetas según el ancho.
  static int gridColumns(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    if (w >= 1100) return 3;
    if (w >= 700) return 2;
    return 1;
  }
}

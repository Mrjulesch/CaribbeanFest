import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fondo propio (sin copyright): degradado azul caribeño + balones de voleibol
/// dibujados con CustomPainter. Se genera por código, así que no hay licencias.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06203A), Color(0xFF0A4FA0), Color(0xFF12B0E8)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _VolleyballPainter(),
        child: child,
      ),
    );
  }
}

/// Dibuja balones de voleibol estilizados, semitransparentes, como marca de agua.
class _VolleyballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Posiciones relativas (x, y, radio) para repartir los balones.
    final balls = <List<double>>[
      [0.85, 0.12, 90],
      [0.12, 0.78, 70],
      [0.70, 0.88, 50],
      [0.30, 0.30, 38],
    ];
    for (final b in balls) {
      _drawBall(canvas, Offset(size.width * b[0], size.height * b[1]), b[2]);
    }
  }

  void _drawBall(Canvas canvas, Offset center, double r) {
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.05);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05;

    canvas.drawCircle(center, r, fill);
    canvas.drawCircle(center, r, line);

    // Tres curvas para evocar las líneas del balón de voleibol.
    for (int i = 0; i < 3; i++) {
      final angle = (math.pi * 2 / 3) * i;
      final path = Path();
      final start = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      final end = center + Offset(math.cos(angle + math.pi) * r, math.sin(angle + math.pi) * r);
      final ctrl = center + Offset(math.cos(angle + math.pi / 2) * r * 0.9, math.sin(angle + math.pi / 2) * r * 0.9);
      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fondo propio (sin copyright): degradado azul caribeño + balones de voleibol
/// dibujados y **animados** (flotan suavemente). Se genera por código, sin licencias.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
      child: Stack(
        children: [
          // Capa animada de balones (no intercepta toques).
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(painter: _VolleyballPainter(_ctrl.value)),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Dibuja balones de voleibol estilizados, semitransparentes, que derivan lentamente.
class _VolleyballPainter extends CustomPainter {
  _VolleyballPainter(this.t);
  final double t; // 0..1 fase de animación

  // Posiciones base (x, y, radio, velocidad de fase).
  static const _balls = <List<double>>[
    [0.85, 0.14, 95, 1.0],
    [0.12, 0.78, 72, 0.7],
    [0.70, 0.88, 52, 1.3],
    [0.30, 0.30, 40, 0.9],
    [0.55, 0.55, 30, 1.6],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _balls) {
      final phase = t * 2 * math.pi * b[3];
      final dx = math.sin(phase) * 10; // deriva horizontal suave
      final dy = math.cos(phase) * 14; // deriva vertical suave
      _drawBall(canvas, Offset(size.width * b[0] + dx, size.height * b[1] + dy), b[2], phase);
    }
  }

  void _drawBall(Canvas canvas, Offset center, double r, double phase) {
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05;

    canvas.drawCircle(center, r, fill);
    canvas.drawCircle(center, r, line);

    // Tres curvas rotando muy lento → evocan las líneas del balón.
    final rot = phase * 0.15;
    for (int i = 0; i < 3; i++) {
      final angle = rot + (math.pi * 2 / 3) * i;
      final start = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      final end = center + Offset(math.cos(angle + math.pi) * r, math.sin(angle + math.pi) * r);
      final ctrl = center + Offset(math.cos(angle + math.pi / 2) * r * 0.9, math.sin(angle + math.pi / 2) * r * 0.9);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant _VolleyballPainter oldDelegate) => oldDelegate.t != t;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fondo propio (sin copyright): escena caribeña de playa + voleibol, dibujada y
/// animada por código. Mar en degradado, sol, palmeras, arena, olas y balones
/// de voleibol flotando. Todo semitransparente para no estorbar la lectura.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Cielo → mar Caribe (turquesa) de arriba a abajo.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF063B6E), Color(0xFF0A66A8), Color(0xFF0E9BC4), Color(0xFF15C0C0)],
          stops: [0.0, 0.4, 0.75, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(painter: _BeachPainter(_ctrl.value)),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _BeachPainter extends CustomPainter {
  _BeachPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    _drawSun(canvas, size);
    _drawWaves(canvas, size);
    _drawSand(canvas, size);
    _drawPalm(canvas, Offset(size.width * 0.10, size.height * 0.99), 1.0, false);
    _drawPalm(canvas, Offset(size.width * 0.90, size.height * 0.99), 1.15, true);
    _drawBalls(canvas, size);
  }

  // Sol cálido con resplandor, arriba a la derecha.
  void _drawSun(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.82, size.height * 0.14);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFE9A8).withValues(alpha: 0.35), const Color(0xFFFFE9A8).withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: c, radius: 140));
    canvas.drawCircle(c, 140, glow);
    canvas.drawCircle(c, 46, Paint()..color = const Color(0xFFFFF0C0).withValues(alpha: 0.55));
  }

  // Olas suaves que se desplazan.
  void _drawWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (int k = 0; k < 3; k++) {
      final y = size.height * (0.62 + k * 0.09);
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        final off = math.sin((x / 60) + t * 2 * math.pi + k) * 6;
        path.lineTo(x, y + off);
      }
      canvas.drawPath(path, paint);
    }
  }

  // Franja de arena ondulada al fondo.
  void _drawSand(Canvas canvas, Size size) {
    final top = size.height * 0.9;
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, top);
    for (double x = 0; x <= size.width; x += 30) {
      path.lineTo(x, top + math.sin(x / 80 + t * 2 * math.pi) * 6);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFEAD7A0).withValues(alpha: 0.16));
  }

  // Palmera silueta (tronco curvo + hojas).
  void _drawPalm(Canvas canvas, Offset base, double scale, bool mirror) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    if (mirror) canvas.scale(-1, 1);
    canvas.scale(scale, scale);
    final col = const Color(0xFF0B3D2E).withValues(alpha: 0.22);
    final trunk = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final trunkPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-18, -110, 8, -210);
    canvas.drawPath(trunkPath, trunk);
    final top = const Offset(8, -210);
    final leaf = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final a = -math.pi * 0.9 + i * (math.pi * 0.8 / 5);
      final end = top + Offset(math.cos(a) * 78, math.sin(a) * 78);
      final ctrl = top + Offset(math.cos(a) * 45, math.sin(a) * 45 - 26);
      final p = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      canvas.drawPath(p, leaf);
    }
    canvas.restore();
  }

  // Balones de voleibol flotando.
  void _drawBalls(Canvas canvas, Size size) {
    const balls = <List<double>>[
      [0.20, 0.30, 42, 0.9],
      [0.68, 0.40, 34, 1.4],
      [0.40, 0.55, 26, 1.1],
    ];
    for (final b in balls) {
      final phase = t * 2 * math.pi * b[3];
      final center = Offset(size.width * b[0] + math.sin(phase) * 10, size.height * b[1] + math.cos(phase) * 14);
      final r = b[2];
      final fill = Paint()..color = Colors.white.withValues(alpha: 0.08);
      final line = Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05;
      canvas.drawCircle(center, r, fill);
      canvas.drawCircle(center, r, line);
      final rot = phase * 0.15;
      for (int i = 0; i < 3; i++) {
        final angle = rot + (math.pi * 2 / 3) * i;
        final start = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        final end = center + Offset(math.cos(angle + math.pi) * r, math.sin(angle + math.pi) * r);
        final ctrl = center + Offset(math.cos(angle + math.pi / 2) * r * 0.9, math.sin(angle + math.pi / 2) * r * 0.9);
        canvas.drawPath(Path()..moveTo(start.dx, start.dy)..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy), line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BeachPainter oldDelegate) => oldDelegate.t != t;
}

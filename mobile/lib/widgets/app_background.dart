import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fondo caribeño realista dibujado por código (sin copyright): cielo y mar en
/// degradado, sol con reflejo, nubes que derivan con la brisa, olas con espuma,
/// palmeras que se mecen, arena con textura y balones de voleibol con costuras.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Cielo (arriba) → mar Caribe turquesa (abajo). Se mantiene legible para el texto.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A5A93), Color(0xFF0E86B8), Color(0xFF13A9C4), Color(0xFF1BC5B8)],
          stops: [0.0, 0.42, 0.72, 1.0],
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
    final horizon = size.height * 0.46;
    _sun(canvas, size, horizon);
    _clouds(canvas, size);
    _seaShimmerAndWaves(canvas, size, horizon);
    _sand(canvas, size);
    _palm(canvas, Offset(size.width * 0.09, size.height * 1.0), 1.0, false);
    _palm(canvas, Offset(size.width * 0.93, size.height * 1.02), 1.2, true);
    _balls(canvas, size);
  }

  // Sol cálido con núcleo brillante y reflejo vertical sobre el agua.
  void _sun(Canvas canvas, Size size, double horizon) {
    final c = Offset(size.width * 0.80, horizon * 0.55);
    canvas.drawCircle(
      c,
      150,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFF6D8).withValues(alpha: 0.5),
          const Color(0xFFFFE9A8).withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: c, radius: 150)),
    );
    canvas.drawCircle(c, 44, Paint()..color = const Color(0xFFFFF4CE).withValues(alpha: 0.85));
    // Reflejo en el mar (franja de destellos bajo el sol).
    final refl = Rect.fromLTWH(c.dx - 40, horizon, 80, size.height - horizon);
    canvas.drawRect(
      refl,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFF4CE).withValues(alpha: 0.22), const Color(0xFFFFF4CE).withValues(alpha: 0.0)],
        ).createShader(refl),
    );
  }

  // Nubes suaves que se desplazan con la brisa.
  void _clouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.16);
    void cloud(double baseX, double y, double s) {
      final x = (baseX + t * 0.6) % 1.2 * size.width - 0.1 * size.width;
      for (final o in [const Offset(0, 0), Offset(26 * s, 6), Offset(-26 * s, 6), Offset(12 * s, -10)]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(x + o.dx, y + o.dy), width: 70 * s, height: 34 * s), paint);
      }
    }

    cloud(0.1, size.height * 0.12, 1.1);
    cloud(0.55, size.height * 0.20, 0.8);
    cloud(0.85, size.height * 0.09, 0.9);
  }

  // Brillo del mar cerca del horizonte + olas con espuma que avanzan.
  void _seaShimmerAndWaves(Canvas canvas, Size size, double horizon) {
    canvas.drawRect(
      Rect.fromLTWH(0, horizon - 2, size.width, 3),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final foam = Paint()..color = Colors.white.withValues(alpha: 0.22);
    for (int k = 0; k < 4; k++) {
      final y = horizon + 26 + k * (size.height - horizon) / 5;
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 20) {
        final off = math.sin((x / 55) + t * 2 * math.pi + k * 0.8) * (4 + k);
        path.lineTo(x, y + off);
        if (x % 120 < 20) {
          canvas.drawCircle(Offset(x, y + off), 1.6, foam); // motas de espuma
        }
      }
      canvas.drawPath(path, wave);
    }
  }

  // Arena con degradado y textura de granos.
  void _sand(Canvas canvas, Size size) {
    final top = size.height * 0.9;
    final path = Path()..moveTo(0, size.height)..lineTo(0, top);
    for (double x = 0; x <= size.width; x += 28) {
      path.lineTo(x, top + math.sin(x / 90 + t * 2 * math.pi) * 5);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFF2E2B0).withValues(alpha: 0.30), const Color(0xFFDFC98A).withValues(alpha: 0.42)],
        ).createShader(Rect.fromLTWH(0, top, size.width, size.height - top)),
    );
    // Granos (deterministas).
    final grain = Paint()..color = const Color(0xFF9C8752).withValues(alpha: 0.35);
    final rnd = math.Random(7);
    for (int i = 0; i < 90; i++) {
      final gx = rnd.nextDouble() * size.width;
      final gy = top + 10 + rnd.nextDouble() * (size.height - top - 10);
      canvas.drawCircle(Offset(gx, gy), 0.9, grain);
    }
  }

  // Palmera con tronco anillado y hojas (fronds) que se mecen con la brisa.
  void _palm(Canvas canvas, Offset base, double scale, bool mirror) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    if (mirror) canvas.scale(-1, 1);
    canvas.scale(scale, scale);

    final trunkCol = const Color(0xFF6B4A2B).withValues(alpha: 0.5);
    final trunk = Paint()
      ..color = trunkCol
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final sway = math.sin(t * 2 * math.pi) * 6;
    final topP = Offset(10 + sway, -235);
    canvas.drawPath(Path()..moveTo(0, 0)..quadraticBezierTo(-20, -120, topP.dx, topP.dy), trunk);
    // Anillos del tronco.
    final ring = Paint()..color = const Color(0xFF4E3620).withValues(alpha: 0.45)..style = PaintingStyle.stroke..strokeWidth = 2;
    for (int i = 1; i <= 6; i++) {
      final p = i / 7.0;
      final y = -235 * p;
      final x = (-20 * 2 * p * (1 - p)) + (10 + sway) * p * p;
      canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), ring);
    }
    // Cocos.
    final coco = Paint()..color = const Color(0xFF5A3F24).withValues(alpha: 0.5);
    canvas.drawCircle(topP + const Offset(-6, 6), 5, coco);
    canvas.drawCircle(topP + const Offset(5, 8), 5, coco);
    // Fronds como hojas rellenas con nervadura.
    final leafFill = const Color(0xFF125A3A).withValues(alpha: 0.32);
    final leafVein = const Color(0xFF0C4429).withValues(alpha: 0.5);
    for (int i = 0; i < 7; i++) {
      final a = -math.pi * 0.95 + i * (math.pi * 0.95 / 6) + math.sin(t * 2 * math.pi + i) * 0.03;
      final len = 92.0;
      final tip = topP + Offset(math.cos(a) * len, math.sin(a) * len);
      final mid = topP + Offset(math.cos(a) * len * 0.5, math.sin(a) * len * 0.5 - 16);
      final perp = a + math.pi / 2;
      final w = 12.0;
      final leaf = Path()
        ..moveTo(topP.dx, topP.dy)
        ..quadraticBezierTo(mid.dx + math.cos(perp) * w, mid.dy + math.sin(perp) * w, tip.dx, tip.dy)
        ..quadraticBezierTo(mid.dx - math.cos(perp) * w, mid.dy - math.sin(perp) * w, topP.dx, topP.dy)
        ..close();
      canvas.drawPath(leaf, Paint()..color = leafFill);
      canvas.drawPath(
        Path()..moveTo(topP.dx, topP.dy)..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy),
        Paint()..color = leafVein..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );
    }
    canvas.restore();
  }

  // Balones de voleibol con costuras (6 paneles) flotando suavemente.
  void _balls(Canvas canvas, Size size) {
    const balls = <List<double>>[
      [0.24, 0.34, 40, 0.9],
      [0.66, 0.30, 30, 1.3],
    ];
    for (final b in balls) {
      final phase = t * 2 * math.pi * b[3];
      final center = Offset(size.width * b[0] + math.sin(phase) * 8, size.height * b[1] + math.cos(phase) * 12);
      final r = b[2];
      canvas.drawCircle(center + Offset(0, r * 0.12), r, Paint()..color = Colors.black.withValues(alpha: 0.05)); // sombra
      canvas.drawCircle(center, r, Paint()..color = Colors.white.withValues(alpha: 0.14));
      final line = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.045;
      canvas.drawCircle(center, r, line);
      // Patrón de paneles: 3 curvas por cada eje → 6 gajos.
      final rot = phase * 0.1;
      for (int i = 0; i < 3; i++) {
        final a = rot + (math.pi / 3) * i;
        final p = Path();
        for (double s = -1.0; s <= 1.0; s += 0.1) {
          final bend = (1 - s * s) * r * 0.55;
          final x = center.dx + math.cos(a) * s * r - math.sin(a) * bend;
          final y = center.dy + math.sin(a) * s * r + math.cos(a) * bend;
          s == -1.0 ? p.moveTo(x, y) : p.lineTo(x, y);
        }
        canvas.drawPath(p, line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BeachPainter oldDelegate) => oldDelegate.t != t;
}

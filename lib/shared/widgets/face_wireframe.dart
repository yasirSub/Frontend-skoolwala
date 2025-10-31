// ignore_for_file: dead_code, unused_local_variable

import 'dart:math' as math;
import 'package:flutter/material.dart';

class FaceWireframe extends StatelessWidget {
  const FaceWireframe({super.key, this.scanProgress = 0});

  final double scanProgress; // 0..1 external scan line position

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _FacePainter(
          t: 0.0, // static face, animations removed
          scanProgress: scanProgress,
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter({required this.t, required this.scanProgress});
  final double t;
  final double scanProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle background gradient
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x00000000), Color(0x2200FFE0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Base colors
    const cyan = Color(0xFF00E5FF);
    const cyanGlow = Color(0x9900E5FF);
    const bool showInternalFace = false;

    // Head outline with glow (custom path for chin/jaw taper)
    final outlineRect = Rect.fromLTWH(
      size.width * 0.14,
      size.height * 0.06,
      size.width * 0.72,
      size.height * 0.88,
    );
    final c = outlineRect.center;
    final outlinePath = Path()
      ..moveTo(c.dx, outlineRect.top)
      ..quadraticBezierTo(
        outlineRect.left,
        outlineRect.top + outlineRect.height * 0.22,
        outlineRect.left + outlineRect.width * 0.10,
        outlineRect.top + outlineRect.height * 0.55,
      )
      ..quadraticBezierTo(
        c.dx,
        outlineRect.bottom + outlineRect.height * 0.06,
        outlineRect.right - outlineRect.width * 0.10,
        outlineRect.top + outlineRect.height * 0.55,
      )
      ..quadraticBezierTo(
        outlineRect.right,
        outlineRect.top + outlineRect.height * 0.22,
        c.dx,
        outlineRect.top,
      );
    final outline = Paint()
      ..color = cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final outlineGlow = Paint()
      ..color = cyanGlow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);
    // Dead code removed - showInternalFace is always false

    // Surrounding sci‑fi halo network (static)
    final haloGlow = Paint()
      ..color = const Color(0x5500E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
    final halo = Paint()
      ..color = const Color(0xFF00BEEF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw 3 offset arcs around the head
    for (int k = 0; k < 3; k++) {
      final inflate = 18.0 + 14.0 * k;
      final arc = outlineRect.inflate(inflate);
      final start = -math.pi * (0.15 + 0.05 * k);
      final sweep = math.pi * (1.3 + 0.15 * k);
      canvas.drawArc(arc, start, sweep, false, haloGlow);
      canvas.drawArc(arc, start, sweep, false, halo);
    }

    // Node cloud around the head with connections
    final rnd = math.Random(42);
    final nodePts = <Offset>[];
    final cloudRect = outlineRect.inflate(40);
    for (int i = 0; i < 70; i++) {
      // sample points in an annulus around the outline
      final angle = rnd.nextDouble() * 2 * math.pi;
      final r = (outlineRect.width * 0.45) + rnd.nextDouble() * 70;
      final px = outlineRect.center.dx + r * math.cos(angle);
      final py = outlineRect.center.dy + r * math.sin(angle) * 0.85;
      if (cloudRect.contains(Offset(px, py))) {
        nodePts.add(Offset(px, py));
      }
    }
    final nodeGlow = Paint()
      ..color = const Color(0x88FFFFFF)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final node = Paint()..color = const Color(0xFFFFFFFF);
    for (final p in nodePts) {
      canvas.drawCircle(p, 2.5, nodeGlow);
      canvas.drawCircle(p, 1.2, node);
    }

    // Light connections to nearest neighbors
    final link = Paint()
      ..color = const Color(0x44FFFFFF)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < nodePts.length; i++) {
      final a = nodePts[i];
      // connect to up to 3 nearest
      final distances = <int, double>{};
      for (int j = 0; j < nodePts.length; j++) {
        if (i == j) continue;
        final d = (a - nodePts[j]).distance;
        distances[j] = d;
      }
      final sorted = distances.entries.toList()
        ..sort((x, y) => x.value.compareTo(y.value));
      for (int k = 0; k < 3 && k < sorted.length; k++) {
        final b = nodePts[sorted[k].key];
        if ((a - b).distance < 140) {
          canvas.drawLine(a, b, link);
        }
      }
    }

    // Scanning highlight following external scanProgress
    final scanY = size.height * (0.1 + 0.8 * scanProgress);
    final scanPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0xAA00FFE0), Colors.transparent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, scanY - 2, size.width, 4));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 2, size.width, 4), scanPaint);

    // Corner brackets
    final corner = Paint()
      ..color = const Color(0xFF00AFE0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const cLen = 22.0;
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    void bracket(Offset p, {required bool top, required bool left}) {
      final path = Path();
      final dx = left ? r.left : r.right;
      final dy = top ? r.top : r.bottom;
      final sx = left ? 1 : -1;
      final sy = top ? 1 : -1;
      path.moveTo(dx.toDouble(), dy + sy * cLen);
      path.lineTo(dx.toDouble(), dy.toDouble());
      path.lineTo(dx + sx * cLen, dy.toDouble());
      canvas.drawPath(path, corner);
    }

    bracket(r.topLeft, top: true, left: true);
    bracket(r.topRight, top: true, left: false);
    bracket(r.bottomLeft, top: false, left: true);
    bracket(r.bottomRight, top: false, left: false);
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.scanProgress != scanProgress;
  }
}

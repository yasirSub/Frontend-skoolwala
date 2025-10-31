import 'package:flutter/material.dart';

class SimpleFaceWireframe extends StatelessWidget {
  const SimpleFaceWireframe({super.key, this.scanProgress = 0});

  final double scanProgress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _SimpleFacePainter(scanProgress: scanProgress),
      ),
    );
  }
}

class _SimpleFacePainter extends CustomPainter {
  _SimpleFacePainter({required this.scanProgress});
  final double scanProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // Transparent background - no background fill for chroma key support

    const cyan = Color(0xFF00E5FF);
    const cyanGlow = Color(0x6600E5FF);

    final stroke = Paint()
      ..color = cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final glow = Paint()
      ..color = cyanGlow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final faceWidth = size.width * 0.35;
    final faceHeight = size.height * 0.45;

    // Face outline (oval)
    final faceRect = Rect.fromCenter(
      center: center,
      width: faceWidth,
      height: faceHeight,
    );
    canvas.drawOval(faceRect, glow);
    canvas.drawOval(faceRect, stroke);

    // Key facial points
    final leftEye = Offset(
      center.dx - faceWidth * 0.15,
      center.dy - faceHeight * 0.12,
    );
    final rightEye = Offset(
      center.dx + faceWidth * 0.15,
      center.dy - faceHeight * 0.12,
    );
    final noseTip = Offset(center.dx, center.dy + faceHeight * 0.05);
    final mouthLeft = Offset(
      center.dx - faceWidth * 0.12,
      center.dy + faceHeight * 0.18,
    );
    final mouthRight = Offset(
      center.dx + faceWidth * 0.12,
      center.dy + faceHeight * 0.18,
    );
    final chin = Offset(center.dx, center.dy + faceHeight * 0.4);
    final forehead = Offset(center.dx, center.dy - faceHeight * 0.35);
    final leftCheek = Offset(
      center.dx - faceWidth * 0.25,
      center.dy + faceHeight * 0.08,
    );
    final rightCheek = Offset(
      center.dx + faceWidth * 0.25,
      center.dy + faceHeight * 0.08,
    );

    // Geometric connections
    final connections = [
      // Eye to eye
      [leftEye, rightEye],
      // Eyes to nose
      [leftEye, noseTip],
      [rightEye, noseTip],
      // Nose to mouth corners
      [noseTip, mouthLeft],
      [noseTip, mouthRight],
      // Mouth line
      [mouthLeft, mouthRight],
      // Face structure
      [leftEye, leftCheek],
      [rightEye, rightCheek],
      [leftCheek, chin],
      [rightCheek, chin],
      [forehead, leftEye],
      [forehead, rightEye],
      // Additional geometric lines
      [leftEye, mouthRight],
      [rightEye, mouthLeft],
      [forehead, noseTip],
      [leftCheek, rightCheek],
    ];

    // Draw connections
    for (final connection in connections) {
      canvas.drawLine(connection[0], connection[1], glow);
      canvas.drawLine(connection[0], connection[1], stroke);
    }

    // Draw nodes at key points
    final nodePaint = Paint()
      ..color = cyan
      ..style = PaintingStyle.fill;
    final nodeGlow = Paint()
      ..color = cyanGlow
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final keyPoints = [
      leftEye,
      rightEye,
      noseTip,
      mouthLeft,
      mouthRight,
      chin,
      forehead,
      leftCheek,
      rightCheek,
    ];

    for (final point in keyPoints) {
      canvas.drawCircle(point, 4.0, nodeGlow);
      canvas.drawCircle(point, 2.5, nodePaint);
    }

    // Eyes with pupils
    final eyePaint = Paint()
      ..color = cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(leftEye, 8.0, eyePaint);
    canvas.drawCircle(rightEye, 8.0, eyePaint);
    canvas.drawCircle(leftEye, 3.0, nodePaint);
    canvas.drawCircle(rightEye, 3.0, nodePaint);

    // Scanning highlight
    final scanY = size.height * (0.1 + 0.8 * scanProgress);
    final scanPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0xAA00FFE0), Colors.transparent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, scanY - 2, size.width, 4));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 2, size.width, 4), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _SimpleFacePainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}

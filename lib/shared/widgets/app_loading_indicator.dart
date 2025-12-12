import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Reusable Loading Indicator Widget
/// Displays the same loading indicator used in splash screen
class AppLoadingIndicator extends StatefulWidget {
  final double? size;
  final String? text;
  final double? fontSize;

  const AppLoadingIndicator({super.key, this.size, this.text, this.fontSize});

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 120.0;
    final fontSize = widget.fontSize ?? 16.0;
    final text = widget.text ?? 'LOADING';

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: LoadingPainter(
            rotation: _rotationController.value * 2 * 3.14159,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFD700), // Bright yellow
                letterSpacing: 2.0,
                shadows: [
                  // Glow effect with multiple shadow layers
                  Shadow(
                    color: const Color(0xFFFFD700).withOpacity(0.9),
                    blurRadius: 25,
                    offset: const Offset(0, 0),
                  ),
                  Shadow(
                    color: const Color(0xFFFFD700).withOpacity(0.7),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                  ),
                  Shadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                  ),
                  Shadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoadingPainter extends CustomPainter {
  final double rotation;

  LoadingPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw circular background with shadow effect
    final circlePaint = Paint()
      ..color =
          const Color(0xFF3A3A3A) // Lighter gray circle
      ..style = PaintingStyle.fill;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius + 5, shadowPaint);
    canvas.drawCircle(center, radius, circlePaint);

    // Draw yellow arc (from 7 o'clock to 2 o'clock = 210° to 60° = 210° arc)
    final arcPaint = Paint()
      ..color =
          const Color(0xFFFFD700) // Bright yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Arc starts at 7 o'clock (210°) and extends 210 degrees clockwise
    const startAngle = 210 * (3.14159 / 180); // 7 o'clock in radians
    const sweepAngle = 210 * (3.14159 / 180); // 210 degrees

    // Apply rotation
    final rotatedStartAngle = startAngle + rotation;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      rotatedStartAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Draw yellow dot at the leading edge (2 o'clock position)
    final dotAngle = rotatedStartAngle + sweepAngle;
    final dotX = center.dx + (radius - 10) * cos(dotAngle);
    final dotY = center.dy + (radius - 10) * sin(dotAngle);

    final dotPaint = Paint()
      ..color =
          const Color(0xFFFFD700) // Bright yellow
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(LoadingPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }

  double cos(double angle) {
    return math.cos(angle);
  }

  double sin(double angle) {
    return math.sin(angle);
  }
}

import 'package:flutter/material.dart';

class AnimatedFaceScan extends StatefulWidget {
  const AnimatedFaceScan({super.key});

  @override
  State<AnimatedFaceScan> createState() => _AnimatedFaceScanState();
}

class _AnimatedFaceScanState extends State<AnimatedFaceScan>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Outer pulse
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    const Color(0xFF00E5FF).withOpacity(0.0),
                    const Color(
                      0xFF00E5FF,
                    ).withOpacity(0.05 + _controller.value * 0.1),
                    const Color(0xFF00E5FF).withOpacity(0.0),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 180,
                height: 180,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(
                      0xFF00E5FF,
                    ).withOpacity(0.2 + _controller.value * 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF00E5FF,
                      ).withOpacity(0.1 + _controller.value * 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: 0.6 + _controller.value * 0.4,
                  child: Image.asset(
                    'assets/FACEdect.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

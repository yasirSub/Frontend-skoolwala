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
      duration: const Duration(seconds: 3),
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
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.9,
              colors: [
                Colors.transparent,
                const Color(
                  0xFF00E5FF,
                  // ignore: deprecated_member_use
                ).withOpacity(0.08 + _controller.value * 0.28),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: Container(
              width: 280,
              height: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(
                    0xFF00E5FF,
                    // ignore: deprecated_member_use
                  ).withOpacity(0.25 + _controller.value * 0.45),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    const Color(
                      0xFF00E5FF,
                      // ignore: deprecated_member_use
                    ).withOpacity(0.8 + _controller.value * 0.2),
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(
                    'assets/FACEdect.png',
                    fit: BoxFit.contain,
                    // ignore: deprecated_member_use
                    color: const Color(0xFF00E5FF).withOpacity(0.9),
                    colorBlendMode: BlendMode.srcATop,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

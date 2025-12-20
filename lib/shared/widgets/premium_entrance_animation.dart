import 'package:flutter/material.dart';

/// A premium entrance animation that combines scaling, sliding, and a shine effect.
class PremiumEntranceAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const PremiumEntranceAnimation({
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    super.key,
  });

  @override
  State<PremiumEntranceAnimation> createState() =>
      _PremiumEntranceAnimationState();
}

class _PremiumEntranceAnimationState extends State<PremiumEntranceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    Future.delayed(
      widget.delay + Duration(milliseconds: widget.index * 100),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: Transform.scale(
              scale: 0.85 + (0.15 * value),
              child: Stack(
                children: [
                  child!,
                  // Shine Effect
                  if (value > 0.1 && value < 0.9)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.5 * (1 - value)),
                                Colors.white.withOpacity(0),
                              ],
                              stops: [
                                (value * 1.5) - 0.5,
                                (value * 1.5) - 0.25,
                                (value * 1.5),
                              ],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Custom loading animations
class LoadingAnimations {
  /// Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return _ShimmerWidget(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      duration: duration,
      child: child,
    );
  }

  /// Pulse loading animation
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minOpacity = 0.3,
    double maxOpacity = 1.0,
  }) {
    return _PulseWidget(
      duration: duration,
      minOpacity: minOpacity,
      maxOpacity: maxOpacity,
      child: child,
    );
  }

  /// Bounce loading animation
  static Widget bounce({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    double minScale = 0.8,
    double maxScale = 1.2,
  }) {
    return _BounceWidget(
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
      child: child,
    );
  }

  /// Rotate loading animation
  static Widget rotate({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return _RotateWidget(duration: duration, child: child);
  }

  /// Wave loading animation
  static Widget wave({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1200),
    int waveCount = 3,
  }) {
    return _WaveWidget(duration: duration, waveCount: waveCount, child: child);
  }
}

/// Shimmer effect implementation
class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const _ShimmerWidget({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    required this.duration,
  });

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Pulse effect implementation
class _PulseWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  const _PulseWidget({
    required this.child,
    required this.duration,
    required this.minOpacity,
    required this.maxOpacity,
  });

  @override
  State<_PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<_PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
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
        return Opacity(opacity: _animation.value, child: widget.child);
      },
    );
  }
}

/// Bounce effect implementation
class _BounceWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const _BounceWidget({
    required this.child,
    required this.duration,
    required this.minScale,
    required this.maxScale,
  });

  @override
  State<_BounceWidget> createState() => _BounceWidgetState();
}

class _BounceWidgetState extends State<_BounceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));
    _controller.repeat(reverse: true);
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
        return Transform.scale(scale: _animation.value, child: widget.child);
      },
    );
  }
}

/// Rotate effect implementation
class _RotateWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _RotateWidget({required this.child, required this.duration});

  @override
  State<_RotateWidget> createState() => _RotateWidgetState();
}

class _RotateWidgetState extends State<_RotateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.repeat();
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
        return Transform.rotate(
          angle: _animation.value * 2 * 3.14159,
          child: widget.child,
        );
      },
    );
  }
}

/// Wave effect implementation
class _WaveWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final int waveCount;

  const _WaveWidget({
    required this.child,
    required this.duration,
    required this.waveCount,
  });

  @override
  State<_WaveWidget> createState() => _WaveWidgetState();
}

class _WaveWidgetState extends State<_WaveWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.waveCount,
      (index) => AnimationController(duration: widget.duration, vsync: this),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    // Start animations with staggered delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.waveCount, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: 20 + (_animations[index].value * 20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(
                  0.3 + (_animations[index].value * 0.7),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Custom loading indicator with text
class LoadingWithText extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;

  const LoadingWithText({
    super.key,
    required this.text,
    this.color,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          color: color ?? Theme.of(context).primaryColor,
          strokeWidth: 2.0,
        ),
        const SizedBox(height: 16),
        Text(
          text,
          style: TextStyle(
            color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

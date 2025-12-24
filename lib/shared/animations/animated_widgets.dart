import 'package:flutter/material.dart';

/// Animated counter that counts from 0 to target value
class AnimatedCounter extends StatefulWidget {
  final int targetValue;
  final Duration duration;
  final TextStyle? textStyle;
  final String? suffix;
  final String? prefix;
  final Curve curve;
  final bool animateOnMount;
  final Duration delay;

  const AnimatedCounter({
    super.key,
    required this.targetValue,
    this.duration = const Duration(milliseconds: 1500),
    this.textStyle,
    this.suffix,
    this.prefix,
    this.curve = Curves.easeOutCubic,
    this.animateOnMount = true,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.targetValue.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _animation.addListener(() {
      setState(() {
        _currentValue = _animation.value.round();
      });
    });

    if (widget.animateOnMount) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _animation = Tween<double>(
        begin: _currentValue.toDouble(),
        end: widget.targetValue.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix ?? ''}$_currentValue${widget.suffix ?? ''}',
      style: widget.textStyle ?? Theme.of(context).textTheme.headlineMedium,
    );
  }
}

/// Animated percentage counter
class AnimatedPercentage extends StatefulWidget {
  final double targetPercentage;
  final Duration duration;
  final TextStyle? textStyle;
  final int decimalPlaces;
  final Curve curve;
  final Duration delay;

  const AnimatedPercentage({
    super.key,
    required this.targetPercentage,
    this.duration = const Duration(milliseconds: 1500),
    this.textStyle,
    this.decimalPlaces = 1,
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedPercentage> createState() => _AnimatedPercentageState();
}

class _AnimatedPercentageState extends State<AnimatedPercentage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.targetPercentage,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _animation.addListener(() {
      setState(() {
        _currentPercentage = _animation.value;
      });
    });

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedPercentage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetPercentage != widget.targetPercentage) {
      _animation = Tween<double>(
        begin: _currentPercentage,
        end: widget.targetPercentage,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_currentPercentage.toStringAsFixed(widget.decimalPlaces)}%',
      style: widget.textStyle ?? Theme.of(context).textTheme.headlineMedium,
    );
  }
}

/// Animated progress bar
class AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final Duration duration;
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;
  final BorderRadius? borderRadius;
  final Curve curve;
  final Duration delay;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.duration = const Duration(milliseconds: 1500),
    this.backgroundColor,
    this.progressColor,
    this.height = 8.0,
    this.borderRadius,
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _controller.reset();
      _controller.forward();
    }
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
        // Clamp the animation value to ensure it's between 0.0 and 1.0
        final clampedValue = _animation.value.clamp(0.0, 1.0);

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color:
                widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedValue,
            child: Container(
              decoration: BoxDecoration(
                color: widget.progressColor ?? Theme.of(context).primaryColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated circular progress indicator
class AnimatedCircularProgress extends StatefulWidget {
  final double progress;
  final Duration duration;
  final Color? backgroundColor;
  final Color? progressColor;
  final double strokeWidth;
  final double size;
  final Curve curve;
  final Duration delay;

  const AnimatedCircularProgress({
    super.key,
    required this.progress,
    this.duration = const Duration(milliseconds: 1500),
    this.backgroundColor,
    this.progressColor,
    this.strokeWidth = 8.0,
    this.size = 100.0,
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedCircularProgress> createState() =>
      _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _controller.reset();
      _controller.forward();
    }
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
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              // Background circle
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      widget.backgroundColor ??
                      Theme.of(context).colorScheme.surface,
                ),
                child: CustomPaint(
                  painter: CircleProgressPainter(
                    progress: 1.0,
                    strokeWidth: widget.strokeWidth,
                    color:
                        widget.backgroundColor ??
                        Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              // Progress circle
              CustomPaint(
                painter: CircleProgressPainter(
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  color: widget.progressColor ?? Theme.of(context).primaryColor,
                ),
                child: SizedBox(width: widget.size, height: widget.size),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for circular progress
class CircleProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  CircleProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = -90 * (3.14159 / 180); // Start from top
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color;
  }
}

/// Animated calendar day
class AnimatedCalendarDay extends StatefulWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool hasData;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final Duration delay;

  const AnimatedCalendarDay({
    super.key,
    required this.day,
    this.isSelected = false,
    this.isToday = false,
    this.hasData = false,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedCalendarDay> createState() => _AnimatedCalendarDayState();
}

class _AnimatedCalendarDayState extends State<AnimatedCalendarDay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? Theme.of(context).primaryColor
                      : widget.isToday
                      // ignore: deprecated_member_use
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: widget.isToday
                      ? Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        widget.day.toString(),
                        style: TextStyle(
                          color: widget.isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: widget.isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (widget.hasData)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

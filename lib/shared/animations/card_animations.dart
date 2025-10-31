import 'package:flutter/material.dart';

/// Animated card with various entrance effects
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Duration delay;
  final AnimationType animationType;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const AnimatedCard({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.animationType = AnimationType.slideInUp,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Set up animation based on type
    switch (widget.animationType) {
      case AnimationType.fadeIn:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        break;
      case AnimationType.slideInUp:
        _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
        break;
      case AnimationType.slideInDown:
        _animation = Tween<double>(begin: -1.0, end: 0.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
        break;
      case AnimationType.slideInLeft:
        _animation = Tween<double>(begin: -1.0, end: 0.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
        break;
      case AnimationType.slideInRight:
        _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
        break;
      case AnimationType.scaleIn:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        );
        break;
      case AnimationType.bounceIn:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
        );
        break;
    }

    // Start animation after delay
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
      animation: _animation,
      builder: (context, child) {
        Widget animatedChild = widget.child;

        // Apply animation based on type
        switch (widget.animationType) {
          case AnimationType.fadeIn:
            animatedChild = Opacity(
              opacity: _animation.value,
              child: widget.child,
            );
            break;
          case AnimationType.slideInUp:
            animatedChild = Transform.translate(
              offset: Offset(0, _animation.value * 100),
              child: Opacity(
                opacity: 1 - _animation.value,
                child: widget.child,
              ),
            );
            break;
          case AnimationType.slideInDown:
            animatedChild = Transform.translate(
              offset: Offset(0, _animation.value * 100),
              child: Opacity(
                opacity: 1 - _animation.value.abs(),
                child: widget.child,
              ),
            );
            break;
          case AnimationType.slideInLeft:
            animatedChild = Transform.translate(
              offset: Offset(_animation.value * 100, 0),
              child: Opacity(
                opacity: 1 - _animation.value.abs(),
                child: widget.child,
              ),
            );
            break;
          case AnimationType.slideInRight:
            animatedChild = Transform.translate(
              offset: Offset(_animation.value * 100, 0),
              child: Opacity(
                opacity: 1 - _animation.value,
                child: widget.child,
              ),
            );
            break;
          case AnimationType.scaleIn:
            animatedChild = Transform.scale(
              scale: _animation.value,
              child: Opacity(
                opacity: _animation.value,
                child: widget.child,
              ),
            );
            break;
          case AnimationType.bounceIn:
            animatedChild = Transform.scale(
              scale: _animation.value,
              child: Opacity(
                opacity: _animation.value,
                child: widget.child,
              ),
            );
            break;
        }

        return Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: widget.borderRadius,
            boxShadow: widget.boxShadow,
          ),
          child: animatedChild,
        );
      },
    );
  }
}

/// Staggered animation for multiple cards
class StaggeredCardList extends StatefulWidget {
  final List<Widget> children;
  final Duration animationDuration;
  final Duration staggerDelay;
  final AnimationType animationType;
  final ScrollPhysics? physics;

  const StaggeredCardList({
    super.key,
    required this.children,
    this.animationDuration = const Duration(milliseconds: 600),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationType = AnimationType.slideInUp,
    this.physics,
  });

  @override
  State<StaggeredCardList> createState() => _StaggeredCardListState();
}

class _StaggeredCardListState extends State<StaggeredCardList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: widget.physics,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedCard(
          animationDuration: widget.animationDuration,
          delay: Duration(milliseconds: index * widget.staggerDelay.inMilliseconds),
          animationType: widget.animationType,
          child: widget.children[index],
        );
      },
    );
  }
}

/// Animation types for cards
enum AnimationType {
  fadeIn,
  slideInUp,
  slideInDown,
  slideInLeft,
  slideInRight,
  scaleIn,
  bounceIn,
}

/// Pulse animation for highlighting
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool repeat;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.repeat = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
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
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

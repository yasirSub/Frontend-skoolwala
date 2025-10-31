import 'package:flutter/material.dart';

/// Custom page transitions for smooth navigation
class PageTransitions {
  /// Slide transition from right to left
  static Widget slideFromRight(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          ),
      child: child,
    );
  }

  /// Slide transition from left to right
  static Widget slideFromLeft(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          ),
      child: child,
    );
  }

  /// Slide transition from bottom to top
  static Widget slideFromBottom(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );
  }

  /// Fade transition
  static Widget fadeTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: child,
    );
  }

  /// Scale transition
  static Widget scaleTransition(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
      child: child,
    );
  }

  /// Combined slide and fade transition
  static Widget slideAndFade(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    );
  }

  /// Hero-like transition with scale and fade
  static Widget heroTransition(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.elasticOut)),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    );
  }
}

/// Custom page route builder
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType transitionType;
  final Duration duration;

  CustomPageRoute({
    required this.child,
    this.transitionType = PageTransitionType.slideFromRight,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           switch (transitionType) {
             case PageTransitionType.slideFromRight:
               return PageTransitions.slideFromRight(child, animation);
             case PageTransitionType.slideFromLeft:
               return PageTransitions.slideFromLeft(child, animation);
             case PageTransitionType.slideFromBottom:
               return PageTransitions.slideFromBottom(child, animation);
             case PageTransitionType.fade:
               return PageTransitions.fadeTransition(child, animation);
             case PageTransitionType.scale:
               return PageTransitions.scaleTransition(child, animation);
             case PageTransitionType.slideAndFade:
               return PageTransitions.slideAndFade(child, animation);
             case PageTransitionType.hero:
               return PageTransitions.heroTransition(child, animation);
           }
         },
       );
}

/// Page transition types
enum PageTransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  fade,
  scale,
  slideAndFade,
  hero,
}

/// Extension for easy navigation with custom transitions
extension NavigatorExtension on NavigatorState {
  /// Navigate with custom transition
  Future<T?> pushWithTransition<T>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return push<T>(
      CustomPageRoute<T>(
        child: page,
        transitionType: transitionType,
        duration: duration,
      ),
    );
  }

  /// Replace with custom transition
  Future<T?> pushReplacementWithTransition<T>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return pushReplacement<T, dynamic>(
      CustomPageRoute<T>(
        child: page,
        transitionType: transitionType,
        duration: duration,
      ),
    );
  }
}

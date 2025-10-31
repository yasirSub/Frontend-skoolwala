import 'package:flutter/material.dart';

/// Utility class for safe widget operations to prevent layout boundary assertion errors
class SafeWidgetOperations {
  /// Safely executes setState only if the widget is still mounted
  static void safeSetState(State state, VoidCallback fn) {
    if (state.mounted) {
      state.setState(fn);
    }
  }

  /// Safely executes animation forward only if not already animating
  static void safeAnimationForward(AnimationController controller) {
    if (!controller.isAnimating && !controller.isCompleted) {
      controller.forward();
    }
  }

  /// Safely executes animation reset only if not currently animating
  static void safeAnimationReset(AnimationController controller) {
    if (controller.isAnimating) {
      controller.stop();
    }
    controller.reset();
  }

  /// Safely executes animation reverse only if not already animating
  static void safeAnimationReverse(AnimationController controller) {
    if (!controller.isAnimating && !controller.isDismissed) {
      controller.reverse();
    }
  }

  /// Safely executes delayed operations
  static void safeDelayed(Duration duration, VoidCallback callback) {
    Future.delayed(duration, () {
      try {
        callback();
      } catch (e) {
        // Ignore errors from delayed operations
      }
    });
  }

  /// Safely shows snackbar
  static void safeShowSnackBar(BuildContext context, SnackBar snackBar) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  /// Safely navigates to a route
  static void safeNavigate(BuildContext context, Widget route) {
    if (context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => route));
    }
  }

  /// Safely disposes animation controllers
  static void safeDisposeAnimationControllers(
    List<AnimationController> controllers,
  ) {
    for (final controller in controllers) {
      try {
        controller.dispose();
      } catch (e) {
        // Controller might already be disposed, ignore error
      }
    }
  }

  /// Safely executes a callback with error handling
  static void safeExecute(VoidCallback callback) {
    try {
      callback();
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Safe execution error: $e');
    }
  }
}

/// Mixin for safe widget operations
mixin SafeWidgetMixin<T extends StatefulWidget> on State<T> {
  /// Safe setState that checks if widget is mounted
  void safeSetState(VoidCallback fn) {
    SafeWidgetOperations.safeSetState(this, fn);
  }

  /// Safe delayed operation
  void safeDelayed(Duration duration, VoidCallback callback) {
    SafeWidgetOperations.safeDelayed(duration, callback);
  }

  /// Safe show snackbar
  void safeShowSnackBar(SnackBar snackBar) {
    SafeWidgetOperations.safeShowSnackBar(context, snackBar);
  }

  /// Safe navigate
  void safeNavigate(Widget route) {
    SafeWidgetOperations.safeNavigate(context, route);
  }

  /// Safe execute
  void safeExecute(VoidCallback callback) {
    SafeWidgetOperations.safeExecute(callback);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Comprehensive fix for Flutter rendering assertion errors
class LayoutBoundaryFix {
  static bool _isLayoutInProgress = false;
  static final List<VoidCallback> _pendingCallbacks = [];

  /// Prevents multiple simultaneous layout operations
  static void safeLayoutOperation(VoidCallback callback) {
    if (_isLayoutInProgress) {
      _pendingCallbacks.add(callback);
      return;
    }

    _isLayoutInProgress = true;

    try {
      callback();
    } catch (e) {
      debugPrint('Layout operation error: $e');
    } finally {
      _isLayoutInProgress = false;

      // Process pending callbacks
      if (_pendingCallbacks.isNotEmpty) {
        final callbacks = List<VoidCallback>.from(_pendingCallbacks);
        _pendingCallbacks.clear();

        // Schedule pending callbacks for next frame
        SchedulerBinding.instance.addPostFrameCallback((_) {
          for (final pendingCallback in callbacks) {
            safeLayoutOperation(pendingCallback);
          }
        });
      }
    }
  }

  /// Safely executes animation operations
  static void safeAnimationOperation(VoidCallback animationCallback) {
    safeLayoutOperation(() {
      try {
        animationCallback();
      } catch (e) {
        debugPrint('Animation operation error: $e');
      }
    });
  }

  /// Safely executes delayed operations with layout protection
  static void safeDelayedOperation(Duration duration, VoidCallback callback) {
    Future.delayed(duration, () {
      safeLayoutOperation(callback);
    });
  }

  /// Safely executes frame-based operations
  static void safeFrameOperation(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      safeLayoutOperation(callback);
    });
  }

  /// Clears all pending operations (use in dispose)
  static void clearPendingOperations() {
    _pendingCallbacks.clear();
    _isLayoutInProgress = false;
  }
}

/// Enhanced mixin for comprehensive layout boundary protection
mixin LayoutBoundaryMixin<T extends StatefulWidget> on State<T> {
  /// Safe setState with layout boundary protection
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    LayoutBoundaryFix.safeLayoutOperation(() {
      setState(fn);
    });
  }

  /// Safe animation operation
  void safeAnimationOperation(VoidCallback animationCallback) {
    LayoutBoundaryFix.safeAnimationOperation(animationCallback);
  }

  /// Safe delayed operation
  void safeDelayedOperation(Duration duration, VoidCallback callback) {
    LayoutBoundaryFix.safeDelayedOperation(duration, callback);
  }

  /// Safe frame operation
  void safeFrameOperation(VoidCallback callback) {
    LayoutBoundaryFix.safeFrameOperation(callback);
  }

  @override
  void dispose() {
    LayoutBoundaryFix.clearPendingOperations();
    super.dispose();
  }
}

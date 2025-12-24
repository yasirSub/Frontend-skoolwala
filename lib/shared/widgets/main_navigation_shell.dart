import 'package:flutter/material.dart';
import 'package:skoolwala/shared/widgets/animated_bottom_nav_bar.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';

/// Global navigation shell that persists the bottom navigation bar across all screens.
///
/// Usage: Wrap your page content with this shell to show the persistent bottom bar.
/// The bar will auto-collapse to a mini FAB on non-home screens and expand on tap.
class MainNavigationShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final bool showBottomBar;
  final VoidCallback? onHomeTap;
  final VoidCallback? onScheduleTap;
  final VoidCallback? onProfileTap;

  const MainNavigationShell({
    super.key,
    required this.child,
    this.currentIndex = 0,
    this.showBottomBar = true,
    this.onHomeTap,
    this.onScheduleTap,
    this.onProfileTap,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _currentIndex = widget.currentIndex;
    }
  }

  void _handleNavigation(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Get the label of the tapped item to determine navigation
    final userRole = SessionManager.instance.currentTeacher?.role;
    final navItems = BottomNavConfigs.getItemsForRole(userRole);

    if (index >= navItems.length) return;

    final itemLabel = navItems[index].label.toLowerCase().trim();

    if (itemLabel.contains('home')) {
      widget.onHomeTap?.call();
    } else if (itemLabel.contains('schedule')) {
      widget.onScheduleTap?.call();
    } else if (itemLabel.contains('profile')) {
      widget.onProfileTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = SessionManager.instance.currentTeacher?.role;
    final navItems = BottomNavConfigs.getItemsForRole(userRole);

    return Stack(
      children: [
        // Main content
        widget.child,

        // Persistent bottom navigation bar overlay
        if (widget.showBottomBar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBottomNavBar(
              currentIndex: _currentIndex,
              items: navItems,
              onTap: _handleNavigation,
              autoNavigation: false,
              collapsible: true,
              notificationCount: 0,
            ),
          ),
      ],
    );
  }
}

/// A mixin to add persistent bottom navigation to any screen.
///
/// Usage:
/// ```dart
/// class MyScreen extends StatefulWidget {
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen> with PersistentBottomNavMixin {
///   @override
///   int get navIndex => 1; // Current tab index
///
///   @override
///   Widget buildContent(BuildContext context) {
///     return YourActualContent();
///   }
/// }
/// ```
mixin PersistentBottomNavMixin<T extends StatefulWidget> on State<T> {
  /// Override this to set the current navigation index for this screen
  int get navIndex => 0;

  /// Override this to hide the bottom bar on specific screens
  bool get showBottomNav => true;

  /// Build the actual screen content (without scaffold)
  Widget buildContent(BuildContext context);

  /// Navigate to home/dashboard
  void navigateToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Navigate to schedule
  void navigateToSchedule() {
    // Override in subclass if needed
  }

  /// Navigate to profile
  void navigateToProfile() {
    // Override in subclass if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.dashboardPrimary,
              AppTheme.dashboardPrimary.withBlue(100).withRed(40),
            ],
          ),
        ),
        child: MainNavigationShell(
          currentIndex: navIndex,
          showBottomBar: showBottomNav,
          onHomeTap: navigateToHome,
          onScheduleTap: navigateToSchedule,
          onProfileTap: navigateToProfile,
          child: buildContent(context),
        ),
      ),
    );
  }
}

/// Standalone bottom nav bar that can be added to any screen.
///
/// This is useful when you want to add the bottom bar to screens
/// that don't use the mixin pattern.
class StandaloneBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final bool collapsible;

  const StandaloneBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.collapsible = true,
  });

  @override
  Widget build(BuildContext context) {
    final userRole = SessionManager.instance.currentTeacher?.role;
    final navItems = BottomNavConfigs.getItemsForRole(userRole);

    return AnimatedBottomNavBar(
      currentIndex: currentIndex,
      items: navItems,
      onTap: onTap,
      autoNavigation: onTap == null,
      collapsible: collapsible,
      notificationCount: 0,
    );
  }
}

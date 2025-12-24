import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import '../services/bottom_nav_handler.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';

/// Animated Bottom Navigation Bar Widget
/// Features:
/// - Floating glass morphism design
/// - Collapsible to mini FAB on non-home screens
/// - Auto-collapse after 4 seconds
/// - Swipe left/right to navigate tabs
/// - Haptic feedback on navigation
/// - Long press to go home
/// - Notification badge support
class AnimatedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final List<BottomNavBarItem> items;
  final bool autoNavigation;
  final bool collapsible; // Enable collapse on non-home screens
  final int notificationCount; // Badge count for collapsed FAB

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.items = const [],
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.autoNavigation = true,
    this.collapsible = true,
    this.notificationCount = 0,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _shimmerController;
  late AnimationController _collapseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _collapseAnimation;

  bool _isLoaded = false;
  bool _isCollapsed = false;
  Timer? _autoCollapseTimer;

  @override
  void initState() {
    super.initState();

    // Shimmer loading animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // Collapse animation
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _collapseAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeOutCubic,
    );

    // Start entrance animation after a brief shimmer
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _entranceController.forward();
        setState(() => _isLoaded = true);
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-collapse when navigating away from home (index 0)
    if (widget.collapsible &&
        widget.currentIndex != 0 &&
        oldWidget.currentIndex == 0) {
      _startAutoCollapseTimer();
    }
    // Expand when returning to home
    if (widget.currentIndex == 0 && _isCollapsed) {
      _expand();
    }
  }

  void _startAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && widget.currentIndex != 0) {
        _collapse();
      }
    });
  }

  void _collapse() {
    if (!_isCollapsed) {
      setState(() => _isCollapsed = true);
      _collapseController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _expand() {
    if (_isCollapsed) {
      setState(() => _isCollapsed = false);
      _collapseController.reverse();
      HapticFeedback.mediumImpact();
      // Restart auto-collapse timer if not on home
      if (widget.currentIndex != 0) {
        _startAutoCollapseTimer();
      }
    }
  }

  void _toggleCollapse() {
    if (_isCollapsed) {
      _expand();
    } else {
      _collapse();
    }
  }

  void _navigateToIndex(int index) {
    if (index < 0 || index >= widget.items.length) return;
    HapticFeedback.selectionClick();

    if (widget.autoNavigation && widget.onTap == null) {
      BottomNavHandler.handleNavigation(context, index, widget.currentIndex);
    } else {
      widget.onTap?.call(index);
    }
  }

  void _goHome() {
    HapticFeedback.heavyImpact();
    _navigateToIndex(0);
    _expand();
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() > 300) {
      // Swipe detected
      if (velocity > 0) {
        // Swipe right - go to previous tab
        _navigateToIndex(widget.currentIndex - 1);
      } else {
        // Swipe left - go to next tab
        _navigateToIndex(widget.currentIndex + 1);
      }
    }
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _entranceController.dispose();
    _shimmerController.dispose();
    _collapseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppTheme.dashboardPrimary;
    final activeColorFinal = widget.activeColor ?? AppTheme.accentCyan;
    final inactiveColorFinal =
        widget.inactiveColor ?? Colors.white.withOpacity(0.6);

    // Show shimmer loading skeleton before content loads
    if (!_isLoaded) {
      return _buildShimmerSkeleton(bgColor);
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _collapseAnimation,
          builder: (context, child) {
            // Show collapsed mini FAB when fully collapsed
            if (_isCollapsed && _collapseAnimation.value > 0.5) {
              return _buildCollapsedFAB(bgColor, activeColorFinal);
            }

            // Show full expanded bar with swipe gestures
            return _buildExpandedBar(
              bgColor,
              activeColorFinal,
              inactiveColorFinal,
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerSkeleton(Color bgColor) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: bgColor.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Shimmer effect
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.4),
                                  Colors.white.withOpacity(0.0),
                                ],
                                stops: [
                                  (_shimmerAnimation.value - 0.3).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  _shimmerAnimation.value.clamp(0.0, 1.0),
                                  (_shimmerAnimation.value + 0.3).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                ],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcATop,
                            child: Container(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ),
                      // Placeholder icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(
                          widget.items.isEmpty ? 3 : widget.items.length,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedFAB(Color bgColor, Color activeColor) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: GestureDetector(
            onTap: _expand,
            onLongPress: _goHome,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: bgColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Current tab icon
                        Icon(
                          widget.items[widget.currentIndex].icon,
                          color: Colors.white,
                          size: 24,
                        ),
                        // Notification badge
                        if (widget.notificationCount > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                widget.notificationCount > 9
                                    ? '9+'
                                    : '${widget.notificationCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // Expand hint
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 16,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedBar(
    Color bgColor,
    Color activeColor,
    Color inactiveColor,
  ) {
    return SafeArea(
      top: false,
      child: GestureDetector(
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 65, // Fixed height for proper positioning
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.white.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: bgColor.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Swipe hint indicator at bottom
                    Positioned(
                      bottom: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: 12,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          Container(
                            width: 30,
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 12,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),

                    // Floating white selection indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: IgnorePointer(
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          alignment: widget.items.length > 1
                              ? Alignment(
                                  (widget.currentIndex /
                                              (widget.items.length - 1)) *
                                          2 -
                                      1,
                                  0,
                                )
                              : Alignment.center,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                widget.items[widget.currentIndex].icon,
                                color: activeColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Actual navigation bar
                    AnimatedBottomNavigationBar(
                      icons: widget.items.map((item) => item.icon).toList(),
                      activeIndex: widget.currentIndex,
                      gapLocation: GapLocation.none,
                      notchSmoothness: NotchSmoothness.softEdge,
                      onTap: (index) {
                        HapticFeedback.selectionClick();
                        // Cancel auto-collapse timer on interaction
                        _autoCollapseTimer?.cancel();
                        if (widget.collapsible && index != 0) {
                          _startAutoCollapseTimer();
                        }
                        if (widget.autoNavigation && widget.onTap == null) {
                          BottomNavHandler.handleNavigation(
                            context,
                            index,
                            widget.currentIndex,
                          );
                        } else {
                          widget.onTap?.call(index);
                        }
                      },
                      backgroundColor: Colors.transparent,
                      activeColor: Colors.transparent,
                      inactiveColor: inactiveColor,
                      leftCornerRadius: 28,
                      rightCornerRadius: 28,
                      splashRadius: 50,
                      splashSpeedInMilliseconds: 300,
                      iconSize: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Model class for bottom navigation items
class BottomNavBarItem {
  final IconData icon;
  final String label;
  final String? tooltip;

  const BottomNavBarItem({
    required this.icon,
    required this.label,
    this.tooltip,
  });
}

/// Predefined bottom navigation configurations
class BottomNavConfigs {
  // Default dashboard navigation items
  static List<BottomNavBarItem> get dashboardItems => const [
    BottomNavBarItem(
      icon: Icons.home_rounded,
      label: 'Home',
      tooltip: 'Dashboard',
    ),
    BottomNavBarItem(
      icon: Icons.class_rounded,
      label: 'Classes',
      tooltip: 'View Classes',
    ),
    BottomNavBarItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      tooltip: 'My Profile',
    ),
  ];

  // Teacher-focused navigation items
  static List<BottomNavBarItem> get teacherItems => const [
    BottomNavBarItem(
      icon: Icons.home_rounded,
      label: 'Home',
      tooltip: 'Dashboard',
    ),
    BottomNavBarItem(
      icon: Icons.schedule_rounded,
      label: 'Schedule',
      tooltip: 'My Classes',
    ),
    BottomNavBarItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      tooltip: 'My Profile',
    ),
  ];

  // Student-focused navigation items
  static List<BottomNavBarItem> get studentItems => const [
    BottomNavBarItem(icon: Icons.home_rounded, label: 'Home'),
    BottomNavBarItem(icon: Icons.assignment_rounded, label: 'Assignments'),
    BottomNavBarItem(icon: Icons.event_note_rounded, label: 'Schedule'),
    BottomNavBarItem(icon: Icons.grade_rounded, label: 'Grades'),
    BottomNavBarItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  // Admin-focused navigation items
  static List<BottomNavBarItem> get adminItems => const [
    BottomNavBarItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    BottomNavBarItem(icon: Icons.people_rounded, label: 'Users'),
    BottomNavBarItem(icon: Icons.school_rounded, label: 'Schools'),
    BottomNavBarItem(icon: Icons.settings_rounded, label: 'Settings'),
    BottomNavBarItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  /// Get navigation items based on user role
  static List<BottomNavBarItem> getItemsForRole(String? role) {
    print('🔍 BottomNavConfigs.getItemsForRole called with role: $role');

    // Check if user is a teacher
    if (role != null &&
        (role.toLowerCase().contains('teacher') ||
            role.toLowerCase().contains('instructor'))) {
      print('✅ Returning teacher items');
      return teacherItems;
    }

    // For non-teacher roles (like admin/role 2), return dashboard items but without Classes
    if (role != null && role != '3') {
      print('⚠️ Role $role is not 3, removing Classes item');
      final filtered = dashboardItems
          .where((item) => item.label != 'Classes')
          .toList();
      print('📊 Filtered items count: ${filtered.length}');
      for (var item in filtered) {
        print('  - ${item.label}');
      }
      return filtered;
    }

    // Default to dashboard items (for role 3 or when role is null)
    print('✅ Returning full dashboard items (role is 3 or null)');
    return dashboardItems;
  }
}

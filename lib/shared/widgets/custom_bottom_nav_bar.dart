import 'package:flutter/material.dart';
import '../services/bottom_nav_handler.dart';

/// Custom Bottom Navigation Bar Widget
/// Reusable bottom navigation bar with modern design
///
/// Usage:
/// - If autoNavigation is true: Just pass currentIndex, navigation is handled automatically
/// - If autoNavigation is false: Pass custom onTap callback for custom behavior
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)?
  onTap; // Optional - if not provided, uses auto navigation
  final Color? primaryColor;
  final Color? accentColor;
  final List<BottomNavItem> items;
  final bool showLabels;
  final double? height;
  final bool autoNavigation; // Enable automatic navigation handling

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    required this.items,
    this.primaryColor,
    this.accentColor,
    this.showLabels = true,
    this.height,
    this.autoNavigation = true, // Default to auto navigation
  });

  @override
  Widget build(BuildContext context) {
    // Adapt colors based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultPrimaryColor =
        primaryColor ??
        (isDark ? const Color(0xFF2A2A2A) : const Color(0xFF1A1F3E));
    final defaultAccentColor =
        accentColor ??
        (isDark ? const Color(0xFF90E0EF) : const Color(0xFF90E0EF));

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [defaultPrimaryColor, defaultPrimaryColor.withOpacity(0.95)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : defaultPrimaryColor).withOpacity(
              isDark ? 0.6 : 0.3,
            ),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (autoNavigation && onTap == null) {
              // Use centralized navigation handler with context from build method
              BottomNavHandler.handleNavigation(context, index, currentIndex);
            } else {
              // Use custom callback if provided
              onTap?.call(index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: defaultAccentColor,
          unselectedItemColor: (isDark ? Colors.white70 : Colors.white)
              .withOpacity(0.5),
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
            color: defaultAccentColor,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            letterSpacing: 0.3,
            color: (isDark ? Colors.white70 : Colors.white).withOpacity(0.5),
          ),
          selectedFontSize: 11,
          unselectedFontSize: 10,
          showSelectedLabels: showLabels,
          showUnselectedLabels: showLabels,
          items: items.map((item) {
            final index = items.indexOf(item);
            final isSelected = currentIndex == index;

            return BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? defaultAccentColor.withOpacity(isDark ? 0.25 : 0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: isSelected ? 26 : 24,
                  color: isSelected
                      ? defaultAccentColor
                      : (isDark ? Colors.white70 : Colors.white).withOpacity(
                          0.6,
                        ),
                ),
              ),
              label: item.label,
              tooltip: item.tooltip ?? item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Model class for bottom navigation items
class BottomNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? tooltip;

  const BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.tooltip,
  });
}

/// Predefined bottom navigation configurations
class BottomNavConfigs {
  // Default dashboard navigation items
  static List<BottomNavItem> get dashboardItems => const [
    BottomNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
      tooltip: 'Dashboard',
    ),
    BottomNavItem(
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check_rounded,
      label: 'Attendance',
      tooltip: 'Check In/Out',
    ),
    BottomNavItem(
      icon: Icons.class_outlined,
      selectedIcon: Icons.class_rounded,
      label: 'Classes',
      tooltip: 'View Classes',
    ),
    BottomNavItem(
      icon: Icons.school_outlined,
      selectedIcon: Icons.school_rounded,
      label: 'Students',
      tooltip: 'View Students',
    ),
    BottomNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
      tooltip: 'My Profile',
    ),
  ];

  // Student-focused navigation items
  static List<BottomNavItem> get studentItems => const [
    BottomNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    BottomNavItem(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      label: 'Assignments',
    ),
    BottomNavItem(
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note_rounded,
      label: 'Schedule',
    ),
    BottomNavItem(
      icon: Icons.grade_outlined,
      selectedIcon: Icons.grade_rounded,
      label: 'Grades',
    ),
    BottomNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  // Admin-focused navigation items
  static List<BottomNavItem> get adminItems => const [
    BottomNavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    BottomNavItem(
      icon: Icons.people_outlined,
      selectedIcon: Icons.people_rounded,
      label: 'Users',
    ),
    BottomNavItem(
      icon: Icons.school_outlined,
      selectedIcon: Icons.school_rounded,
      label: 'Schools',
    ),
    BottomNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
    BottomNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];
}

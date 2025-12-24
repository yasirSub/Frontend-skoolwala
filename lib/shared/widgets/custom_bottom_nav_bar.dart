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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use app theme colors by default; allow screens to override with `primaryColor`/`accentColor`.
    final defaultPrimaryColor = primaryColor ?? scheme.primaryContainer;
    final defaultAccentColor = accentColor ?? scheme.secondary;

    // Compute a readable foreground for icons/labels when the background is overridden.
    final bgBrightness = ThemeData.estimateBrightnessForColor(
      defaultPrimaryColor,
    );
    final onBackground = bgBrightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    final selectedLabelStyle =
        (theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: defaultAccentColor,
        );
    final unselectedLabelStyle =
        (theme.textTheme.labelSmall ?? const TextStyle(fontSize: 10)).copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: onBackground.withOpacity(0.60),
        );

    return SafeArea(
      top: false,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              defaultPrimaryColor,
              Color.lerp(defaultPrimaryColor, scheme.primary, 0.12) ??
                  defaultPrimaryColor,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
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
                BottomNavHandler.handleNavigation(context, index, currentIndex);
              } else {
                onTap?.call(index);
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: defaultAccentColor,
            unselectedItemColor: onBackground.withOpacity(0.55),
            selectedLabelStyle: selectedLabelStyle,
            unselectedLabelStyle: unselectedLabelStyle,
            selectedFontSize: selectedLabelStyle.fontSize ?? 11,
            unselectedFontSize: unselectedLabelStyle.fontSize ?? 10,
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
                        ? defaultAccentColor.withOpacity(isDark ? 0.22 : 0.18)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    size: isSelected ? 26 : 24,
                    color: isSelected
                        ? defaultAccentColor
                        : onBackground.withOpacity(0.70),
                  ),
                ),
                label: item.label,
                tooltip: item.tooltip ?? item.label,
              );
            }).toList(),
          ),
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
      icon: Icons.class_outlined,
      selectedIcon: Icons.class_rounded,
      label: 'Classes',
      tooltip: 'View Classes',
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

  // Teacher-focused navigation items
  static List<BottomNavItem> get teacherItems => const [
    BottomNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
      tooltip: 'Dashboard',
    ),
    BottomNavItem(
      icon: Icons.schedule_rounded,
      selectedIcon: Icons.schedule,
      label: 'Schedule',
      tooltip: 'My Classes',
    ),
    BottomNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
      tooltip: 'My Profile',
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

  /// Get navigation items based on user role
  static List<BottomNavItem> getItemsForRole(String? role) {
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
      // Remove Classes item for non-teacher roles
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

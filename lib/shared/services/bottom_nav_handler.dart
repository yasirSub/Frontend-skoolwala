import 'package:flutter/material.dart';
import 'package:skoolwala/features/dashboard/screens/dashboard_screen.dart';
import 'package:skoolwala/features/teacher_attendance/simple_teacher_attendance.dart';
import 'package:skoolwala/features/teacher/screens/my_classes_screen.dart';
import 'package:skoolwala/features/teacher/screens/teacher_schedule_screen.dart';
import 'package:skoolwala/features/profile/screens/profile_screen.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/widgets/custom_bottom_nav_bar.dart';

/// Centralized Bottom Navigation Handler
/// Handles all navigation logic for bottom navigation bar
/// Screens just need to pass their current index - navigation is handled here
class BottomNavHandler {
  /// Handle bottom navigation tap
  /// Returns true if navigation was handled, false if no action needed (same tab)
  static bool handleNavigation(
    BuildContext context,
    int newIndex,
    int currentIndex,
  ) {
    // If tapping on the same tab, do nothing
    if (newIndex == currentIndex) {
      return false;
    }

    // Get the user's role to determine which nav items are available
    final userRole = SessionManager.instance.currentTeacher?.role;
    final navItems = BottomNavConfigs.getItemsForRole(userRole);

    // Make sure the newIndex is valid
    if (newIndex >= navItems.length) {
      return false;
    }

    // Get the label of the tapped item to determine navigation
    final itemLabel = navItems[newIndex].label.toLowerCase().trim();

    print(
      '🔍 BottomNavHandler: Tab $newIndex tapped - Label: "${navItems[newIndex].label}" (lowercase: "$itemLabel")',
    );

    // Navigate based on selected tab label (more flexible than hardcoded indices)
    if (itemLabel.contains('home') || itemLabel == 'home') {
      _navigateToDashboard(context);
    } else if (itemLabel.contains('attendance') || itemLabel == 'attendance') {
      _navigateToAttendance(context);
    } else if (itemLabel.contains('class') || itemLabel == 'classes') {
      _navigateToClasses(context);
    } else if (itemLabel.contains('schedule') || itemLabel == 'schedule') {
      _navigateToSchedule(context);
    } else if (itemLabel.contains('student') || itemLabel == 'students') {
      _navigateToStudents(context);
    } else if (itemLabel.contains('profile') || itemLabel == 'profile') {
      _navigateToProfile(context);
    } else {
      print('🔍 BottomNavHandler: No matching label for: "$itemLabel"');
      return false;
    }

    return true;
  }

  /// Navigate to Dashboard
  static void _navigateToDashboard(BuildContext context) {
    // Pop until we reach dashboard or first route
    Navigator.of(context).popUntil((route) {
      // Check if current route is dashboard by checking if it's first or if it's dashboard
      if (route.isFirst) return true;
      // If route has a settings name that indicates it's dashboard
      if (route.settings.name?.contains('dashboard') == true) return true;
      return false;
    });

    // If dashboard is not in stack, navigate to it
    if (Navigator.of(context).canPop()) {
      // We already popped to first, so we're at dashboard
      return;
    }

    // If no dashboard found, create one using session credentials
    final sessionManager = SessionManager.instance;
    final username = sessionManager.currentUsername ?? '';
    final password = sessionManager.currentPassword ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              DashboardScreen(username: username, password: password),
        ),
      );
    } else {
      // Show error if no session available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Navigate to Attendance
  static void _navigateToAttendance(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SimpleTeacherAttendance()));
  }

  /// Navigate to Classes (Teacher Schedule - Today's Schedule)
  static void _navigateToClasses(BuildContext context) {
    // Navigate to Teacher Schedule screen (Today's Schedule)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TeacherScheduleScreen(),
        settings: const RouteSettings(name: 'schedule'),
      ),
    );
  }

  /// Navigate to Schedule (Teacher's class schedule)
  static void _navigateToSchedule(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TeacherScheduleScreen(),
        settings: const RouteSettings(name: 'schedule'),
      ),
    );
  }

  /// Navigate to Students
  static void _navigateToStudents(BuildContext context) {
    // Navigate to My Classes screen first, where user can select a class
    // Then they can view students for that class
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MyClassesScreen(),
        settings: const RouteSettings(name: 'my_classes'),
      ),
    );
  }

  /// Navigate to Profile
  static void _navigateToProfile(BuildContext context) {
    final teacher = SessionManager.instance.currentTeacher;
    if (teacher != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(teacher: teacher),
          settings: const RouteSettings(name: 'profile'),
        ),
      );
    } else {
      // Show error if no teacher in session
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to view profile'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:skoolwala/shared/animations/animations.dart';
import 'package:skoolwala/features/auth/screens/login_screen.dart';
import 'package:skoolwala/features/school/screens/school_selection_screen.dart';
import 'package:skoolwala/features/dashboard/screens/dashboard_screen.dart';
import 'package:skoolwala/features/attendance/screens/attendance_scan_screen.dart';
import 'package:skoolwala/features/attendance/screens/face_verification_screen.dart';
import 'package:skoolwala/features/attendance/screens/attendance_history_screen.dart';
import 'package:skoolwala/features/profile/screens/profile_screen.dart';
import 'package:skoolwala/features/statistics/screens/statistics_screen.dart';
import 'package:skoolwala/features/attendance/screens/teacher_self_attendance_screen.dart';
import 'package:skoolwala/features/teacher_attendance/teacher_statistics_screen.dart';
import 'package:skoolwala/features/profile/models/teacher_profile.dart';
import 'package:skoolwala/shared/models/teacher.dart';

/// App route names
class AppRoutes {
  // Auth routes
  static const String schoolSelection = '/';
  static const String login = '/login';

  // Dashboard routes
  static const String dashboard = '/dashboard';

  // Attendance routes
  static const String attendanceScan = '/attendance/scan';
  static const String faceVerification = '/attendance/face-verification';
  static const String attendanceHistory = '/attendance/history';

  // Profile routes
  static const String profile = '/profile';

  // Statistics routes
  static const String statistics = '/statistics';
  static const String teacherStatistics = '/teacher-statistics';
  // Removed: f2fHome and faceAnalyzerTest

  // Attendance routes
  static const String teacherSelfAttendance = '/teacher-self-attendance';

  /// Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case schoolSelection:
        return CustomPageRoute(
          child: const SchoolSelectionScreen(),
          transitionType: PageTransitionType.fade,
        );

      case login:
        final args = settings.arguments as Map<String, dynamic>?;
        return CustomPageRoute(
          child: LoginScreen(
            schoolName: args?['schoolName'] ?? 'SkoolWala',
            branchId: args?['branchId'], // Pass branchId if provided
            mainLogo: args?['mainLogo'],
          ),
          transitionType: PageTransitionType.slideFromRight,
        );

      case dashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        return CustomPageRoute(
          child: DashboardScreen(
            username: args?['username'] ?? '',
            password: args?['password'] ?? '',
          ),
          transitionType: PageTransitionType.slideFromBottom,
        );

      case attendanceScan:
        return CustomPageRoute(
          child: const AttendanceScanScreen(),
          transitionType: PageTransitionType.slideFromRight,
        );

      case faceVerification:
        return CustomPageRoute(
          child: const FaceVerificationScreen(),
          transitionType: PageTransitionType.scale,
        );

      case attendanceHistory:
        final args = settings.arguments as Map<String, dynamic>?;
        return CustomPageRoute(
          child: AttendanceHistoryScreen(
            presentDays: args?['presentDays'] ?? 0,
            absentDays: args?['absentDays'] ?? 0,
            username: args?['username'] ?? '',
            password: args?['password'] ?? '',
          ),
          transitionType: PageTransitionType.slideFromLeft,
        );

      case profile:
        final args = settings.arguments as Map<String, dynamic>?;
        return CustomPageRoute(
          child: ProfileScreen(
            teacher: args?['teacher'] as Teacher,
            schoolName: args?['schoolName'] as String?,
            teacherProfile: args?['teacherProfile'] as TeacherProfile?,
          ),
          transitionType: PageTransitionType.slideFromRight,
        );

      case statistics:
        final args = settings.arguments as Map<String, dynamic>?;
        return CustomPageRoute(
          child: StatisticsScreen(
            username: args?['username'] ?? '',
            password: args?['password'] ?? '',
          ),
          transitionType: PageTransitionType.slideAndFade,
        );

      case teacherStatistics:
        final args = settings.arguments as Map<String, dynamic>?;
        return CustomPageRoute(
          child: TeacherStatisticsScreen(staffId: args?['staffId'] ?? ''),
          transitionType: PageTransitionType.slideAndFade,
        );

      case teacherSelfAttendance:
        return CustomPageRoute(
          child: const TeacherSelfAttendanceScreen(),
          transitionType: PageTransitionType.slideFromBottom,
        );

      // Removed: F2F and Face Analyzer routes

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  /// Navigate to school selection
  static Future<dynamic> toSchoolSelection(BuildContext context) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      schoolSelection,
      (route) => false,
    );
  }

  /// Navigate to login
  static Future<dynamic> toLogin(
    BuildContext context, {
    required String schoolName,
  }) {
    return Navigator.pushNamed(
      context,
      login,
      arguments: {'schoolName': schoolName},
    );
  }

  /// Navigate to dashboard
  static Future<dynamic> toDashboard(
    BuildContext context, {
    required String username,
    required String password,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      dashboard,
      arguments: {'username': username, 'password': password},
    );
  }

  /// Navigate to attendance scan
  static Future<dynamic> toAttendanceScan(BuildContext context) {
    return Navigator.pushNamed(context, attendanceScan);
  }

  /// Navigate to face verification
  static Future<dynamic> toFaceVerification(BuildContext context) {
    return Navigator.pushNamed(context, faceVerification);
  }

  /// Navigate to attendance history
  static Future<dynamic> toAttendanceHistory(
    BuildContext context, {
    required int presentDays,
    required int absentDays,
    required String username,
    required String password,
  }) {
    return Navigator.pushNamed(
      context,
      attendanceHistory,
      arguments: {
        'presentDays': presentDays,
        'absentDays': absentDays,
        'username': username,
        'password': password,
      },
    );
  }

  /// Navigate to profile
  static Future<dynamic> toProfile(
    BuildContext context, {
    required Teacher teacher,
    String? schoolName,
    TeacherProfile? teacherProfile,
  }) {
    return Navigator.pushNamed(
      context,
      profile,
      arguments: {
        'teacher': teacher,
        'schoolName': schoolName,
        'teacherProfile': teacherProfile,
      },
    );
  }

  /// Navigate to statistics
  static Future<dynamic> toStatistics(
    BuildContext context, {
    required String username,
    required String password,
  }) {
    return Navigator.pushNamed(
      context,
      statistics,
      arguments: {'username': username, 'password': password},
    );
  }

  /// Navigate to teacher statistics
  static Future<dynamic> toTeacherStatistics(
    BuildContext context, {
    required String staffId,
    required String baseUrl,
  }) {
    return Navigator.pushNamed(
      context,
      teacherStatistics,
      arguments: {'staffId': staffId, 'baseUrl': baseUrl},
    );
  }

  /// Navigate to teacher self-attendance
  static Future<dynamic> toTeacherSelfAttendance(BuildContext context) {
    return Navigator.pushNamed(context, teacherSelfAttendance);
  }
}

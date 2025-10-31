import 'package:flutter/foundation.dart';

import '../../../shared/models/teacher.dart';
import '../../../shared/models/school.dart';
import '../../../shared/services/session_manager.dart';
import '../../auth/services/teacher_service.dart';
import '../../school/services/school_service.dart';
import '../../school/services/school_data_service.dart';
import '../../attendance/services/attendance_service.dart';
import '../../profile/services/teacher_profile_service.dart';
import '../../profile/models/teacher_profile.dart';

class DashboardData {
  final Teacher teacher;
  final School? school;
  final int presentDays;
  final int absentDays;
  final int totalStudents;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> sections;
  final TeacherProfile? teacherProfile;

  const DashboardData({
    required this.teacher,
    this.school,
    required this.presentDays,
    required this.absentDays,
    required this.totalStudents,
    this.classes = const [],
    this.sections = const [],
    this.teacherProfile,
  });
}

class DashboardService {
  static const bool _debugLogs = false; // disable verbose dashboard logs
  static Future<DashboardData> fetchDashboardData({
    required String username,
    required String password,
  }) async {
    if (_debugLogs) {
      print('🔍 DashboardService Debug - Starting fetchDashboardData');
      print('🔍 DashboardService Debug - Username: $username');
      print('🔍 DashboardService Debug - Session Manager logged in: ${SessionManager.instance.isLoggedIn}');
    }

    // Fetch teacher data first (login)
    final teacher = await TeacherService.teacherLogin(
      username: username,
      password: password,
    );
    if (_debugLogs) {
      print('🔍 DashboardService Debug - Teacher login successful: ${teacher.name}');
    }

    // Fetch other data in parallel where possible
    School? school;
    int presentDays = 0;
    int absentDays = 0;
    int totalStudents = 0;
    List<Map<String, dynamic>> classes = [];
    List<Map<String, dynamic>> sections = [];

    // Try to fetch school data
    try {
      final schoolService = SchoolService();
      final schools = await schoolService.fetchSchools();
      if (schools.isNotEmpty) {
        school = schools.first; // Use the first school
      }
    } catch (e) {
      // Error fetching school data
    }

    // Fetch attendance counts
    try {
      if (_debugLogs) print('🔍 DashboardService Debug - Fetching present days...');
      final presentResponse =
          await AttendanceService.getTeacherPresentDaysCount();
      if (_debugLogs) print('🔍 DashboardService Debug - Present response: $presentResponse');
      if (presentResponse['status'] == 'success' &&
          presentResponse['data'] != null) {
        presentDays = presentResponse['data']['present_days_count'] ?? 0;
        if (_debugLogs) print('🔍 DashboardService Debug - Present days: $presentDays');
      }
    } catch (e) {
      if (_debugLogs) print('🔍 DashboardService Debug - Error fetching present days: $e');
      debugPrint('Error fetching present days: $e');
    }

    try {
      if (_debugLogs) print('🔍 DashboardService Debug - Fetching absent days...');
      final absentResponse =
          await AttendanceService.getTeacherAbsentDaysCount();
      if (_debugLogs) print('🔍 DashboardService Debug - Absent response: $absentResponse');
      if (absentResponse['status'] == 'success' &&
          absentResponse['data'] != null) {
        absentDays = absentResponse['data']['absent_days_count'] ?? 0;
        if (_debugLogs) print('🔍 DashboardService Debug - Absent days: $absentDays');
      }
    } catch (e) {
      if (_debugLogs) print('🔍 DashboardService Debug - Error fetching absent days: $e');
      debugPrint('Error fetching absent days: $e');
    }

    // Fetch class list for student count calculation
    try {
      final classResponse = await SchoolDataService.getClassList();
      if (classResponse['status'] == 'success' &&
          classResponse['data'] != null) {
        final classList = classResponse['data'] as List<dynamic>? ?? [];
        classes = classList.cast<Map<String, dynamic>>();

        // Calculate total students from all classes
        for (final classData in classes) {
          final studentCount = classData['student_count'] as int? ?? 0;
          totalStudents += studentCount;
        }
      }
    } catch (e) {
      // Error fetching class list
    }

    // 5. Fetch detailed teacher profile (optional - can fail)
    TeacherProfile? teacherProfile;
    try {
      teacherProfile = await TeacherProfileService.getTeacherProfileByUsername(
        username: username,
      );
    } catch (e) {
      // Error fetching teacher profile - use basic teacher data
    }

    if (_debugLogs) {
      print('🔍 DashboardService Debug - Returning DashboardData');
      print('🔍 DashboardService Debug - Teacher: ${teacher.name}');
      print('🔍 DashboardService Debug - Present Days: $presentDays');
      print('🔍 DashboardService Debug - Absent Days: $absentDays');
      print('🔍 DashboardService Debug - Total Students: $totalStudents');
    }

    return DashboardData(
      teacher: teacher,
      school: school,
      presentDays: presentDays,
      absentDays: absentDays,
      totalStudents: totalStudents,
      classes: classes,
      sections: sections,
      teacherProfile: teacherProfile,
    );
  }
}

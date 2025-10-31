import 'package:skoolwala/features/auth/services/teacher_service.dart';
import 'package:skoolwala/features/attendance/services/attendance_service.dart';
import 'package:skoolwala/features/school/services/school_data_service.dart';
import 'package:skoolwala/shared/models/teacher.dart';

class StatisticsData {
  final Teacher teacher;
  final int presentDays;
  final int absentDays;
  final int totalWorkingDays;
  final double attendancePercentage;
  final int totalStudents;
  final int totalClasses;
  final int totalSections;
  final List<Map<String, dynamic>> monthlyAttendance;
  final List<Map<String, dynamic>> classStatistics;
  final Map<String, int> weeklyAttendance;

  const StatisticsData({
    required this.teacher,
    required this.presentDays,
    required this.absentDays,
    required this.totalWorkingDays,
    required this.attendancePercentage,
    required this.totalStudents,
    required this.totalClasses,
    required this.totalSections,
    required this.monthlyAttendance,
    required this.classStatistics,
    required this.weeklyAttendance,
  });
}

class StatisticsService {
  static Future<StatisticsData> fetchStatisticsData({
    required String username,
    required String password,
  }) async {
    try {
      // 1. Get teacher data from login API
      final teacher = await TeacherService.teacherLogin(
        username: username,
        password: password,
      );

      // 2. Fetch attendance statistics
      int presentDays = 0;
      int absentDays = 0;
      int totalWorkingDays = 0;

      try {
        print('🔍 DEBUG: Fetching present days using session manager');
        final presentResponse =
            await AttendanceService.getTeacherPresentDaysCount();
        print('🔍 DEBUG: Present response: $presentResponse');
        if (presentResponse['status'] == 'success' &&
            presentResponse['data'] != null) {
          presentDays = presentResponse['data']['present_days_count'] ?? 0;
          print('🔍 DEBUG: Parsed present days: $presentDays');
        } else {
          print('🔍 DEBUG: Present API response not successful or no data');
        }
      } catch (e) {
        print('Error fetching present days: $e');
      }

      try {
        print('🔍 DEBUG: Fetching absent days using session manager');
        final absentResponse =
            await AttendanceService.getTeacherAbsentDaysCount();
        print('🔍 DEBUG: Absent response: $absentResponse');
        if (absentResponse['status'] == 'success' &&
            absentResponse['data'] != null) {
          absentDays = absentResponse['data']['absent_days_count'] ?? 0;
          print('🔍 DEBUG: Parsed absent days: $absentDays');
        } else {
          print('🔍 DEBUG: Absent API response not successful or no data');
        }
      } catch (e) {
        print('Error fetching absent days: $e');
      }

      totalWorkingDays = presentDays + absentDays;
      double attendancePercentage = totalWorkingDays > 0
          ? (presentDays / totalWorkingDays) * 100
          : 0.0;

      // 3. Fetch student and class statistics
      int totalStudents = 0;
      int totalClasses = 0;
      int totalSections = 0;
      List<Map<String, dynamic>> classStatistics = [];

      try {
        final classResponse = await SchoolDataService.getClassList();
        if (classResponse['classes'] != null) {
          final classes = (classResponse['classes'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          totalClasses = classes.length;

          for (final classData in classes) {
            try {
              final sectionsResponse =
                  await SchoolDataService.getSectionListByClass(
                    classId: classData['id']?.toString() ?? '',
                  );

              if (sectionsResponse['sections'] != null) {
                final sections =
                    sectionsResponse['sections'] as List<dynamic>? ?? [];
                totalSections += sections.length;

                for (final section in sections) {
                  try {
                    final studentsResponse =
                        await SchoolDataService.getStudentList(
                          classId: classData['id']?.toString() ?? '',
                          sectionId: section['id']?.toString() ?? '',
                        );

                    if (studentsResponse['students'] != null) {
                      final students =
                          studentsResponse['students'] as List<dynamic>? ?? [];
                      totalStudents += students.length;
                    }
                  } catch (e) {
                    print(
                      'Error fetching students for section ${section['id']}: $e',
                    );
                  }
                }
              }
            } catch (e) {
              print('Error fetching sections for class ${classData['id']}: $e');
            }
          }
        }
      } catch (e) {
        print('Error fetching class data: $e');
      }

      // 4. Generate mock monthly attendance data (last 6 months)
      final List<Map<String, dynamic>> monthlyAttendance =
          _generateMonthlyAttendanceData();

      // 5. Generate mock weekly attendance data
      final Map<String, int> weeklyAttendance = _generateWeeklyAttendanceData();

      return StatisticsData(
        teacher: teacher,
        presentDays: presentDays,
        absentDays: absentDays,
        totalWorkingDays: totalWorkingDays,
        attendancePercentage: attendancePercentage,
        totalStudents: totalStudents,
        totalClasses: totalClasses,
        totalSections: totalSections,
        monthlyAttendance: monthlyAttendance,
        classStatistics: classStatistics,
        weeklyAttendance: weeklyAttendance,
      );
    } catch (e) {
      print('Error fetching statistics data: $e');
      rethrow;
    }
  }

  static List<Map<String, dynamic>> _generateMonthlyAttendanceData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthName(month.month);
      final workingDays = _getWorkingDaysInMonth(month);
      final presentDays = (workingDays * (0.85 + (i * 0.02)))
          .round(); // Mock data with slight improvement trend
      final absentDays = workingDays - presentDays;

      data.add({
        'month': monthName,
        'year': month.year,
        'presentDays': presentDays,
        'absentDays': absentDays,
        'workingDays': workingDays,
        'percentage': workingDays > 0
            ? (presentDays / workingDays * 100).round().clamp(0, 100)
            : 0,
      });
    }

    return data;
  }

  static Map<String, int> _generateWeeklyAttendanceData() {
    final Map<String, int> data = {};

    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (int i = 0; i < 6; i++) {
      final dayKey = weekDays[i];
      // Mock data: present most days, occasionally absent
      data[dayKey] = i == 2 ? 0 : 1; // Absent on Wednesday
    }

    return data;
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  static int _getWorkingDaysInMonth(DateTime month) {
    // Simple calculation: exclude weekends (Saturday and Sunday)
    final lastDay = DateTime(month.year, month.month + 1, 0);
    int workingDays = 0;

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);
      if (date.weekday < 6) {
        // Monday = 1, Friday = 5
        workingDays++;
      }
    }

    return workingDays;
  }
}

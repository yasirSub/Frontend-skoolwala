import 'package:skoolwala/features/auth/services/teacher_service.dart';
import 'package:skoolwala/features/attendance/services/attendance_service.dart';
import 'package:skoolwala/features/school/services/school_data_service.dart';
import 'package:skoolwala/features/teacher/services/teacher_class_service.dart';
import 'package:skoolwala/shared/models/teacher.dart';
import 'package:intl/intl.dart';

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

      // 2. Fetch comprehensive attendance statistics
      int presentDays = 0;
      int absentDays = 0;
      int totalWorkingDays = 0;
      double attendancePercentage = 0.0;
      Map<String, int> weeklyAttendance = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
      };
      List<Map<String, dynamic>> monthlyAttendance = [];

      try {
        print('🔍 DEBUG: Fetching comprehensive stats for ${teacher.id}');
        final statsResponse =
            await AttendanceService.getTeacherSelfAttendanceStats(
              staffId: teacher.id,
              filterType: 'month',
              filterValue: DateFormat('yyyy-MM').format(DateTime.now()),
            );

        if (statsResponse['status'] == 'success' &&
            statsResponse['data'] != null) {
          final summary = statsResponse['data']['summary_stats'];
          presentDays = summary['present_days'] ?? 0;
          absentDays = summary['absent_days'] ?? 0;
          totalWorkingDays = summary['total_days'] ?? 0;
          attendancePercentage = (summary['present_percentage'] ?? 0.0)
              .toDouble();

          // Populate weekly attendance from records
          final records = statsResponse['data']['attendance_records'] as List?;
          if (records != null) {
            // Get current week dates
            final now = DateTime.now();
            final lastMonday = now
                .subtract(Duration(days: now.weekday - 1))
                .subtract(const Duration(minutes: 1));

            for (var record in records) {
              final dateStr = record['date'];
              if (dateStr != null) {
                final date = DateTime.parse(dateStr);
                // Check if date is in current week
                if (date.isAfter(lastMonday)) {
                  final dayName = DateFormat(
                    'E',
                  ).format(date); // Mon, Tue, etc.
                  if (weeklyAttendance.containsKey(dayName)) {
                    if (record['status'] == 'P') {
                      weeklyAttendance[dayName] = 1;
                    }
                  }
                }
              }
            }
          }

          print(
            '🔍 DEBUG: Fetched real stats: $presentDays present, $absentDays absent, $attendancePercentage%',
          );
        }
      } catch (e) {
        print('Error fetching comprehensive stats: $e');
        // Fallback to old simple APIs if new one fails
        try {
          final presentRes =
              await AttendanceService.getTeacherPresentDaysCount();
          if (presentRes['status'] == 'success') {
            presentDays = presentRes['data']['present_days_count'] ?? 0;
          }

          final absentRes = await AttendanceService.getTeacherAbsentDaysCount();
          if (absentRes['status'] == 'success') {
            absentDays = absentRes['data']['absent_days_count'] ?? 0;
          }

          totalWorkingDays = presentDays + absentDays;
          attendancePercentage = totalWorkingDays > 0
              ? (presentDays / totalWorkingDays) * 100
              : 0.0;
        } catch (e2) {
          print('Fallback stats fetch also failed: $e2');
        }
      }

      // 3. Fetch student and class statistics (teacher-specific)
      int totalStudents = 0;
      int totalClasses = 0;
      int totalSections = 0;
      List<Map<String, dynamic>> classStatistics = [];

      try {
        final classesRes = await TeacherClassService.getMyClasses();

        if (classesRes.isSuccess && classesRes.classes.isNotEmpty) {
          final classes = classesRes.classes;
          totalClasses = classes.length;

          // Unique sections across classes
          final Set<String> sectionKeys = {};

          for (final c in classes) {
            sectionKeys.add('${c.classId}-${c.sectionId}');
            totalStudents += c.studentCount;

            classStatistics.add({
              'class': c.className,
              'section': c.sectionName,
              'students': c.studentCount,
            });
          }

          totalSections = sectionKeys.length;
        } else {
          // Fallback to school-wide data if teacher-specific fails
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
                            studentsResponse['students'] as List<dynamic>? ??
                            [];
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
                print(
                  'Error fetching sections for class ${classData['id']}: $e',
                );
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching class data: $e');
      }

      // 4. Generate monthly attendance data if we couldn't get it from API
      if (monthlyAttendance.isEmpty) {
        monthlyAttendance = _generateMonthlyAttendanceData();
      }

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

      data.add({
        'month': monthName,
        'year': month.year,
        'presentDays': 0, // Default to 0 for real observation
        'absentDays': 0,
        'workingDays': workingDays,
        'percentage': 0,
      });
    }

    return data;
  }

  static Map<String, int> _generateWeeklyAttendanceData() {
    final Map<String, int> data = {};

    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (int i = 0; i < 6; i++) {
      final dayKey = weekDays[i];
      data[dayKey] = 0; // Default to 0
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

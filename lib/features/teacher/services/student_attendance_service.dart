import 'dart:convert';

import '../../../shared/services/http_client.dart';
import '../../../shared/services/cache_service.dart';
import '../../../shared/config/api_config.dart';

/// Model for Student Attendance Entry
class StudentAttendanceEntry {
  final int enrollId;
  final String status; // P, A, H, L
  final String? remark;

  StudentAttendanceEntry({
    required this.enrollId,
    required this.status,
    this.remark,
  });

  Map<String, dynamic> toJson() {
    return {'enroll_id': enrollId, 'status': status, 'remark': remark ?? ''};
  }
}

/// Response for bulk attendance marking
class BulkAttendanceResponse {
  final String status;
  final String date;
  final int classId;
  final int sectionId;
  final int totalRecords;
  final int successCount;
  final int errorCount;
  final List<String> errors;
  final String message;

  BulkAttendanceResponse({
    required this.status,
    required this.date,
    required this.classId,
    required this.sectionId,
    required this.totalRecords,
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.message,
  });

  factory BulkAttendanceResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final errorsList = data['errors'] as List<dynamic>? ?? [];

    return BulkAttendanceResponse(
      status: json['status']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      classId: int.parse(data['class_id']?.toString() ?? '0'),
      sectionId: int.parse(data['section_id']?.toString() ?? '0'),
      totalRecords: int.parse(data['total_records']?.toString() ?? '0'),
      successCount: int.parse(data['success_count']?.toString() ?? '0'),
      errorCount: int.parse(data['error_count']?.toString() ?? '0'),
      errors: errorsList.map((e) => e.toString()).toList(),
      message: json['message']?.toString() ?? '',
    );
  }

  bool get isSuccess => status == 'success';
}

/// Model for Student Attendance Report Item
class StudentAttendanceReportItem {
  final int enrollId;
  final int studentId;
  final String name;
  final String registerNo;
  final String? roll;
  final String photo;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int halfdayCount;
  final int totalAttendanceDays;
  final double attendancePercentage;

  StudentAttendanceReportItem({
    required this.enrollId,
    required this.studentId,
    required this.name,
    required this.registerNo,
    this.roll,
    required this.photo,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.halfdayCount,
    required this.totalAttendanceDays,
    required this.attendancePercentage,
  });

  factory StudentAttendanceReportItem.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceReportItem(
      enrollId: int.parse(json['enroll_id']?.toString() ?? '0'),
      studentId: int.parse(json['student_id']?.toString() ?? '0'),
      name: json['name']?.toString() ?? '',
      registerNo: json['register_no']?.toString() ?? '',
      roll: json['roll']?.toString(),
      photo: json['photo']?.toString() ?? '',
      presentCount: int.parse(json['present_count']?.toString() ?? '0'),
      absentCount: int.parse(json['absent_count']?.toString() ?? '0'),
      lateCount: int.parse(json['late_count']?.toString() ?? '0'),
      halfdayCount: int.parse(json['halfday_count']?.toString() ?? '0'),
      totalAttendanceDays: int.parse(
        json['total_attendance_days']?.toString() ?? '0',
      ),
      attendancePercentage: double.parse(
        json['attendance_percentage']?.toString() ?? '0',
      ),
    );
  }
}

/// Response for Attendance Report
class StudentAttendanceReportResponse {
  final String status;
  final int classId;
  final int sectionId;
  final String startDate;
  final String endDate;
  final int totalDays;
  final List<StudentAttendanceReportItem> students;
  final AttendanceSummary summary;
  final String message;

  StudentAttendanceReportResponse({
    required this.status,
    required this.classId,
    required this.sectionId,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.students,
    required this.summary,
    required this.message,
  });

  factory StudentAttendanceReportResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final studentsList = data['students'] as List<dynamic>? ?? [];
    final summaryData = data['summary'] as Map<String, dynamic>? ?? {};

    return StudentAttendanceReportResponse(
      status: json['status']?.toString() ?? '',
      classId: int.parse(data['class_id']?.toString() ?? '0'),
      sectionId: int.parse(data['section_id']?.toString() ?? '0'),
      startDate: data['start_date']?.toString() ?? '',
      endDate: data['end_date']?.toString() ?? '',
      totalDays: int.parse(data['total_days']?.toString() ?? '0'),
      students: studentsList
          .map(
            (item) => StudentAttendanceReportItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      summary: AttendanceSummary.fromJson(summaryData),
      message: json['message']?.toString() ?? '',
    );
  }

  bool get isSuccess => status == 'success';
}

/// Attendance Summary Statistics
class AttendanceSummary {
  final int totalStudents;
  final int totalPresent;
  final int totalAbsent;
  final int totalLate;
  final int totalHalfday;

  AttendanceSummary({
    required this.totalStudents,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLate,
    required this.totalHalfday,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalStudents: int.parse(json['total_students']?.toString() ?? '0'),
      totalPresent: int.parse(json['total_present']?.toString() ?? '0'),
      totalAbsent: int.parse(json['total_absent']?.toString() ?? '0'),
      totalLate: int.parse(json['total_late']?.toString() ?? '0'),
      totalHalfday: int.parse(json['total_halfday']?.toString() ?? '0'),
    );
  }
}

/// Service for Student Attendance Management
class StudentAttendanceService {
  /// Get student attendance for a specific date and class-section (with optional subject for subject-wise)
  /// Uses existing studentAttendance API with action='get'
  static Future<Map<String, dynamic>> getStudentAttendance({
    required int classId,
    required int sectionId,
    String? date,
    int? subjectId, // For subject-wise attendance
  }) async {
    try {
      final response = await HttpClient().post(
        'studentAttendance',
        body: {
          'action': 'get',
          'class_id': classId.toString(),
          'section_id': sectionId.toString(),
          if (date != null) 'date': date,
          if (subjectId != null) 'subject_id': subjectId.toString(),
        },
        requireAuth: true,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to get student attendance: $e');
    }
  }

  /// Mark attendance for a single student
  /// Uses existing studentAttendance API with action='set'
  static Future<Map<String, dynamic>> markStudentAttendance({
    required int enrollId,
    required String status,
    String? date,
    String? remark,
    int? subjectId,
  }) async {
    try {
      final response = await HttpClient().post(
        'studentAttendance',
        body: {
          'action': 'set',
          'enroll_id': enrollId.toString(),
          'status': status,
          if (date != null) 'date': date,
          if (remark != null) 'remark': remark,
          if (subjectId != null) 'subject_id': subjectId.toString(),
        },
        requireAuth: true,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to mark student attendance: $e');
    }
  }

  /// Mark attendance for multiple students at once (with optional subject for subject-wise)
  static Future<BulkAttendanceResponse> markStudentAttendanceBulk({
    required int classId,
    required int sectionId,
    required List<StudentAttendanceEntry> attendanceEntries,
    String? date,
    int? subjectId, // For subject-wise attendance
  }) async {
    try {
      final attendanceData = attendanceEntries.map((e) => e.toJson()).toList();

      // Use postJson for sending complex JSON data with arrays
      final response = await HttpClient().postJson(
        ApiConfig.markStudentAttendanceBulk,
        body: {
          'class_id': classId.toString(),
          'section_id': sectionId.toString(),
          'attendance': attendanceData,
          if (date != null) 'date': date,
          if (subjectId != null) 'subject_id': subjectId.toString(),
        },
        requireAuth: true,
      );

      return BulkAttendanceResponse.fromJson(response);
    } catch (e) {
      // Parse HTTP 403 errors for cutoff time violations
      if (e.toString().contains('HTTP 403')) {
        // Extract the JSON response from the error message
        final responseMatch = RegExp(
          r'Response: (\{.*\})',
        ).firstMatch(e.toString());
        if (responseMatch != null) {
          try {
            final jsonStr = responseMatch.group(1);
            final errorData = json.decode(jsonStr!);
            final errorMessage =
                errorData['message'] ?? 'Attendance modification not allowed';
            throw Exception(errorMessage);
          } catch (_) {
            // If parsing fails, throw a generic message
          }
        }
        throw Exception(
          'Attendance can only be modified until the cutoff time',
        );
      }
      throw Exception('Failed to mark bulk attendance: $e');
    }
  }

  /// Get attendance report for a class-section - WITH CACHING
  static Future<StudentAttendanceReportResponse> getAttendanceReport({
    required int classId,
    required int sectionId,
    String? startDate,
    String? endDate,
    int? studentId,
    int? subjectId,
    bool forceRefresh = false,
  }) async {
    try {
      // Generate cache key
      final cacheKey = CacheService.generateKey('student_report', {
        'class_id': classId,
        'section_id': sectionId,
        'start_date': startDate ?? '',
        'end_date': endDate ?? '',
        'student_id': studentId ?? 0,
        'subject_id': subjectId ?? 0,
      });

      // Check cache first (unless forced refresh)
      if (!forceRefresh) {
        final cached = await CacheService.get<Map<String, dynamic>>(
          key: cacheKey,
          ttlMinutes: 5, // 5 minute cache
        );
        if (cached != null) {
          return StudentAttendanceReportResponse.fromJson(cached);
        }
      }

      // Fetch from API
      final Map<String, String> queryParams = {
        'class_id': classId.toString(),
        'section_id': sectionId.toString(),
      };

      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (studentId != null) queryParams['student_id'] = studentId.toString();
      if (subjectId != null) queryParams['subject_id'] = subjectId.toString();

      final response = await HttpClient().get(
        ApiConfig.getStudentAttendanceReport,
        queryParams: queryParams,
        requireAuth: true,
      );

      // Cache successful response
      if (response['status'] == 'success') {
        await CacheService.set(key: cacheKey, data: response);
      }

      return StudentAttendanceReportResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get attendance report: $e');
    }
  }
}

import '../../../shared/services/http_client.dart';
import '../../../shared/services/session_manager.dart';
import '../../../shared/config/api_config.dart';

/// Model for Timetable Entry
class TimetableEntry {
  final String day;
  final String subjectName;
  final String? subjectCode;
  final String className;
  final String sectionName;
  final String timeStart;
  final String timeEnd;
  final String? teacherName;
  final String? classRoom;
  final bool isBreak;

  TimetableEntry({
    required this.day,
    required this.subjectName,
    this.subjectCode,
    required this.className,
    required this.sectionName,
    required this.timeStart,
    required this.timeEnd,
    this.teacherName,
    this.classRoom,
    this.isBreak = false,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      day: json['day']?.toString().toLowerCase() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
      subjectCode: json['subject_code']?.toString(),
      className: json['class_name']?.toString() ?? '',
      sectionName: json['section_name']?.toString() ?? '',
      timeStart: json['time_start']?.toString() ?? '',
      timeEnd: json['time_end']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString(),
      classRoom: json['class_room']?.toString(),
      isBreak: json['break'] == 1 || json['break'] == true,
    );
  }
}

/// Response model for teacher timetable
class TeacherTimetableResponse {
  final String status;
  final List<TimetableEntry> timetables;
  final String message;

  TeacherTimetableResponse({
    required this.status,
    required this.timetables,
    required this.message,
  });

  factory TeacherTimetableResponse.fromJson(Map<String, dynamic> json) {
    final timetablesList = json['data']?['timetables'] as List<dynamic>? ?? [];

    return TeacherTimetableResponse(
      status: json['status']?.toString() ?? '',
      timetables: timetablesList
          .map((item) => TimetableEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      message: json['message']?.toString() ?? '',
    );
  }

  bool get isSuccess => status == 'success';
}

/// Service for Teacher Timetable
class TeacherTimetableService {
  /// Get teacher timetable/schedule
  static Future<TeacherTimetableResponse> getTeacherTimetable({
    String? teacherId,
  }) async {
    try {
      final tId = teacherId ?? SessionManager.instance.teacherId?.toString();

      if (tId == null) {
        throw Exception('Teacher ID not found');
      }

      // Try POST first (as other endpoints use POST)
      Map<String, dynamic> response;
      try {
        response = await HttpClient().post(
          ApiConfig.getTeacherTimetable,
          body: {'teacher_id': tId},
          requireAuth: true,
        );
      } catch (e) {
        // Fallback to GET
        response = await HttpClient().get(
          ApiConfig.getTeacherTimetable,
          queryParams: {'teacher_id': tId},
          requireAuth: true,
        );
      }

      return TeacherTimetableResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get teacher timetable: $e');
    }
  }
}

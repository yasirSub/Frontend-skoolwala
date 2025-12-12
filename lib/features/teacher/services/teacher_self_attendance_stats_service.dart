import '../../../shared/services/http_client.dart';
import '../../../shared/services/session_manager.dart';

/// Service for Teacher Self Attendance Statistics
class TeacherSelfAttendanceStatsService {
  /// Get teacher self-attendance statistics with filters
  static Future<Map<String, dynamic>> getSelfAttendanceStats({
    String? filterType, // 'month', 'daterange', 'year'
    String? filterValue, // e.g., '2024-01', '2024-01-01 to 2024-01-31', '2024'
    String? staffId,
    String? startDate,
    String? endDate,
    String? date,
    String? month,
    String? year,
    String? daterange,
  }) async {
    try {
      final teacherId =
          staffId ?? SessionManager.instance.teacherId?.toString();

      if (teacherId == null) {
        throw Exception('Teacher ID not found');
      }

      final queryParams = <String, String>{'staff_id': teacherId};

      if (filterType != null) {
        queryParams['filter_type'] = filterType;
      }
      if (filterValue != null) {
        queryParams['filter_value'] = filterValue;
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate;
      }
      if (date != null) {
        queryParams['date'] = date;
      }
      if (month != null) {
        queryParams['month'] = month;
      }
      if (year != null) {
        queryParams['year'] = year;
      }
      if (daterange != null) {
        queryParams['daterange'] = daterange;
      }

      // Try GET first, fallback to POST if needed
      Map<String, dynamic> response;
      try {
        response = await HttpClient().get(
          'getTeacherSelfAttendanceStats',
          queryParams: queryParams,
          requireAuth: true,
        );
      } catch (e) {
        // Fallback to POST if GET fails
        response = await HttpClient().post(
          'getTeacherSelfAttendanceStats',
          body: queryParams,
          requireAuth: true,
        );
      }

      return response;
    } catch (e) {
      throw Exception('Failed to get self-attendance stats: $e');
    }
  }

  /// Get attendance records with filters
  static Future<Map<String, dynamic>> getAttendanceRecords({
    String? startDate,
    String? endDate,
    String? date,
    String? month,
    String? year,
  }) async {
    try {
      final body = <String, String>{'action': 'get'};

      if (date != null) {
        body['date'] = date;
      } else if (startDate != null && endDate != null) {
        body['start_date'] = startDate;
        body['end_date'] = endDate;
      } else if (month != null) {
        // Convert month to date range
        final start = '$month-01';
        final end = _getLastDayOfMonth(month);
        body['start_date'] = start;
        body['end_date'] = end;
      } else if (year != null) {
        body['start_date'] = '$year-01-01';
        body['end_date'] = '$year-12-31';
      }

      final response = await HttpClient().post(
        'teacherSelfAttendance',
        body: body,
        requireAuth: true,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to get attendance records: $e');
    }
  }

  static String _getLastDayOfMonth(String month) {
    // month format: YYYY-MM
    final parts = month.split('-');
    if (parts.length == 2) {
      final year = int.parse(parts[0]);
      final monthNum = int.parse(parts[1]);
      final lastDay = DateTime(year, monthNum + 1, 0).day;
      return '$month-$lastDay';
    }
    return month;
  }
}

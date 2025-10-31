import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skoolwala/shared/config/api_config.dart';

class DeveloperAttendanceService {
  static String get baseUrl => ApiConfig.getBaseUrl().replaceAll('/api', '');

  /// Delete attendance for today
  static Future<Map<String, dynamic>> deleteTodayAttendance(int staffId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/deleteAttendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'staff_id': staffId,
          'date': DateTime.now().toIso8601String().split(
            'T',
          )[0], // Today's date
          'type': 'today',
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  /// Delete attendance for full month
  static Future<Map<String, dynamic>> deleteMonthAttendance(
    int staffId,
    int year,
    int month,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/deleteAttendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'staff_id': staffId,
          'year': year,
          'month': month,
          'type': 'month',
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  /// Delete attendance for date range
  static Future<Map<String, dynamic>> deleteDateRangeAttendance(
    int staffId,
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/deleteAttendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'staff_id': staffId,
          'start_date': startDate,
          'end_date': endDate,
          'type': 'range',
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }
}

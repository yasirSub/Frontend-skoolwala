import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skoolwala/shared/config/api_config.dart';

class AttendanceFlow {
  const AttendanceFlow._();

  /// Get centralized base URL from ApiConfig (without /api suffix)
  static String _getBaseUrl() {
    return ApiConfig.getBaseUrl().replaceFirst(RegExp(r"/api/?$"), '');
  }

  static Future<Map<String, dynamic>?> fetchSchoolLocation() async {
    final baseUrl = _getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/api/getSchoolLocation'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<http.Response> postTeacherAttendance(
    Map<String, dynamic> requestData,
  ) {
    final baseUrl = _getBaseUrl();
    return http.post(
      Uri.parse('$baseUrl/api/attendanceForTeacher'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestData),
    );
  }

  static Future<http.Response> getSelfAttendanceStats(
    String staffId,
    String filterType,
    String filterValue,
  ) {
    final baseUrl = _getBaseUrl();
    final uri = Uri.parse(
      '$baseUrl/api/getTeacherSelfAttendanceStats?staff_id=$staffId&filter_type=$filterType&filter_value=$filterValue',
    );
    return http.get(uri);
  }
}

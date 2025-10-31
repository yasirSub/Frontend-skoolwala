import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceFlow {
  const AttendanceFlow._();

  static Future<Map<String, dynamic>?> fetchSchoolLocation(
    String baseUrl,
  ) async {
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
    String baseUrl,
    Map<String, dynamic> requestData,
  ) {
    return http.post(
      Uri.parse('$baseUrl/api/attendanceForTeacher'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestData),
    );
  }

  static Future<http.Response> getSelfAttendanceStats(
    String baseUrl,
    String staffId,
    String filterType,
    String filterValue,
  ) {
    final uri = Uri.parse(
      '$baseUrl/api/getTeacherSelfAttendanceStats?staff_id=$staffId&filter_type=$filterType&filter_value=$filterValue',
    );
    return http.get(uri);
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skoolwala/shared/services/api_service.dart';

class DummyDataService {
  static String get _baseUrl => ApiService.apiBaseUrl;

  /// Generate dummy attendance data for a staff member
  /// Only works in development mode
  static Future<Map<String, dynamic>> generateDummyData({
    required int staffId,
    required String type, // 'today', 'month', 'year'
    String pattern = 'mixed', // 'present', 'absent', 'mixed'
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/generateDummyData');
      print('🌐 Flutter calling URL: $url');
      print('🌐 Full URL string: $_baseUrl/generateDummyData');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'staff_id': staffId,
          'type': type,
          'pattern': pattern,
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Check if response is HTML (error page)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<!doctype') ||
          response.body.trim().startsWith('<html')) {
        throw Exception(
          'Server returned HTML instead of JSON. This usually means:\n'
          '1. The API endpoint does not exist\n'
          '2. The server is not running on the expected port\n'
          '3. There is a routing configuration issue\n'
          '4. The server returned an error page\n\n'
          'Please check:\n'
          '- Backend server is running on ${ApiService.currentApiUrl}\n'
          '- API endpoint /api/generateDummyData exists\n'
          '- Network connectivity to the server\n\n'
          'Response preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );
      }

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data;
        } catch (e) {
          throw Exception(
            'Failed to parse JSON response. Response body: ${response.body}',
          );
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
            errorData['message'] ?? 'Failed to generate dummy data',
          );
        } catch (e) {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}\n'
            'Response: ${response.body}',
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('Network error:')) {
        throw Exception(
          'Network error: $e\n\n'
          'This usually means:\n'
          '1. Backend server is not running\n'
          '2. Wrong IP address or port\n'
          '3. Network connectivity issues\n\n'
          'Current API URL: ${ApiService.currentApiUrl}\n'
          'Please check your backend server configuration.',
        );
      }
      rethrow;
    }
  }

  /// Delete attendance data for a staff member
  static Future<Map<String, dynamic>> deleteAttendanceData({
    required int staffId,
    required String type, // 'today', 'month', 'range'
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/deleteAttendance');

      final requestBody = {'staff_id': staffId, 'type': type};

      if (date != null) requestBody['date'] = date;
      if (startDate != null) requestBody['start_date'] = startDate;
      if (endDate != null) requestBody['end_date'] = endDate;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to delete attendance data',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get available staff list for dummy data generation
  static Future<List<Map<String, dynamic>>> getStaffList() async {
    try {
      final url = Uri.parse('$_baseUrl/getStaffList');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'Failed to get staff list');
        }
      } else {
        throw Exception('Failed to get staff list');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

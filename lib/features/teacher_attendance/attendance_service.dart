import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/config/api_config.dart';

class AttendanceService {
  static String get baseUrl => ApiConfig.getBaseUrl().replaceFirst(RegExp(r"/api/?$"), '');
  
  /// Mark teacher attendance (check-in or check-out)
  static Future<Map<String, dynamic>> markAttendance({
    required List<double> faceData,
    required String attendanceType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/attendanceForTeacher'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'face_data': faceData,
          'attendance_type': attendanceType,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Unknown error');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  /// Check if face is recognized (optional - for validation)
  static Future<Map<String, dynamic>> checkFaceRecognition({
    required List<double> faceData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/face/identify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'face_data': faceData,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Face recognition failed');
      }
    } catch (e) {
      throw Exception('Face recognition error: $e');
    }
  }
}

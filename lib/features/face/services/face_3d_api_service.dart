import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/session_manager.dart';

class Face3DApiService {
  static String get _baseUrl => ApiService.apiBaseUrl;

  /// Enroll 3D face with multi-angle data and depth information
  static Future<Map<String, dynamic>?> enrollFace3D(
    Map<String, dynamic> enrollmentData,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/api/face/enroll3D');

      // Get session cookies
      final sessionManager = SessionManager.instance;
      final cookies = sessionManager.getAuthHeaders();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', ...cookies},
        body: jsonEncode(enrollmentData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ 3D Face enrollment failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 3D Face enrollment error: $e');
      return null;
    }
  }

  /// Identify face using 3D recognition
  static Future<Map<String, dynamic>?> identifyFace3D(
    List<double> faceData,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/api/face/identify3D');

      // Get session cookies
      final sessionManager = SessionManager.instance;
      final cookies = sessionManager.getAuthHeaders();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', ...cookies},
        body: jsonEncode({'face_data': faceData}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ 3D Face identification failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 3D Face identification error: $e');
      return null;
    }
  }

  /// List all enrolled 3D faces
  static Future<Map<String, dynamic>?> list3DFaces() async {
    try {
      final url = Uri.parse('$_baseUrl/api/face/list3D');

      // Get session cookies
      final sessionManager = SessionManager.instance;
      final cookies = sessionManager.getAuthHeaders();

      final response = await http.get(url, headers: cookies);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ 3D Face list failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 3D Face list error: $e');
      return null;
    }
  }

  /// Create 3D face table
  static Future<Map<String, dynamic>?> create3DFaceTable() async {
    try {
      final url = Uri.parse('$_baseUrl/api/create3DFaceTable');

      // Get session cookies
      final sessionManager = SessionManager.instance;
      final cookies = sessionManager.getAuthHeaders();

      final response = await http.get(url, headers: cookies);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ 3D Face table creation failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 3D Face table creation error: $e');
      return null;
    }
  }
}

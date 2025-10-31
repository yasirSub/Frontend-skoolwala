import '../../../shared/models/teacher.dart';
import '../../../shared/models/api_response.dart';
import '../../../shared/services/http_client.dart';
import '../../../shared/services/session_manager.dart';

class TeacherService {
  // Get teacher profile from API
  static Future<Teacher> getTeacherProfile({
    required String username,
    required String password,
  }) async {
    try {
      final response = await HttpClient().post(
        'teacherProfile',
        body: {'username': username, 'password': password},
      );

      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => Teacher.fromApiResponse(json),
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw Exception(
          'Failed to get teacher profile: ${apiResponse.message}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Teacher login
  static Future<Teacher> teacherLogin({
    required String username,
    required String password,
    String? schoolName,
  }) async {
    try {
      final response = await HttpClient().post(
        'teacherLogin',
        body: {'username': username, 'password': password},
      );

      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => Teacher.fromApiResponse(json),
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        await SessionManager.instance.login(
          teacher: apiResponse.data!,
          username: username,
          password: password,
          schoolName: schoolName,
        );
        return apiResponse.data!;
      } else {
        // Check for specific error messages
        final message = apiResponse.message.toLowerCase();
        if (message.contains('invalid') ||
            message.contains('incorrect') ||
            message.contains('wrong')) {
          throw Exception('Invalid username or password');
        } else if (message.contains('not found') || message.contains('exist')) {
          throw Exception('User account not found');
        } else if (message.contains('disabled') ||
            message.contains('inactive')) {
          throw Exception('Account is disabled. Please contact administrator');
        } else {
          throw Exception('Login failed: ${apiResponse.message}');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Teacher logout
  static Future<void> teacherLogout({required String username}) async {
    try {
      final response = await HttpClient().post(
        'teacherLogout',
        body: {'username': username},
        requireAuth: true,
      );

      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => json, // For logout, we don't need to parse data
      );

      if (!apiResponse.isSuccess) {
        // Logout API returned error but we continue with local logout
      }
    } catch (e) {
      // Even if logout API fails, we should still allow local logout
    }
  }
}

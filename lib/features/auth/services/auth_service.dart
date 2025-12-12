import '../../../shared/models/api_response.dart';
import '../../../shared/services/http_client.dart';
import '../../../shared/config/api_config.dart';

class AuthService {
  /// Request password reset
  ///
  /// Sends a password reset request to the backend API
  /// with the user's email and role (teacher/student)
  static Future<void> forgotPassword({
    required String email,
    required String role,
  }) async {
    try {
      final response = await HttpClient().post(
        ApiConfig.forgotPassword,
        body: {'email': email, 'role': role},
      );

      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => json, // For forgot password, we don't need to parse data
      );

      if (!apiResponse.isSuccess) {
        // Check for specific error messages
        final message = apiResponse.message.toLowerCase();
        if (message.contains('not found') || message.contains('exist')) {
          throw Exception('Email address not found');
        } else if (message.contains('invalid') ||
            message.contains('invalid email')) {
          throw Exception('Invalid email address');
        } else {
          throw Exception('Failed to send reset link: ${apiResponse.message}');
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}

import '../../../shared/models/role.dart';
import '../../../shared/models/api_response.dart';
import '../../../shared/models/teacher.dart';
import '../../../shared/services/session_manager.dart';
import '../../../shared/services/http_client.dart';
import '../../../shared/config/api_config.dart';
import 'teacher_service.dart';

class ProfileService {
  /// Authenticate user (generic - works for all roles: teacher, student, parent, admin, etc.)
  static Future<void> authenticateUser({
    required String username,
    required String password,
    required String schoolName,
    required Role role,
  }) async {
    try {
      // Use generic authLogin endpoint that handles all roles
      final response = await HttpClient().post(
        ApiConfig.authLogin,
        body: {'username': username, 'password': password},
        requireAuth: false,
      );

      final apiResponse = ApiResponse.fromJson(response, (json) => json);

      if (apiResponse.isSuccess && apiResponse.data != null) {
        final userData = apiResponse.data as Map<String, dynamic>;

        // Map authLogin response to Teacher model format
        // authLogin returns: id, name, email, mobile_no, photo, role (ID), branch_id, face_enrolled, etc.
        final mappedData = {
          'id': userData['id']?.toString() ?? '',
          'name': userData['name']?.toString() ?? '',
          'email': userData['email']?.toString() ?? '',
          'mobile_no': userData['mobile_no']?.toString() ?? '',
          'photo': userData['photo']?.toString() ?? '',
          'role': userData['role']?.toString() ?? role.id,
          'branch_id': userData['branch_id']?.toString() ?? '',
          'face_enrolled': userData['face_enrolled'] == true,
          // Set defaults for fields not in authLogin response
          'staff_id': '',
          'sex': '',
          'religion': '',
          'blood_group': '',
          'birthday': '',
          'present_address': '',
          'permanent_address': '',
          'designation': '',
          'department': '',
          'joining_date': '',
          'qualification': '',
          'experience_details': '',
          'total_experience': '',
          'facebook_url': '',
          'linkedin_url': '',
          'twitter_url': '',
          'username': username,
          'active': true,
        };

        // Create a Teacher object for session management (works for all roles)
        final teacher = Teacher.fromApiResponse(mappedData);

        // Setup session
        await SessionManager.instance.login(
          teacher: teacher,
          username: username,
          password: password,
          schoolName: schoolName,
        );

        print(
          '✅ ProfileService: User authenticated - ${teacher.name} (Role: ${role.name})',
        );
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
      print('❌ ProfileService: Authentication failed - $e');
      rethrow;
    }
  }

  /// Authenticate teacher and setup session (legacy method - kept for compatibility)
  static Future<void> authenticateTeacher({
    required String username,
    required String password,
    required String schoolName,
  }) async {
    try {
      // Login teacher
      final teacher = await TeacherService.teacherLogin(
        username: username,
        password: password,
        schoolName: schoolName,
      );

      // Session is already managed in TeacherService.teacherLogin()
      print('✅ ProfileService: Teacher authenticated - ${teacher.name}');
    } catch (e) {
      print('❌ ProfileService: Authentication failed - $e');
      rethrow;
    }
  }

  /// Logout teacher
  static Future<void> logoutTeacher({required String username}) async {
    try {
      await TeacherService.teacherLogout(username: username);
      await SessionManager.instance.logout();
      print('✅ ProfileService: Teacher logged out');
    } catch (e) {
      print('❌ ProfileService: Logout failed - $e');
      // Continue with logout even if API fails
      await SessionManager.instance.logout();
    }
  }
}

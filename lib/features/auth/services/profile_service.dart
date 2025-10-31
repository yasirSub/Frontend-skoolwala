import '../../../shared/services/session_manager.dart';
import 'teacher_service.dart';

class ProfileService {
  /// Authenticate teacher and setup session
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

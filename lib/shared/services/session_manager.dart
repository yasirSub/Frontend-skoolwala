import 'package:skoolwala/shared/models/teacher.dart';
import 'persistent_storage.dart';

class SessionManager {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();

  SessionManager._();

  // Session data
  Teacher? _currentTeacher;
  String? _currentUsername;
  String? _currentPassword;
  String? _sessionCookie;
  bool _isLoggedIn = false;

  // Getters
  Teacher? get currentTeacher => _currentTeacher;
  String? get currentUsername => _currentUsername;
  String? get currentPassword => _currentPassword;
  String? get sessionCookie => _sessionCookie;
  bool get isLoggedIn => _isLoggedIn;
  String? get teacherId => _currentTeacher?.id;

  /// Login and store session data
  Future<void> login({
    required Teacher teacher,
    required String username,
    required String password,
    String? sessionCookie,
    String? schoolName,
  }) async {
    _currentTeacher = teacher;
    _currentUsername = username;
    _currentPassword = password;
    _sessionCookie = sessionCookie;
    _isLoggedIn = true;

    // Save to persistent storage
    await PersistentStorage.saveLoginSession(
      username: username,
      password: password,
      teacher: teacher,
      sessionCookie: sessionCookie,
      schoolName: schoolName,
    );

    print(
      '🔐 Session Manager: User logged in - ${teacher.name} (ID: ${teacher.id})',
    );
    if (sessionCookie != null) {
      print('🔐 Session Cookie: $sessionCookie');
    }
  }

  /// Logout and clear session data (keeps selected school)
  Future<void> logout() async {
    _currentTeacher = null;
    _currentUsername = null;
    _currentPassword = null;
    _sessionCookie = null;
    _isLoggedIn = false;

    // Clear all persistent storage but keep selected school
    await PersistentStorage.clearAllData();

    print('🔐 Session Manager: User logged out (school selection kept)');
  }

  /// Complete logout - clears everything including selected school
  Future<void> completeLogout() async {
    _currentTeacher = null;
    _currentUsername = null;
    _currentPassword = null;
    _sessionCookie = null;
    _isLoggedIn = false;

    // Clear all persistent storage including selected school
    await PersistentStorage.clearAllData();
    await PersistentStorage.clearSelectedSchool();

    print('🔐 Session Manager: Complete logout (all data cleared)');
  }

  /// Get authentication headers for API calls
  Map<String, String> getAuthHeaders() {
    if (!_isLoggedIn) {
      throw Exception('User not logged in');
    }

    final headers = {
      'username': _currentUsername!,
      'password': _currentPassword!,
    };
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  /// Get authentication body for API calls
  Map<String, String> getAuthBody() {
    if (!_isLoggedIn) {
      throw Exception('User not logged in');
    }

    return {'username': _currentUsername!, 'password': _currentPassword!};
  }

  /// Get authentication body with teacher ID
  Map<String, String> getAuthBodyWithTeacherId() {
    if (!_isLoggedIn) {
      throw Exception('User not logged in');
    }

    return {
      'teacher_id': _currentTeacher!.id,
      'username': _currentUsername!,
      'password': _currentPassword!,
    };
  }

  /// Check if session is valid
  bool get hasValidSession =>
      _isLoggedIn && _currentTeacher != null && _currentUsername != null;

  /// Restore session from persistent storage
  Future<bool> restoreSession() async {
    try {
      final sessionData = await PersistentStorage.loadLoginSession();

      if (sessionData == null) {
        return false;
      }

      _currentTeacher = sessionData['teacher'] as Teacher;
      _currentUsername = sessionData['username'] as String;
      _currentPassword = sessionData['password'] as String;
      _sessionCookie = sessionData['sessionCookie'] as String?;
      _isLoggedIn = true;

      print(
        '🔐 Session Manager: Session restored for ${_currentTeacher?.name} (ID: ${_currentTeacher?.id})',
      );

      return true;
    } catch (e) {
      print('🔐 Session Manager: Error restoring session: $e');
      await logout(); // Clear any corrupted data
      return false;
    }
  }

  /// Update teacher data in both memory and persistent storage
  Future<void> updateTeacherData(Teacher teacher) async {
    _currentTeacher = teacher;
    await PersistentStorage.updateTeacherData(teacher);
    print('🔐 Session Manager: Teacher data updated');
  }

  /// Check if there's a stored login session
  static Future<bool> hasStoredSession() async {
    return await PersistentStorage.isLoggedIn();
  }

  /// Get session info for debugging
  Map<String, dynamic> getSessionInfo() {
    return {
      'isLoggedIn': _isLoggedIn,
      'teacherId': _currentTeacher?.id,
      'teacherName': _currentTeacher?.name,
      'username': _currentUsername,
      'hasPassword': _currentPassword != null,
    };
  }
}

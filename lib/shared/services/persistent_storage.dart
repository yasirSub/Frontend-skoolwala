import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/teacher.dart';

/// Service for managing persistent storage of user authentication data
class PersistentStorage {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';
  static const String _keyPassword = 'password';
  static const String _keyTeacherData = 'teacher_data';
  static const String _keySessionCookie = 'session_cookie';
  static const String _keySchoolName = 'school_name';
  static const String _keyIsFirstLaunch = 'is_first_launch';

  static SharedPreferences? _prefs;

  /// Initialize shared preferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if user is currently logged in
  static Future<bool> isLoggedIn() async {
    await init();
    return _prefs?.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Save login session data
  static Future<void> saveLoginSession({
    required String username,
    required String password,
    required Teacher teacher,
    String? sessionCookie,
    String? schoolName,
  }) async {
    await init();

    if (_prefs != null) {
      await _prefs!.setBool(_keyIsLoggedIn, true);
      await _prefs!.setString(_keyUsername, username);
      await _prefs!.setString(_keyPassword, password);
      await _prefs!.setString(_keyTeacherData, jsonEncode(teacher.toJson()));

      if (sessionCookie != null) {
        await _prefs!.setString(_keySessionCookie, sessionCookie);
      }

      if (schoolName != null) {
        await _prefs!.setString(_keySchoolName, schoolName);
      }

      print('💾 Persistent Storage: Login session saved');
    }
  }

  /// Load login session data
  static Future<Map<String, dynamic>?> loadLoginSession() async {
    await init();

    if (_prefs == null || !(_prefs!.getBool(_keyIsLoggedIn) ?? false)) {
      return null;
    }

    try {
      final username = _prefs!.getString(_keyUsername);
      final password = _prefs!.getString(_keyPassword);
      final teacherDataString = _prefs!.getString(_keyTeacherData);
      final sessionCookie = _prefs!.getString(_keySessionCookie);
      final schoolName = _prefs!.getString(_keySchoolName);

      if (username == null || password == null || teacherDataString == null) {
        print(
          '💾 Persistent Storage: Incomplete login data found, clearing...',
        );
        await clearLoginSession();
        return null;
      }

      final teacherData = jsonDecode(teacherDataString) as Map<String, dynamic>;
      final teacher = Teacher.fromJson(teacherData);

      print('💾 Persistent Storage: Login session loaded for ${teacher.name}');

      return {
        'username': username,
        'password': password,
        'teacher': teacher,
        'sessionCookie': sessionCookie,
        'schoolName': schoolName,
      };
    } catch (e) {
      print('💾 Persistent Storage: Error loading session: $e');
      await clearLoginSession();
      return null;
    }
  }

  /// Clear login session data
  static Future<void> clearLoginSession() async {
    await init();

    if (_prefs != null) {
      await _prefs!.remove(_keyIsLoggedIn);
      await _prefs!.remove(_keyUsername);
      await _prefs!.remove(_keyPassword);
      await _prefs!.remove(_keyTeacherData);
      await _prefs!.remove(_keySessionCookie);
      await _prefs!.remove(_keySchoolName);

      print('💾 Persistent Storage: Login session cleared');
    }
  }

  /// Clear all app data (for logout)
  static Future<void> clearAllData() async {
    await init();

    if (_prefs != null) {
      await _prefs!.clear();
      print('💾 Persistent Storage: All data cleared');
    }
  }

  /// Update teacher data only
  static Future<void> updateTeacherData(Teacher teacher) async {
    await init();

    if (_prefs != null && (_prefs!.getBool(_keyIsLoggedIn) ?? false)) {
      await _prefs!.setString(_keyTeacherData, jsonEncode(teacher.toJson()));
      print('💾 Persistent Storage: Teacher data updated');
    }
  }

  /// Get stored school name
  static Future<String?> getSchoolName() async {
    await init();
    return _prefs?.getString(_keySchoolName);
  }

  /// Check if this is the first app launch
  static Future<bool> isFirstLaunch() async {
    await init();
    return _prefs?.getBool(_keyIsFirstLaunch) ?? true;
  }

  /// Mark that the app has been launched before
  static Future<void> setFirstLaunchCompleted() async {
    await init();
    if (_prefs != null) {
      await _prefs!.setBool(_keyIsFirstLaunch, false);
      print('💾 Persistent Storage: First launch marked as completed');
    }
  }
}

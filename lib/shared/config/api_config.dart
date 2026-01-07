/// API Configuration File
///
/// This file contains all API endpoints, base URLs, and configuration settings
/// for the SkoolWala application.
///
/// HOW TO USE:
/// 1. Change the environment in main.dart to switch between dev/prod
/// 2. Update base URLs below as needed
/// 3. Add new API endpoints to their respective sections
library;

import 'package:flutter/foundation.dart' show kReleaseMode;

class ApiConfig {
  // ============================================
  // ENVIRONMENT CONFIGURATION
  // ============================================

  /// Current environment: 'development' or 'production'
  ///
  /// Override at runtime with:
  ///   flutter run --dart-define=ENV=production
  ///   flutter run --dart-define=ENV=development
  ///
  /// Notes:
  /// - This value is case-insensitive (e.g. "Production" works).
  /// - If not provided, release builds default to "production".
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: '',
  );

  /// Optional full override for API base URL.
  ///
  /// Example (real device on Wi‑Fi):
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.6:8080/api
  static const String apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Enable debug logging
  static const bool enableDebugLogging = false;

  // ============================================
  // BASE URLs
  // ============================================

  /// Production API URL
  static const String productionBaseUrl = 'https://skoolwala.com/api';

  /// Development API URL - Physical Device (10.25.202.134 is your machine IP)
  static const String developmentBaseUrl = 'http://10.25.202.134:8080/api';

  /// Localhost URL (for emulator/simulator)
  static const String localhostBaseUrl = 'http://10.25.202.134:8080/api';

  /// Android Emulator URL
  static const String androidEmulatorUrl = 'http://10.0.2.2:8080/api';

  /// iOS Simulator URL
  static const String iosSimulatorUrl = 'http://127.0.0.1:8080/api';

  /// Get current base URL based on environment
  static String getBaseUrl() {
    final override = apiBaseUrlOverride.trim();
    if (override.isNotEmpty) return override;

    switch (_resolvedEnvironment()) {
      case 'production':
        return productionBaseUrl;
      case 'development':
        return developmentBaseUrl;
      default:
        return developmentBaseUrl;
    }
  }

  static String _resolvedEnvironment() {
    final raw = environment.trim();
    if (raw.isEmpty) {
      return kReleaseMode ? 'production' : 'development';
    }

    final env = raw.toLowerCase();
    if (env == 'prod') return 'production';
    if (env == 'production') return 'production';
    if (env == 'dev') return 'development';
    if (env == 'development') return 'development';

    return kReleaseMode ? 'production' : 'development';
  }

  /// Get website base URL (non-API) for opening web pages like Mailbox.
  ///
  /// Example: https://skoolwala.com/api -> https://skoolwala.com
  static String getWebBaseUrl() {
    final apiBase = getBaseUrl();
    if (apiBase.endsWith('/api')) {
      return apiBase.substring(0, apiBase.length - 4);
    }
    return apiBase;
  }

  // ============================================
  // AUTHENTICATION ENDPOINTS
  // ============================================

  static const String authLogin = 'v1/auth/login';
  static const String teacherLogin = 'teacherLogin';
  static const String teacherProfile = 'teacherProfile';
  static const String updateTeacherProfile = 'updateTeacherProfile';
  static const String uploadTeacherPhoto = 'uploadTeacherPhoto';
  static const String updateTeacherPassword = 'updateTeacherPassword';
  static const String forgotPassword = 'forgotPassword';
  static const String getRoleList = 'getRoleList';
  static const String getMyClasses = 'getMyClasses';
  static const String getMyStudents = 'getMyStudents';
  static const String markStudentAttendanceBulk = 'markStudentAttendanceBulk';
  static const String getStudentAttendanceReport = 'getStudentAttendanceReport';
  static const String createHomework = 'createHomework';
  static const String getMyHomeworks = 'getMyHomeworks';
  static const String getHomeworkSubmissions = 'getHomeworkSubmissions';
  static const String evaluateHomework = 'evaluateHomework';
  static const String getSubjectsForClassSection = 'getSubjectsForClassSection';
  static const String getTeacherTimetable = 'getTeacherTimetable';
  static const String getStaffList = 'getStaffList';
  static const String getTeacherClasses = 'getTeacherClasses';
  static const String getTeacherTodayClasses = 'getTeacherTodayClasses';
  static const String getTeacherSchedule = 'getTeacherSchedule';
  static const String checkTeacherPresentToday = 'checkTeacherPresentToday';
  static const String getNextUpcomingClass = 'getNextUpcomingClass';

  // ============================================
  // SCHOOL ENDPOINTS
  // ============================================

  static const String getSchoolInfo = 'getSchoolInfo';
  static const String getSchoolLocation = 'getSchoolLocation';
  static const String getClassList = 'getClassList';
  static const String getSectionListByClass = 'getSectionListByClass';
  static const String getStudentList = 'getStudentList';

  // ============================================
  // ATTENDANCE ENDPOINTS
  // ============================================

  static const String quickAttendance = 'quickAttendance';
  static const String markAttendance = 'attendance/mark';
  static const String todayAttendance = 'attendance/today';
  static const String teacherAttendance = 'teacherAttendance';
  static const String teacherSelfAttendance = 'teacherSelfAttendance';
  static const String attendanceForTeacher = 'attendanceForTeacher';
  static const String getTeacherSelfAttendanceStats =
      'getTeacherSelfAttendanceStats';
  static const String teacherPresentDaysCount = 'teacherPresentDaysCount';
  static const String teacherAbsentDaysCount = 'teacherAbsentDaysCount';
  static const String deleteAttendance = 'deleteAttendance';

  // ============================================
  // LIBRARY ENDPOINTS
  // ============================================

  static const String getBookList = 'getBookList';
  static const String issueBook = 'issueBook';
  static const String getIssuedBooks = 'getIssuedBooks';
  static const String returnBook = 'returnBook';

  // ============================================
  // EVENT ENDPOINTS
  // ============================================

  static const String getEvents = 'getEvents';
  static const String createEvent = 'createEvent';
  static const String updateEvent = 'updateEvent';
  static const String deleteEvent = 'deleteEvent';

  // ============================================
  // MESSAGE ENDPOINTS
  // ============================================

  static const String getMessages = 'getMessages';
  static const String getMessageThread = 'getMessageThread';
  static const String markMessageAsRead = 'markMessageAsRead';
  static const String sendMessage = 'sendMessage';
  static const String replyMessage = 'replyMessage';
  static const String mailboxRecipients = 'mailboxRecipients';
  static const String setMessageFavouriteStatus = 'setMessageFavouriteStatus';

  // ============================================
  // FACE RECOGNITION ENDPOINTS
  // ============================================

  /// Face Enrollment
  static const String enrollFace = 'enrollFace';
  static const String enrollFaceImage = 'enrollFaceImage';
  // Removed: enrollFace3D

  /// Face Verification
  static const String verifyFace = 'verifyFace';
  static const String verifyFaceImage = 'verifyFaceImage';
  static const String identifyFace = 'face/identify';
  // Removed: identifyFace3D

  /// Face Management
  static const String listEnrolledFaces = 'listEnrolledFaces';
  // Removed: list3DFaces
  static const String deleteFaceEnrollment = 'face/delete';
  static const String checkFaceEnrollment = 'face/enrollment/check';
  static const String checkFaceDuplicate = 'checkFaceDuplicate';

  /// Face Analysis
  static const String faceAnalyze = 'face/analyze';
  static const String faceTestAnalyzer = 'face/testAnalyzer';
  static const String debugFaceRecognition = 'debugFaceRecognition';
  static const String checkFaceDuplicateAPI = 'face/check-duplicate';

  // (F2F endpoints removed per request)

  // ============================================
  // LOCATION ENDPOINTS
  // ============================================

  static const String schoolLocationSet = 'school-location/set';
  static const String schoolLocationList = 'school-location/list';
  static const String schoolLocationCheck = 'school-location/check';
  static const String schoolLocationDelete = 'school-location/delete';
  static const String locationAnalytics = 'locationAnalytics';
  static const String exportLocationAnalytics = 'exportLocationAnalytics';

  // ============================================
  // STATISTICS & ANALYTICS ENDPOINTS
  // ============================================

  static const String getTeacherStatistics = 'getTeacherStatistics';
  static const String getDashboardData = 'getDashboardData';
  static const String getStudentStatistics = 'getStudentStatistics';

  // ============================================
  // TEST & DEBUG ENDPOINTS
  // ============================================

  static const String apiTest = 'test';
  static const String testDatabase = 'testDatabase';
  static const String testCodeVersion = 'testCodeVersion';
  static const String fixDatabaseSchema = 'fixDatabaseSchema';
  static const String attendanceForTeacherTest = 'attendanceForTeacherTest';
  static const String generateDummyData = 'generateDummyData';
  static const String generateDummyDataAlt = 'generateDummyDataAlt';
  static const String testGenerateDummyData = 'testGenerateDummyData';
  static const String testGenerateDummyDataSimple =
      'testGenerateDummyDataSimple';
  static const String create3DFaceTable = 'create3DFaceTable';

  // ============================================
  // API CONFIGURATION
  // ============================================

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Default headers for all requests
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Supported API response formats
  static const List<String> supportedFormats = ['json'];
}

/// API Endpoint Builder
/// Helper class to build full API URLs
class ApiEndpoint {
  final String path;

  const ApiEndpoint(this.path);

  /// Get full URL for this endpoint
  String getUrl([String? baseUrl]) {
    final base = baseUrl ?? ApiConfig.getBaseUrl();
    return '$base/$path';
  }

  @override
  String toString() => path;
}

/// Pre-defined API Endpoints for easy access
class ApiEndpoints {
  // Authentication
  static const Auth login = Auth('teacherLogin');
  static const Auth logout = Auth('teacherLogout');
  static const Auth profile = Auth('teacherProfile');

  // School
  static const School schoolInfo = School('getSchoolInfo');
  static const School classList = School('getClassList');
  static const School sectionList = School('getSectionListByClass');
  static const School studentList = School('getStudentList');

  // Attendance
  static const Attendance markAttendance = Attendance('markAttendance');
  static const Attendance history = Attendance('getAttendanceHistory');
  static const Attendance status = Attendance('getAttendanceStatus');

  // Face Recognition
  static const Face faceEnroll = Face('enrollFace');
  static const Face faceVerify = Face('verifyFace');
  static const Face enrolledFaces = Face('getEnrolledFaces');

  // Dashboard
  static const Dashboard dashboard = Dashboard('getDashboardData');
  static const Dashboard statistics = Dashboard('getTeacherStatistics');
}

// Tag classes for better organization
class Auth extends ApiEndpoint {
  const Auth(super.path);
}

class School extends ApiEndpoint {
  const School(super.path);
}

class Attendance extends ApiEndpoint {
  const Attendance(super.path);
}

class Face extends ApiEndpoint {
  const Face(super.path);
}

class Dashboard extends ApiEndpoint {
  const Dashboard(super.path);
}

/// Environment helper
class Environment {
  static bool isDevelopment() => ApiConfig.environment == 'development';
  static bool isProduction() => ApiConfig.environment == 'production';

  static String get baseUrl => ApiConfig.getBaseUrl();

  static void setBaseUrl(String? url) {
    // This would need to be implemented based on how your ApiService handles overrides
    // For now, update the ApiConfig.environment or base URLs above
  }
}

/// Configuration helper methods
class ConfigHelper {
  /// Print current configuration (useful for debugging)
  static void printConfig() {
    if (ApiConfig.enableDebugLogging) {
      print('🔧 API Configuration:');
      print('   Environment: ${ApiConfig.environment}');
      print('   Base URL: ${ApiConfig.getBaseUrl()}');
      print('   Debug Logging: ${ApiConfig.enableDebugLogging}');
    }
  }

  /// Get all available endpoints
  static Map<String, String> getAllEndpoints() {
    return {
      // Auth
      'Teacher Login': ApiEndpoints.login.toString(),
      'Teacher Logout': ApiEndpoints.logout.toString(),
      'Teacher Profile': ApiEndpoints.profile.toString(),

      // School
      'School Info': ApiEndpoints.schoolInfo.toString(),
      'Class List': ApiEndpoints.classList.toString(),
      'Section List': ApiEndpoints.sectionList.toString(),
      'Student List': ApiEndpoints.studentList.toString(),

      // Attendance
      'Mark Attendance': ApiEndpoints.markAttendance.toString(),
      'Attendance History': ApiEndpoints.history.toString(),
      'Attendance Status': ApiEndpoints.status.toString(),

      // Face Recognition
      'Enroll Face': ApiEndpoints.faceEnroll.toString(),
      'Verify Face': ApiEndpoints.faceVerify.toString(),
      'Get Enrolled Faces': ApiEndpoints.enrolledFaces.toString(),

      // Dashboard
      'Dashboard': ApiEndpoints.dashboard.toString(),
      'Statistics': ApiEndpoints.statistics.toString(),
    };
  }
}

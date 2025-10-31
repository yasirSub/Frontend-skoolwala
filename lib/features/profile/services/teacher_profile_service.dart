import '../../../shared/services/http_client.dart';
import '../models/teacher_profile.dart';

class TeacherProfileService {
  /// Fetch teacher profile from API
  static Future<TeacherProfile> getTeacherProfile({
    required String teacherId,
    required String username,
  }) async {
    try {
      final response = await HttpClient().post(
        'teacherProfile',
        body: {'teacher_id': teacherId, 'username': username},
        requireAuth: true,
      );

      return TeacherProfile.fromApiResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch teacher profile: $e');
    }
  }

  /// Fetch teacher profile by username only
  static Future<TeacherProfile> getTeacherProfileByUsername({
    required String username,
  }) async {
    try {
      final response = await HttpClient().post(
        'teacherProfile',
        body: {'username': username},
        requireAuth: true,
      );

      return TeacherProfile.fromApiResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch teacher profile: $e');
    }
  }

  /// Update teacher profile
  static Future<TeacherProfile> updateTeacherProfile({
    required String teacherId,
    required String username,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await HttpClient().post(
        'updateTeacherProfile',
        body: {'teacher_id': teacherId, 'username': username, ...updates},
        requireAuth: true,
      );

      return TeacherProfile.fromApiResponse(response);
    } catch (e) {
      throw Exception('Failed to update teacher profile: $e');
    }
  }

  /// Update teacher photo
  static Future<TeacherProfile> updateTeacherPhoto({
    required String teacherId,
    required String username,
    required String photoBase64,
  }) async {
    try {
      final response = await HttpClient().post(
        'updateTeacherPhoto',
        body: {
          'teacher_id': teacherId,
          'username': username,
          'photo': photoBase64,
        },
        requireAuth: true,
      );

      return TeacherProfile.fromApiResponse(response);
    } catch (e) {
      throw Exception('Failed to update teacher photo: $e');
    }
  }

  /// Update teacher password
  static Future<bool> updateTeacherPassword({
    required String teacherId,
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await HttpClient().post(
        'updateTeacherPassword',
        body: {
          'teacher_id': teacherId,
          'username': username,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        requireAuth: true,
      );

      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  /// Get teacher profile with caching
  static TeacherProfile? _cachedProfile;
  static String? _cachedUsername;

  static Future<TeacherProfile> getCachedTeacherProfile({
    required String username,
    bool forceRefresh = false,
  }) async {
    // Return cached profile if available and not forcing refresh
    if (!forceRefresh &&
        _cachedProfile != null &&
        _cachedUsername == username) {
      return _cachedProfile!;
    }

    // Fetch fresh profile
    final profile = await getTeacherProfileByUsername(username: username);

    // Cache the profile
    _cachedProfile = profile;
    _cachedUsername = username;

    return profile;
  }

  /// Clear cached profile
  static void clearCache() {
    _cachedProfile = null;
    _cachedUsername = null;
  }

  /// Validate teacher profile data
  static bool validateProfileData(TeacherProfile profile) {
    // Check required fields
    if (profile.name.isEmpty ||
        profile.email.isEmpty ||
        profile.mobileNo.isEmpty ||
        profile.username.isEmpty) {
      return false;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(profile.email)) {
      return false;
    }

    // Validate mobile number (basic check)
    if (profile.mobileNo.length < 10) {
      return false;
    }

    return true;
  }

  /// Get profile completion percentage
  static double getProfileCompletionPercentage(TeacherProfile profile) {
    int completedFields = 0;
    int totalFields = 0;

    // Basic info
    totalFields += 4;
    if (profile.name.isNotEmpty) completedFields++;
    if (profile.email.isNotEmpty) completedFields++;
    if (profile.mobileNo.isNotEmpty) completedFields++;
    if (profile.photo.isNotEmpty) completedFields++;

    // Personal info
    totalFields += 4;
    if (profile.sex.isNotEmpty) completedFields++;
    if (profile.birthday.isNotEmpty) completedFields++;
    if (profile.bloodGroup.isNotEmpty) completedFields++;
    if (profile.religion.isNotEmpty) completedFields++;

    // Address info
    totalFields += 2;
    if (profile.presentAddress.isNotEmpty) completedFields++;
    if (profile.permanentAddress.isNotEmpty) completedFields++;

    // Professional info
    totalFields += 5;
    if (profile.designation.isNotEmpty) completedFields++;
    if (profile.department.isNotEmpty) completedFields++;
    if (profile.qualification.isNotEmpty) completedFields++;
    if (profile.experienceDetails.isNotEmpty) completedFields++;
    if (profile.totalExperience.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  /// Get missing profile fields
  static List<String> getMissingProfileFields(TeacherProfile profile) {
    final missing = <String>[];

    if (profile.name.isEmpty) missing.add('Name');
    if (profile.email.isEmpty) missing.add('Email');
    if (profile.mobileNo.isEmpty) missing.add('Mobile Number');
    if (profile.photo.isEmpty) missing.add('Profile Photo');
    if (profile.sex.isEmpty) missing.add('Gender');
    if (profile.birthday.isEmpty) missing.add('Birthday');
    if (profile.bloodGroup.isEmpty) missing.add('Blood Group');
    if (profile.religion.isEmpty) missing.add('Religion');
    if (profile.presentAddress.isEmpty) missing.add('Present Address');
    if (profile.permanentAddress.isEmpty) missing.add('Permanent Address');
    if (profile.designation.isEmpty) missing.add('Designation');
    if (profile.department.isEmpty) missing.add('Department');
    if (profile.qualification.isEmpty) missing.add('Qualification');
    if (profile.experienceDetails.isEmpty) missing.add('Experience Details');
    if (profile.totalExperience.isEmpty) missing.add('Total Experience');

    return missing;
  }
}

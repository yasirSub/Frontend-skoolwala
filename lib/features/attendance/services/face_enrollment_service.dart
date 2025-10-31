import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoolwala/features/attendance/services/face_recognition_engine.dart';
import 'package:skoolwala/features/attendance/services/google_ml_face_service.dart';
import 'package:skoolwala/shared/services/session_manager.dart';

/// Service for managing face enrollment and verification workflows
class FaceEnrollmentService {
  static const String _enrollmentKey = 'face_enrollments';
  static const String _lastEnrollmentKey = 'last_enrollment';
  static const String _baseUrl = 'http://192.168.31.129:8080/api';

  /// Check if user has enrolled their face (checks backend first, then local fallback)
  static Future<bool> isUserEnrolled(String userId) async {
    try {
      // First, try to check enrollment status from backend API
      final backendCheck = await _checkBackendEnrollment(userId);
      if (backendCheck != null) {
        return backendCheck;
      }

      // Fallback to local storage if backend check fails
      print(
        '⚠️ Backend enrollment check failed, falling back to local storage',
      );
      final prefs = await SharedPreferences.getInstance();
      final enrollmentsJson = prefs.getString(_enrollmentKey);

      if (enrollmentsJson == null) return false;

      final enrollments = List<Map<String, dynamic>>.from(
        json.decode(enrollmentsJson),
      );
      return enrollments.any((enrollment) => enrollment['user_id'] == userId);
    } catch (e) {
      print('❌ Failed to check enrollment status: $e');
      return false;
    }
  }

  /// Check enrollment status from backend API
  static Future<bool?> _checkBackendEnrollment(String userId) async {
    try {
      final sessionManager = SessionManager.instance;
      final sessionCookie = sessionManager.sessionCookie;

      if (sessionCookie == null) {
        print('⚠️ No session cookie found for backend enrollment check');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/face/enrollment/check/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Cookie': sessionCookie,
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Backend enrollment check timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final isEnrolled = data['data']['is_enrolled'] ?? false;
          print(
            '✅ Backend enrollment check: ${isEnrolled ? "ENROLLED" : "NOT ENROLLED"}',
          );
          return isEnrolled;
        }
      }

      print(
        '⚠️ Backend enrollment check returned status: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      print('⚠️ Backend enrollment check failed: $e');
      return null;
    }
  }

  /// Get enrollment data for a user
  static Future<Map<String, dynamic>?> getUserEnrollment(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enrollmentsJson = prefs.getString(_enrollmentKey);

      if (enrollmentsJson == null) return null;

      final enrollments = List<Map<String, dynamic>>.from(
        json.decode(enrollmentsJson),
      );
      final userEnrollment = enrollments.firstWhere(
        (enrollment) => enrollment['user_id'] == userId,
        orElse: () => {},
      );

      return userEnrollment.isEmpty ? null : userEnrollment;
    } catch (e) {
      print('❌ Failed to get user enrollment: $e');
      return null;
    }
  }

  /// Enroll user's face
  static Future<FaceEnrollmentResult> enrollUser({
    required String userId,
    required String userName,
    required FaceRecognitionResult faceResult,
  }) async {
    try {
      print('🎭 Starting face enrollment for: $userName ($userId)');

      // Check if user is already enrolled
      if (await isUserEnrolled(userId)) {
        return FaceEnrollmentResult(
          success: false,
          message: 'User is already enrolled',
          faceHash: null,
        );
      }

      // Validate face quality
      if (faceResult.confidence < 0.7) {
        return FaceEnrollmentResult(
          success: false,
          message:
              'Face quality is too low. Please ensure good lighting and look directly at the camera.',
          faceHash: null,
        );
      }

      // Save face embedding
      final faceHash = await FaceRecognitionEngine.saveFaceEmbedding(
        embedding: faceResult.embedding,
        userId: userId,
        userName: userName,
      );

      // Save enrollment record
      await _saveEnrollmentRecord(
        userId: userId,
        userName: userName,
        faceHash: faceHash,
        confidence: faceResult.confidence,
        enrollmentDate: DateTime.now(),
      );

      print('✅ Face enrollment completed successfully for: $userName');

      return FaceEnrollmentResult(
        success: true,
        message: 'Face enrollment completed successfully',
        faceHash: faceHash,
      );
    } catch (e) {
      print('❌ Face enrollment failed: $e');
      return FaceEnrollmentResult(
        success: false,
        message: 'Face enrollment failed: $e',
        faceHash: null,
      );
    }
  }

  /// Verify user's face
  static Future<FaceVerificationResult> verifyUser({
    required String userId,
    required FaceRecognitionResult faceResult,
  }) async {
    try {
      print('🔍 Starting face verification for user: $userId');

      // Check if user is enrolled
      if (!await isUserEnrolled(userId)) {
        return FaceVerificationResult(
          success: false,
          isMatch: false,
          message: 'User is not enrolled. Please enroll your face first.',
          similarity: 0.0,
        );
      }

      // Validate face quality
      if (faceResult.confidence < 0.6) {
        return FaceVerificationResult(
          success: false,
          isMatch: false,
          message:
              'Face quality is too low. Please ensure good lighting and look directly at the camera.',
          similarity: 0.0,
        );
      }

      // Verify face
      final isMatch = await FaceRecognitionEngine.verifyFace(
        candidateEmbedding: faceResult.embedding,
        userId: userId,
      );

      // Get similarity score for logging
      final enrollment = await getUserEnrollment(userId);
      double similarity = 0.0;
      if (enrollment != null && enrollment['embedding'] != null) {
        final storedEmbedding = List<double>.from(enrollment['embedding']);
        similarity = FaceRecognitionEngine.compareEmbeddings(
          faceResult.embedding,
          storedEmbedding,
        );
      }

      if (isMatch) {
        print('✅ Face verification successful for user: $userId');
        return FaceVerificationResult(
          success: true,
          isMatch: true,
          message: 'Face verification successful',
          similarity: similarity,
        );
      } else {
        print('❌ Face verification failed for user: $userId');
        return FaceVerificationResult(
          success: true,
          isMatch: false,
          message: 'Face verification failed. Please try again.',
          similarity: similarity,
        );
      }
    } catch (e) {
      print('❌ Face verification error: $e');
      return FaceVerificationResult(
        success: false,
        isMatch: false,
        message: 'Face verification failed: $e',
        similarity: 0.0,
      );
    }
  }

  /// Save enrollment record to local storage
  static Future<void> _saveEnrollmentRecord({
    required String userId,
    required String userName,
    required String faceHash,
    required double confidence,
    required DateTime enrollmentDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing enrollments
      final enrollmentsJson = prefs.getString(_enrollmentKey);
      List<Map<String, dynamic>> enrollments = [];

      if (enrollmentsJson != null) {
        enrollments = List<Map<String, dynamic>>.from(
          json.decode(enrollmentsJson),
        );
      }

      // Add new enrollment
      enrollments.add({
        'user_id': userId,
        'user_name': userName,
        'face_hash': faceHash,
        'confidence': confidence,
        'enrollment_date': enrollmentDate.toIso8601String(),
        'status': 'active',
      });

      // Save back to preferences
      await prefs.setString(_enrollmentKey, json.encode(enrollments));
      await prefs.setString(
        _lastEnrollmentKey,
        enrollmentDate.toIso8601String(),
      );

      print('💾 Enrollment record saved for: $userName');
    } catch (e) {
      print('❌ Failed to save enrollment record: $e');
      rethrow;
    }
  }

  /// Get all enrolled users
  static Future<List<Map<String, dynamic>>> getAllEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enrollmentsJson = prefs.getString(_enrollmentKey);

      if (enrollmentsJson == null) return [];

      return List<Map<String, dynamic>>.from(json.decode(enrollmentsJson));
    } catch (e) {
      print('❌ Failed to get enrollments: $e');
      return [];
    }
  }

  /// Remove user enrollment
  static Future<bool> removeEnrollment(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enrollmentsJson = prefs.getString(_enrollmentKey);

      if (enrollmentsJson == null) return false;

      final enrollments = List<Map<String, dynamic>>.from(
        json.decode(enrollmentsJson),
      );
      final initialLength = enrollments.length;

      enrollments.removeWhere((enrollment) => enrollment['user_id'] == userId);

      if (enrollments.length < initialLength) {
        await prefs.setString(_enrollmentKey, json.encode(enrollments));
        print('🗑️ Enrollment removed for user: $userId');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Failed to remove enrollment: $e');
      return false;
    }
  }

  /// Clear all enrollments (use with caution)
  static Future<void> clearAllEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_enrollmentKey);
      await prefs.remove(_lastEnrollmentKey);
      print('🗑️ All enrollments cleared');
    } catch (e) {
      print('❌ Failed to clear enrollments: $e');
    }
  }

  /// Get enrollment statistics
  static Future<Map<String, dynamic>> getEnrollmentStats() async {
    try {
      final enrollments = await getAllEnrollments();
      final activeEnrollments = enrollments
          .where((e) => e['status'] == 'active')
          .length;

      return {
        'total_enrollments': enrollments.length,
        'active_enrollments': activeEnrollments,
        'last_enrollment': enrollments.isNotEmpty
            ? enrollments.last['enrollment_date']
            : null,
      };
    } catch (e) {
      print('❌ Failed to get enrollment stats: $e');
      return {
        'total_enrollments': 0,
        'active_enrollments': 0,
        'last_enrollment': null,
      };
    }
  }
}

/// Result of face enrollment operation
class FaceEnrollmentResult {
  final bool success;
  final String message;
  final String? faceHash;

  FaceEnrollmentResult({
    required this.success,
    required this.message,
    this.faceHash,
  });
}

/// Result of face verification operation
class FaceVerificationResult {
  final bool success;
  final bool isMatch;
  final String message;
  final double similarity;

  FaceVerificationResult({
    required this.success,
    required this.isMatch,
    required this.message,
    required this.similarity,
  });
}

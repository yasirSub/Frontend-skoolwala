import 'dart:convert';
import 'package:skoolwala/features/attendance/services/face_enrollment_service.dart';
import 'package:skoolwala/features/attendance/services/google_ml_face_service.dart';
import 'package:skoolwala/features/face/services/face_api_service.dart'; // Add this import
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/services/http_client.dart';

/// Service for handling face-based attendance marking
class FaceAttendanceService {
  /// Mark attendance using face verification
  static Future<AttendanceResult> markAttendanceWithFace({
    required FaceRecognitionResult faceResult,
    required String attendanceType, // 'check_in' or 'check_out'
    String? location,
    Map<String, dynamic>? locationData,
    String? notes,
  }) async {
    try {
      print('🎯 Starting face-based attendance marking...');

      // Get current user session
      final sessionManager = SessionManager.instance;
      final currentTeacher = sessionManager.currentTeacher;

      if (currentTeacher == null) {
        return AttendanceResult(
          success: false,
          message: 'User session not found. Please login again.',
          attendanceId: null,
        );
      }

      // Verify face using the new identifyFace API
      print('🔍 Identifying face for attendance...');
      final identificationResult = await FaceApiService.identifyFace(
        embedding: faceResult.embedding,
      );

      if (identificationResult['status'] != 'success') {
        return AttendanceResult(
          success: false,
          message:
              'Face identification failed: ${identificationResult['message'] ?? 'Unknown error'}',
          attendanceId: null,
        );
      }

      final matched = identificationResult['matched'] ?? false;
      final identifiedName = identificationResult['name']?.toString();
      final confidence = (identificationResult['confidence'] ?? 0.0).toDouble();

      if (!matched) {
        return AttendanceResult(
          success: false,
          message:
              'Face not recognized. Please ensure you are enrolled and try again.',
          attendanceId: null,
        );
      }

      print(
        '✅ Face identified as: $identifiedName (${confidence.toStringAsFixed(1)}% confidence)',
      );

      // Prepare attendance data - match backend API expectations
      final attendanceData = {
        'attendance_type': attendanceType,
        'face_confidence': confidence,
        'face_embeddings':
            faceResult.embedding, // Send the actual embedding array
        'remark': notes ?? 'Face recognition attendance',
        // Always include location data (for now, no restrictions)
        if (locationData != null) ...{
          'location_latitude': locationData['latitude'],
          'location_longitude': locationData['longitude'],
          'location_accuracy': locationData['accuracy'] ?? 0.0,
        } else ...{
          // If no location data, send default values (no restrictions for now)
          'location_latitude': 0.0,
          'location_longitude': 0.0,
          'location_accuracy': 0.0,
        },
      };

      // Send to backend API
      // Note: Backend will validate that the face embeddings match the logged-in user
      print('📤 Sending attendance data to backend...');
      print('📤 Data being sent: ${json.encode(attendanceData)}');
      final apiResult = await _sendAttendanceToAPI(attendanceData);

      if (apiResult['success']) {
        print('✅ Attendance marked successfully');
        return AttendanceResult(
          success: true,
          message: 'Attendance marked successfully using face verification',
          attendanceId: apiResult['attendance_id'],
        );
      } else {
        print('❌ Failed to mark attendance on backend');
        return AttendanceResult(
          success: false,
          message:
              apiResult['message'] ?? 'Failed to mark attendance on backend',
          attendanceId: null,
        );
      }
    } catch (e) {
      print('❌ Face attendance marking failed: $e');
      return AttendanceResult(
        success: false,
        message: 'Attendance marking failed: $e',
        attendanceId: null,
      );
    }
  }

  /// Check if user can mark attendance (business rules)
  static Future<AttendanceCheckResult> canMarkAttendance({
    required String userId,
    required String attendanceType,
  }) async {
    try {
      print('🔍 Checking attendance eligibility for user: $userId');

      // Check if user is enrolled
      if (!await FaceEnrollmentService.isUserEnrolled(userId)) {
        return AttendanceCheckResult(
          canMark: false,
          message: 'Please enroll your face before marking attendance.',
          nextAction: 'enroll_face',
        );
      }

      // Check if user has already marked this type of attendance today
      final todayAttendance = await _getTodayAttendance(userId, attendanceType);

      if (todayAttendance != null) {
        final nextType = attendanceType == 'check_in'
            ? 'check_out'
            : 'check_in';
        return AttendanceCheckResult(
          canMark: false,
          message: 'You have already marked $attendanceType today.',
          nextAction: 'mark_$nextType',
          lastAttendance: todayAttendance,
        );
      }

      // Check business hours (optional)
      final businessHoursCheck = _checkBusinessHours();
      if (!businessHoursCheck['allowed']) {
        return AttendanceCheckResult(
          canMark: false,
          message: businessHoursCheck['message'],
          nextAction: 'wait',
        );
      }

      return AttendanceCheckResult(
        canMark: true,
        message: 'Ready to mark attendance',
        nextAction: 'proceed',
      );
    } catch (e) {
      print('❌ Attendance check failed: $e');
      return AttendanceCheckResult(
        canMark: false,
        message: 'Unable to verify attendance eligibility: $e',
        nextAction: 'retry',
      );
    }
  }

  /// Get today's attendance for a user
  static Future<Map<String, dynamic>?> _getTodayAttendance(
    String userId,
    String type,
  ) async {
    try {
      final response = await HttpClient().get(
        'attendance/today/$userId',
        requireAuth: true,
      );

      final attendances = List<Map<String, dynamic>>.from(
        response['data'] ?? [],
      );

      // Find attendance of the requested type
      for (final attendance in attendances) {
        if (attendance['attendance_type'] == type) {
          return attendance;
        }
      }

      return null;
    } catch (e) {
      print('❌ Failed to get today\'s attendance: $e');
      return null;
    }
  }

  /// Send attendance data to backend API
  static Future<Map<String, dynamic>> _sendAttendanceToAPI(
    Map<String, dynamic> data,
  ) async {
    try {
      print('📤 Sending attendance data to backend via HttpClient...');

      final response = await HttpClient().postJson(
        'attendance/mark',
        body: data,
        requireAuth: true,
      );

      print('✅ Attendance API response received');
      return {
        'success': true,
        'attendance_id': response['data']?['id'],
        'message': response['message'] ?? 'Attendance marked successfully',
      };
    } catch (e) {
      print('❌ Attendance API request failed: $e');
      return {
        'success': false,
        'message': e.toString().contains('HTTP')
            ? e.toString().split('\n')[0]
            : 'Network error: $e',
      };
    }
  }

  /// Check if current time is within business hours
  static Map<String, dynamic> _checkBusinessHours() {
    final now = DateTime.now();
    final hour = now.hour;

    // Define business hours (8 AM to 6 PM)
    const startHour = 8;
    const endHour = 18;

    if (hour < startHour) {
      return {
        'allowed': false,
        'message': 'Attendance can only be marked from 8:00 AM onwards.',
      };
    } else if (hour >= endHour) {
      return {
        'allowed': false,
        'message': 'Attendance can only be marked until 6:00 PM.',
      };
    } else {
      return {'allowed': true, 'message': 'Within business hours'};
    }
  }

  /// Get attendance history for a user
  static Future<List<Map<String, dynamic>>> getAttendanceHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{'user_id': userId};

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await HttpClient().get(
        'attendance/history',
        queryParams: queryParams,
        requireAuth: true,
      );

      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('❌ Failed to get attendance history: $e');
      return [];
    }
  }

  /// Get attendance statistics for a user
  static Future<Map<String, dynamic>> getAttendanceStats(String userId) async {
    try {
      final response = await HttpClient().get(
        'attendance/stats/$userId',
        requireAuth: true,
      );

      return response['data'] ?? {};
    } catch (e) {
      print('❌ Failed to get attendance stats: $e');
      return {};
    }
  }
}

/// Result of attendance marking operation
class AttendanceResult {
  final bool success;
  final String message;
  final String? attendanceId;

  AttendanceResult({
    required this.success,
    required this.message,
    this.attendanceId,
  });
}

/// Result of attendance eligibility check
class AttendanceCheckResult {
  final bool canMark;
  final String message;
  final String nextAction;
  final Map<String, dynamic>? lastAttendance;

  AttendanceCheckResult({
    required this.canMark,
    required this.message,
    required this.nextAction,
    this.lastAttendance,
  });
}

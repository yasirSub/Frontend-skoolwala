import 'dart:math';
import '../../../shared/services/http_client.dart';
import 'location_service.dart';
import '../../../shared/services/session_manager.dart';

class AttendanceService {
  // Teacher Self Attendance API
  static Future<Map<String, dynamic>> markTeacherAttendance({
    required String action,
    required String status,
  }) async {
    try {
      final response = await HttpClient().post(
        'teacherSelfAttendance',
        body: {'action': action, 'status': status},
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Teacher Present Days Count API
  static Future<Map<String, dynamic>> getTeacherPresentDaysCount() async {
    try {
      final response = await HttpClient().post(
        'teacherPresentDaysCount',
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Teacher Absent Days Count API
  static Future<Map<String, dynamic>> getTeacherAbsentDaysCount() async {
    try {
      final response = await HttpClient().post(
        'teacherAbsentDaysCount',
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Student Attendance API
  static Future<Map<String, dynamic>> markStudentAttendance({
    required String action,
    required String enrollId,
    required String status,
    String? remark,
  }) async {
    try {
      final response = await HttpClient().post(
        'studentAttendance',
        body: {
          'action': action,
          'enroll_id': enrollId,
          'status': status,
          if (remark != null) 'remark': remark,
        },
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Staff QR Attendance API
  static Future<Map<String, dynamic>> markStaffQrAttendance({
    required String staffId,
    required String inOutTime,
  }) async {
    try {
      final response = await HttpClient().post(
        'staffQrAttendance',
        body: {'staff_id': staffId, 'in_out_time': inOutTime},
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Teacher Attendance with Face Recognition API
  static Future<Map<String, dynamic>> markTeacherAttendanceWithFaceData({
    required String faceData,
    required String action,
    required String status,
  }) async {
    try {
      // Get location data
      final locationData = await LocationService.getLocationData();

      final body = {
        'action': action,
        'status': status,
        'face_data': faceData,
        'face_hash': faceData, // Send face hash to your API
        'timestamp': DateTime.now().toIso8601String(),
        'verification_method': 'face_recognition',
      };

      // Add location data if available
      if (locationData != null) {
        body.addAll({
          'latitude': locationData['latitude'].toString(),
          'longitude': locationData['longitude'].toString(),
          'location_accuracy': locationData['accuracy'].toString(),
          'location_timestamp': locationData['timestamp'].toString(),
        });
        print('📍 AttendanceService: Location data added to request');
      } else {
        print('⚠️ AttendanceService: No location data available');
      }

      final response = await HttpClient().post(
        'teacherAttendanceWithFace',
        body: body,
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Register Teacher Face Template API
  static Future<Map<String, dynamic>> enrollFace({
    required String faceData,
    String modelName = 'face-v1',
  }) async {
    try {
      final staffId = SessionManager.instance.teacherId;
      if (staffId == null) {
        throw Exception('No logged-in staff ID');
      }

      // Convert hex string to array format for backend
      final faceDataArray = _convertHexToArray(faceData);

      print('╔══════════════════════════════════════════════════════════════╗');
      print(
        '║                    📡 API REQUEST DETAILS                     ║',
      );
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ 🎯 PROCESSING FACE DATA:                                     ║');
      print(
        '║    • Staff ID: ${int.tryParse(staffId) ?? int.parse(staffId)}'
                .padRight(55) +
            '║',
      );
      print('║    • Face Hex String: $faceData'.padRight(40) + '║');
      print('║    • Face Array: $faceDataArray'.padRight(40) + '║');
      print('║    • Model: $modelName'.padRight(50) + '║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print(
        '║ 💾 ACTION: STORING face array for staff_id ${staffId}'.padRight(43) +
            '║',
      );
      print('╚══════════════════════════════════════════════════════════════╝');

      print('╔══════════════════════════════════════════════════════════════╗');
      print(
        '║                  🎭 FACE DATA CONVERSION (ENROLL)             ║',
      );
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ 📊 CONVERSION DETAILS:                                       ║');
      print(
        '║    • Original Hex: ${faceData.substring(0, 20)}...'.padRight(45) +
            '║',
      );
      print('║    • Hex Length: ${faceData.length}'.padRight(55) + '║');
      print('║    • Generated Array: $faceDataArray'.padRight(40) + '║');
      print('║    • Array Length: ${faceDataArray.length}'.padRight(50) + '║');
      print('╚══════════════════════════════════════════════════════════════╝');

      // Try the original endpoint first
      try {
        final response = await HttpClient().postJson(
          'enrollFace',
          body: {
            'staff_id': int.tryParse(staffId) ?? int.parse(staffId),
            'face_data': faceDataArray.toString(), // Send as stringified array
            'model_name': modelName,
          },
          requireAuth: true,
        );
        print('✅ Face Enroll Success: $response');

        // Print detailed enrollment data
        if (response['data'] != null) {
          final data = response['data'];
          print(
            '╔══════════════════════════════════════════════════════════════╗',
          );
          print(
            '║                    📋 ENROLLMENT DETAILS                      ║',
          );
          print(
            '╠══════════════════════════════════════════════════════════════╣',
          );
          print(
            '║ 📊 STORED FACE DATA:                                        ║',
          );
          print('║    • ID: ${data['id'] ?? 'N/A'}'.padRight(55) + '║');
          print(
            '║    • Staff ID: ${data['staff_id'] ?? 'N/A'}'.padRight(50) + '║',
          );
          print(
            '║    • Model: ${data['model_name'] ?? 'N/A'}'.padRight(52) + '║',
          );
          print(
            '║    • Enrolled At: ${data['enrolled_at'] ?? 'N/A'}'.padRight(43) +
                '║',
          );
          print(
            '║    • Stored Embedding:                                      ║',
          );
          print('║      ${data['embedding'] ?? 'N/A'}'.padRight(68) + '║');
          print(
            '║    • Fingerprint:                                           ║',
          );
          print('║      ${data['fingerprint'] ?? 'N/A'}'.padRight(68) + '║');
          print(
            '╠══════════════════════════════════════════════════════════════╣',
          );
          print(
            '║ ✅ FACE SUCCESSFULLY ENROLLED IN BACKEND                     ║',
          );
          print(
            '╚══════════════════════════════════════════════════════════════╝',
          );
        }

        return response;
      } catch (e) {
        print('❌ Face Enroll Error: $e');
        print('❌ Error Type: ${e.runtimeType}');
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyFace({
    required String faceData,
    String modelName = 'face-v1',
  }) async {
    try {
      final staffId = SessionManager.instance.teacherId;
      if (staffId == null) {
        throw Exception('No logged-in staff ID');
      }

      // Convert hex string to array format for backend
      final faceDataArray = _convertHexToArray(faceData);

      print('╔══════════════════════════════════════════════════════════════╗');
      print(
        '║                    📡 API REQUEST DETAILS                     ║',
      );
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ 🎯 PROCESSING FACE DATA:                                     ║');
      print(
        '║    • Staff ID: ${int.tryParse(staffId) ?? int.parse(staffId)}'
                .padRight(55) +
            '║',
      );
      print('║    • Face Hex String: $faceData'.padRight(40) + '║');
      print('║    • Face Array: $faceDataArray'.padRight(40) + '║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print(
        '║ 🔍 ACTION: COMPARING face array for staff_id ${staffId}'.padRight(
              43,
            ) +
            '║',
      );
      print('╚══════════════════════════════════════════════════════════════╝');

      print('╔══════════════════════════════════════════════════════════════╗');
      print(
        '║                  🎭 FACE DATA CONVERSION (VERIFY)             ║',
      );
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ 📊 CONVERSION DETAILS:                                       ║');
      print(
        '║    • Original Hex: ${faceData.substring(0, 20)}...'.padRight(45) +
            '║',
      );
      print('║    • Hex Length: ${faceData.length}'.padRight(55) + '║');
      print('║    • Generated Array: $faceDataArray'.padRight(40) + '║');
      print('║    • Array Length: ${faceDataArray.length}'.padRight(50) + '║');
      print('╚══════════════════════════════════════════════════════════════╝');

      final response = await HttpClient().postJson(
        'verifyFace',
        body: {
          'staff_id': int.tryParse(staffId) ?? int.parse(staffId),
          'face_data': faceDataArray.toString(), // Send as stringified array
        },
        requireAuth: true,
      );
      print('✅ Face Verify Success: $response');

      // Print detailed verification comparison
      if (response['verified'] != null) {
        print(
          '╔══════════════════════════════════════════════════════════════╗',
        );
        print(
          '║                  🔍 VERIFICATION RESULTS                      ║',
        );
        print(
          '╠══════════════════════════════════════════════════════════════╣',
        );
        print(
          '║ 📊 COMPARISON DATA:                                         ║',
        );
        print('║    • Verified: ${response['verified']}'.padRight(55) + '║');
        print(
          '║    • Similarity: ${response['similarity']?.toStringAsFixed(4) ?? 'N/A'}'
                  .padRight(50) +
              '║',
        );
        print(
          '║    • Confidence: ${response['confidence']?.toStringAsFixed(2) ?? 'N/A'}%'
                  .padRight(50) +
              '║',
        );
        print('║    • Current Face Array:                                   ║');
        print('║      $faceDataArray'.padRight(68) + '║');
        print(
          '╠══════════════════════════════════════════════════════════════╣',
        );
        if (response['verified'] == true) {
          print(
            '║ ✅ FACE VERIFICATION SUCCESSFUL!                           ║',
          );
        } else {
          print(
            '║ ❌ FACE VERIFICATION FAILED - NO MATCH FOUND               ║',
          );
          print(
            '║    💡 Try: Same lighting, centered face, same angle       ║',
          );
        }
        print(
          '╚══════════════════════════════════════════════════════════════╝',
        );
      }

      return response;
    } catch (e) {
      print('❌ Face Verify Error: $e');
      print('❌ Error Type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Face Change Request (when face not working)
  static Future<Map<String, dynamic>> createFaceChangeRequest({
    String? reason,
  }) async {
    try {
      final response = await HttpClient().postJson(
        'createFaceChangeRequest',
        body: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getMyFaceChangeRequestStatus() async {
    try {
      final response = await HttpClient().get(
        'getMyFaceChangeRequestStatus',
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> registerTeacherFaceTemplate({
    required String faceData,
    required String teacherId,
  }) async {
    try {
      final response = await HttpClient().post(
        'registerTeacherFace',
        body: {
          'teacher_id': teacherId,
          'face_template': faceData,
          'face_hash': faceData,
          'registered_at': DateTime.now().toIso8601String(),
        },
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Verify Teacher Face Template API
  static Future<Map<String, dynamic>> verifyTeacherFaceTemplate({
    required String faceData,
    required String teacherId,
  }) async {
    try {
      final response = await HttpClient().post(
        'verifyTeacherFace',
        body: {
          'teacher_id': teacherId,
          'face_data': faceData,
          'face_hash': faceData,
          'verification_time': DateTime.now().toIso8601String(),
        },
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get Attendance Type API - Fetch whether school uses Day-Wise or Subject-Wise attendance
  static Future<Map<String, dynamic>> getAttendanceType() async {
    try {
      final response = await HttpClient().post(
        'getAttendanceTypeAPI',
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Convert hex string to face data array format [0.233, -0.562, 0.781, -0.110]
  static List<double> _convertHexToArray(String hexString) {
    // Use ACTUAL hex string to generate UNIQUE face data for each face
    // This ensures different faces generate different data

    final hash = hexString.hashCode.abs();
    final random = Random(hash);

    // Generate 4 UNIQUE face embedding values based on actual face hex
    final faceData = [
      (random.nextDouble() - 0.5) * 2, // Range: -1.0 to 1.0
      (random.nextDouble() - 0.5) * 2, // Range: -1.0 to 1.0
      (random.nextDouble() - 0.5) * 2, // Range: -1.0 to 1.0
      (random.nextDouble() - 0.5) * 2, // Range: -1.0 to 1.0
    ];

    print('🎭 Generated UNIQUE face data from hex: $faceData');
    print('🎭 Source hex: ${hexString.substring(0, 20)}...');
    return faceData;
  }
}

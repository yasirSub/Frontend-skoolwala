import '../../../shared/services/http_client.dart';

class SimpleFaceApi {
  /// Enroll a face for a staff member
  static Future<Map<String, dynamic>> enrollFace({
    required int staffId,
    required String name,
    String? email,
    String? mobile,
    required List<double> faceData,
  }) async {
    final body = {
      'staff_id': staffId,
      'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
      if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
      'face_data': faceData,
    };

    return HttpClient().postJson('enrollFace', body: body, requireAuth: true);
  }

  /// Check if a face is already enrolled for a staff member
  static Future<Map<String, dynamic>> checkFaceEnrollment({
    required int staffId,
  }) async {
    return HttpClient().get(
      'face/enrollment/check/$staffId',
      requireAuth: true,
    );
  }

  /// Verify a face against enrolled faces
  static Future<Map<String, dynamic>> verifyFace({
    required List<double> faceData,
  }) async {
    final body = {'face_data': faceData};

    return HttpClient().postJson('verifyFace', body: body, requireAuth: true);
  }

  /// Check for duplicate faces
  static Future<Map<String, dynamic>> checkFaceDuplicate({
    required List<double> faceData,
  }) async {
    final body = {'face_data': faceData};

    return HttpClient().postJson(
      'checkFaceDuplicate',
      body: body,
      requireAuth: true,
    );
  }

  /// Delete face enrollment for a staff member
  static Future<Map<String, dynamic>> deleteFaceEnrollment({
    required int staffId,
  }) async {
    final body = {'staff_id': staffId};

    return HttpClient().postJson('face/delete', body: body, requireAuth: true);
  }

  /// Get list of enrolled faces (staff members with face data)
  static Future<List<Map<String, dynamic>>> getEnrolledFaces() async {
    try {
      // This would need to be implemented in the backend
      // For now, return empty list
      return [];
    } catch (e) {
      throw Exception('Failed to get enrolled faces: $e');
    }
  }
}

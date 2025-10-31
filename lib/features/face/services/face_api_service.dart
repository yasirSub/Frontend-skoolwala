import '../../../shared/services/http_client.dart';

class FaceApiService {
  static Future<Map<String, dynamic>> enrollFaceMultiAngle({
    required String staffId,
    required List<double> straightEmbedding,
    required List<double> rightEmbedding,
    required List<double> leftEmbedding,
    String modelName = 'mobilefacenet',
  }) async {
    try {
      final body = {
        'staff_id': staffId,
        'face_data_straight': straightEmbedding,
        'face_data_right': rightEmbedding,
        'face_data_left': leftEmbedding,
        'model_name': modelName,
      };
      return await HttpClient().postJson(
        'face/enroll',
        body: body,
        requireAuth: true,
      );
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to enroll face: $e',
        'staff_id': staffId,
      };
    }
  }

  static Future<Map<String, dynamic>> enrollFace({
    required String staffId,
    required List<double> embedding,
    String modelName = 'mobilefacenet',
  }) async {
    try {
      final body = {
        'staff_id': staffId,
        'embedding': embedding,
        'model_name': modelName,
      };
      return await HttpClient().postJson(
        'face/enroll',
        body: body,
        requireAuth: true,
      );
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to enroll face: $e',
        'staff_id': staffId,
      };
    }
  }

  static Future<Map<String, dynamic>> checkFaceDuplicate({
    required List<double> embedding,
    String? staffId,
  }) async {
    final body = {
      'embedding': embedding,
      if (staffId != null) 'staff_id': staffId,
    };
    return HttpClient().postJson(
      'face/check-duplicate',
      body: body,
      requireAuth: true,
    );
  }

  static Future<Map<String, dynamic>> checkFaceDuplicateMultiAngle({
    required List<double> straightEmbedding,
    required List<double> rightEmbedding,
    required List<double> leftEmbedding,
    String? staffId,
  }) async {
    final body = {
      'face_data_straight': straightEmbedding,
      'face_data_right': rightEmbedding,
      'face_data_left': leftEmbedding,
      if (staffId != null) 'staff_id': staffId,
    };
    return HttpClient().postJson(
      'face/check-duplicate',
      body: body,
      requireAuth: true,
    );
  }

  static Future<Map<String, dynamic>> verifyFace({
    required String staffId,
    required List<double> embedding,
  }) async {
    final body = {'staff_id': staffId, 'face_data': embedding};
    return HttpClient().postJson('verifyFace', body: body, requireAuth: true);
  }

  static Future<Map<String, dynamic>> identifyFace({
    required List<double> embedding,
    double? latitude,
    double? longitude,
  }) async {
    final body = {
      'face_data': embedding,
      if (latitude != null) 'user_latitude': latitude,
      if (longitude != null) 'user_longitude': longitude,
    };
    return HttpClient().postJson(
      'face/identify',
      body: body,
      requireAuth: true,
    );
  }

  static Future<Map<String, dynamic>> listEnrolledFaces() async {
    try {
      return await HttpClient().get('listEnrolledFaces', requireAuth: true);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to load enrolled faces: $e',
        'data': <Map<String, dynamic>>[],
      };
    }
  }

  static Future<Map<String, dynamic>> teacherProfile() async {
    // Returns: { status, data: { face_enrolled: bool, ... } }
    return HttpClient().get('teacherProfile', requireAuth: true);
  }

  static Future<Map<String, dynamic>> deleteFaceEnrollment({
    String? userId,
  }) async {
    final endpoint = userId != null ? 'face/delete/$userId' : 'face/delete';
    return HttpClient().get(endpoint, requireAuth: true);
  }
}

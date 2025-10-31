import '../../../shared/services/http_client.dart';

class FaceAnalyzerService {
  /// Analyze a face embedding against enrolled faces
  static Future<Map<String, dynamic>> analyzeFace({
    required List<double> faceData,
  }) async {
    try {
      final body = {'face_data': faceData};

      return await HttpClient().postJson(
        'face/analyze',
        body: body,
        requireAuth: true,
      );
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to analyze face: $e',
        'matched': false,
      };
    }
  }

  /// Test if the face analyzer is working
  static Future<Map<String, dynamic>> testAnalyzer() async {
    try {
      return await HttpClient().get('face/testAnalyzer', requireAuth: false);
    } catch (e) {
      return {'status': 'error', 'message': 'Failed to test analyzer: $e'};
    }
  }

  /// Get list of enrolled faces for debugging
  static Future<List<Map<String, dynamic>>> getEnrolledFaces() async {
    try {
      final response = await HttpClient().get(
        'listEnrolledFaces',
        requireAuth: true,
      );

      if (response['status'] == 'success') {
        return (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}

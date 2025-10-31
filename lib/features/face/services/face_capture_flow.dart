import 'dart:io';
import 'face_detection_service.dart';
import 'face_embedding_service.dart';
import 'face_api_service.dart';
import '../../../shared/services/http_client.dart';

class FaceCaptureFlow {
  final FaceDetectionService _detector = FaceDetectionService();
  final FaceEmbeddingService _embedder = FaceEmbeddingService();

  Future<void> init() async {
    await _embedder.init();
  }

  Future<List<double>?> computeEmbeddingFromFile(File file) async {
    final face = await _detector.detectPrimaryFace(file);
    if (face == null) return null;
    final cropped = await _detector.cropFaceRegion(file, face);
    if (cropped == null) return null;
    return _embedder.getEmbedding(cropped);
  }

  Future<Map<String, dynamic>?> enrollFromFile({
    required String staffId,
    required File file,
  }) async {
    final emb = await computeEmbeddingFromFile(file);
    if (emb == null) throw Exception('No face detected');
    return FaceApiService.enrollFace(staffId: staffId, embedding: emb);
  }

  Future<Map<String, dynamic>?> verifyFromFile({
    required String staffId,
    required File file,
  }) async {
    final emb = await computeEmbeddingFromFile(file);
    if (emb == null) throw Exception('No face detected');
    try {
      return await FaceApiService.verifyFace(staffId: staffId, embedding: emb);
    } on HttpException catch (e) {
      if (e.statusCode == 404) {
        await FaceApiService.enrollFace(staffId: staffId, embedding: emb);
        return await FaceApiService.verifyFace(
          staffId: staffId,
          embedding: emb,
        );
      }
      rethrow;
    }
  }

  void dispose() {
    _detector.dispose();
    _embedder.dispose();
  }
}

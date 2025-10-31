import 'package:camera/camera.dart';
import 'package:skoolwala/features/attendance/services/google_ml_face_service.dart';
import 'package:skoolwala/features/face/services/face_api_service.dart';

class FaceWorkflow {
  const FaceWorkflow._();

  static Future<List<double>?> analyzeFace(XFile imageFile) async {
    final faceResult = await GoogleMLFaceService.processCameraImage(imageFile);
    return faceResult?.embedding;
  }

  static Future<Map<String, dynamic>> validateEmbedding(
    List<double> embedding,
  ) async {
    return await FaceApiService.identifyFace(embedding: embedding);
  }
}

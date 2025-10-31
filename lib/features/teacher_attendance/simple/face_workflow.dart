import 'package:camera/camera.dart';
import 'package:skoolwala/features/attendance/services/google_ml_face_service.dart';
import 'package:skoolwala/features/face/services/face_api_service.dart';
import 'package:skoolwala/features/teacher_attendance/simple/spoofing_detector.dart';

class FaceWorkflow {
  const FaceWorkflow._();

  static Future<List<double>?> analyzeFace(XFile imageFile) async {
    final faceResult = await GoogleMLFaceService.processCameraImage(imageFile);
    
    if (faceResult == null) {
      return null;
    }
    
    // Check for spoofing (photo detection) - Use lenient mode for teacher attendance
    // Only reject obvious spoofing (very small faces or perfectly identical eye states)
    if (!SpoofingDetector.isLiveFace(faceResult.face, strict: false)) {
      throw Exception('SPOOFING_DETECTED');
    }
    
    // Check liveness - Use lenient mode for teacher attendance
    // Allow natural eye states (people can have similar eye states when both eyes are open)
    if (!SpoofingDetector.checkLiveness(faceResult.face, strict: false)) {
      throw Exception('LIVENESS_FAILED');
    }
    
    return faceResult.embedding;
  }

  static Future<Map<String, dynamic>> validateEmbedding(
    List<double> embedding,
  ) async {
    return await FaceApiService.identifyFace(embedding: embedding);
  }
}

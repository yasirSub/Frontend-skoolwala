import 'package:camera/camera.dart';

class CameraWorkflow {
  const CameraWorkflow._();

  static Future<CameraController?> initFrontCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras[0],
    );
    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
    return controller;
  }
}

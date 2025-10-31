import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class FaceDetectionService {
  final FaceDetector _detector;

  FaceDetectionService()
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableLandmarks: true,
          enableContours: true,
        ),
      );

  Future<Face?> detectPrimaryFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _detector.processImage(inputImage);
    if (faces.isEmpty) return null;
    // Return the largest face by bounding box area
    faces.sort(
      (a, b) => (b.boundingBox.width * b.boundingBox.height).compareTo(
        a.boundingBox.width * a.boundingBox.height,
      ),
    );
    return faces.first;
  }

  Future<img.Image?> cropFaceRegion(File imageFile, Face face) async {
    final rawBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return null;

    final bb = face.boundingBox;
    final x = bb.left.clamp(0, decoded.width.toDouble()).toInt();
    final y = bb.top.clamp(0, decoded.height.toDouble()).toInt();
    final w = bb.width.clamp(1, (decoded.width - x).toDouble()).toInt();
    final h = bb.height.clamp(1, (decoded.height - y).toDouble()).toInt();

    final crop = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    // Normalize size for embedding model input
    final resized = img.copyResize(crop, width: 112, height: 112);
    return resized;
  }

  void dispose() {
    _detector.close();
  }
}

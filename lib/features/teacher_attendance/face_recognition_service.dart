import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  static Interpreter? _interpreter;
  static bool _isInitialized = false;

  /// Initialize the TensorFlow Lite model
  static Future<bool> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/face_model.tflite',
      );
      _isInitialized = true;
      print('Face recognition model loaded successfully');
      return true;
    } catch (e) {
      print('Error loading face recognition model: $e');
      return false;
    }
  }

  /// Process image and extract face embedding
  static Future<List<double>?> extractFaceEmbedding(String imagePath) async {
    if (!_isInitialized || _interpreter == null) {
      print('Model not initialized');
      return null;
    }

    try {
      // Load and preprocess image
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        print('Failed to decode image');
        return null;
      }

      // Resize image to model input size (typically 112x112 for face recognition)
      final resizedImage = img.copyResize(image, width: 112, height: 112);

      // Convert to float array and normalize
      final input = _preprocessImage(resizedImage);

      // Run inference
      final output = List.filled(192, 0.0).reshape([1, 192]);
      _interpreter!.run(input, output);

      // Return embedding as list
      return List<double>.from(output[0]);
    } catch (e) {
      print('Error extracting face embedding: $e');
      return null;
    }
  }

  /// Preprocess image for model input
  static List<List<List<double>>> _preprocessImage(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(112, (_) => List.generate(112, (_) => 0.0)),
    );

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = image.getPixel(x, y);
        // Convert RGB to float and normalize to [-1, 1]
        // Extract red channel value from pixel
        final redValue = pixel.r;
        input[0][y][x] = (redValue / 255.0) * 2.0 - 1.0;
      }
    }

    return input;
  }

  /// Generate mock embedding for testing (remove in production)
  static List<double> generateMockEmbedding() {
    List<double> embedding = [];
    for (int i = 0; i < 192; i++) {
      embedding.add((i % 10) * 0.1);
    }
    return embedding;
  }

  /// Dispose resources
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

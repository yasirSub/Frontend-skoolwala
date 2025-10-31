import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class FaceEmbeddingService {
  tfl.Interpreter? _interpreter;
  List<int> _inputShape = [1, 112, 112, 3];
  int _outputDim = 512;

  Future<void> init({
    String modelAsset = 'assets/models/FaceMobileNet_Float32.tflite',
  }) async {
    try {
      _interpreter = await tfl.Interpreter.fromAsset(modelAsset);
      final inputT = _interpreter!.getInputTensors().first;
      final outputT = _interpreter!.getOutputTensors().first;
      _inputShape = inputT.shape;
      _outputDim = outputT.shape.last;
    } catch (_) {
      _interpreter = null; // fallback
    }
  }

  bool get isReady => _interpreter != null;

  // Return model embedding or fallback mock if model unavailable
  List<double> getEmbedding(img.Image face112) {
    if (_interpreter == null) {
      final bytes = img.encodePng(face112);
      return _mockEmbedding(bytes, dim: _outputDim);
    }
    final input = _imageToFloat32(face112, _inputShape[1], _inputShape[2]);
    final output = List.generate(1, (_) => List.filled(_outputDim, 0.0));
    _interpreter!.run(input, output);
    final emb = List<double>.from(output.first);
    final norm = math.sqrt(emb.fold<double>(0, (s, v) => s + v * v));
    if (norm > 0) {
      for (int i = 0; i < emb.length; i++) emb[i] /= norm;
    }
    return emb;
  }

  List<double> _mockEmbedding(List<int> bytes, {int dim = 512}) {
    // Deterministic pseudo-embedding from bytes for dev
    final out = List<double>.filled(dim, 0);
    for (int i = 0; i < bytes.length; i++) {
      out[i % dim] += (bytes[i] & 0xFF) / 255.0;
    }
    // L2 normalize
    final norm = math.sqrt(out.fold<double>(0, (s, v) => s + v * v));
    if (norm > 0) {
      for (int i = 0; i < out.length; i++) out[i] /= norm;
    }
    return out;
  }

  void dispose() {
    _interpreter?.close();
  }
}

List<List<List<List<double>>>> _imageToFloat32(img.Image image, int w, int h) {
  final resized = img.copyResize(image, width: w, height: h);
  final input = List.generate(
    1,
    (_) =>
        List.generate(h, (_) => List.generate(w, (_) => List.filled(3, 0.0))),
  );
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = resized.getPixel(x, y);
      final r = p.r;
      final g = p.g;
      final b = p.b;
      input[0][y][x][0] = (r - 127.5) / 128.0;
      input[0][y][x][1] = (g - 127.5) / 128.0;
      input[0][y][x][2] = (b - 127.5) / 128.0;
    }
  }
  return input;
}

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import '../services/simple_face_api.dart';

class SimpleFaceEnrollmentScreen extends StatefulWidget {
  const SimpleFaceEnrollmentScreen({super.key});

  @override
  State<SimpleFaceEnrollmentScreen> createState() =>
      _SimpleFaceEnrollmentScreenState();
}

class _SimpleFaceEnrollmentScreenState
    extends State<SimpleFaceEnrollmentScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Initializing camera...';
  Interpreter? _interpreter;

  // Staff information
  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        // Find front camera (lensDirection.front)
        CameraDescription? frontCamera;
        for (final camera in _cameras!) {
          if (camera.lensDirection == CameraLensDirection.front) {
            frontCamera = camera;
            break;
          }
        }

        // Fallback to first camera if no front camera found
        final selectedCamera = frontCamera ?? _cameras![0];

        print(
          '📷 Selected camera: ${selectedCamera.name} (${selectedCamera.lensDirection})',
        );

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        setState(() {
          _isInitialized = true;
          _statusMessage = 'Camera ready. Enter staff details and tap enroll.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera initialization failed: $e';
      });
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/facenet.tflite',
      );
      setState(() {
        _statusMessage = 'Model loaded. Camera ready.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Model loading failed: $e';
      });
    }
  }

  Future<void> _enrollFace() async {
    if (!_isInitialized || _cameraController == null) {
      _showSnackBar('Camera not ready', Colors.red);
      return;
    }

    if (_staffIdController.text.isEmpty) {
      _showSnackBar('Please enter Staff ID', Colors.red);
      return;
    }

    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter Name', Colors.red);
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing and processing face...';
    });

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      final File imageFile = File(image.path);

      // Process image and extract embedding
      final List<double> embedding = await _extractEmbedding(imageFile);

      if (embedding.isEmpty) {
        _showSnackBar('No face detected. Please try again.', Colors.red);
        return;
      }

      // Enroll face using API
      final result = await SimpleFaceApi.enrollFace(
        staffId: int.parse(_staffIdController.text),
        name: _nameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
        faceData: embedding,
      );

      if (result['status'] == 'success') {
        _showSnackBar('Face enrolled successfully!', Colors.green);
        _clearForm();
      } else {
        _showSnackBar('Enrollment failed: ${result['message']}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Camera ready. Enter staff details and tap enroll.';
      });
    }
  }

  Future<List<double>> _extractEmbedding(File imageFile) async {
    try {
      if (_interpreter == null) return [];

      // Load and preprocess image
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final List<List<List<double>>> processedImage = await _preprocessImage(
        imageBytes,
      );

      // Run inference
      final input = [processedImage];
      final output = List.filled(1 * 512, 0.0).reshape([1, 512]);

      _interpreter!.run(input, output);

      // Normalize embedding
      final List<double> embedding = output[0].cast<double>();
      final double norm = math.sqrt(
        embedding.map((e) => e * e).reduce((a, b) => a + b),
      );

      return embedding.map((e) => e / norm).toList();
    } catch (e) {
      print('Error extracting embedding: $e');
      return [];
    }
  }

  Future<List<List<List<double>>>> _preprocessImage(
    Uint8List imageBytes,
  ) async {
    // Simple preprocessing - resize to 160x160 and normalize
    // In a real implementation, you'd use proper image processing
    final List<List<List<double>>> processed = List.generate(
      160,
      (i) => List.generate(160, (j) => List.generate(3, (k) => 0.0)),
    );

    // This is a simplified version - you'd need proper image processing
    return processed;
  }

  void _clearForm() {
    _staffIdController.clear();
    _nameController.clear();
    _emailController.clear();
    _mobileController.clear();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    _staffIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Face Enrollment'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Camera Preview
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isInitialized
                    ? CameraPreview(_cameraController!)
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),

            const SizedBox(height: 16),

            // Status Message
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Staff Information Form
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _staffIdController,
                      decoration: const InputDecoration(
                        labelText: 'Staff ID *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 20),

                    // Enroll Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _enrollFace,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isProcessing
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Processing...'),
                                ],
                              )
                            : const Text(
                                'Enroll Face',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

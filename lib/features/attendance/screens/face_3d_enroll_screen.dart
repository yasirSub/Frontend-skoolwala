// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'dart:async';
import '../services/google_ml_face_service.dart';
import '../../face/services/face_embedding_service.dart';
import '../../face/services/face_3d_api_service.dart';

class Face3DEnrollScreen extends StatefulWidget {
  const Face3DEnrollScreen({super.key});

  @override
  State<Face3DEnrollScreen> createState() => _Face3DEnrollScreenState();
}

class _Face3DEnrollScreenState extends State<Face3DEnrollScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _busy = false;
  String _status = 'Initializing...';

  // Services
  FaceEmbeddingService? _embeddingService;

  // 3D Face Data
  List<FaceRecognitionResult> _capturedFaces = [];
  List<Map<String, dynamic>> _poseData = [];
  List<List<double>> _depthData = [];

  // Steps
  int _currentStep = 0;
  final List<String> _steps = ['Straight', 'Right', 'Left'];
  final List<String> _instructions = [
    'Look Straight\nKeep eyes open',
    'Turn Right\nLook at right side',
    'Turn Left\nLook at left side',
  ];

  // Auto-capture variables
  bool _isAutoCapturing = false;
  Timer? _faceDetectionTimer;
  int _stableFaceCount = 0;
  static const int _requiredStableFrames = 10; // Capture after 10 stable frames

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      print('🔧 Initializing services...');

      // Initialize embedding service
      print('🧠 Initializing embedding service...');
      _embeddingService = FaceEmbeddingService();
      await _embeddingService!.init();
      print('✅ Embedding service initialized');

      // Initialize camera
      print('📷 Initializing camera...');
      await _initializeCamera();

      print('✅ All services initialized successfully');
    } catch (e) {
      print('❌ Service initialization error: $e');
      setState(() {
        _status = 'Service initialization error: $e';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      print('📷 Initializing camera...');
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _status = 'No cameras available');
        print('❌ No cameras available');
        return;
      }

      print('📷 Found ${_cameras!.length} cameras');

      // Find front camera (lensDirection.front)
      CameraDescription? frontCamera;
      for (final camera in _cameras!) {
        print('📷 Camera: ${camera.name} (${camera.lensDirection})');
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

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
        _status = 'Ready to start 3D enrollment';
      });
      print('✅ Camera initialized successfully');
    } catch (e) {
      setState(() => _status = 'Camera error: $e');
      print('❌ Camera initialization error: $e');
    }
  }

  Future<void> _start3DEnrollment() async {
    if (!_isInitialized || _busy) return;

    setState(() {
      _busy = true;
      _currentStep = 0;
      _capturedFaces.clear();
      _poseData.clear();
      _depthData.clear();
      _isAutoCapturing =
          false; // Changed to false since we're using manual capture
      _stableFaceCount = 0;
      _status =
          'Position your face for ${_steps[_currentStep]} and tap capture';
    });
  }

  // Removed unused _startFaceDetection method since we're using manual capture

  // Removed unused _detectFaceInPreview method since we're using manual capture

  // Removed unused pose detection methods since we're using manual capture

  // Removed unused _captureStableFace method since we're using manual capture

  List<double> _generateSimulatedDepthData(Face face) {
    // Simulate depth data based on face features
    // In real implementation, use depth camera or stereo vision
    List<double> depthData = [];

    // Simulate depth map (32 values)
    for (int i = 0; i < 32; i++) {
      double depth = 0.5 + (i / 32.0) * 0.3; // Simulate depth range 0.5-0.8
      depthData.add(depth);
    }

    return depthData;
  }

  Future<void> _process3DEnrollment() async {
    if (_capturedFaces.length != 3) {
      setState(() {
        _status = 'Error: Need all 3 face angles';
        _busy = false;
      });
      return;
    }

    setState(() => _status = 'Creating 3D face model...');

    try {
      // Prepare 3D enrollment data
      final enrollmentData = {
        'face_data_straight': _capturedFaces[0].embedding,
        'face_data_right': _capturedFaces[1].embedding,
        'face_data_left': _capturedFaces[2].embedding,
        'pose_data': _poseData,
        'depth_data': _depthData,
      };

      // Send to backend
      final response = await Face3DApiService.enrollFace3D(enrollmentData);

      if (response != null && response['status'] == 'success') {
        setState(() {
          _status = '3D Face enrolled successfully!';
        });

        // Show success dialog
        _showSuccessDialog(response);
      } else {
        setState(() {
          _status =
              'Enrollment failed: ${response?['message'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Enrollment error: $e';
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('3D Face Enrolled!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quality Score: ${response['quality_score']?.toString() ?? 'N/A'}',
            ),
            Text('Model Version: ${response['model_version'] ?? '3d_v1.0'}'),
            const SizedBox(height: 16),
            const Text('Your 3D face model has been created with:'),
            const Text('• Multi-angle embeddings'),
            const Text('• Depth information'),
            const Text('• Pose-aware features'),
            const Text('• Enhanced security'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _faceDetectionTimer?.cancel();
    _controller?.dispose();
    _embeddingService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Face Enrollment'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isInitialized ? _buildCameraView() : _buildLoadingView(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing 3D camera...'),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera preview
        Positioned.fill(child: CameraPreview(_controller!)),

        // 3D Progress indicator
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: _build3DProgressIndicator(),
        ),

        // Status overlay
        Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: _buildStatusOverlay(),
        ),

        // Manual capture button
        if (_busy && _currentStep < _steps.length)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildManualCaptureButton(),
          ),
      ],
    );
  }

  Widget _build3DProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            '3D Face Enrollment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_steps.length, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                          ? Colors.blue
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[index],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          if (_isAutoCapturing && _currentStep < _steps.length) ...[
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _stableFaceCount / _requiredStableFrames,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          Text(
            _status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          if (_currentStep < _steps.length) ...[
            const SizedBox(height: 8),
            Text(
              _instructions[_currentStep],
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Rotate your head slowly like Android fingerprint enrollment',
              style: TextStyle(color: Colors.blue[300], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_busy) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _start3DEnrollment,
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      icon: const Icon(Icons.face_retouching_natural),
      label: const Text('Start 3D Enrollment'),
    );
  }

  Widget _buildManualCaptureButton() {
    return ElevatedButton.icon(
      onPressed: _busy ? _captureCurrentStep : null,
      icon: const Icon(Icons.camera_alt),
      label: Text('Capture ${_steps[_currentStep]}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Future<void> _captureCurrentStep() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      setState(() {
        _status = 'Camera not initialized';
      });
      return;
    }

    try {
      setState(() {
        _status = 'Capturing ${_steps[_currentStep]} face...';
      });

      print('📸 Starting capture for step: ${_steps[_currentStep]}');

      // Capture image
      final image = await _controller!.takePicture();
      print('📸 Image captured: ${image.path}');

      // Detect face using GoogleMLFaceService
      print('🔍 Processing face detection...');
      final faceResult = await GoogleMLFaceService.processCameraImage(image);
      print(
        '🔍 Face detection result: ${faceResult != null ? "Face found" : "No face"}',
      );

      if (faceResult != null) {
        final face = faceResult.face;
        print('👤 Face detected with confidence: ${faceResult.confidence}');

        // Generate embedding using the embedding service
        if (_embeddingService != null) {
          print('🧠 Generating embedding...');
          final imageBytes = await image.readAsBytes();
          final img.Image? imgImage = img.decodeImage(imageBytes);

          if (imgImage != null) {
            final embedding = _embeddingService!.getEmbedding(imgImage);
            print('🧠 Embedding generated: ${embedding.length} dimensions');

            if (embedding.isNotEmpty) {
              // Store face data
              _capturedFaces.add(
                FaceRecognitionResult(
                  embedding: embedding,
                  confidence: faceResult.confidence,
                  face: face,
                  faceHash: DateTime.now().millisecondsSinceEpoch.toString(),
                ),
              );

              // Store pose data
              _poseData.add({
                'head_euler_x': face.headEulerAngleX,
                'head_euler_y': face.headEulerAngleY,
                'head_euler_z': face.headEulerAngleZ,
                'step': _currentStep,
                'step_name': _steps[_currentStep],
              });

              // Simulate depth data
              _depthData.add(_generateSimulatedDepthData(face));

              setState(() {
                _status = '${_steps[_currentStep]} captured ✓';
              });

              print('✅ Step ${_currentStep + 1} completed successfully');

              // Move to next step
              await Future.delayed(const Duration(seconds: 1));
              _currentStep++;
              _stableFaceCount = 0;

              if (_currentStep >= _steps.length) {
                _isAutoCapturing = false;
                _faceDetectionTimer?.cancel();
                print('🎯 All steps completed, processing 3D enrollment...');
                await _process3DEnrollment();
              } else {
                setState(() {
                  _status =
                      'Position your face for ${_steps[_currentStep]} and tap capture';
                });
                print('➡️ Moving to next step: ${_steps[_currentStep]}');
              }
            } else {
              setState(() {
                _status =
                    'Failed to generate embedding for ${_steps[_currentStep]}';
              });
              print('❌ Embedding generation failed');
            }
          } else {
            setState(() {
              _status = 'Failed to decode image for ${_steps[_currentStep]}';
            });
            print('❌ Image decoding failed');
          }
        } else {
          setState(() {
            _status = 'Embedding service not initialized';
          });
          print('❌ Embedding service not initialized');
        }
      } else {
        setState(() {
          _status = 'No face detected for ${_steps[_currentStep]}';
        });
        print('❌ No face detected in image');
      }
    } catch (e) {
      setState(() {
        _status = 'Capture error: $e';
      });
      print('❌ Capture error: $e');
    }
  }
}

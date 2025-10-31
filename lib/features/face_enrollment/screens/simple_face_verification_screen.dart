// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../services/simple_face_api.dart';

class SimpleFaceVerificationScreen extends StatefulWidget {
  const SimpleFaceVerificationScreen({super.key});

  @override
  State<SimpleFaceVerificationScreen> createState() =>
      _SimpleFaceVerificationScreenState();
}

class _SimpleFaceVerificationScreenState
    extends State<SimpleFaceVerificationScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Initializing camera...';
  String _verificationResult = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
          _statusMessage = 'Camera ready. Tap verify to check face.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera initialization failed: $e';
      });
    }
  }

  Future<void> _verifyFace() async {
    if (!_isInitialized || _cameraController == null) {
      _showSnackBar('Camera not ready', Colors.red);
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing and verifying face...';
      _verificationResult = '';
    });

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      final File imageFile = File(image.path);

      // For now, we'll use a dummy embedding
      // In a real implementation, you'd extract the embedding from the image
      final List<double> dummyEmbedding = List.generate(512, (index) => 0.0);

      // Verify face using API
      final result = await SimpleFaceApi.verifyFace(faceData: dummyEmbedding);

      setState(() {
        if (result['status'] == 'success') {
          _verificationResult = 'Face verified successfully!';
          _statusMessage = 'Verification complete.';
        } else {
          _verificationResult =
              'Face verification failed: ${result['message']}';
          _statusMessage = 'Verification failed.';
        }
      });
    } catch (e) {
      setState(() {
        _verificationResult = 'Error: $e';
        _statusMessage = 'Error occurred during verification.';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Verification'),
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

            // Verification Result
            if (_verificationResult.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _verificationResult.contains('successfully')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _verificationResult.contains('successfully')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _verificationResult,
                  style: TextStyle(
                    fontSize: 16,
                    color: _verificationResult.contains('successfully')
                        ? Colors.green[800]
                        : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _verifyFace,
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
                          Text('Verifying...'),
                        ],
                      )
                    : const Text('Verify Face', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

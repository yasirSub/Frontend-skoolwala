// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:skoolwala/features/face/services/face_api_service.dart';
import 'package:skoolwala/features/attendance/services/google_ml_face_service.dart';

class FaceAnalyzerScreen extends StatefulWidget {
  const FaceAnalyzerScreen({super.key});

  @override
  State<FaceAnalyzerScreen> createState() => _FaceAnalyzerScreenState();
}

class _FaceAnalyzerScreenState extends State<FaceAnalyzerScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isFaceDetected = false;
  String? _errorMessage;
  bool _isCapturingFrame = false;
  bool _captureInFlight = false;

  // Analysis results
  String? _analyzedName;
  double? _confidence;
  bool? _isMatched;
  bool _userFound = false; // Flag to track if user has been found

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _setupScanAnimation();
  }

  void _setupScanAnimation() {
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeScreen() async {
    try {
      await _requestCameraPermission();
      await _initializeCamera();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      final selectedCamera = frontCamera ?? _cameras![0];

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _startFaceDetection();
    } catch (e) {
      throw Exception('Camera initialization failed: $e');
    }
  }

  Timer? _faceDetectionTimer;

  void _startFaceDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _faceDetectionTimer?.cancel();

    _faceDetectionTimer = Timer.periodic(const Duration(milliseconds: 700), (
      timer,
    ) async {
      if (!mounted ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _isCapturingFrame ||
          _userFound) {
        // Stop scanning if user is found
        return;
      }

      try {
        _isCapturingFrame = true;
        final XFile imageFile = await _cameraController!.takePicture().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Camera capture timeout');
          },
        );

        final result = await GoogleMLFaceService.processCameraImage(imageFile);

        final File file = File(imageFile.path);
        if (await file.exists()) {
          await file.delete();
        }

        if (mounted) {
          setState(() {
            _isFaceDetected = result != null && result.confidence >= 0.6;
          });
        }

        if (_isFaceDetected && !_isProcessing) {
          _analyzeFace();
        }
      } catch (e) {
        print('Face detection error: $e');
        if (mounted) {
          setState(() {
            _isFaceDetected = false;
          });
        }
      } finally {
        _isCapturingFrame = false;
      }
    });
  }

  void _stopFaceDetection() {
    _faceDetectionTimer?.cancel();
    _faceDetectionTimer = null;
    _isCapturingFrame = false;
  }

  Future<void> _analyzeFace() async {
    if (_captureInFlight || _isProcessing) {
      return;
    }
    _captureInFlight = true;
    _isCapturingFrame = true;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _analyzedName = null;
      _confidence = null;
      _isMatched = null;
    });

    try {
      if (_cameraController == null) {
        setState(() {
          _errorMessage = 'Camera not initialized.';
        });
        return;
      }

      if (!_isFaceDetected) {
        setState(() {
          _errorMessage =
              'No face detected. Please position your face in the frame.';
        });
        return;
      }

      final XFile image = await _cameraController!.takePicture().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Camera capture timeout during analysis');
        },
      );
      final faceResult = await GoogleMLFaceService.processCameraImage(image);

      if (faceResult == null) {
        setState(() {
          _errorMessage = 'Face detection failed. Please try again.';
        });
        return;
      }

      // Call the identifyFace API
      print('🔍 Analysis: Embedding size: ${faceResult.embedding.length}');
      print(
        '🔍 Analysis: First 5 embedding values: ${faceResult.embedding.take(5).toList()}',
      );
      final analysisResult = await FaceApiService.identifyFace(
        embedding: faceResult.embedding,
      );
      print('📊 Analysis Result: $analysisResult');

      if (analysisResult['status'] == 'success') {
        final matched = analysisResult['matched'] ?? false;
        final name = analysisResult['name']?.toString();
        final confidence = (analysisResult['confidence'] ?? 0.0).toDouble();

        setState(() {
          _isMatched = matched;
          _analyzedName = matched ? name : null;
          _confidence = confidence;
        });

        if (matched && name != null) {
          setState(() {
            _userFound = true; // Mark user as found
          });
          _stopFaceDetection(); // Stop continuous scanning
          _scanController.stop(); // Stop scanning animation
          _showAnalysisResult(name, confidence, true);
        } else {
          _showAnalysisResult('Face Not Registered', 0.0, false);
        }
      } else {
        setState(() {
          _errorMessage =
              'Analysis failed: ${analysisResult['message'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Face analysis failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _captureInFlight = false;
      _isCapturingFrame = false;
    }
  }

  void _restartScanning() {
    setState(() {
      _userFound = false;
      _analyzedName = null;
      _confidence = null;
      _isMatched = null;
      _errorMessage = null;
    });
    _scanController.repeat(); // Restart scanning animation
    _startFaceDetection(); // Restart face detection
  }

  void _showAnalysisResult(String name, double confidence, bool isMatched) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isMatched ? Icons.check_circle : Icons.person_off,
                color: isMatched ? Colors.green : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Face Analysis'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isMatched
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMatched ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isMatched
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                    if (isMatched) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Confidence: ${confidence.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartScanning(); // Restart scanning instead of just resetting
              },
              child: const Text('Scan Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _stopFaceDetection();
    _cameraController?.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.purple[600],
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Face Analyzer',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _analyzeFace,
            icon: const Icon(Icons.analytics, size: 28),
            tooltip: 'Analyze Face',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(flex: 3, child: _buildCameraView()),
              Expanded(flex: 2, child: _buildAnalysisPanel()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(_cameraController!)),
        Center(
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _userFound
                    ? Colors.green
                    : (_isFaceDetected ? Colors.green : Colors.blueAccent),
                width: 5,
              ),
            ),
            child: Stack(
              children: [
                if (!_isFaceDetected && !_userFound)
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanAnimation.value * 320,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.blueAccent,
                                Colors.blue,
                                Colors.blueAccent,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                Center(
                  child: Icon(
                    _userFound
                        ? Icons.check_circle
                        : (_isFaceDetected
                              ? Icons.face
                              : Icons.face_retouching_natural),
                    color: _userFound
                        ? Colors.green
                        : (_isFaceDetected ? Colors.green : Colors.blueAccent),
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213e),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            // Analysis Results
            if (_analyzedName != null) _buildAnalysisResult(),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    _userFound ? Icons.check_circle : Icons.info_outline,
                    color: _userFound ? Colors.green : Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userFound ? 'User Found!' : 'Face Analyzer',
                    style: TextStyle(
                      color: _userFound ? Colors.green : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userFound
                        ? 'Face analysis completed successfully. Tap "Scan Again" to analyze another face.'
                        : 'Position your face in the circle and wait for automatic analysis, or tap the analyze button.',
                    style: TextStyle(
                      color: _userFound ? Colors.green[100] : Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Analyze Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _userFound
                    ? _restartScanning
                    : (_isFaceDetected && !_isProcessing ? _analyzeFace : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userFound
                      ? Colors.green[600]
                      : Colors.purple[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _userFound ? Icons.refresh : Icons.analytics,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _userFound
                                ? 'Scan Again'
                                : (_isFaceDetected
                                      ? 'Analyze Face'
                                      : 'Position Face'),
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

  Widget _buildAnalysisResult() {
    if (_analyzedName == null) return const SizedBox.shrink();

    final isMatched = _isMatched ?? false;
    final confidence = _confidence ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMatched
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMatched ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isMatched ? Icons.check_circle : Icons.person_off,
            color: isMatched ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            _analyzedName!,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isMatched ? Colors.green : Colors.orange,
            ),
          ),
          if (isMatched) ...[
            const SizedBox(height: 4),
            Text(
              'Confidence: ${confidence.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 16, color: Colors.green[600]),
            ),
          ],
        ],
      ),
    );
  }
}

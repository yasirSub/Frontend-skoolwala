// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:skoolwala/features/attendance/services/google_ml_face_service.dart';
import 'package:skoolwala/features/face/services/face_api_service.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/features/teacher_attendance/simple/spoofing_detector.dart';
import 'dart:async';

enum EnrollmentStep { straight, right, left, processing, completed }

class MultiAngleEnrollScreen extends StatefulWidget {
  const MultiAngleEnrollScreen({super.key});

  @override
  State<MultiAngleEnrollScreen> createState() => _MultiAngleEnrollScreenState();
}

class _MultiAngleEnrollScreenState extends State<MultiAngleEnrollScreen> {
  CameraController? _controller;
  bool _ready = false;
  bool _busy = false;
  String? _error;
  String _status = 'Initializing...';

  EnrollmentStep _currentStep = EnrollmentStep.straight;
  Timer? _captureTimer;
  Timer? _livenessCheckTimer;
  List<FaceRecognitionResult> _capturedFaces = [];

  // Motion/Liveness tracking for photo detection
  List<double?> _leftEyeHistory = [];
  List<double?> _rightEyeHistory = [];
  int _blinkCount = 0;
  bool _hasDetectedBlink = false;
  bool _hasDetectedMovement = false;

  // Step configurations
  final Map<EnrollmentStep, Map<String, dynamic>> _stepConfig = {
    EnrollmentStep.straight: {
      'title': 'Look Straight',
      'instruction': 'Look directly at the camera with open eyes',
      'angle': 0.0,
      'duration': 3,
      'icon': Icons.center_focus_strong,
      'color': Colors.blue,
    },
    EnrollmentStep.right: {
      'title': 'Turn Right',
      'instruction': 'Slowly turn your head to the right',
      'angle': 15.0,
      'duration': 3,
      'icon': Icons.keyboard_arrow_right,
      'color': Colors.orange,
    },
    EnrollmentStep.left: {
      'title': 'Turn Left',
      'instruction': 'Slowly turn your head to the left',
      'angle': -15.0,
      'duration': 3,
      'icon': Icons.keyboard_arrow_left,
      'color': Colors.purple,
    },
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      CameraDescription? front;
      for (final c in cams) {
        if (c.lensDirection == CameraLensDirection.front) {
          front = c;
          break;
        }
      }
      final selected = front ?? cams.first;
      final ctrl = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _controller = ctrl;
        _ready = true;
        _status = 'Camera ready. Starting enrollment...';
      });

      // Start the enrollment process
      _startEnrollmentProcess();
    } catch (e) {
      setState(() {
        _error = 'Camera init failed: $e';
      });
    }
  }

  void _startEnrollmentProcess() {
    // Start with straight capture after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      _captureCurrentStep();
    });
  }

  void _captureCurrentStep() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_busy) return;

    setState(() {
      _error = null;
      _status =
          'Detecting face for ${_currentStep.name}... (Auto-detection every 3s)';
    });

    // Start continuous face detection with timer
    _startFaceDetection();
  }

  void _startFaceDetection() {
    _captureTimer?.cancel();
    _livenessCheckTimer?.cancel();

    // Reset liveness tracking when starting new step
    _leftEyeHistory.clear();
    _rightEyeHistory.clear();
    _blinkCount = 0;
    _hasDetectedBlink = false;
    _hasDetectedMovement = false;

    // Start continuous liveness checking (check every 500ms)
    _livenessCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      _checkLivenessContinuously();
    });

    // Much slower timer for actual capture attempts
    _captureTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_busy) return; // Don't capture if already busy
      if (_capturedFaces.length >= 3) {
        // Stop timer if we already have all 3 faces
        timer.cancel();
        _captureTimer = null;
        _livenessCheckTimer?.cancel();
        return;
      }
      _attemptCapture();
    });
  }

  Future<void> _checkLivenessContinuously() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_busy) return;

    try {
      final x = await _controller!.takePicture();
      final result = await GoogleMLFaceService.processCameraImage(x);

      if (result == null) return;

      final leftEye = result.face.leftEyeOpenProbability;
      final rightEye = result.face.rightEyeOpenProbability;

      // Track eye states
      _leftEyeHistory.add(leftEye);
      _rightEyeHistory.add(rightEye);

      // Keep only last 10 frames
      if (_leftEyeHistory.length > 10) {
        _leftEyeHistory.removeAt(0);
        _rightEyeHistory.removeAt(0);
      }

      // Update UI with helpful instructions based on frames collected
      if (mounted && _leftEyeHistory.length > 0) {
        String instructionStatus = 'Detecting face...';
        if (_leftEyeHistory.length < 4) {
          instructionStatus = 'Position your face in the frame...';
        } else if (_leftEyeHistory.length < 8) {
          instructionStatus = 'Please blink naturally...';
        } else if (_hasDetectedMovement || _hasDetectedBlink) {
          instructionStatus = 'Face detected! Hold position...';
        } else {
          instructionStatus = 'Please blink or move slightly...';
        }

        setState(() {
          if (_error == null) {
            _status = instructionStatus;
          }
        });
      }

      // Need at least 4 frames to check for blinking
      if (_leftEyeHistory.length >= 4) {
        // Check for blinking: eye state should change (open -> closed -> open)
        for (int i = 1; i < _leftEyeHistory.length - 1; i++) {
          final prev = _leftEyeHistory[i - 1];
          final curr = _leftEyeHistory[i];
          final next = _leftEyeHistory[i + 1];

          if (prev != null && curr != null && next != null) {
            // Detect blink: open -> closed -> open pattern
            if (prev > 0.7 && curr < 0.3 && next > 0.7) {
              _blinkCount++;
              _hasDetectedBlink = true;
              print('👁️ Blink detected! Total blinks: $_blinkCount');
              break;
            }

            // Detect movement: ANY change in eye state (even small variations indicate live face)
            // Real faces have natural micro-movements, photos are perfectly static
            if ((prev - curr).abs() > 0.05 || (curr - next).abs() > 0.05) {
              _hasDetectedMovement = true;
            }

            // Also check for any variation between left and right eyes (real faces have asymmetry)
            if (_rightEyeHistory.length > i &&
                i - 1 >= 0 &&
                i < _rightEyeHistory.length) {
              final rightPrev = _rightEyeHistory[i - 1];
              final rightCurr = _rightEyeHistory[i];
              if (rightPrev != null && rightCurr != null) {
                // Natural asymmetry between eyes
                final leftRightDiff =
                    (prev - rightPrev).abs() + (curr - rightCurr).abs();
                if (leftRightDiff > 0.1) {
                  _hasDetectedMovement = true;
                }
              }
            }
          }
        }

        // Also check right eye
        for (int i = 1; i < _rightEyeHistory.length - 1; i++) {
          final prev = _rightEyeHistory[i - 1];
          final curr = _rightEyeHistory[i];
          final next = _rightEyeHistory[i + 1];

          if (prev != null && curr != null && next != null) {
            if (prev > 0.7 && curr < 0.3 && next > 0.7) {
              _hasDetectedBlink = true;
              print('👁️ Right eye blink detected!');
              break;
            }
          }
        }
      }
    } catch (e) {
      // Silently fail - this is just for liveness checking
      print('Liveness check error: $e');
    }
  }

  Future<void> _attemptCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_busy) return; // Prevent multiple simultaneous captures

    // Set busy to prevent multiple captures
    setState(() {
      _busy = true;
    });

    try {
      // Add longer delay to prevent buffer overflow
      await Future.delayed(const Duration(milliseconds: 1000));

      final x = await _controller!.takePicture();
      final result = await GoogleMLFaceService.processCameraImage(x);

      if (result == null || result.embedding.isEmpty) {
        print('No face detected, trying again...');
        setState(() {
          _busy = false; // Reset busy state to allow retry
        });
        return; // Try again
      }

      // Additional face quality checks
      if (result.confidence < 0.6) {
        print('Face confidence too low: ${result.confidence}, trying again...');
        setState(() {
          _busy = false; // Reset busy state to allow retry
        });
        return; // Face confidence too low, try again
      }

      // MOTION-BASED SPOOFING PROTECTION: Require movement (more lenient for real faces)
      // Photos are perfectly static - real faces have natural micro-movements
      // Give users time and clear instructions before blocking

      // Update status with helpful instructions
      if (_leftEyeHistory.length < 8) {
        // Give users instructions while we gather data
        setState(() {
          _status = 'Detecting face... Please blink naturally and hold still.';
          _error = null; // Clear error to show instructions instead
        });
      }

      // Only check after we have enough frames (8 frames = ~4 seconds) to make a decision
      // Give users time to naturally blink/move before checking
      if (_leftEyeHistory.length >= 8) {
        // Check if face appears completely static (all eye values identical = photo)
        bool isCompletelyStatic = true;
        final first = _leftEyeHistory[0];
        for (int i = 1; i < _leftEyeHistory.length; i++) {
          final current = _leftEyeHistory[i];
          if (first != null &&
              current != null &&
              (first - current).abs() > 0.01) {
            // There's some variation - not completely static
            isCompletelyStatic = false;
            _hasDetectedMovement = true; // Set this if we see any variation
            break;
          }
        }

        // Only block if face is COMPLETELY static (all values identical) after 8 frames
        // This gives users ~4 seconds to naturally move/blink
        if (isCompletelyStatic) {
          print(
            '⚠️ Face appears completely static (all eye values identical) - likely a photo',
          );
          setState(() {
            _error =
                'Face appears static. Please use your live face. Blink naturally or move your head slightly.';
            _status = 'Waiting for movement... Please blink or move naturally.';
            _busy = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Please blink naturally or move your head slightly. Photos are not accepted.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      // If we haven't checked yet or detected movement, allow it to proceed
      // Real faces have natural variation even when looking straight

      // SPOOFING PROTECTION: Check if face is live (not a photo)
      // Use strict: false for enrollment but still block obvious photos
      if (!SpoofingDetector.isLiveFace(result.face, strict: false)) {
        final spoofingMessage = SpoofingDetector.getSpoofingMessage(
          result.face,
        );
        print(
          '⚠️ Spoofing detected during multi-angle enrollment: $spoofingMessage',
        );
        setState(() {
          _error = spoofingMessage;
          _status = 'Please use your live face, not a photo.';
          _busy = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(spoofingMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // SPOOFING PROTECTION: Check liveness indicators (photos will fail this)
      // Even in lenient mode, basic liveness checks should pass
      if (!SpoofingDetector.checkLiveness(result.face, strict: false)) {
        print('⚠️ Liveness check failed during multi-angle enrollment');
        setState(() {
          _error =
              'Please use your live face. Blink naturally and ensure good lighting. Photos are not accepted.';
          _status =
              'Liveness check failed - please try again with your live face.';
          _busy = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please use your live face. Photos or screens cannot be used for enrollment.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Check if face angle is appropriate for current step
      if (_isFaceAngleCorrect(result.face)) {
        _captureTimer?.cancel();
        _captureTimer = null;

        // For straight capture (first step), check if face already exists
        if (_currentStep == EnrollmentStep.straight) {
          final duplicateCheck = await _checkFaceDuplicate(result.embedding);
          if (duplicateCheck['isDuplicate']) {
            setState(() {
              _error =
                  'This face is already registered to another user. Please use a different face or contact admin.';
              _busy = false;
            });
            return;
          }
        }

        // Double-check result is valid before adding
        if (result.embedding.isNotEmpty) {
          setState(() {
            _capturedFaces.add(result);
            _busy = false;
            _status = '✅ Captured ${_currentStep.name} face!';
          });
        } else {
          setState(() {
            _busy = false;
            _status = 'Failed to capture valid face data. Trying again...';
          });
          return;
        }

        print(
          '✅ Captured ${_currentStep.name} face with confidence: ${result.confidence}',
        );

        // Stop the capture timer immediately to prevent buffer overflow
        _captureTimer?.cancel();
        _captureTimer = null;

        // Move to next step
        _moveToNextStep();
      } else {
        print(
          'Face angle not correct for ${_currentStep.name}, trying again...',
        );
        setState(() {
          _busy = false; // Reset busy state to allow retry
        });
      }
    } catch (e) {
      print('Capture attempt failed: $e');
      setState(() {
        _busy = false; // Reset busy state on error
      });

      // If capture fails repeatedly, stop the timer to prevent buffer overflow
      if (e.toString().contains('buffer') ||
          e.toString().contains('ImageReader') ||
          e.toString().contains('Unable to acquire')) {
        _captureTimer?.cancel();
        _captureTimer = null;
        setState(() {
          _error =
              'Camera buffer overflow detected. Please restart enrollment.';
          _status = 'Camera error - please restart';
        });
        print('🚨 Camera buffer overflow detected - stopping capture timer');
      }
    }
  }

  Future<Map<String, dynamic>> _checkFaceDuplicate(
    List<double> embedding,
  ) async {
    try {
      // Check if this face embedding already exists for another user
      final response = await FaceApiService.checkFaceDuplicate(
        embedding: embedding,
      );
      return {
        'isDuplicate': response['status'] == 'duplicate_found',
        'message': response['message'] ?? 'Face check completed',
      };
    } catch (e) {
      print('Face duplicate check failed: $e');
      return {
        'isDuplicate': false,
        'message': 'Unable to check face uniqueness',
      };
    }
  }

  bool _isFaceAngleCorrect(Face face) {
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;

    // For left angle, check if head is turned left (negative Y angle)
    if (_currentStep == EnrollmentStep.left) {
      // More lenient: accept if turned left (negative Y) OR turned left on Z axis
      final isLeftY = headEulerAngleY <= -8.0; // Left turn on Y axis
      final isLeftZ = headEulerAngleZ <= -8.0; // Left turn on Z axis
      print(
        '🔍 Left check: Y=$headEulerAngleY (need <=-8), Z=$headEulerAngleZ (need <=-8) -> ${isLeftY || isLeftZ}',
      );
      return isLeftY || isLeftZ;
    }

    // For right angle, check if head is turned right (positive Y angle)
    if (_currentStep == EnrollmentStep.right) {
      // More lenient: accept if turned right (positive Y) OR turned right on Z axis
      final isRightY = headEulerAngleY >= 8.0; // Right turn on Y axis
      final isRightZ = headEulerAngleZ >= 8.0; // Right turn on Z axis
      print(
        '🔍 Right check: Y=$headEulerAngleY (need >=8), Z=$headEulerAngleZ (need >=8) -> ${isRightY || isRightZ}',
      );
      return isRightY || isRightZ;
    }

    // For straight, check if head is centered
    if (_currentStep == EnrollmentStep.straight) {
      // More lenient: within 15 degrees of center on both axes
      final isCenteredY = headEulerAngleY.abs() <= 15.0;
      final isCenteredZ = headEulerAngleZ.abs() <= 15.0;
      print(
        '🔍 Straight check: Y=$headEulerAngleY (need |<=15|), Z=$headEulerAngleZ (need |<=15|) -> ${isCenteredY && isCenteredZ}',
      );
      return isCenteredY && isCenteredZ;
    }

    return false;
  }

  void _moveToNextStep() {
    setState(() {
      _busy = false;
    });

    switch (_currentStep) {
      case EnrollmentStep.straight:
        setState(() {
          _currentStep = EnrollmentStep.right;
          _status = 'Moving to right angle capture...';
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _captureCurrentStep();
        });
        break;
      case EnrollmentStep.right:
        setState(() {
          _currentStep = EnrollmentStep.left;
          _status = 'Moving to left angle capture...';
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _captureCurrentStep();
        });
        break;
      case EnrollmentStep.left:
        // Stop any running timer before processing
        _captureTimer?.cancel();
        _captureTimer = null;

        setState(() {
          _status = 'All faces captured. Processing enrollment...';
        });
        _processEnrollment();
        break;
      default:
        break;
    }
  }

  Future<void> _processEnrollment() async {
    print('🔄 Starting enrollment process with ${_capturedFaces.length} faces');

    // Ensure timer is stopped before processing
    _captureTimer?.cancel();
    _captureTimer = null;

    setState(() {
      _currentStep = EnrollmentStep.processing;
      _busy = true;
    });

    try {
      final staffId = SessionManager.instance.teacherId?.toString();
      if (staffId == null || staffId.isEmpty) {
        setState(() {
          _error = 'No user session. Please login again.';
        });
        return;
      }

      // Validate that we have all three captured faces
      if (_capturedFaces.length < 3) {
        setState(() {
          _error = 'Incomplete face capture. Please try again.';
          _currentStep = EnrollmentStep.straight;
          _capturedFaces.clear();
          _busy = false;
        });
        return;
      }

      // Use all three captured faces for enrollment with null safety
      final straightFace = _capturedFaces[0];
      final rightFace = _capturedFaces[1];
      final leftFace = _capturedFaces[2];

      print('📊 Face data validation:');
      print(
        '  Straight face: valid, embedding length: ${straightFace.embedding.length}',
      );
      print(
        '  Right face: valid, embedding length: ${rightFace.embedding.length}',
      );
      print(
        '  Left face: valid, embedding length: ${leftFace.embedding.length}',
      );

      // Additional null safety checks
      if (straightFace.embedding.isEmpty ||
          rightFace.embedding.isEmpty ||
          leftFace.embedding.isEmpty) {
        setState(() {
          _error = 'Invalid face data captured. Please try again.';
          _currentStep = EnrollmentStep.straight;
          _capturedFaces.clear();
          _busy = false;
        });
        return;
      }

      // STEP 1: Check for duplicate face before enrolling (use multi-face duplicate check)
      print('🔍 Checking for duplicate face...');
      final duplicateCheck = await FaceApiService.checkFaceDuplicateMultiAngle(
        straightEmbedding: straightFace.embedding,
        rightEmbedding: rightFace.embedding,
        leftEmbedding: leftFace.embedding,
        staffId: staffId,
      );
      print('🔍 Duplicate check result: $duplicateCheck');

      if (!mounted) return;

      if (duplicateCheck['status'] == 'duplicate_found') {
        setState(() {
          _error =
              'This face is already registered to another user. Please use a different face or contact admin.';
          _currentStep = EnrollmentStep.straight;
          _capturedFaces.clear();
          _busy = false;
        });
        return;
      } else if (duplicateCheck['status'] == 'error') {
        setState(() {
          _error =
              'Failed to check for duplicates: ${duplicateCheck['message']}';
          _currentStep = EnrollmentStep.straight;
          _capturedFaces.clear();
          _busy = false;
        });
        return;
      }

      // STEP 2: If no duplicate, proceed with enrollment
      print('✅ No duplicate found, proceeding with multi-angle enrollment...');
      print('📤 Sending enrollment request to server...');
      final resp = await FaceApiService.enrollFaceMultiAngle(
        staffId: staffId,
        straightEmbedding: straightFace.embedding,
        rightEmbedding: rightFace.embedding,
        leftEmbedding: leftFace.embedding,
      );

      if (!mounted) return;

      // Print full response for debugging
      print('📥 Enrollment Response: $resp');
      print('📥 Response Status: ${resp['status']}');
      print('📥 Response Message: ${resp['message'] ?? 'No message'}');

      // Check if response is valid
      if (resp.isEmpty) {
        print('❌ Error: Empty response from server');
        setState(() {
          _error = 'No response from server. Please try again.';
          _busy = false;
        });
        return;
      }

      if (resp['status'] == 'success') {
        print('✅ Enrollment successful! Status: ${resp['status']}');
        final successMessage =
            resp['message']?.toString() ??
            'Face enrolled successfully with multiple angles!';
        print('✅ Success message: $successMessage');

        setState(() {
          _currentStep = EnrollmentStep.completed;
          _busy = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      } else {
        final errorMessage = resp['message']?.toString() ?? 'Enrollment failed';
        print('❌ Enrollment failed. Status: ${resp['status']}');
        print('❌ Error message: $errorMessage');
        print('❌ Full error response: $resp');

        setState(() {
          _error = errorMessage;
          _busy = false;
          _currentStep = EnrollmentStep.straight;
          _capturedFaces.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Enrollment Exception: $e');
      print('❌ Stack Trace: $stackTrace');
      setState(() {
        _error = 'Enrollment failed: ${e.toString()}';
        _busy = false;
        _currentStep = EnrollmentStep.straight;
        _capturedFaces.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enrollment error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  void dispose() {
    // Cancel any running timers
    _captureTimer?.cancel();
    _captureTimer = null;
    _livenessCheckTimer?.cancel();
    _livenessCheckTimer = null;

    // Clear liveness tracking
    _leftEyeHistory.clear();
    _rightEyeHistory.clear();

    // Properly dispose camera controller
    _controller?.dispose();
    _controller = null;

    // Clear captured faces
    _capturedFaces.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Face Enrollment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                // Camera preview
                Positioned.fill(
                  child: _controller != null
                      ? CameraPreview(_controller!)
                      : const SizedBox.shrink(),
                ),

                // Simple 3-dot progress indicator at top
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: _buildSimpleProgressIndicator(),
                ),

                // Error message overlay
                if (_error != null)
                  Positioned(
                    top: 120,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _error = null),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomOverlay(),
                ),
              ],
            ),
    );
  }

  Widget _buildSimpleProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simple instruction text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getCurrentInstruction(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 3 dots progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSimpleDot(0, 'Straight'),
              const SizedBox(width: 20),
              _buildSimpleDot(1, 'Right'),
              const SizedBox(width: 20),
              _buildSimpleDot(2, 'Left'),
            ],
          ),
          const SizedBox(height: 12),
          // Small progress line
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withOpacity(0.2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _capturedFaces.length / 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      _stepConfig[_currentStep]!['color'],
                      _stepConfig[_currentStep]!['color'].withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleDot(int index, String label) {
    final isCompleted = _capturedFaces.length > index;
    final isCurrent = _capturedFaces.length == index;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isCurrent
                ? _stepConfig[_currentStep]!['color'] as Color
                : Colors.grey.withOpacity(0.5),
            border: isCurrent
                ? Border.all(color: Colors.white, width: 2)
                : null,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: (_stepConfig[_currentStep]!['color'] as Color)
                          .withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 12)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _getCurrentInstruction() {
    switch (_currentStep) {
      case EnrollmentStep.straight:
        return 'Look Straight';
      case EnrollmentStep.right:
        return 'Look Right';
      case EnrollmentStep.left:
        return 'Look Left';
      case EnrollmentStep.processing:
        return 'Processing...';
      case EnrollmentStep.completed:
        return 'Completed!';
    }
  }

  Widget _buildBottomOverlay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
            Colors.black,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress section
          if (_currentStep == EnrollmentStep.processing)
            const Column(
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                SizedBox(height: 16),
                Text(
                  'Processing enrollment...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else if (_currentStep == EnrollmentStep.completed)
            const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(
                  'Enrollment completed successfully!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Text(
                  'Captured: ${_capturedFaces.length}/3',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _capturedFaces.length / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [
                            _stepConfig[_currentStep]!['color'],
                            _stepConfig[_currentStep]!['color'].withOpacity(
                              0.7,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (_currentStep == EnrollmentStep.completed) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  int _getCurrentStepIndex() {
    switch (_currentStep) {
      case EnrollmentStep.straight:
        return 0;
      case EnrollmentStep.right:
        return 1;
      case EnrollmentStep.left:
        return 2;
      default:
        return 0;
    }
  }
}

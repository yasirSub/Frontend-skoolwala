// ignore_for_file: deprecated_member_use, prefer_is_empty, use_build_context_synchronously, prefer_final_fields, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:skoolwala/features/attendance/services/google_ml_face_service.dart';
import 'package:skoolwala/features/face/services/face_api_service.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/features/teacher_attendance/simple/spoofing_detector.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum EnrollmentStep { straight, right, left, processing, completed }

class MultiAngleEnrollScreen extends StatefulWidget {
  const MultiAngleEnrollScreen({super.key});

  @override
  State<MultiAngleEnrollScreen> createState() => _MultiAngleEnrollScreenState();
}

class _MultiAngleEnrollScreenState extends State<MultiAngleEnrollScreen> {
  final FlutterTts _tts = FlutterTts();
  CameraController? _controller;
  bool _ready = false;
  bool _busy = false;
  String? _error;
  String _status = 'Initializing...';

  EnrollmentStep _currentStep = EnrollmentStep.straight;
  Timer? _captureTimer;
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
    _initTTS();
    _init();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  void _playSuccessFeedback() {
    HapticFeedback.lightImpact(); // Quick tap for each step
    SystemSound.play(SystemSoundType.click);
    _speak("Captured!");
  }

  void _playFinalSuccessFeedback() {
    // Distinct triple pulse for final success
    Future.delayed(Duration.zero, () => HapticFeedback.heavyImpact());
    Future.delayed(
      const Duration(milliseconds: 150),
      () => HapticFeedback.heavyImpact(),
    );
    Future.delayed(
      const Duration(milliseconds: 300),
      () => HapticFeedback.heavyImpact(),
    );
    _speak("Enrollment successful. Thank you.");
  }

  void _playErrorFeedback() {
    HapticFeedback.vibrate(); // Long vibrate for errors
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
        // High is overkill for 112x112 embeddings and can cause UI jank.
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await ctrl.initialize();

      // Zoom in a bit so mostly the face is visible in the circle.
      // This is intentionally conservative to avoid over-zoom on low-end devices.
      await _applyDefaultZoom(ctrl);

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

  Future<void> _applyDefaultZoom(CameraController ctrl) async {
    try {
      final minZoom = await ctrl.getMinZoomLevel();
      final maxZoom = await ctrl.getMaxZoomLevel();

      // Aim for a "face-friendly" framing.
      // If the device supports less, clamp automatically.
      const targetZoom = 1.8;
      final zoom = targetZoom.clamp(minZoom, maxZoom);
      await ctrl.setZoomLevel(zoom);
    } catch (_) {
      // Some devices/OS versions may not support zoom; ignore.
    }
  }

  void _startEnrollmentProcess() {
    // Start with straight capture after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      _speak("Look straight at the camera");
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

    // Reset liveness tracking when starting new step
    _leftEyeHistory.clear();
    _rightEyeHistory.clear();
    _blinkCount = 0;
    _hasDetectedBlink = false;
    _hasDetectedMovement = false;

    // Much slower timer for actual capture attempts
    _captureTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_busy) return; // Don't capture if already busy
      if (_capturedFaces.length >= 3) {
        // Stop timer if we already have all 3 faces
        timer.cancel();
        _captureTimer = null;
        return;
      }
      _attemptCapture();
    });
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

      // Update liveness history opportunistically (we only capture every 3s).
      final leftEye = result.face.leftEyeOpenProbability;
      final rightEye = result.face.rightEyeOpenProbability;
      _leftEyeHistory.add(leftEye);
      _rightEyeHistory.add(rightEye);
      if (_leftEyeHistory.length > 10) {
        _leftEyeHistory.removeAt(0);
      }
      if (_rightEyeHistory.length > 10) {
        _rightEyeHistory.removeAt(0);
      }

      // Blink / micro-movement detection on stored history.
      if (_leftEyeHistory.length >= 4) {
        for (int i = 1; i < _leftEyeHistory.length - 1; i++) {
          final prev = _leftEyeHistory[i - 1];
          final curr = _leftEyeHistory[i];
          final next = _leftEyeHistory[i + 1];

          if (prev != null && curr != null && next != null) {
            if (prev > 0.7 && curr < 0.3 && next > 0.7) {
              _blinkCount++;
              _hasDetectedBlink = true;
              break;
            }

            if ((prev - curr).abs() > 0.05 || (curr - next).abs() > 0.05) {
              _hasDetectedMovement = true;
            }

            if (_rightEyeHistory.length > i) {
              final rightPrev = _rightEyeHistory[i - 1];
              final rightCurr = _rightEyeHistory[i];
              if (rightPrev != null && rightCurr != null) {
                final leftRightDiff =
                    (prev - rightPrev).abs() + (curr - rightCurr).abs();
                if (leftRightDiff > 0.1) {
                  _hasDetectedMovement = true;
                }
              }
            }
          }
        }
      }

      print(
        '🧪 Liveness debug: blinkCount=$_blinkCount, blink=$_hasDetectedBlink, movement=$_hasDetectedMovement',
      );

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
          _playSuccessFeedback();
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
        _speak("Now turn your head to the right");
        Future.delayed(const Duration(milliseconds: 1500), () {
          _captureCurrentStep();
        });
        break;
      case EnrollmentStep.right:
        setState(() {
          _currentStep = EnrollmentStep.left;
          _status = 'Moving to left angle capture...';
        });
        _speak("Now turn your head to the left");
        Future.delayed(const Duration(milliseconds: 1500), () {
          _captureCurrentStep();
        });
        break;
      case EnrollmentStep.left:
        // Stop any running timer before processing
        _captureTimer?.cancel();
        _captureTimer = null;

        _speak("Face capture complete. Enrolling now.");
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
        _playErrorFeedback();
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
        _playErrorFeedback();
        setState(() {
          _error =
              'This face is already registered to another user. Please use a different face or contact admin.';
          _currentStep = EnrollmentStep.straight;
          _capturedFaces.clear();
          _busy = false;
        });
        return;
      } else if (duplicateCheck['status'] == 'error') {
        _playErrorFeedback();
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
        _playFinalSuccessFeedback();
        final successMessage =
            resp['message']?.toString() ??
            'Face enrolled successfully with multiple angles!';
        print('✅ Success message: $successMessage');

        setState(() {
          _currentStep = EnrollmentStep.completed;
          _busy = false;
        });

        // Update local session so the dashboard doesn't immediately ask
        // the user to enroll again (backend may still refresh shortly after).
        final currentTeacher = SessionManager.instance.currentTeacher;
        if (currentTeacher != null) {
          await SessionManager.instance.updateTeacherData(
            currentTeacher.copyWith(faceEnrolled: true),
          );
        }

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
        _playErrorFeedback();
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

    // Clear liveness tracking
    _leftEyeHistory.clear();
    _rightEyeHistory.clear();

    // Properly dispose camera controller
    _controller?.dispose();
    _controller = null;

    // Clear captured faces
    _capturedFaces.clear();

    // Stop TTS
    _tts.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: AppTheme.darkPurple.withOpacity(0.5)),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'BIOMETRIC ENROLLMENT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: !_ready
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : Stack(
              children: [
                // Background Gradient (App-consistent vibrant purple)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.dashboardPrimary.withOpacity(0.8),
                        AppTheme.darkPurple,
                        Colors.black,
                      ],
                    ),
                  ),
                ),

                // Technical Grid Pattern
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                ),

                // Radial Glow Effect
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentCyan.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      _buildStepProgressHeader(),
                      Expanded(child: Center(child: _buildCameraView())),
                      _buildBottomOverlay(),
                    ],
                  ),
                ),

                // Error message overlay
                if (_error != null)
                  Positioned(
                    top: 100,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _error = null),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStepProgressHeader() {
    final labels = ['STRAIGHT', 'RIGHT', 'LEFT'];
    final icons = [
      Icons.face,
      Icons.face_retouching_natural,
      Icons.face_retouching_natural,
    ];

    Color stepColor(int index) {
      final done = _capturedFaces.length > index;
      final current = _capturedFaces.length == index;
      return done
          ? AppTheme.accentGreen
          : (current ? AppTheme.accentCyan : Colors.white.withOpacity(0.2));
    }

    Widget buildStep(int index) {
      final done = _capturedFaces.length > index;
      final current = _capturedFaces.length == index;
      final color = stepColor(index);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: current ? color.withOpacity(0.15) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(current ? 1.0 : 0.4),
                width: current ? 3 : 1.5,
              ),
              boxShadow: [
                if (current)
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Icon(
              done ? Icons.check_circle_rounded : icons[index],
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            labels[index],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      );
    }

    Widget buildConnector(int leftStepIndex) {
      final leftColor = stepColor(leftStepIndex);
      final rightDone = _capturedFaces.length > leftStepIndex + 1;

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              leftColor.withOpacity(0.3),
              rightDone ? AppTheme.accentGreen : Colors.white.withOpacity(0.1),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Center(child: buildStep(0))),
          Expanded(flex: 2, child: Center(child: buildConnector(0))),
          Expanded(child: Center(child: buildStep(1))),
          Expanded(flex: 2, child: Center(child: buildConnector(1))),
          Expanded(child: Center(child: buildStep(2))),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_controller == null || !_controller!.value.isInitialized)
      return const SizedBox.shrink();

    final boxColor = _currentStep == EnrollmentStep.processing
        ? AppTheme.accentGreen
        : AppTheme.accentCyan;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Camera Preview Circle with Scanning Animation
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(child: _buildCroppedCameraPreview()),
                  _ScanningLine(color: boxColor),
                ],
              ),
            ),
          ),

          // Techy Frame Overlays
          // Outer Glow
          _CameraGlow(color: boxColor),

          // Corner Guides
          ...List.generate(4, (i) => _buildCircularCorner(i, boxColor)),

          // Instruction Label
          Positioned(
            bottom: -25,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkPurple.withOpacity(0.72),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: boxColor.withOpacity(0.3)),
              ),
              child: Text(
                _getCurrentInstruction().toUpperCase(),
                style: TextStyle(
                  color: boxColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Step Icon Indicator
          if (_currentStep != EnrollmentStep.processing &&
              _currentStep != EnrollmentStep.completed)
            Positioned(
              top: -30,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: boxColor.withOpacity(0.3)),
                ),
                child: Icon(
                  _stepConfig[_currentStep]!['icon'] as IconData,
                  color: boxColor,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCroppedCameraPreview() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const SizedBox.shrink();
    }

    // Use BoxFit.cover so the preview fills the circle and gets center-cropped.
    // This avoids "top/side" letterboxing on different aspect ratios.
    final previewSize = ctrl.value.previewSize;

    if (previewSize == null) {
      return CameraPreview(ctrl);
    }

    // NOTE: previewSize is in landscape on Android; swap for portrait.
    final width = previewSize.height;
    final height = previewSize.width;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(width: width, height: height, child: CameraPreview(ctrl)),
    );
  }

  Widget _buildCircularCorner(int index, Color color) {
    final angles = [0.0, 1.57, 3.14, 4.71];
    return Transform.rotate(
      angle: angles[index],
      child: SizedBox(
        width: 340,
        height: 340,
        child: CustomPaint(painter: _CornerPainter(color: color)),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: BoxDecoration(
        color: AppTheme.darkPurple.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentStep == EnrollmentStep.processing)
            Column(
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: AppTheme.accentCyan,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'LINKING BIOMETRIC DATA...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            )
          else if (_currentStep == EnrollmentStep.completed)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successGreen,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ENROLLMENT SUCCESSFUL',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CAPTURED: ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${_capturedFaces.length}/3',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _status.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                // Cancel button for enrollment
                if (_currentStep != EnrollmentStep.completed)
                  TextButton(
                    onPressed: _currentStep == EnrollmentStep.processing
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'CANCEL ENROLLMENT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'ABORT',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              if (_currentStep == EnrollmentStep.completed) ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
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

  String _getCurrentInstruction() {
    switch (_currentStep) {
      case EnrollmentStep.straight:
        return 'Look Straight';
      case EnrollmentStep.right:
        return 'Turn Right';
      case EnrollmentStep.left:
        return 'Turn Left';
      case EnrollmentStep.processing:
        return 'Processing...';
      case EnrollmentStep.completed:
        return 'Completed!';
    }
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

/// Helper widget for camera glow animation
class _CameraGlow extends StatefulWidget {
  final Color color;
  const _CameraGlow({required this.color});

  @override
  State<_CameraGlow> createState() => _CameraGlowState();
}

class _CameraGlowState extends State<_CameraGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.1 + (0.1 * _ctrl.value)),
                blurRadius: 20 + (20 * _ctrl.value),
                spreadRadius: 2 * _ctrl.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    const double step = 30.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const double len = 40;
    const double rad = 170; // Half of 340

    // Top-left corner stylized
    path.moveTo(size.width / 2 - rad, size.height / 2 - rad + len);
    path.lineTo(size.width / 2 - rad, size.height / 2 - rad);
    path.lineTo(size.width / 2 - rad + len, size.height / 2 - rad);

    canvas.drawPath(path, paint);

    // Minor decorative dots/lines
    final dotPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(size.width / 2 - rad - 10, size.height / 2 - rad - 10),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _ScanningLine extends StatefulWidget {
  final Color color;
  const _ScanningLine({required this.color});

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          top: -100 + (400 * _ctrl.value),
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.color.withOpacity(0),
                  widget.color.withOpacity(0.3),
                  widget.color.withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

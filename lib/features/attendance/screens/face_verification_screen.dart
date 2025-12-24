// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:skoolwala/features/attendance/services/face_recognition_service.dart';
import 'package:skoolwala/features/attendance/services/google_ml_face_service.dart';
import 'package:skoolwala/features/face/services/face_api_service.dart';
import 'package:skoolwala/features/attendance/services/face_attendance_service.dart';
import 'package:skoolwala/features/attendance/services/location_service.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/features/attendance/services/attendance_service.dart';
import 'package:skoolwala/features/teacher_attendance/simple/spoofing_detector.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'dart:ui';

class FaceVerificationScreen extends StatefulWidget {
  final bool verifyMode; // false => enroll, true => verify
  const FaceVerificationScreen({super.key, this.verifyMode = false});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isFaceDetected = false;
  String? _errorMessage;
  String _statusMessage = 'Position your face in the circle';
  final bool _useMLKit =
      true; // Toggle between mock and real ML Kit - enabled for camera
  // Multi-angle enrollment state
  final List<String> _enrollAngles = const ['center', 'left', 'right'];
  int _currentAngleIndex = 0; // 0=center,1=left,2=right
  bool _isTargetAngleSatisfied = false; // head pose satisfied for target angle
  // Hold per-angle embeddings for averaging
  final List<List<double>?> _angleEmbeddings = [null, null, null];
  // Track completion per step (center, left, right)
  final List<bool> _stepsCompleted = [false, false, false];
  // Basic liveness (anti-spoofing) heuristics
  bool _livenessPassed = false;
  double? _lastLeftEye;
  double? _lastRightEye;
  int _livenessEvents = 0; // eye state changes
  // Removed captures count; angle flow is tracked by index only

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  // Auto-capture when conditions are satisfied
  Timer? _autoCaptureTimer;
  bool _autoCaptureArmed = false; // prevents repeated scheduling
  bool _captureInFlight = false; // prevent overlapping takePicture calls

  // Location verification state
  final bool _locationVerified = false;
  bool _locationVerificationRequired = false;

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
      // Debug: Print current teacher ID if available
      try {
        final teacherId = SessionManager.instance.teacherId;
        print('👤 Current Teacher ID: ${teacherId ?? 'unknown'}');
      } catch (_) {}

      // Request location permission
      final hasLocationPermission =
          await LocationService.hasLocationPermission();
      if (!hasLocationPermission) {
        final granted = await LocationService.requestLocationPermission();
        if (!granted) {
          setState(() {
            _errorMessage =
                'Location permission is required for attendance verification';
          });
          return;
        }
      }

      if (_useMLKit) {
        // Initialize real camera and ML Kit
        await _initializeCamera();
      } else {
        // Simulate initialization delay for mock mode
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // Check if location verification is required
      final sessionManager = SessionManager.instance;
      final currentTeacher = sessionManager.currentTeacher;
      if (currentTeacher != null) {
        final isRequired = await LocationService.isLocationVerificationRequired(
          currentTeacher.branchId.toString(),
        );
        setState(() {
          _locationVerificationRequired = isRequired;
        });
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permissions first
      await _requestCameraPermission();

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      // Find front camera for face verification
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      // Use front camera if available, otherwise fall back to first camera
      final selectedCamera = frontCamera ?? _cameras![0];

      print('📷 Using camera: ${selectedCamera.lensDirection.name} camera');

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Start real-time face detection
      if (_useMLKit) {
        _startFaceDetection();
      }
    } catch (e) {
      throw Exception('Camera initialization failed: $e');
    }
  }

  Timer? _faceDetectionTimer;
  bool _isCapturingFrame = false; // Prevent overlapping captures

  void _startFaceDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // Cancel any existing timer
    _faceDetectionTimer?.cancel();

    // Start a timer to periodically check for faces using real ML Kit detection
    _faceDetectionTimer = Timer.periodic(const Duration(milliseconds: 700), (
      timer,
    ) async {
      if (!mounted ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _isCapturingFrame) {
        // Prevent overlapping captures
        timer.cancel();
        return;
      }

      try {
        _isCapturingFrame = true; // Set flag to prevent overlapping captures

        // Capture a frame for face detection with timeout
        final XFile imageFile = await _cameraController!.takePicture().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Camera capture timeout');
          },
        );

        // Use Google ML Kit to detect faces in the captured frame
        final result = await GoogleMLFaceService.processCameraImage(imageFile);

        // Clean up the temporary image file
        final File file = File(imageFile.path);
        if (await file.exists()) {
          await file.delete();
        }

        // Check head pose against current target angle during enrollment
        bool targetOk = false;
        if (result != null && !widget.verifyMode) {
          final face = result.face;
          final double yaw = (face.headEulerAngleY ?? 0)
              .toDouble(); // left/right rotation
          final String target = _enrollAngles[_currentAngleIndex];
          if (target == 'center') {
            targetOk = yaw.abs() <= 12; // more tolerant straight
          } else if (target == 'left') {
            targetOk = yaw <= -12; // more tolerant left
          } else if (target == 'right') {
            targetOk = yaw >= 12; // more tolerant right
          }
        }

        // Update basic liveness using eye open probabilities
        if (result != null) {
          final face = result.face;
          final double? lEye = face.leftEyeOpenProbability;
          final double? rEye = face.rightEyeOpenProbability;
          if (lEye != null && rEye != null) {
            if (_lastLeftEye != null && _lastRightEye != null) {
              final bool leftChanged = (lEye - _lastLeftEye!).abs() > 0.35;
              final bool rightChanged = (rEye - _lastRightEye!).abs() > 0.35;
              if (leftChanged || rightChanged) {
                _livenessEvents = (_livenessEvents + 1).clamp(0, 3);
              }
            }
            _lastLeftEye = lEye;
            _lastRightEye = rEye;
          }
          // Enhanced liveness check with strict spoofing detection
          final isLiveFace = SpoofingDetector.isLiveFace(
            result.face,
            strict: true,
          );
          final hasLiveness = SpoofingDetector.checkLiveness(
            result.face,
            strict: true,
          );
          _livenessPassed =
              _livenessEvents >= 2 &&
              (result.confidence >= 0.7) &&
              isLiveFace &&
              hasLiveness;
        } else {
          _livenessPassed = false;
          _lastLeftEye = null;
          _lastRightEye = null;
          _livenessEvents = 0;
        }

        if (mounted) {
          setState(() {
            _isFaceDetected = result != null && result.confidence >= 0.6;
            _isTargetAngleSatisfied =
                _isFaceDetected && (widget.verifyMode ? true : targetOk);
          });
        }

        // Auto-capture logic
        if (_isFaceDetected && !_isProcessing) {
          final readyForCapture = widget.verifyMode
              ? true
              : (_isTargetAngleSatisfied && _livenessPassed);

          if (readyForCapture && !_autoCaptureArmed) {
            _autoCaptureArmed = true;
            _autoCaptureTimer?.cancel();
            _autoCaptureTimer = Timer(const Duration(milliseconds: 900), () {
              if (!mounted) return;
              // Re-check before firing to avoid stale state
              if (_isFaceDetected && !_isProcessing) {
                if (widget.verifyMode ||
                    (_isTargetAngleSatisfied && _livenessPassed)) {
                  _captureAndVerifyFace();
                }
              }
              _autoCaptureArmed = false;
            });
          }
          // If conditions not ready anymore, disarm
          if (!readyForCapture && _autoCaptureArmed) {
            _autoCaptureTimer?.cancel();
            _autoCaptureArmed = false;
          }
        } else {
          // Not detected or already processing: ensure no pending timer
          if (_autoCaptureArmed) {
            _autoCaptureTimer?.cancel();
            _autoCaptureArmed = false;
          }
        }
      } catch (e) {
        print('Face detection error: $e');
        if (mounted) {
          setState(() {
            _isFaceDetected = false;
            _isTargetAngleSatisfied = false;
          });
        }
        // Cancel any pending auto-capture on error
        if (_autoCaptureArmed) {
          _autoCaptureTimer?.cancel();
          _autoCaptureArmed = false;
        }
      } finally {
        // Always reset the capture flag to allow next capture
        _isCapturingFrame = false;
      }
    });
  }

  void _stopFaceDetection() {
    _faceDetectionTimer?.cancel();
    _faceDetectionTimer = null;
    _autoCaptureTimer?.cancel();
    _autoCaptureArmed = false;
    _isCapturingFrame = false; // Reset capture flag
  }

  Future<void> _requestCameraPermission() async {
    // For now, we'll use a simple approach since permission_handler is commented out
    // The camera package should handle permissions automatically when calling availableCameras()
    // But we can add a delay to ensure permissions are processed
    await Future.delayed(const Duration(milliseconds: 500));

    // Note: Proper permission handling can be enabled when permission_handler is added
    // Example:
    // final status = await Permission.camera.request();
    // if (!status.isGranted) {
    //   throw Exception('Camera permission denied');
    // }
  }

  Future<void> _captureAndVerifyFace() async {
    if (_captureInFlight || _isCapturingFrame) {
      return; // drop if a capture is already running
    }
    _captureInFlight = true;
    _isCapturingFrame = true; // Also set frame capture flag
    // stop any pending auto-capture to avoid double triggers
    _autoCaptureTimer?.cancel();
    _autoCaptureArmed = false;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = 'Processing...';
    });

    try {
      String? faceData;

      if (_useMLKit && _cameraController != null) {
        // Check if face is detected in the overlay first
        if (!_isFaceDetected) {
          setState(() {
            _errorMessage =
                'Please position your face within the frame first. Wait for the green circle.';
          });
          return;
        }

        // During enrollment flow require target angle satisfaction + liveness
        if (!widget.verifyMode &&
            (!_isTargetAngleSatisfied || !_livenessPassed)) {
          setState(() {
            final target = _enrollAngles[_currentAngleIndex];
            _errorMessage = !_isTargetAngleSatisfied
                ? (target == 'center'
                      ? 'Look straight at the camera.'
                      : (target == 'left'
                            ? 'Turn your face to the LEFT slightly.'
                            : 'Turn your face to the RIGHT slightly.'))
                : 'Please blink naturally to verify liveness and use your live face (not a photo).';
          });
          return;
        }

        // Get current location if location verification is required
        Map<String, dynamic>? locationData;
        if (_locationVerificationRequired) {
          locationData = await LocationService.getCurrentLocation();
          if (locationData == null) {
            setState(() {
              _errorMessage =
                  'Unable to get current location. Please ensure location services are enabled.';
            });
            return;
          }
        }

        // Use real Google ML Kit face detection with proper recognition
        final XFile image = await _cameraController!.takePicture().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Camera capture timeout during verification');
          },
        );
        final result = await GoogleMLFaceService.processCameraImage(image);

        if (result != null) {
          // Check face confidence
          if (result.confidence < 0.6) {
            setState(() {
              _errorMessage =
                  'Face quality is too low. Please ensure good lighting and look directly at the camera.';
            });
            return;
          }

          // SPOOFING PROTECTION: During verification, check for photo spoofing (STRICT MODE)
          if (widget.verifyMode) {
            final face = result.face;
            if (!SpoofingDetector.isLiveFace(face, strict: true)) {
              final spoofingMessage = SpoofingDetector.getSpoofingMessage(face);
              setState(() {
                _errorMessage = spoofingMessage;
              });
              print(
                '⚠️ Spoofing detected during verification: $spoofingMessage',
              );
              return;
            }

            if (!SpoofingDetector.checkLiveness(face, strict: true)) {
              setState(() {
                _errorMessage =
                    'Please use your live face. Photos or screens are not accepted. Blink naturally.';
              });
              print('⚠️ Liveness check failed during verification');
              return;
            }
          }

          // SPOOFING PROTECTION: During enrollment, check for photo spoofing (LENIENT MODE)
          if (!widget.verifyMode) {
            final face = result.face;
            if (!SpoofingDetector.isLiveFace(face, strict: false)) {
              final spoofingMessage = SpoofingDetector.getSpoofingMessage(face);
              setState(() {
                _errorMessage = spoofingMessage;
              });
              print('⚠️ Spoofing detected during enrollment: $spoofingMessage');
              return;
            }

            if (!SpoofingDetector.checkLiveness(face, strict: false)) {
              setState(() {
                _errorMessage =
                    'Please use your live face. Blink naturally and ensure good lighting.';
              });
              print('⚠️ Liveness check failed during enrollment');
              return;
            }
          }

          // Add a small delay to show the success state
          await Future.delayed(const Duration(milliseconds: 400));

          if (widget.verifyMode) {
            // Identify against backend and confirm current teacher
            setState(() {
              _statusMessage = 'Verifying face...';
            });

            final idResp = await FaceApiService.identifyFace(
              embedding: result.embedding,
              latitude: locationData?['latitude'],
              longitude: locationData?['longitude'],
            );

            if (idResp['status'] == 'success' && idResp['matched'] == true) {
              final matchedStaffId = idResp['staff_id']?.toString();
              final currentId = SessionManager.instance.currentTeacher?.id
                  .toString();
              if (matchedStaffId != null &&
                  currentId != null &&
                  matchedStaffId == currentId) {
                setState(() {
                  _statusMessage = 'Face verified!';
                });
                await _verifyFaceWithResult(result, locationData);
              } else {
                setState(() {
                  _errorMessage = 'Face matches a different user';
                  _statusMessage = 'Face not recognized';
                });
              }
            } else {
              final message = idResp['message'] ?? 'Face not recognized';
              setState(() {
                _errorMessage = message;
                _statusMessage = message;
              });
            }
          } else {
            // Store current embedding for this step
            _angleEmbeddings[_currentAngleIndex] = result.embedding;
            _stepsCompleted[_currentAngleIndex] = true;

            if (_currentAngleIndex < _enrollAngles.length - 1) {
              // Move to next target angle
              setState(() {
                _currentAngleIndex += 1;
                _isTargetAngleSatisfied = false;
                _errorMessage = null;
              });
            } else {
              // Final angle captured — average embeddings and submit
              final averaged = _averageEmbeddings(_angleEmbeddings);
              await _submitEnrollmentEmbedding(averaged);
              // Reset flow for next time
              setState(() {
                _currentAngleIndex = 0;
                _isTargetAngleSatisfied = false;
                _livenessPassed = false;
                _livenessEvents = 0;
                _lastLeftEye = null;
                _lastRightEye = null;
                for (int i = 0; i < _angleEmbeddings.length; i++) {
                  _angleEmbeddings[i] = null;
                  _stepsCompleted[i] = false;
                }
              });
            }
          }
        } else {
          setState(() {
            _errorMessage =
                'Face detection failed. Please ensure your face is clearly visible and try again.';
          });
        }
      } else {
        // Use mock face data for testing
        faceData = await FaceRecognitionService.generateMockFaceData();

        setState(() {
          _isFaceDetected = true;
        });

        // Add a small delay to show the success state
        await Future.delayed(const Duration(milliseconds: 500));

        if (widget.verifyMode) {
          await _verifyFace(faceData);
        } else {
          await _enrollFace(faceData);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Face verification failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Position your face in the circle';
      });
      _captureInFlight = false;
      _isCapturingFrame = false; // Reset frame capture flag
    }
  }

  // Removed unused _markAttendanceWithFaceData method (local-only storage)

  /// Get current location for attendance
  List<double> _averageEmbeddings(List<List<double>?> parts) {
    final valid = parts.where((e) => e != null).cast<List<double>>().toList();
    if (valid.isEmpty) return [];
    final length = valid.first.length;
    final sums = List<double>.filled(length, 0.0);
    for (final v in valid) {
      for (int i = 0; i < length; i++) {
        sums[i] += v[i];
      }
    }
    final count = valid.length.toDouble();
    for (int i = 0; i < length; i++) {
      sums[i] = sums[i] / count;
    }
    return sums;
  }

  Future<void> _submitEnrollmentEmbedding(List<double> embedding) async {
    final sessionManager = SessionManager.instance;
    final currentTeacher = sessionManager.currentTeacher;
    if (currentTeacher == null) {
      setState(() {
        _errorMessage = 'User session not found. Please login again.';
        _statusMessage = 'Error occurred';
      });
      return;
    }
    try {
      setState(() {
        _statusMessage = 'Sending to server...';
      });

      final response = await FaceApiService.enrollFace(
        staffId: currentTeacher.id.toString(),
        embedding: embedding,
      );
      if (response['status'] == 'success') {
        setState(() {
          _statusMessage = 'Enrollment successful!';
        });

        // Keep session state in sync with backend enrollment.
        await sessionManager.updateTeacherData(
          currentTeacher.copyWith(faceEnrolled: true),
        );

        _showSuccessDialog(
          'Face Enrollment Successful',
          'Your face has been enrolled using multi-angle capture and liveness.',
        );
      } else {
        final msg = response['message']?.toString() ?? 'Enrollment failed';
        setState(() {
          _errorMessage = msg;
          _statusMessage = msg;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Enrollment failed: $e';
        _statusMessage = 'Enrollment failed';
      });
    }
  }

  Future<String> _getCurrentLocation() async {
    try {
      // You can implement location service here
      // For now, return a default location
      return 'Office';
    } catch (e) {
      print('❌ Failed to get location: $e');
      return 'Unknown';
    }
  }

  /// Verify face with proper face recognition result
  Future<void> _verifyFaceWithResult(
    FaceRecognitionResult result,
    Map<String, dynamic>? locationData,
  ) async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
        _statusMessage = 'Marking attendance...';
      });

      // Get current user info from session
      final sessionManager = SessionManager.instance;
      final currentTeacher = sessionManager.currentTeacher;

      if (currentTeacher == null) {
        setState(() {
          _errorMessage = 'User session not found. Please login again.';
        });
        return;
      }

      // Check if user can mark attendance first
      final attendanceCheck = await FaceAttendanceService.canMarkAttendance(
        userId: currentTeacher.id.toString(),
        attendanceType: 'check_in', // You can make this dynamic
      );

      if (!attendanceCheck.canMark) {
        setState(() {
          _errorMessage = attendanceCheck.message;
        });
        return;
      }

      // Mark attendance using face verification
      final attendanceResult =
          await FaceAttendanceService.markAttendanceWithFace(
            faceResult: result,
            attendanceType: 'check_in', // You can make this dynamic
            location: locationData != null
                ? '${locationData['latitude']}, ${locationData['longitude']}'
                : await _getCurrentLocation(),
            locationData: locationData,
          );

      if (attendanceResult.success) {
        setState(() {
          _errorMessage = null;
          _isProcessing = false;
        });

        // Show success message
        _showSuccessDialog(
          'Attendance Marked',
          'Your attendance has been successfully marked using face verification.',
        );
      } else {
        setState(() {
          _errorMessage = attendanceResult.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Face verification failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _enrollFace(String faceData) async {
    try {
      final staffId = SessionManager.instance.teacherId;
      print('\n');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║                    🎭 FACE ENROLLMENT                        ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ 📊 CAPTURED DATA:                                            ║');
      print('║    • Staff ID: ${staffId ?? 'unknown'}'.padRight(55) + '║');
      print('║    • Face Data Length: ${faceData.length}'.padRight(51) + '║');
      print('║    • Raw Data (Full):                                       ║');
      print('║      $faceData'.padRight(68) + '║');
      print('║    • Hex String (Generated):                                 ║');
      print(
        '║      ${faceData.hashCode.toRadixString(16).padLeft(16, '0')}'
                .padRight(68) +
            '║',
      );
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ 📤 SENDING TO BACKEND API...                                 ║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('\n');

      final response = await AttendanceService.enrollFace(faceData: faceData);
      print('✅ EnrollFace Response: $response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face enrolled successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to enroll face: $e';
      });
    }
  }

  Future<void> _verifyFace(String faceData) async {
    try {
      final staffId = SessionManager.instance.teacherId;
      print('\n');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║                  🔍 FACE VERIFICATION                        ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ 📊 CAPTURED DATA:                                            ║');
      print('║    • Staff ID: ${staffId ?? 'unknown'}'.padRight(55) + '║');
      print('║    • Face Data Length: ${faceData.length}'.padRight(51) + '║');
      print('║    • Raw Data (Full):                                       ║');
      print('║      $faceData'.padRight(68) + '║');
      print('║    • Hex String (Generated):                                 ║');
      print(
        '║      ${faceData.hashCode.toRadixString(16).padLeft(16, '0')}'
                .padRight(68) +
            '║',
      );
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ 📤 SENDING TO BACKEND API...                                 ║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('\n');

      final response = await AttendanceService.verifyFace(faceData: faceData);
      print('✅ VerifyFace Response: $response');

      final bool verified =
          response['verified'] == true ||
          (response['status'] == 'success' && response['verified'] == true);
      final similarity = response['similarity'];
      final confidence = response['confidence'];

      if (!mounted) return;

      if (verified) {
        final details = [
          if (similarity != null) 'similarity: ${similarity.toString()}',
          if (confidence != null) 'confidence: ${confidence.toString()}%',
        ].join('  •  ');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              details.isEmpty
                  ? 'Face verified successfully'
                  : 'Face verified successfully  ($details)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ?? 'Face not verified',
            ),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify face: $e';
      });
    }
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
        title: Text(
          (widget.verifyMode ? 'Face Verification' : 'Face Enrollment')
              .toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main vibrant gradient background matching the app dashboard
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.dashboardPrimaryLight,
                  AppTheme.dashboardPrimary,
                ],
              ),
            ),
          ),

          // Subtle decorative tech elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.3),
                    AppTheme.primaryPurple.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // Technical background pattern (subtle)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildCameraView()),
                _buildStatusAndControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 24),
            Text(
              'INITIALIZING BIOMETRICS...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    final boxColor =
        _isFaceDetected && (widget.verifyMode || _isTargetAngleSatisfied)
        ? AppTheme.accentGreen
        : AppTheme.accentCyan;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Camera Preview
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(child: CameraPreview(_cameraController!)),
            ),

          // Techy Frame Overlays
          // Outer Glow
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: boxColor.withOpacity(
                        0.1 + (0.1 * _scanController.value),
                      ),
                      blurRadius: 30 + (20 * _scanController.value),
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),

          // Scanning Line (Circular)
          if (!_isFaceDetected || _isProcessing)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 320 * _scanAnimation.value,
                  child: Container(
                    width: 300,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          boxColor.withOpacity(0),
                          boxColor,
                          boxColor.withOpacity(0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: boxColor.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Corner Guides (Stylized for Circle)
          ...List.generate(4, (i) => _buildCircularCorner(i, boxColor)),

          // Instruction Overlay
          Positioned(
            bottom: -20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.darkPurple.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: boxColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    (_isProcessing
                            ? _statusMessage
                            : !_isFaceDetected
                            ? 'POSITION FACE IN CENTER'
                            : widget.verifyMode
                            ? 'HOLD STEADY'
                            : (_currentAngleIndex == 0
                                  ? 'LOOK STRAIGHT'
                                  : _currentAngleIndex == 1
                                  ? 'TURN FACE LEFT'
                                  : 'TURN FACE RIGHT'))
                        .toUpperCase(),
                    style: TextStyle(
                      color: boxColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularCorner(int index, Color color) {
    final angles = [0.0, 1.57, 3.14, 4.71];
    return Transform.rotate(
      angle: angles[index],
      child: Container(
        width: 380,
        height: 380,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(190),
          border: Border(
            top: BorderSide(color: color.withOpacity(0.5), width: 3),
            left: BorderSide(color: color.withOpacity(0.5), width: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAndControls() {
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
          // Error messages - Dynamic Chip
          if (_errorMessage != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Enrollment Steps
          if (!widget.verifyMode) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final done = _stepsCompleted[i];
                final current = _currentAngleIndex == i;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: done
                        ? AppTheme.accentGreen
                        : current
                        ? AppTheme.accentCyan
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      if (current)
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
          ],

          // Action Row
          Row(
            children: [
              // Cancel Button
              Expanded(
                flex: 1,
                child: TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Primary Action
              Expanded(
                flex: 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isFaceDetected
                          ? [AppTheme.primaryPurple, AppTheme.darkPurple]
                          : [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      if (_isFaceDetected)
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed:
                        (_isProcessing ||
                            (_locationVerificationRequired &&
                                !_locationVerified))
                        ? null
                        : _captureAndVerifyFace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.verifyMode
                                    ? Icons.verified_user
                                    : Icons.person_add,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                (widget.verifyMode
                                        ? 'VERIFY FACE'
                                        : 'ENROLL FACE')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show success dialog
  void _showSuccessDialog(String title, String message) {
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
              const Icon(
                Icons.check_circle,
                color: Color(0xFF48BB78),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Return to previous screen
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF48BB78),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
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

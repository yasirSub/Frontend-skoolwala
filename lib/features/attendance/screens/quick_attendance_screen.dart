import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:skoolwala/features/attendance/services/attendance_service.dart';
import 'package:skoolwala/features/attendance/services/attendance_status_service.dart';
import 'package:skoolwala/features/attendance/services/face_attendance_service.dart';
import 'package:skoolwala/features/attendance/services/google_ml_face_service.dart';
import 'package:skoolwala/features/attendance/services/location_service.dart';
import '../../../shared/widgets/app_loading_indicator.dart';

class QuickAttendanceScreen extends StatefulWidget {
  final String? forceMode; // 'checkin' or 'checkout' to force a specific mode

  const QuickAttendanceScreen({super.key, this.forceMode});

  @override
  State<QuickAttendanceScreen> createState() => _QuickAttendanceScreenState();
}

class _QuickAttendanceScreenState extends State<QuickAttendanceScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isFaceDetected = false;
  String? _errorMessage;
  String? _successMessage;

  // Attendance status
  AttendanceStatus? _currentStatus;
  AttendanceSummary? _todaySummary;
  bool _userFound = false; // Flag to track if user has been found

  // Attendance type variables
  int _attendanceType = 0;
  String _attendanceTypeDisplay = 'Day-Wise Attendance';
  bool _attendanceTypeLoading = true;

  // Camera capture state
  bool _isCapturingFrame = false;
  Timer? _faceDetectionTimer;

  // Animation controllers
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _setupAnimations();
  }

  void _setupAnimations() {
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeScreen() async {
    try {
      // Get current attendance status
      await _loadAttendanceStatus();

      // Load attendance type
      await _loadAttendanceType();

      // Initialize camera
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

  Future<void> _loadAttendanceStatus() async {
    try {
      final status = await AttendanceStatusService.getCurrentStatus();
      final summary = await AttendanceStatusService.getTodaySummary();

      setState(() {
        _currentStatus = status;
        _todaySummary = summary;
      });
    } catch (e) {
      print('❌ Failed to load attendance status: $e');
    }
  }

  Future<void> _loadAttendanceType() async {
    try {
      final response = await AttendanceService.getAttendanceType();
      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          _attendanceType = response['data']['attendance_type'] ?? 0;
          _attendanceTypeDisplay =
              response['data']['type_display'] ?? 'Day-Wise Attendance';
          _attendanceTypeLoading = false;
        });
      }
    } catch (e) {
      print('Error loading attendance type: $e');
      setState(() {
        _attendanceTypeLoading = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
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

  void _startFaceDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _faceDetectionTimer?.cancel();
    _faceDetectionTimer = Timer.periodic(const Duration(milliseconds: 800), (
      timer,
    ) async {
      if (!mounted ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _isCapturingFrame ||
          _isProcessing ||
          _userFound) {
        // Stop scanning if user is found
        timer.cancel();
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

        // Clean up temporary file
        final File file = File(imageFile.path);
        if (await file.exists()) {
          await file.delete();
        }

        if (mounted) {
          setState(() {
            _isFaceDetected = result != null && result.confidence >= 0.6;
          });
        }

        // Auto-capture when face is detected and ready
        if (_isFaceDetected && _currentStatus?.nextAction != 'none') {
          _captureAndMarkAttendance();
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
  }

  Future<void> _captureAndMarkAttendance() async {
    if (_isProcessing || _currentStatus?.nextAction == 'none') {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Get location data
      Map<String, dynamic>? locationData;
      try {
        locationData = await LocationService.getCurrentLocation();
      } catch (e) {
        print('⚠️ Location not available: $e');
      }

      // Capture final image for attendance
      final XFile image = await _cameraController!.takePicture().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Camera capture timeout during attendance marking');
        },
      );

      final result = await GoogleMLFaceService.processCameraImage(image);

      if (result != null && result.confidence >= 0.6) {
        // Determine attendance type based on forceMode or current status
        String attendanceType;
        if (widget.forceMode != null) {
          attendanceType = widget.forceMode == 'checkin'
              ? 'check_in'
              : 'check_out';
        } else {
          attendanceType = _currentStatus!.nextAction == 'check_in'
              ? 'check_in'
              : 'check_out';
        }

        // Mark attendance
        final attendanceResult =
            await FaceAttendanceService.markAttendanceWithFace(
              faceResult: result,
              attendanceType: attendanceType,
              location: locationData != null
                  ? '${locationData['latitude']}, ${locationData['longitude']}'
                  : 'Unknown',
              locationData: locationData,
            );

        if (attendanceResult.success) {
          setState(() {
            _successMessage = 'Attendance marked successfully!';
            _errorMessage = null;
            _userFound = true; // Mark user as found
          });

          // Stop face detection and scanning animation
          _stopFaceDetection();
          _scanController.stop();

          // Reload attendance status
          await _loadAttendanceStatus();

          // Show success feedback
          _showSuccessFeedback(attendanceType);
        } else {
          setState(() {
            _errorMessage = attendanceResult.message;
            _successMessage = null;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Face not detected clearly. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Attendance marking failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _restartScanning() {
    setState(() {
      _userFound = false;
      _errorMessage = null;
      _successMessage = null;
    });
    _scanController.repeat(); // Restart scanning animation
    _startFaceDetection(); // Restart face detection
  }

  void _showSuccessFeedback(String attendanceType) {
    // Show success dialog with options
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
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text('Attendance Marked'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      attendanceType == 'check_in'
                          ? 'Checked In Successfully!'
                          : 'Checked Out Successfully!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Face recognition completed successfully.',
                      style: TextStyle(fontSize: 14, color: Colors.green[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartScanning(); // Restart scanning
              },
              child: const Text('Scan Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to dashboard
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
    _faceDetectionTimer?.cancel();
    _cameraController?.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Quick Attendance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
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
              Expanded(flex: 2, child: _buildStatusAndControls()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isInitialized) {
      return _buildLoadingView();
    }

    return Stack(
      children: [
        // Camera preview
        if (_cameraController != null && _cameraController!.value.isInitialized)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: CameraPreview(_cameraController!),
            ),
          )
        else
          _buildLoadingView(),

        // Face detection overlay
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isFaceDetected ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _userFound
                          ? const Color(0xFF4CAF50)
                          : (_isFaceDetected
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF00E5FF)),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isFaceDetected
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFF00E5FF))
                                .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Scanning animation
                      if (!_isFaceDetected && !_userFound)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanAnimation.value * 280,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF00E5FF).withOpacity(0.8),
                                      const Color(0xFF00E5FF),
                                      const Color(0xFF00E5FF).withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      // Center icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                (_isFaceDetected
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF00E5FF))
                                    .withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _userFound
                                ? Icons.check_circle_rounded
                                : (_isFaceDetected
                                      ? Icons.check_circle_rounded
                                      : Icons.face_rounded),
                            color: _userFound
                                ? const Color(0xFF4CAF50)
                                : (_isFaceDetected
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF00E5FF)),
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Status indicator
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: _buildStatusIndicator(),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    if (_currentStatus == null) return const SizedBox.shrink();

    Color backgroundColor;
    Color textColor;
    String statusText;

    // Use forceMode if provided, otherwise use current status
    if (widget.forceMode != null) {
      if (widget.forceMode == 'checkin') {
        backgroundColor = const Color(0xFF4CAF50).withOpacity(0.9);
        textColor = Colors.white;
        statusText = 'Ready to Check In';
      } else {
        backgroundColor = const Color(0xFFFF9800).withOpacity(0.9);
        textColor = Colors.white;
        statusText = 'Ready to Check Out';
      }
    } else {
      switch (_currentStatus!.status) {
        case AttendanceState.canCheckIn:
          backgroundColor = const Color(0xFF4CAF50).withOpacity(0.9);
          textColor = Colors.white;
          statusText = 'Ready to Check In';
          break;
        case AttendanceState.canCheckOut:
          backgroundColor = const Color(0xFFFF9800).withOpacity(0.9);
          textColor = Colors.white;
          statusText = 'Ready to Check Out';
          break;
        case AttendanceState.completed:
          backgroundColor = const Color(0xFF2196F3).withOpacity(0.9);
          textColor = Colors.white;
          statusText = 'Attendance Completed';
          break;
        default:
          backgroundColor = Colors.grey.withOpacity(0.9);
          textColor = Colors.white;
          statusText = 'Status Unknown';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Color(0xFF2c3e50), Color(0xFF1a1a2e)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const AppLoadingIndicator(color: Color(0xFF00E5FF)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Initializing Quick Attendance...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAndControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0f3460), Color(0xFF16213e)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attendance Type Badge
            if (!_attendanceTypeLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      (_attendanceType == 0
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF9C27B0))
                          .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _attendanceType == 0
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF9C27B0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _attendanceType == 0 ? Icons.calendar_today : Icons.book,
                      color: _attendanceType == 0
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF9C27B0),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _attendanceTypeDisplay,
                      style: TextStyle(
                        color: _attendanceType == 0
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF9C27B0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Today's summary
            if (_todaySummary != null) ...[
              _buildTodaySummary(),
              const SizedBox(height: 20),
            ],

            // Messages
            if (_errorMessage != null) ...[
              _buildMessageCard(_errorMessage!, true),
              const SizedBox(height: 12),
            ],

            if (_successMessage != null) ...[
              _buildMessageCard(_successMessage!, false),
              const SizedBox(height: 12),
            ],

            // Instructions
            _buildInstructions(),

            const SizedBox(height: 20),

            // Manual capture button
            if (_currentStatus?.nextAction != 'none')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFaceDetected
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF00E5FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isProcessing ? null : _captureAndMarkAttendance,
                  child: _isProcessing
                      ? const AppLoadingIndicator(color: Colors.white, size: 24)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentStatus?.nextAction == 'check_in'
                                  ? Icons.login
                                  : Icons.logout,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isProcessing
                                  ? 'Processing...'
                                  : (widget.forceMode != null
                                        ? (widget.forceMode == 'checkin'
                                              ? 'Check In'
                                              : 'Check Out')
                                        : (_currentStatus?.nextAction ==
                                                  'check_in'
                                              ? 'Check In'
                                              : 'Check Out')),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'Today\'s Attendance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Check In',
                _todaySummary!.formattedCheckInTime,
                _todaySummary!.hasCheckedIn,
              ),
              _buildSummaryItem(
                'Check Out',
                _todaySummary!.formattedCheckOutTime,
                _todaySummary!.hasCheckedOut,
              ),
              _buildSummaryItem(
                'Total Hours',
                _todaySummary!.formattedTotalHours,
                _todaySummary!.hasCheckedOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, bool isActive) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(String message, bool isError) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFF2D1B1B) : const Color(0xFF1B2D1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? const Color(0xFFE53E3E).withOpacity(0.3)
              : const Color(0xFF48BB78).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isError
                  ? const Color(0xFFE53E3E).withOpacity(0.2)
                  : const Color(0xFF48BB78).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError
                  ? const Color(0xFFE53E3E)
                  : const Color(0xFF48BB78),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    String instructionText;

    if (_currentStatus == null) {
      instructionText = 'Loading attendance status...';
    } else {
      // Use forceMode if provided, otherwise use current status
      if (widget.forceMode != null) {
        instructionText = widget.forceMode == 'checkin'
            ? 'Position your face in the circle to check in automatically'
            : 'Position your face in the circle to check out automatically';
      } else {
        switch (_currentStatus!.status) {
          case AttendanceState.canCheckIn:
            instructionText =
                'Position your face in the circle to check in automatically';
            break;
          case AttendanceState.canCheckOut:
            instructionText =
                'Position your face in the circle to check out automatically';
            break;
          case AttendanceState.completed:
            instructionText = 'Your attendance is complete for today';
            break;
          default:
            instructionText = 'Please ensure your face is enrolled';
        }
      }
    }

    return Text(
      instructionText,
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }
}

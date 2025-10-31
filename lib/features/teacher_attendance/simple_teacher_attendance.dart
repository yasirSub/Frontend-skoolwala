import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
// Face workflow encapsulates ML and API calls
import 'package:skoolwala/features/teacher_attendance/simple/face_workflow.dart';
import 'package:skoolwala/features/teacher_attendance/simple/location_workflow.dart';
import 'package:skoolwala/features/teacher_attendance/simple/camera_workflow.dart';
import 'package:skoolwala/features/teacher_attendance/simple/attendance_flow.dart';
import 'package:skoolwala/shared/utils/safe_widget_operations.dart';
import 'package:skoolwala/shared/utils/layout_boundary_fix.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/error_dialog.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/location_overlay.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/camera_overlays/school_mobile_location_panel.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/camera_overlays/verified_user_badge.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/camera_overlays/debug_ids_panel.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/panels/gps_banner.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/panels/location_status_panel.dart';
// import 'package:skoolwala/features/teacher_attendance/simple/widgets/camera_overlays/face_detection_overlay.dart'; // DISABLED - overlay removed
import 'package:skoolwala/features/teacher_attendance/simple/widgets/face_tracking/face_tracking_overlay.dart';
// import 'package:skoolwala/features/teacher_attendance/simple/widgets/processing_overlay.dart'; // REMOVED - status shown in button instead
import 'package:skoolwala/features/teacher_attendance/simple/widgets/check_in_out_button.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/bottom_status_bar.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/face_mismatch_dialog.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/attendance_instructions.dart';
import 'package:skoolwala/shared/widgets/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleTeacherAttendance extends StatefulWidget {
  final String? staffId; // optional: provide from dashboard/session

  const SimpleTeacherAttendance({Key? key, this.staffId}) : super(key: key);

  @override
  _SimpleTeacherAttendanceState createState() =>
      _SimpleTeacherAttendanceState();
}

class _SimpleTeacherAttendanceState extends State<SimpleTeacherAttendance>
    with SafeWidgetMixin, LayoutBoundaryMixin, TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _lastResult;

  // Location variables
  Position? _currentPosition;
  bool _locationPermissionGranted = false;
  String _locationStatus = 'Initializing location detection...';
  bool _isFetchingLocation = false;
  bool _permissionDeniedForever = false;
  bool _showGpsBanner = false; // controls visibility of GPS banner

  // School location variables
  Map<String, dynamic>? _schoolLocation;
  double? _distanceFromSchool;
  bool _isWithinSchoolRadius = false;

  // Face analysis variables
  bool _isAnalyzingFace = false;
  String? _faceAnalysisStatus;
  String _bottomStatusMessage = 'Position your face in the circle';
  List<double>? _capturedFaceEmbedding;
  int _noMatchCount = 0; // consecutive no-match attempts before showing Retry
  bool _schoolLocationLoaded = false; // set true after first fetch completes
  bool _showInfoPanels =
      false; // toggle to show/hide info overlays (default hidden)

  // Face validation data (saved temporarily)
  Map<String, dynamic>? _faceValidationData;

  // Cached verification data - stores when everything is verified
  bool _isEverythingVerified = false; // Flag to indicate all checks passed
  bool _stopAutomaticAnalysis = false; // Flag to stop automatic analysis

  // Auto check-in/out toggle
  bool _autoCheckEnabled = false; // Toggle for automatic check in/out
  static const String _autoCheckPrefsKey =
      'teacher_attendance_auto_check_enabled';

  // User's current attendance status
  bool _isCurrentlyCheckedIn = false;
  double? _lastDistanceMeters;
  String? _lastDetectedStaffId; // for UI debug: last detected face staff id

  // Animation variables - DISABLED (overlay removed)
  late AnimationController _faceDetectionAnimationController;
  // late Animation<double> _faceDetectionAnimation; // Not used - overlay disabled

  // Base URL is now centralized in AttendanceFlow via ApiConfig

  bool get _isFaceValidatedForLoggedInUser {
    final String? expectedStaffId = widget.staffId;
    final String actualStaffId =
        (_faceValidationData != null &&
            _faceValidationData!['staff_id'] != null)
        ? _faceValidationData!['staff_id'].toString()
        : '';
    return expectedStaffId != null &&
        expectedStaffId.isNotEmpty &&
        actualStaffId == expectedStaffId;
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controller - DISABLED (animation overlay is hidden)
    _faceDetectionAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animation setup disabled - overlay removed
    // _faceDetectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    //   CurvedAnimation(
    //     parent: _faceDetectionAnimationController,
    //     curve: Curves.easeInOut,
    //   ),
    // );

    // Animation stopped - overlay is disabled
    // _faceDetectionAnimationController.repeat(reverse: true);

    _initializeCamera();
    // Fetch school location in parallel to speed up readiness
    _fetchSchoolLocation();
    _initializeLocation(); // Get mobile location first
    // Start automatic face analysis after camera and location are ready
    // (will be called from _fetchSchoolLocation when ready)

    // Check user's current attendance status
    _checkCurrentAttendanceStatus(explicitStaffId: widget.staffId);

    // Load saved auto-check preference
    _loadAutoCheckPreference();

    // Debug: Initialize location status
    print(
      'Teacher Attendance initialized - starting mobile location detection',
    );
  }

  /// Load saved auto-check preference from phone storage
  Future<void> _loadAutoCheckPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getBool(_autoCheckPrefsKey) ?? false;
      safeSetState(() {
        _autoCheckEnabled = savedValue;
      });
      print('📱 Loaded auto-check preference: $_autoCheckEnabled');
    } catch (e) {
      print('⚠️ Failed to load auto-check preference: $e');
      // Default to false if loading fails
      safeSetState(() {
        _autoCheckEnabled = false;
      });
    }
  }

  /// Save auto-check preference to phone storage
  Future<void> _saveAutoCheckPreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoCheckPrefsKey, value);
      print('📱 Saved auto-check preference: $value');
    } catch (e) {
      print('⚠️ Failed to save auto-check preference: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameraController = await CameraWorkflow.initFrontCamera();
      if (_cameraController != null) {
        safeSetState(() {
          _isInitialized = true;
        });
        // Automatic face analysis will start after school location is loaded
        // (called from _fetchSchoolLocation to ensure location readiness)
      }
    } catch (e) {
      print('Camera error: $e');
    }
  }

  Future<void> _initializeLocation() async {
    print('=== STARTING LOCATION INITIALIZATION ===');
    try {
      safeSetState(() {
        _locationStatus = 'Checking location permission...';
      });
      print('Location status set: Checking location permission...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        safeSetState(() {
          _locationStatus =
              '❌ Location services are disabled. Please enable location services in device settings.';
        });
        print('Location services disabled - stopping');
        return;
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('Initial permission: $permission');

      if (permission == LocationPermission.denied) {
        safeSetState(() {
          _locationStatus = 'Requesting location permission...';
        });
        print('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('Permission after request: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        safeSetState(() {
          _locationStatus =
              '❌ Location permission permanently denied. Please enable in device settings > Apps > Skoolwala > Permissions > Location.';
        });
        print('Location permission permanently denied');
        _permissionDeniedForever = true;
        return;
      }

      if (permission == LocationPermission.denied) {
        safeSetState(() {
          _locationStatus =
              '❌ Location permission denied. Please allow location access.';
        });
        print('Location permission denied');
        return;
      }

      safeSetState(() {
        _locationPermissionGranted = true;
        _locationStatus = 'Getting GPS location...';
      });
      print('Location permission granted - getting GPS location');

      // Check if GPS is available
      bool isGPSAvailable = await Geolocator.isLocationServiceEnabled();
      print('GPS available: $isGPSAvailable');

      if (!isGPSAvailable) {
        safeSetState(() {
          _locationStatus = 'GPS not available. Using network location...';
        });
        print('GPS not available - using network location');
      }

      print('Getting current position...');
      // Try fastest GPS with very short timeout
      try {
        safeSetState(() {
          _locationStatus = 'Getting GPS location...';
        });
        print('Trying fast GPS...');
        // First attempt: balanced accuracy with moderate timeout
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        safeSetState(() {
          _locationStatus = '✅ GPS Location obtained';
        });
        print('Fast GPS location obtained');
      } catch (e) {
        print('Fast GPS failed: $e, trying last known position...');
        // Fallback to last known position
        try {
          _currentPosition = await Geolocator.getLastKnownPosition();
          if (_currentPosition != null) {
            safeSetState(() {
              _locationStatus = '✅ GPS Location (last known) obtained';
            });
            print('Last known GPS Location obtained');
          } else {
            // Second attempt: high accuracy with longer timeout
            print('No last known location. Trying high-accuracy GPS...');
            try {
              _currentPosition = await Geolocator.getCurrentPosition(
                locationSettings: LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 8),
                ),
              );
              if (_currentPosition != null) {
                safeSetState(() {
                  _locationStatus = '✅ GPS Location (high accuracy) obtained';
                });
                print('High-accuracy GPS Location obtained');
              } else {
                safeSetState(() {
                  _locationStatus = '❌ No GPS location available';
                });
              }
            } catch (e2) {
              print('High-accuracy GPS failed: $e2');
              safeSetState(() {
                _locationStatus = '❌ GPS Location failed: $e2';
              });
              // Coarse fallback: try network/coarse location quickly
              try {
                _currentPosition = await Geolocator.getCurrentPosition(
                  locationSettings: LocationSettings(
                    accuracy: LocationAccuracy.low,
                    timeLimit: Duration(seconds: 2),
                  ),
                );
                if (_currentPosition != null) {
                  safeSetState(() {
                    _locationStatus = '✅ Coarse location obtained';
                  });
                  print('Coarse GPS (network) obtained');
                }
              } catch (_) {}
              // Final fallback: listen for first location update (up to 10s)
              try {
                safeSetState(() {
                  _isFetchingLocation = true;
                });
                final pos = await Geolocator.getPositionStream(
                  locationSettings: LocationSettings(
                    accuracy: LocationAccuracy.high,
                    distanceFilter: 0,
                  ),
                ).first.timeout(Duration(seconds: 10));
                _currentPosition = pos;
                safeSetState(() {
                  _locationStatus = '✅ GPS Location (stream) obtained';
                });
              } catch (e3) {
                print('Stream-based GPS fallback failed: $e3');
              } finally {
                safeSetState(() {
                  _isFetchingLocation = false;
                });
              }
            }
          }
        } catch (fallbackError) {
          print('Last known position also failed: $fallbackError');
          safeSetState(() {
            _locationStatus = '❌ GPS Location failed: $fallbackError';
          });
        }
      }

      if (_currentPosition != null) {
        print(
          'Location obtained: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
        );

        // Simple debug: phone GPS summary
        safeSetState(() {
          _locationStatus =
              '📍 Your location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
        });
        print(
          'Phone GPS: lat=${_currentPosition!.latitude}, lng=${_currentPosition!.longitude}',
        );

        // Check if everything is verified and cache (mobile location might be the last piece)
        _checkAndCacheVerifiedData();
      } else {
        print('⚠️ No mobile GPS location available after attempts');
        safeSetState(() {
          _locationStatus = '❌ No GPS location available';
        });
      }

      // Now fetch school location and compare
      _fetchSchoolLocation();
    } catch (e) {
      print('Location error: $e');
      safeSetState(() {
        _locationStatus = 'Location error: $e';
      });
      print('Location error status set');
    }
    print('=== LOCATION INITIALIZATION COMPLETE ===');
  }

  /// Force fetch location: used by floating panel refresh button
  Future<void> _forceFetchLocation() async {
    try {
      safeSetState(() {
        _isFetchingLocation = true;
        _locationStatus = 'Getting GPS location...';
      });

      // Try last known first
      _currentPosition = await Geolocator.getLastKnownPosition();
      if (_currentPosition == null) {
        // Try balanced
        try {
          _currentPosition = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
        } catch (_) {
          // Try high
          try {
            _currentPosition = await Geolocator.getCurrentPosition(
              locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 8),
              ),
            );
          } catch (_) {
            // Try coarse/network quick
            try {
              _currentPosition = await Geolocator.getCurrentPosition(
                locationSettings: LocationSettings(
                  accuracy: LocationAccuracy.low,
                  timeLimit: Duration(seconds: 2),
                ),
              );
            } catch (_) {}
            // Stream fallback
            final pos = await Geolocator.getPositionStream(
              locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 0,
              ),
            ).first.timeout(Duration(seconds: 10));
            _currentPosition = pos;
          }
        }
      }

      if (_currentPosition != null) {
        print(
          'Phone GPS: lat=${_currentPosition!.latitude}, lng=${_currentPosition!.longitude}',
        );
        safeSetState(() {
          _locationStatus =
              '📍 Your location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
        });
        if (_schoolLocation != null) {
          _checkLocationProximity();
        }
      } else {
        print('⚠️ No mobile GPS location available after force fetch');
        safeSetState(() {
          _locationStatus = '❌ No GPS location available';
        });
      }
    } catch (e) {
      print('Force fetch location error: $e');
    } finally {
      safeSetState(() {
        _isFetchingLocation = false;
      });
    }
  }

  /// Diagnose permission/service reasons for missing location
  Future<void> _diagnoseLocationIssues() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final lastKnown = await Geolocator.getLastKnownPosition();
      print(
        'Location Diagnostic -> serviceEnabled=$serviceEnabled, permission=$permission, lastKnown=${lastKnown != null}',
      );
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location services are OFF. Enable GPS and try again.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location permission DENIED. Please allow and retry.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission permanently denied. Open App Settings.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ),
        );
        return;
      }
      // If here, services and permission look OK
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lastKnown != null
                ? 'Permissions OK. Using last known position.'
                : 'Permissions OK but no last known fix. Try Refresh or go outdoors.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Location Diagnostic error: $e');
    }
  }

  /// Retry location detection with better error handling
  Future<void> _retryLocation() async {
    safeSetState(() {
      _locationStatus = '🔄 Retrying mobile location detection...';
      _currentPosition = null;
      _locationPermissionGranted = false;
    });

    try {
      await _initializeLocation();
    } catch (e) {
      safeSetState(() {
        _locationStatus = '❌ Location retry failed: $e';
      });
      print('Location retry failed: $e');
    }
  }

  /// Quick location test for debugging
  Future<void> _testLocation() async {
    try {
      safeSetState(() {
        _locationStatus = '🧪 Testing location...';
      });

      // Test with very low accuracy and short timeout
      Position? testPosition;

      try {
        testPosition = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.lowest, // Fastest option
            timeLimit: Duration(seconds: 1), // Ultra-fast: 1 second only
          ),
        );
      } catch (e) {
        print('Current position failed, trying last known: $e');
        // Try last known position
        testPosition = await Geolocator.getLastKnownPosition();
      }

      if (testPosition != null) {
        final position = testPosition; // Non-null assertion
        safeSetState(() {
          _locationStatus =
              '✅ Location test successful: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _currentPosition = position;
        });

        print(
          'Location test successful: ${position.latitude}, ${position.longitude}',
        );
      } else {
        throw Exception('No location available');
      }
    } catch (e) {
      safeSetState(() {
        _locationStatus = '❌ Location test failed: $e';
      });
      print('Location test failed: $e');
    }
  }

  /// Clear face validation data (for re-analysis)
  void _clearFaceValidationData() {
    _faceValidationData = null;
    _capturedFaceEmbedding = null;
    safeSetState(() {
      _faceAnalysisStatus =
          'Face validation data cleared. Ready for new analysis.';
    });
    print('Face validation data cleared');
  }

  /// Fetch school location from database
  Future<void> _fetchSchoolLocation() async {
    try {
      print('Fetching school location from database...');
      safeSetState(() {
        _locationStatus = 'Fetching school location...';
      });

      final data = await AttendanceFlow.fetchSchoolLocation();

      if (data != null && data['status'] == 'success' && data['data'] != null) {
        _schoolLocation = data['data'];

        // Compare with mobile location if available
        if (_currentPosition != null) {
          _checkLocationProximity();
        } else {
          safeSetState(() {
            _locationStatus =
                'School location loaded. Getting your location...';
          });
        }

        // Mark as loaded on success so UI can enable when other conditions are met
        safeSetState(() {
          _schoolLocationLoaded = true;
        });

        // Check if everything is verified and cache (location might be the last piece)
        _checkAndCacheVerifiedData();

        // Start automatic face analysis now that location is ready (if not already verified)
        _startAutomaticAnalysis();
      } else {
        safeSetState(() {
          _locationStatus = 'School location not configured';
          _schoolLocationLoaded = true;
        });
      }
    } catch (e) {
      safeSetState(() {
        _locationStatus = 'Error loading school location: $e';
        _schoolLocationLoaded = true;
      });
    }
  }

  /// Calculate distance between mobile location and school location
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double dLat = (lat2 - lat1) * (math.pi / 180);
    double dLon = (lon2 - lon1) * (math.pi / 180);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c; // Distance in meters
  }

  /// Check if mobile location is within school radius
  void _checkLocationProximity() {
    if (_currentPosition != null && _schoolLocation != null) {
      double schoolLat = double.parse(_schoolLocation!['latitude'].toString());
      double schoolLon = double.parse(_schoolLocation!['longitude'].toString());
      double allowedRadius = double.parse(
        _schoolLocation!['radius']?.toString() ?? '100',
      ); // Default 100 meters

      _distanceFromSchool = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        schoolLat,
        schoolLon,
      );

      _isWithinSchoolRadius = _distanceFromSchool! <= allowedRadius;

      print(
        'Distance from school: ${_distanceFromSchool!.toStringAsFixed(1)} meters',
      );
      print('Allowed radius: $allowedRadius meters');
      print('Within school radius: $_isWithinSchoolRadius');

      safeSetState(() {
        _lastDistanceMeters = _distanceFromSchool;
        if (_isWithinSchoolRadius) {
          _locationStatus =
              '📍 Your location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}\n✅ At school (${_distanceFromSchool!.toStringAsFixed(1)}m from center)';
        } else {
          _locationStatus =
              '📍 Your location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}\n⚠️ Outside school (${_distanceFromSchool!.toStringAsFixed(1)}m from center)';
        }
      });
    }
  }

  void _restartFaceDetection() {
    _capturedFaceEmbedding = null;
    _faceAnalysisStatus = null;
  }

  /// Check if everything is verified and cache the data, stop automatic analysis
  /// If auto-check is enabled, automatically check in/out when everything is verified
  void _checkAndCacheVerifiedData() async {
    // Check if everything is ready: face validated + location ready
    if (_isFaceValidatedForLoggedInUser &&
        _schoolLocationLoaded &&
        _schoolLocation != null &&
        _currentPosition != null) {
      // Everything is verified - cache it and stop automatic analysis
      if (!_isEverythingVerified) {
        print(
          '✅ Everything verified! Caching data and stopping automatic analysis.',
        );
        safeSetState(() {
          _isEverythingVerified = true;
          _stopAutomaticAnalysis = true;
        });
        print('Cached verification data:');
        print('  - Face validated: ${_faceValidationData?['name']}');
        print('  - Staff ID: ${_faceValidationData?['staff_id']}');
        print('  - School location: ${_schoolLocation != null}');
        print('  - Mobile location: ${_currentPosition != null}');

        // If auto-check is enabled, automatically check in/out
        if (_autoCheckEnabled && !_isProcessing) {
          print('🔄 Auto-check enabled - automatically checking in/out...');
          // Small delay to ensure UI updates
          await Future.delayed(const Duration(milliseconds: 500));
          // Automatically trigger check in/out
          _autoCheckInOut();
        }
      }
    }
  }

  /// Automatically check in/out when everything is verified and auto-check is enabled
  Future<void> _autoCheckInOut() async {
    if (!mounted || _isProcessing || !_isEverythingVerified) {
      return;
    }

    try {
      // Determine check type based on current status
      final checkType = _isCurrentlyCheckedIn ? 'check_out' : 'check_in';
      print('🔄 Auto-checking ${checkType}...');

      // Show status message
      safeSetState(() {
        _faceAnalysisStatus =
            'Auto-checking ${checkType == 'check_in' ? 'in' : 'out'}...';
        _bottomStatusMessage =
            'Automatically checking ${checkType == 'check_in' ? 'in' : 'out'}...';
      });

      // Call the attendance marking function
      await _markAttendance(checkType);

      // Success will be handled in _markAttendance's _showSuccess
      print('✅ Auto-check completed successfully');
    } catch (e) {
      print('❌ Auto-check failed: $e');
      // Show error to user
      if (mounted) {
        safeSetState(() {
          _faceAnalysisStatus = 'Auto-check failed: ${e.toString()}';
          _bottomStatusMessage = 'Auto-check failed. Please try manually.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Auto-check failed: ${e.toString()}. Please try manually.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _autoCheckInOut();
              },
            ),
          ),
        );
      }
    }
  }

  /// Restart face analysis when user clicks "Try Again"
  Future<void> _restartFaceAnalysis() async {
    print('🔄 Restarting face analysis...');

    safeSetState(() {
      _capturedFaceEmbedding = null;
      _faceAnalysisStatus = null;
      _faceValidationData = null;
      _bottomStatusMessage = 'Position your face in the circle';
      _isAnalyzingFace = false;
      _noMatchCount = 0; // Reset retry counter for new attempt
      _isEverythingVerified = false; // Clear verification cache
      _stopAutomaticAnalysis = false; // Allow automatic analysis to resume
    });

    // Wait a moment for state to update
    await Future.delayed(const Duration(milliseconds: 300));

    // Start automatic analysis again (will analyze up to 3 times)
    _startAutomaticAnalysis();
  }

  /// Starts automatic face analysis when camera is ready and location is available
  Future<void> _startAutomaticAnalysis() async {
    // Stop automatic analysis if everything is already verified and cached
    if (_stopAutomaticAnalysis || _isEverythingVerified) {
      print(
        'Automatic analysis stopped - everything already verified and cached.',
      );
      return;
    }

    // Wait for camera to be initialized
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _cameraController == null || !_isInitialized) {
      return;
    }

    // Only start analysis if location is ready (school location loaded)
    if (!_schoolLocationLoaded) {
      print('Waiting for school location before starting face analysis...');
      return;
    }

    // Don't start if already failed 3 times - wait for user to click Try Again
    if (_noMatchCount >= 3) {
      print('Face analysis failed 3 times. Waiting for user to retry.');
      return;
    }

    try {
      safeSetState(() {
        _faceAnalysisStatus = 'Starting automatic face analysis...';
        // Keep isAnalyzingFace true during the entire analysis process
        _isAnalyzingFace = true;
      });

      // Capture and analyze face automatically
      XFile imageFile = await _cameraController!.takePicture();
      await _analyzeFace(imageFile);

      // If face analysis was successful, show success message
      if (_capturedFaceEmbedding != null) {
        safeSetState(() {
          _faceAnalysisStatus = 'Face analysis complete! Ready for attendance.';
        });
      }
    } catch (e) {
      safeSetState(() {
        _faceAnalysisStatus =
            'Automatic analysis failed. Click Check In to try manually.';
      });
    }
  }

  Future<void> _analyzeFace(XFile imageFile) async {
    try {
      setState(() {
        _isAnalyzingFace = true;
        _faceAnalysisStatus = 'Analyzing face...';
        _bottomStatusMessage = 'Analyzing face features...';
      });

      final embedding = await FaceWorkflow.analyzeFace(imageFile);

      if (embedding == null) {
        // Face not detected - increment retry count and retry if attempts remaining
        _noMatchCount += 1;
        safeSetState(() {
          _faceAnalysisStatus =
              'No face detected. Please position your face in the frame.';
          _bottomStatusMessage = _noMatchCount < 3
              ? 'Analyzing face... (${_noMatchCount}/3)'
              : 'Face detection failed after 3 attempts. Please try again.';
          _isAnalyzingFace = false;
        });

        // Auto retry up to 3 attempts
        if (_noMatchCount < 3 && mounted && !_stopAutomaticAnalysis) {
          print('🔄 Face not detected, retrying... (${_noMatchCount}/3)');
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && _noMatchCount < 3 && !_stopAutomaticAnalysis) {
              _startAutomaticAnalysis();
            }
          });
        } else if (_noMatchCount >= 3) {
          print(
            '❌ Face detection failed after 3 attempts. Showing Try Again button.',
          );
          safeSetState(() {
            _faceAnalysisStatus = 'Face detection failed. Please try again.';
            _isAnalyzingFace = false;
          });
        }
        return;
      }

      // Use the face embedding from FaceWorkflow
      _capturedFaceEmbedding = embedding;

      // Now validate the face against enrolled faces
      await _validateFace();
    } catch (e) {
      String errorMessage = 'Face analysis error: $e';

      // Check for spoofing detection - Only show if face is too small
      if (e.toString().contains('SPOOFING_DETECTED')) {
        errorMessage = 'Face too small. Please move closer to camera.';
        _noMatchCount += 1; // Count as failed attempt
        safeSetState(() {
          _faceAnalysisStatus = errorMessage;
          _bottomStatusMessage = _noMatchCount < 3
              ? 'Analyzing face... (${_noMatchCount}/3)'
              : 'Please move closer to the camera for better face detection.';
          _isAnalyzingFace = false;
        });

        // Only show error for face size issues (most common legitimate issue)
        // Don't show aggressive "photo detected" message as it's usually just distance
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Face too small. Please move closer to the camera for better detection.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        // Auto retry up to 3 attempts
        if (_noMatchCount < 3 && mounted && !_stopAutomaticAnalysis) {
          print('🔄 Face too small, retrying... (${_noMatchCount}/3)');
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && _noMatchCount < 3 && !_stopAutomaticAnalysis) {
              _startAutomaticAnalysis();
            }
          });
        } else if (_noMatchCount >= 3) {
          print('❌ Face detection failed after 3 attempts (face too small).');
          safeSetState(() {
            _faceAnalysisStatus = 'Face detection failed. Please try again.';
            _isAnalyzingFace = false;
          });
        }
        return;
      }

      // Check for liveness failure - In lenient mode, this rarely happens
      // If it does, just continue (don't block the user)
      if (e.toString().contains('LIVENESS_FAILED')) {
        // In lenient mode, liveness check should pass, but if it fails,
        // just log and continue - don't block the user
        print('⚠️ Liveness check flagged but continuing in lenient mode');
        // Don't return - allow the flow to continue
        // The face analysis will proceed anyway
      }

      setState(() {
        _faceAnalysisStatus = errorMessage;
      });
    } finally {
      setState(() {
        _isAnalyzingFace = false;
      });
    }
  }

  Future<void> _validateFace() async {
    if (_capturedFaceEmbedding == null) return;

    try {
      setState(() {
        _faceAnalysisStatus = 'Validating face...';
        _bottomStatusMessage = 'Verifying face identity...';
      });

      // Call face analyzer to check if user is valid using FaceWorkflow
      final analysisResult = await FaceWorkflow.validateEmbedding(
        _capturedFaceEmbedding!,
      );

      // Keep last detected staff id for UI display
      if (analysisResult.containsKey('staff_id') &&
          analysisResult['staff_id'] != null) {
        _lastDetectedStaffId = analysisResult['staff_id'].toString();
      }

      if (analysisResult['status'] == 'success') {
        final matched = analysisResult['matched'] ?? false;
        final name = analysisResult['name']?.toString();
        final confidence = (analysisResult['confidence'] ?? 0.0).toDouble();

        if (matched && name != null) {
          // Enforce: face must match the logged-in teacher
          final String detectedStaffId = (analysisResult['staff_id'] ?? '')
              .toString();
          final String? expectedStaffId = widget.staffId;

          if (expectedStaffId != null &&
              expectedStaffId.isNotEmpty &&
              detectedStaffId != expectedStaffId) {
            // Face belongs to another account: block and notify
            safeSetState(() {
              _faceAnalysisStatus = 'Face mismatch';
              _bottomStatusMessage = 'Face mismatch';
              _isAnalyzingFace = false;
              _noMatchCount = 3; // definitive mismatch; require user action
            });
            await showFaceMismatchDialog(
              context,
              onConfirmed: () {
                if (mounted) {
                  Navigator.pop(context); // back to dashboard
                }
              },
            );
            return; // Do not accept validation for another account
          }

          // Save face validation data for reuse
          _faceValidationData = {
            'staff_id': analysisResult['staff_id'],
            'name': analysisResult['name'],
            'email': analysisResult['email'],
            'mobile': analysisResult['mobile'],
            'similarity': analysisResult['similarity'],
            'confidence': confidence,
            'threshold': analysisResult['threshold'],
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };

          safeSetState(() {
            _faceAnalysisStatus =
                'Face validated: $name (${confidence.toStringAsFixed(1)}%) - Ready for attendance';
            _bottomStatusMessage = 'Face verified successfully!';
            _noMatchCount = 0; // reset on success
          });

          // Check if everything is verified and cache the data
          _checkAndCacheVerifiedData();

          // Refresh today's status using known staff id after face validation
          _checkCurrentAttendanceStatus(explicitStaffId: widget.staffId);
        } else {
          final apiMessage =
              analysisResult['message'] ?? 'No matching face found';
          _noMatchCount += 1;
          safeSetState(() {
            _faceAnalysisStatus = apiMessage;
            _bottomStatusMessage = _noMatchCount < 3
                ? 'Verifying face... (${_noMatchCount}/3)'
                : apiMessage; // Only show error after 3 tries
            _isAnalyzingFace = false; // stop current analyze tick
          });

          // Auto retry up to 3 attempts ONLY
          if (_noMatchCount < 3) {
            // small delay to let UI update before retry
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted && _noMatchCount < 3) {
                _startAutomaticAnalysis();
              }
            });
          } else {
            // Stop analyzing after 3 attempts - show Try Again button
            print(
              'Face analysis stopped after 3 failed attempts. Showing Try Again button.',
            );
            safeSetState(() {
              _isAnalyzingFace = false;
              _faceAnalysisStatus = apiMessage; // Keep error message
            });
          }
        }
      } else {
        final apiMessage = analysisResult['message'] ?? 'Unknown error';
        setState(() {
          _faceAnalysisStatus = 'Face validation failed: $apiMessage';
          _bottomStatusMessage = apiMessage; // Update bottom message
          _isAnalyzingFace = false; // Reset to allow "Try Again"
          _noMatchCount = 3; // force retry state on API failure
        });
      }
    } catch (e) {
      setState(() {
        _faceAnalysisStatus = 'Error: $e'; // Format that triggers "Try Again"
        _isAnalyzingFace = false;
        _bottomStatusMessage = 'Error occurred. Tap Try Again.';
        _noMatchCount = 3; // force retry state on exception
      });
    }
  }

  Future<void> _markAttendance(String type) async {
    if (_cameraController == null) return;

    safeSetState(() {
      _isProcessing = true;
      _lastResult = null;
    });

    try {
      // ========================================
      // STEP 1: GET GPS LOCATION FROM PHONE
      // ========================================

      // Get current location from phone
      if (_currentPosition == null) {
        safeSetState(() {
          _locationStatus = '🔍 Getting your phone GPS location...';
        });
        try {
          _currentPosition = await LocationWorkflow.tryResolvePosition();
          if (_currentPosition == null) {
            throw Exception('No GPS fix');
          }
          safeSetState(() {
            _locationStatus = '✅ GPS Location obtained from phone';
          });
        } catch (e) {
          safeSetState(() {
            _lastResult = '❌ GPS Location failed: $e';
            _locationStatus = 'GPS Location error: $e';
          });
          _showError(
            'Failed to get GPS location from phone: $e\n\nPlease check location permissions and try again.',
          );
          return;
        }
      }

      // Show GPS location obtained
      safeSetState(() {
        _locationStatus =
            '✅ GPS Location: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
      });

      // ========================================
      // STEP 2: FACE CHECK SECOND (ONLY IF LOCATION PASSED)
      // ========================================

      safeSetState(() {
        _faceAnalysisStatus = '🔍 Step 2: Starting face recognition...';
      });

      // Check if we have saved face validation data (reuse it)
      if (_faceValidationData != null) {
        // Invalidate cached face data if it doesn't belong to logged-in user
        final String? expectedStaffId = widget.staffId;
        final String cachedStaffId = (_faceValidationData!['staff_id'] ?? '')
            .toString();
        if (expectedStaffId != null &&
            expectedStaffId.isNotEmpty &&
            cachedStaffId != expectedStaffId) {
          _faceValidationData = null; // force fresh validation
        }
      }

      if (_faceValidationData != null) {
        safeSetState(() {
          _faceAnalysisStatus =
              '✅ STEP 2 PASSED: Using validated face data: ${_faceValidationData!['name']}';
        });
      } else {
        // Use already analyzed face data if available, otherwise capture new one
        List<double>? faceData = _capturedFaceEmbedding;

        if (faceData == null) {
          // Capture face and analyze if not already done
          safeSetState(() {
            _faceAnalysisStatus = '🔍 Step 2: Capturing face image...';
          });

          XFile imageFile = await _cameraController!.takePicture();

          await _analyzeFace(imageFile);
          faceData = _capturedFaceEmbedding;
        } else {}

        // Check if face analysis was successful
        if (faceData == null) {
          safeSetState(() {
            _lastResult = '❌ STEP 2 FAILED: No face detected';
            _faceAnalysisStatus = '❌ STEP 2 FAILED: No face detected';
          });
          _showError(
            'Face check failed!\n\nNo face detected in the image.\n\nPlease position your face clearly in the circle and try again.',
          );
          return; // STOP HERE - Face check failed
        }

        // Check if face validation was successful
        if (_faceAnalysisStatus != null &&
            _faceAnalysisStatus!.contains('No matching face found')) {
          safeSetState(() {
            _lastResult = '❌ STEP 2 FAILED: Face not recognized';
            _faceAnalysisStatus = '❌ STEP 2 FAILED: Face not recognized';
          });
          _showError(
            'Face check failed!\n\nFace not recognized in the system.\n\nPlease ensure you are enrolled in the system and try again.',
          );
          return; // STOP HERE - Face check failed
        }

        // Face check passed
        print('👤 ✅ STEP 2 PASSED: Face recognized successfully');
        safeSetState(() {
          _faceAnalysisStatus = '✅ STEP 2 PASSED: Face recognized successfully';
        });
        print('👤 ✅ Face check passed - proceeding to API call');
      }

      // ========================================
      // STEP 3: API CALL (ONLY IF BOTH LOCATION AND FACE PASSED)
      // ========================================

      print('Check action: ' + type);
      safeSetState(() {
        _faceAnalysisStatus = '📡 Step 3: Sending attendance data...';
      });

      // Prepare request data with location
      Map<String, dynamic> requestData = {'attendance_type': type};

      // Determine authoritative staff id: prefer logged-in id from dashboard
      final String? staffIdForRequest = widget.staffId;

      if (staffIdForRequest == null || staffIdForRequest.isEmpty) {
        _showError('Unable to determine user. Please login again.');
        safeSetState(() {
          _isProcessing = false;
        });
        return;
      }

      requestData['staff_id'] = staffIdForRequest;
      if (_currentPosition != null) {
        final double _lat = _currentPosition!.latitude;
        final double _lng = _currentPosition!.longitude;
        // Include multiple aliases to satisfy different backend expectations
        requestData['lat'] = _lat;
        requestData['lng'] = _lng;
        requestData['latitude'] = _lat;
        requestData['longitude'] = _lng;
        requestData['user_latitude'] = _lat;
        requestData['user_longitude'] = _lng;
      }
      if (_capturedFaceEmbedding != null) {
        requestData['face_data'] = _capturedFaceEmbedding;
      }

      // Call API with timeout
      final response = await AttendanceFlow.postTeacherAttendance(
        requestData,
      ).timeout(Duration(seconds: 15));

      // Simple response status
      print('Attendance API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Simple debug: match summary
        if (data['location_data'] is Map) {
          final loc = data['location_data'];
          print(
            'Match: ${loc['is_within_location']} (distance=${loc['distance']})',
          );
        }

        // Guard: treat non-success payloads as error even if HTTP 200
        final isSuccessPayload = (data['status'] == 'success');
        final isCheckIn = (data['attendance_type'] == 'check_in');
        final locationVerified = (data['location_verified'] == true);

        if (!isSuccessPayload || (isCheckIn && !locationVerified)) {
          // Show error in red
          final errMsg = data['message'] ?? 'Attendance failed';
          print('📡 ❌ Treating as error: $errMsg');
          print(
            'Check status: FAILED (' +
                (isCheckIn ? 'check_in' : 'check_out') +
                ') - ' +
                errMsg,
          );
          safeSetState(() {
            _lastResult = '❌ ${errMsg}';
            _faceAnalysisStatus = '❌ Attendance failed';
            _noMatchCount = 3; // force Try Again state
            _isProcessing = false; // stop spinner
            _faceValidationData = null; // require re-validation
          });
          // Overlay with distance details if available
          double? distance =
              (data['location_data'] != null &&
                  data['location_data']['distance'] is num)
              ? (data['location_data']['distance'] as num).toDouble()
              : (data['distance_from_school'] is num)
              ? (data['distance_from_school'] as num).toDouble()
              : null;
          distance ??= _computeDistanceMeters();
          // Overlay disabled per UX; keeping snackbar only
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errMsg),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        if (data.containsKey('location_data')) {
          print('📡 📍 Location verification details:');
          print(
            '📡 📍 Within location: ${data['location_data']['is_within_location']}',
          );
          print('📡 📍 Distance: ${data['location_data']['distance']} meters');
          // Persist distance for UI chip next to name
          final d = data['location_data']['distance'];
          if (d is num) {
            safeSetState(() {
              _lastDistanceMeters = d.toDouble();
            });
          }
        }

        if (data.containsKey('face_data')) {
          print('📡 👤 Face verification details:');
          print('📡 👤 Face recognized: ${data['face_data']['recognized']}');
          print('📡 👤 Similarity score: ${data['face_data']['similarity']}');
        }

        // Fallback: some responses may use distance_from_school at root
        if (_lastDistanceMeters == null &&
            data['distance_from_school'] is num) {
          safeSetState(() {
            _lastDistanceMeters = (data['distance_from_school'] as num)
                .toDouble();
          });
        }

        print('📡 ✅ STEP 3 PASSED: Attendance marked successfully!');
        print(
          'Check status: SUCCESS (' +
              (isCheckIn ? 'check_in' : 'check_out') +
              ')',
        );
        safeSetState(() {
          _lastResult =
              '✅ SUCCESS: ${data['name']} - ${data['message']} at ${data['time']}';
          _faceAnalysisStatus =
              '✅ STEP 3 PASSED: Attendance marked successfully';
        });
        // If checkout and outside radius, show non-blocking overlay warning with distance
        if (!isCheckIn && locationVerified != true) {
          double? distance =
              (data['location_data'] != null &&
                  data['location_data']['distance'] is num)
              ? (data['location_data']['distance'] as num).toDouble()
              : (data['distance_from_school'] is num)
              ? (data['distance_from_school'] as num).toDouble()
              : null;
          distance ??= _computeDistanceMeters();
          // Overlay disabled per UX
        }
        _showSuccess(data);
      } else {
        final error = jsonDecode(response.body);

        if (error['location_data'] is Map) {
          final loc = error['location_data'];
          print(
            'Match: ${loc['is_within_location']} (closest_distance=${loc['closest_distance']})',
          );
        }

        if (error.containsKey('similarity')) {
          print('📡 👤 Face error details:');
          print('📡 👤 Similarity score: ${error['similarity']}');
          print('📡 👤 Threshold: ${error['threshold']}');
        }

        print('📡 ❌ STEP 3 FAILED: API call failed');
        safeSetState(() {
          _lastResult = '❌ STEP 3 FAILED: ${error['message']}';
          _faceAnalysisStatus = '❌ STEP 3 FAILED: API call failed';
        });
        final errText = (error['message'] ?? 'Unknown error').toString();
        print('Check status: FAILED (' + (type) + ') - ' + errText);
        // Red error for failures
        final errMsg = 'API call failed: ${error['message']}';
        _showError(errMsg);
        // Overlay with distance if provided by backend error payload
        double? distance =
            (error['location_data'] != null &&
                error['location_data']['closest_distance'] is num)
            ? (error['location_data']['closest_distance'] as num).toDouble()
            : null;
        distance ??= _computeDistanceMeters();
        // Overlay disabled per UX
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('\n❌ ===========================================');
      print('❌ ATTENDANCE PROCESS FAILED');
      print('❌ ===========================================');
      print('❌ Error: $e');
      print('❌ Timestamp: ${DateTime.now()}');

      safeSetState(() {
        _lastResult = '❌ ERROR: $e';
        _faceAnalysisStatus = '❌ ERROR: $e';
      });
      _showError('Network error: $e');
    }

    print('\n🏁 ===========================================');
    print('🏁 ATTENDANCE PROCESS COMPLETED');
    print('🏁 ===========================================');
    print('🏁 Final Status: ${_lastResult ?? 'Unknown'}');
    print('🏁 Timestamp: ${DateTime.now()}');
    print('🏁 ===========================================\n');

    safeSetState(() {
      _isProcessing = false;
    });
  }

  /// Check user's current attendance status
  Future<void> _checkCurrentAttendanceStatus({String? explicitStaffId}) async {
    try {
      // Prefer explicit staff id (from dashboard), then fall back to validated face data
      final String? staffId =
          (explicitStaffId != null && explicitStaffId.isNotEmpty)
          ? explicitStaffId
          : (_faceValidationData != null &&
                _faceValidationData!['staff_id'] != null)
          ? _faceValidationData!['staff_id'].toString()
          : null;

      if (staffId == null || staffId.isEmpty) {
        // Cannot determine status without a staff id
        return;
      }

      final response = await AttendanceFlow.getSelfAttendanceStats(
        staffId,
        'date',
        DateTime.now().toIso8601String().split('T')[0],
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final todayStatus = data['data']['today_status'];
          final isCheckedIn =
              todayStatus['status'] == 'P' &&
              todayStatus['check_in_time'] != null;

          // Add distance data to face validation if available
          if (_faceValidationData != null &&
              todayStatus['distance_from_school'] != null) {
            _faceValidationData!['distance_from_school'] =
                todayStatus['distance_from_school'];
          }

          safeSetState(() {
            _isCurrentlyCheckedIn = isCheckedIn;
          });
        }
      }
    } catch (e) {
      print('Error checking attendance status: $e');
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(String errorResult) {
    if (errorResult.contains('No face detected')) {
      return 'No face detected in the image.\nPlease position your face clearly in the circle.';
    } else if (errorResult.contains('Face not recognized')) {
      return 'Face not recognized in the system.\nPlease ensure you are enrolled.';
    } else if (errorResult.contains('GPS Location failed')) {
      return 'Location access failed.\nPlease check location permissions.';
    } else if (errorResult.contains('Outside school')) {
      return 'You are outside the school area.\nPlease move to the school location.';
    } else if (errorResult.contains('API call failed')) {
      return 'Network error occurred.\nPlease check your internet connection.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  void _showSuccess(Map<String, dynamic> data) {
    // Show success message from backend response (avoid null)
    final action = _isCurrentlyCheckedIn ? 'Check-out' : 'Check-in';
    final backendMsg =
        (data['message'] is String &&
            (data['message'] as String).trim().isNotEmpty)
        ? data['message'] as String
        : '$action successful.';
    final who =
        (data['name'] is String && (data['name'] as String).trim().isNotEmpty)
        ? '${data['name']}! '
        : '';
    final timePart =
        (data['time'] is String && (data['time'] as String).trim().isNotEmpty)
        ? ' at ${data['time']}'
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$who$backendMsg$timePart'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Redirect to dashboard after a short delay with success result
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, true); // Go back to dashboard with success flag
      }
    });
  }

  void _showError(String message) {
    showErrorDialog(context, message);
  }

  // Lightweight overlay to show location distance warnings/errors
  void _showLocationOverlay({
    required String message,
    required double distanceMeters,
    _OverlaySeverity severity = _OverlaySeverity.warning,
  }) {
    showLocationOverlayDialog(
      context: context,
      message: message,
      distanceMeters: distanceMeters,
      schoolLocation: _schoolLocation,
      userLatitude: _currentPosition?.latitude,
      userLongitude: _currentPosition?.longitude,
      severity: severity == _OverlaySeverity.error
          ? OverlaySeverity.error
          : OverlaySeverity.warning,
    );
  }

  // Compute distance between mobile and school when backend distance is missing
  double? _computeDistanceMeters() {
    try {
      if (_currentPosition == null || _schoolLocation == null) return null;
      final lat1 = _currentPosition!.latitude;
      final lng1 = _currentPosition!.longitude;
      final lat2 = double.tryParse(
        (_schoolLocation!['latitude'] ?? '').toString(),
      );
      final lng2 = double.tryParse(
        (_schoolLocation!['longitude'] ?? '').toString(),
      );
      if (lat2 == null || lng2 == null) return null;
      return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    } catch (_) {
      return null;
    }
  }

  // Compact final debug summary for attendance API responses
  void _printBackendAttendanceSummary(
    Map<String, dynamic> payload, {
    required bool success,
  }) {
    try {
      final hasLocation = payload['location_data'] != null;
      final attendanceType = payload['attendance_type'];
      final msg = payload['message'];
      final name = payload['name'];
      final time = payload['time'];
      final loc = payload['location_data'];

      print(
        '\n════════════════════════ Attendance API Summary ════════════════════════',
      );
      print('Result: ${success ? 'SUCCESS' : 'ERROR'}');
      print('Attendance Type: ${attendanceType ?? '-'}');
      print('Message: ${msg ?? '-'}');
      print('Name: ${name ?? '-'}');
      print('Time: ${time ?? '-'}');
      print('Has location_data: $hasLocation');
      if (hasLocation && loc is Map) {
        print('location_data.is_within_location: ${loc['is_within_location']}');
        print('location_data.distance: ${loc['distance']}');
        print('location_data.school_latitude: ${loc['school_latitude']}');
        print('location_data.school_longitude: ${loc['school_longitude']}');
        print('location_data.user_latitude: ${loc['user_latitude']}');
        print('location_data.user_longitude: ${loc['user_longitude']}');
      }
      print('Raw payload: ${jsonEncode(payload)}');
      print(
        '══════════════════════════════════════════════════════════════════════\n',
      );
    } catch (e) {
      print('⚠️ Failed to print attendance summary: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetectionAnimationController.dispose();
    // Clear temporary face validation data when user goes back
    _faceValidationData = null;
    _capturedFaceEmbedding = null;
    print(
      'Teacher Attendance disposed - temporary face validation data cleared',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Clear temporary face validation data when user goes back
          _faceValidationData = null;
          _capturedFaceEmbedding = null;
          print(
            'User navigating back - temporary face validation data cleared',
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: CustomAppBar(
          title: 'Teacher Attendance',
          backgroundColor: Colors.black,
          primaryColor: Colors.black, // Color for curved top bar
          foregroundColor: Colors.white,
          automaticallyImplyLeading: true,
          showRoundedCorners:
              true, // Use curved/rounded corners from shared top bar
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black.withOpacity(0.95)],
          ),
          actions: [
            // Auto check-in/out toggle button with label
            Tooltip(
              message: _autoCheckEnabled
                  ? 'Auto check enabled - Turn off'
                  : 'Auto check disabled - Turn on',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Small text label when enabled
                  if (_autoCheckEnabled)
                    Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text(
                        'AUTO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Switch(
                    value: _autoCheckEnabled,
                    onChanged: (value) async {
                      // Save preference to phone storage
                      await _saveAutoCheckPreference(value);

                      safeSetState(() {
                        _autoCheckEnabled = value;
                      });

                      // If enabling and everything is already verified, trigger auto-check
                      if (value && _isEverythingVerified && !_isProcessing) {
                        _autoCheckInOut();
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Auto check enabled - Will automatically check in/out when ready'
                                : 'Auto check disabled - Manual check in/out required',
                          ),
                          backgroundColor: value ? Colors.green : Colors.grey,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.green[600]!, // Green when ON
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Camera Preview
            Expanded(
              flex: 4,
              child: _isInitialized
                  ? Stack(
                      children: [
                        // Ensure camera preview fills the entire area
                        Positioned.fill(
                          child: CameraPreview(_cameraController!),
                        ),
                        // Static Face Guide Frame - Simple centered frame (no tracking)
                        FaceTrackingOverlay(
                          isProcessing: _isProcessing,
                          isAnalyzingFace: _isAnalyzingFace,
                        ),
                        // Processing overlay - REMOVED (status shown in button instead)
                        // ProcessingOverlay(
                        //   isProcessing: _isProcessing,
                        //   isAnalyzingFace: _isAnalyzingFace,
                        //   faceAnalysisStatus: _faceAnalysisStatus,
                        // ),

                        // Floating debug panel: School & Mobile locations (toggleable)
                        if (_showInfoPanels)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SchoolMobileLocationPanel(
                                    schoolLocation: _schoolLocation,
                                    userLatitude: _currentPosition?.latitude,
                                    userLongitude: _currentPosition?.longitude,
                                    isProcessing: _isProcessing,
                                    isFetchingLocation: _isFetchingLocation,
                                    onRefresh: () async {
                                      await _forceFetchLocation();
                                    },
                                    onDiagnose: () async {
                                      await _diagnoseLocationIssues();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Verified User Name Overlay on Camera - Top Right
                        if (_isFaceValidatedForLoggedInUser)
                          Positioned(
                            top: 10,
                            right: 15,
                            child: VerifiedUserBadge(
                              name: _faceValidationData!['name']?.toString(),
                              lastDistanceMeters:
                                  _lastDistanceMeters ??
                                  ((_faceValidationData!['distance_from_school']
                                          is num)
                                      ? ((_faceValidationData!['distance_from_school']
                                                    as num)
                                                .toDouble() *
                                            1000)
                                      : null),
                              isWithinSchoolRadius: _isWithinSchoolRadius,
                              confidencePercent:
                                  (_faceValidationData!['confidence'] is double)
                                  ? _faceValidationData!['confidence'] as double
                                  : null,
                            ),
                          ),
                        // Top-left overlay: Logged-in and Face IDs (debug aid)
                        if (_showInfoPanels)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: DebugIdsPanel(
                              loggedInStaffId: widget.staffId,
                              faceStaffId: _faceValidationData != null
                                  ? _faceValidationData!['staff_id']?.toString()
                                  : (_lastDetectedStaffId ?? '-'),
                            ),
                          ),

                        // Toggle button to hide/show info overlays (top center)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  safeSetState(() {
                                    _showInfoPanels = !_showInfoPanels;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _showInfoPanels
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        _showInfoPanels
                                            ? 'Hide info'
                                            : 'Show info',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text(
                            'Loading Camera...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ),

            // Control Panel
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Dynamic Check In/Out Button - ALWAYS VISIBLE AT TOP (not scrollable)
                    // Use SizedBox to prevent button from being squished
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: CheckInOutButton(
                          schoolLocationLoaded: _schoolLocationLoaded,
                          schoolLocation: _schoolLocation,
                          isFetchingMobileLocation: _isFetchingLocation,
                          isProcessing: _isProcessing,
                          isAnalyzingFace: _isAnalyzingFace,
                          isFaceValidatedForLoggedInUser:
                              _isFaceValidatedForLoggedInUser,
                          faceAnalysisStatus: _faceAnalysisStatus,
                          noMatchCount: _noMatchCount,
                          isCurrentlyCheckedIn: _isCurrentlyCheckedIn,
                          onSchoolLocationNotSet: () => Navigator.pop(context),
                          onRestartFaceAnalysis: _restartFaceAnalysis,
                          onMarkAttendance: (type) => _markAttendance(type),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    // Scrollable area for other content (instructions)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Face Analysis Status - HIDDEN
                            if (false)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: _capturedFaceEmbedding != null
                                      ? Colors.green[900]
                                      : Colors.blue[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.face_retouching_natural,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _faceAnalysisStatus ??
                                            'Initializing camera and analyzing face automatically...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // GPS Location Display (controlled by _showGpsBanner)
                            if (_showGpsBanner && _currentPosition != null)
                              GpsBanner(
                                latitude: _currentPosition!.latitude,
                                longitude: _currentPosition!.longitude,
                              ),

                            // Location Status - HIDDEN
                            if (false)
                              LocationStatusPanel(
                                statusText: _locationStatus,
                                hasPosition: _currentPosition != null,
                                permissionGranted: _locationPermissionGranted,
                                onRetry: _isProcessing ? null : _retryLocation,
                                onTest: _isProcessing ? null : _testLocation,
                                onReAnalyzeFace: _isProcessing
                                    ? null
                                    : _clearFaceValidationData,
                                showReAnalyze: _faceValidationData != null,
                              ),

                            // Last Result - HIDDEN
                            if (false && _lastResult != null)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(15),
                                margin: EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: _lastResult!.startsWith('✅')
                                      ? Colors.green[900]
                                      : Colors.red[900],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _lastResult!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            // Error Display (hidden per UX request)
                            if (false &&
                                _lastResult != null &&
                                _lastResult!.startsWith('❌'))
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(15),
                                margin: EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.red[800],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Error',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _getErrorMessage(_lastResult!),
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                            // Instructions - HIDDEN
                            if (false)
                              // ignore: dead_code
                              Text(
                                _isProcessing || _isAnalyzingFace
                                    ? 'Getting GPS location and processing face...'
                                    : _isFaceValidatedForLoggedInUser
                                    ? 'Face validated! Click Check In/Out to get GPS location and mark attendance'
                                    : _capturedFaceEmbedding != null
                                    ? 'Face analysis complete! Click Check In/Out to get GPS location and mark attendance'
                                    : 'Face analysis in progress... Please wait for automatic detection',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),

                            // Dynamic Instructions
                            AttendanceInstructions(
                              isAnalyzingFace: _isAnalyzingFace,
                              isProcessing: _isProcessing,
                              isFetchingMobileLocation: _isFetchingLocation,
                              schoolLocationLoaded: _schoolLocationLoaded,
                              isFaceValidatedForLoggedInUser:
                                  _isFaceValidatedForLoggedInUser,
                              faceAnalysisStatus: _faceAnalysisStatus,
                              noMatchCount: _noMatchCount,
                              hasFaceEmbedding: _capturedFaceEmbedding != null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Progress Bar at Bottom - Always Visible
            BottomStatusBar(
              isProcessing: _isProcessing,
              isAnalyzingFace: _isAnalyzingFace,
              isFaceValidatedForLoggedInUser: _isFaceValidatedForLoggedInUser,
              bottomStatusMessage: _bottomStatusMessage,
            ),
          ],
        ),
      ),
    );
  }
}

enum _OverlaySeverity { warning, error }

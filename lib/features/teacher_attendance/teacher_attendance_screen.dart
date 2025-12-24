import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/config/api_config.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  _TeacherAttendanceScreenState createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _detectedUser;
  double? _confidence;
  String? _lastAttendanceTime;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        // Find front camera for face recognition
        CameraDescription? frontCamera;
        for (var camera in _cameras!) {
          if (camera.lensDirection == CameraLensDirection.front) {
            frontCamera = camera;
            break;
          }
        }

        // Use front camera if available, otherwise fall back to first camera
        final selectedCamera = frontCamera ?? _cameras![0];

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _detectedUser = null;
      _confidence = null;
    });

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();

      // Process face recognition
      await _processFaceRecognition(image);
    } catch (e) {
      print('Error capturing image: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processFaceRecognition(XFile image) async {
    try {
      // Simulate face embedding (replace with actual ML model)
      List<double> faceEmbedding = _generateMockEmbedding();

      // Call attendance API
      await _markAttendance(faceEmbedding, 'check_in');
    } catch (e) {
      print('Face recognition error: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  List<double> _generateMockEmbedding() {
    // Generate 192-dimensional mock embedding
    List<double> embedding = [];
    for (int i = 0; i < 192; i++) {
      embedding.add((i % 10) * 0.1);
    }
    return embedding;
  }

  Future<void> _markAttendance(
    List<double> faceData,
    String attendanceType,
  ) async {
    try {
      final baseUrl = ApiConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/quickAttendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'face_data': faceData,
          'attendance_type': attendanceType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _detectedUser = data['name'];
          _confidence = data['confidence'].toDouble();
          _lastAttendanceTime = data['time'];
          _isProcessing = false;
        });

        // Show success message
        _showSuccessDialog(data);
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog(errorData['message']);
      }
    } catch (e) {
      print('API call error: $e');
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Network error. Please try again.');
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Success!', style: TextStyle(color: Colors.green)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome ${data['name']}!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Confidence: ${data['confidence']}%'),
              Text('Time: ${data['time']}'),
              Text('Date: ${data['date']}'),
              Text('Status: ${data['message']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('Error', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Teacher Attendance',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: _isInitialized
                ? Stack(
                    children: [
                      CameraPreview(_cameraController!),
                      // Face detection overlay
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isProcessing
                                  ? Colors.orange
                                  : Colors.white,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(125),
                          ),
                        ),
                      ),
                      // Processing indicator
                      if (_isProcessing)
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 10),
                                Text(
                                  'Processing...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
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
                          'Initializing Camera...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
          ),

          // Control Panel
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Detection Results
                  if (_detectedUser != null)
                    Container(
                      padding: EdgeInsets.all(15),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.green[900],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Detected: $_detectedUser',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Confidence: ${_confidence?.toStringAsFixed(1)}%',
                            style: TextStyle(color: Colors.white70),
                          ),
                          if (_lastAttendanceTime != null)
                            Text(
                              'Last: $_lastAttendanceTime',
                              style: TextStyle(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _captureAndProcess,
                          icon: Icon(Icons.login),
                          label: Text('Check In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _markAttendance(
                                  _generateMockEmbedding(),
                                  'check_out',
                                ),
                          icon: Icon(Icons.logout),
                          label: Text('Check Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),

                  // Status Text
                  Text(
                    _isProcessing
                        ? 'Processing face recognition...'
                        : 'Position your face in the circle and tap Check In/Out',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

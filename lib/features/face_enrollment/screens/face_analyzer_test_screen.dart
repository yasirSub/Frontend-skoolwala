import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/face_analyzer_service.dart';
import '../../attendance/services/google_ml_face_service.dart';

class FaceAnalyzerTestScreen extends StatefulWidget {
  const FaceAnalyzerTestScreen({super.key});

  @override
  State<FaceAnalyzerTestScreen> createState() => _FaceAnalyzerTestScreenState();
}

class _FaceAnalyzerTestScreenState extends State<FaceAnalyzerTestScreen> {
  bool _isLoading = false;
  String _statusMessage = 'Ready to test';
  Map<String, dynamic>? _lastResult;
  List<Map<String, dynamic>> _enrolledFaces = [];

  // Camera functionality
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isAnalyzing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _loadEnrolledFaces();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      CameraDescription? frontCamera;

      // Find front camera
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      final selectedCamera = frontCamera ?? cameras.first;

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera initialization failed: $e';
          _isCameraReady = false;
        });
      }
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _statusMessage = 'Camera not ready';
      });
      return;
    }

    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Capturing and analyzing face...';
    });

    try {
      // Capture image
      final image = await _cameraController!.takePicture();

      // Process image for face detection
      final result = await GoogleMLFaceService.processCameraImage(image);

      if (result == null || result.embedding.isEmpty) {
        setState(() {
          _statusMessage =
              'No face detected. Please position your face in the camera view.';
          _isAnalyzing = false;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Face detected! Analyzing...';
      });

      // Analyze face using our analyzer
      final analysisResult = await FaceAnalyzerService.analyzeFace(
        faceData: result.embedding,
      );

      setState(() {
        _lastResult = analysisResult;
        _isAnalyzing = false;

        if (analysisResult['matched'] == true) {
          final name = analysisResult['name'] ?? 'Unknown';
          final confidence = analysisResult['confidence'] ?? 0;
          _statusMessage = '✅ Recognized: $name (${confidence}% confidence)';
        } else {
          _statusMessage =
              '❌ Face not recognized. Try enrolling this face first.';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Analysis failed: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledFaces() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading enrolled faces...';
    });

    try {
      final faces = await FaceAnalyzerService.getEnrolledFaces();
      setState(() {
        _enrolledFaces = faces;
        _statusMessage = 'Found ${faces.length} enrolled faces';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load enrolled faces: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAnalyzer() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing analyzer...';
    });

    try {
      final result = await FaceAnalyzerService.testAnalyzer();
      setState(() {
        _lastResult = result;
        _statusMessage = result['message'] ?? 'Test completed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testFaceAnalysis() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing face analysis...';
    });

    try {
      // Create a dummy embedding for testing
      final dummyEmbedding = List.generate(512, (index) => 0.0);

      final result = await FaceAnalyzerService.analyzeFace(
        faceData: dummyEmbedding,
      );
      setState(() {
        _lastResult = result;
        _statusMessage = result['message'] ?? 'Analysis completed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Analysis failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Analyzer Test', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadEnrolledFaces,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Analyzer Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Face Analyzer Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.api,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'API Endpoint:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'POST /api/face/analyze',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.blue[800],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.storage,
                                color: Colors.green[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Database Tables:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'staff_face, staff_face_3d',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.green[800],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.speed,
                                color: Colors.orange[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Threshold:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '0.65 (Same as F2F System)',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.orange[800],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Camera Preview Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Face Scanner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_cameraError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _cameraError!,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      )
                    else if (_isCameraReady && _cameraController != null)
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    else
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Initializing camera...'),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing || !_isCameraReady
                            ? null
                            : _captureAndAnalyze,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt),
                        label: Text(
                          _isAnalyzing ? 'Analyzing...' : 'Scan Face',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testAnalyzer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Analyzer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testFaceAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Analysis'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Last Result
            if (_lastResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _lastResult!['matched'] == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _lastResult!['matched'] == true
                                ? Colors.green
                                : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _lastResult!['matched'] == true
                                ? 'Face Recognized'
                                : 'Face Not Recognized',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _lastResult!['matched'] == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_lastResult!['matched'] == true) ...[
                        _buildResultRow(
                          'Name',
                          _lastResult!['name'] ?? 'Unknown',
                        ),
                        _buildResultRow(
                          'Staff ID',
                          _lastResult!['staff_id']?.toString() ?? 'N/A',
                        ),
                        _buildResultRow(
                          'Email',
                          _lastResult!['email'] ?? 'N/A',
                        ),
                        _buildResultRow(
                          'Mobile',
                          _lastResult!['mobile'] ?? 'N/A',
                        ),
                        _buildResultRow(
                          'Confidence',
                          '${_lastResult!['confidence'] ?? 0}%',
                        ),
                        _buildResultRow(
                          'Similarity',
                          _lastResult!['similarity']?.toString() ?? 'N/A',
                        ),
                      ] else ...[
                        _buildResultRow(
                          'Message',
                          _lastResult!['message'] ?? 'No match found',
                        ),
                        _buildResultRow(
                          'Similarity',
                          _lastResult!['similarity']?.toString() ?? 'N/A',
                        ),
                        _buildResultRow(
                          'Threshold',
                          _lastResult!['threshold']?.toString() ?? 'N/A',
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          'Raw Result: ${_lastResult.toString()}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 12),

            // Enrolled Faces List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Enrolled Faces',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text('${_enrolledFaces.length} faces'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200, // Fixed height instead of Expanded
                      child: _enrolledFaces.isEmpty
                          ? const Center(child: Text('No enrolled faces found'))
                          : ListView.builder(
                              itemCount: _enrolledFaces.length,
                              itemBuilder: (context, index) {
                                final face = _enrolledFaces[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      face['name']
                                              ?.toString()
                                              .substring(0, 1)
                                              .toUpperCase() ??
                                          '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    face['name']?.toString() ?? 'Unknown',
                                  ),
                                  subtitle: Text(
                                    'Staff ID: ${face['staff_id']}',
                                  ),
                                  trailing: Text(
                                    face['model_name']?.toString() ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

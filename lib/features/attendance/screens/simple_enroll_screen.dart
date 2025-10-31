import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:skoolwala/features/attendance/services/google_ml_face_service.dart';
import 'package:skoolwala/features/face/services/face_api_service.dart';
import 'package:skoolwala/shared/services/session_manager.dart';

class SimpleEnrollScreen extends StatefulWidget {
  const SimpleEnrollScreen({super.key});

  @override
  State<SimpleEnrollScreen> createState() => _SimpleEnrollScreenState();
}

class _SimpleEnrollScreenState extends State<SimpleEnrollScreen> {
  CameraController? _controller;
  bool _ready = false;
  bool _busy = false;
  String? _error;

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
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _controller = ctrl;
        _ready = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Camera init failed: $e';
      });
    }
  }

  Future<void> _captureAndEnroll() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final x = await _controller!.takePicture();
      final result = await GoogleMLFaceService.processCameraImage(x);
      if (result == null || result.embedding.isEmpty) {
        setState(() {
          _error = 'No face found. Try again.';
        });
        return;
      }
      final staffId = SessionManager.instance.teacherId?.toString();
      if (staffId == null || staffId.isEmpty) {
        setState(() {
          _error = 'No user session. Please login again.';
        });
        return;
      }

      print('📝 Enrollment: Embedding size: ${result.embedding.length}');
      print(
        '📝 Enrollment: First 5 embedding values: ${result.embedding.take(5).toList()}',
      );

      // STEP 1: Check for duplicate face before enrolling
      print('🔍 Checking for duplicate face...');
      final duplicateCheck = await FaceApiService.checkFaceDuplicate(
        embedding: result.embedding,
      );
      print('🔍 Duplicate check result: $duplicateCheck');

      if (!mounted) return;

      if (duplicateCheck['status'] == 'duplicate_found') {
        setState(() {
          _error =
              'This face is already registered to another user. Please use a different face or contact admin.';
        });
        return;
      } else if (duplicateCheck['status'] == 'error') {
        setState(() {
          _error =
              'Failed to check for duplicates: ${duplicateCheck['message']}';
        });
        return;
      }

      // STEP 2: If no duplicate, proceed with enrollment
      print('✅ No duplicate found, proceeding with enrollment...');
      final resp = await FaceApiService.enrollFace(
        staffId: staffId,
        embedding: result.embedding,
      );
      print('📝 Enrollment Result: $resp');

      if (!mounted) return;
      if (resp['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face enrolled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = resp['message']?.toString() ?? 'Enroll failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Enroll failed: $e';
      });
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll Face', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _controller != null
                      ? CameraPreview(_controller!)
                      : const SizedBox.shrink(),
                ),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFFEE2E2),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFF991B1B)),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _captureAndEnroll,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Capture & Enroll'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

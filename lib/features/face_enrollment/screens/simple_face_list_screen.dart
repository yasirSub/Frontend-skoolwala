import 'package:flutter/material.dart';
import '../services/simple_face_api.dart';

class SimpleFaceListScreen extends StatefulWidget {
  const SimpleFaceListScreen({super.key});

  @override
  State<SimpleFaceListScreen> createState() => _SimpleFaceListScreenState();
}

class _SimpleFaceListScreenState extends State<SimpleFaceListScreen> {
  List<Map<String, dynamic>> _enrolledFaces = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadEnrolledFaces();
  }

  Future<void> _loadEnrolledFaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final faces = await SimpleFaceApi.getEnrolledFaces();
      setState(() {
        _enrolledFaces = faces;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load enrolled faces: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFace(int staffId) async {
    try {
      final result = await SimpleFaceApi.deleteFaceEnrollment(staffId: staffId);

      if (result['status'] == 'success') {
        _showSnackBar('Face enrollment deleted successfully', Colors.green);
        _loadEnrolledFaces(); // Refresh the list
      } else {
        _showSnackBar('Failed to delete: ${result['message']}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrolled Faces'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnrolledFaces,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadEnrolledFaces,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _enrolledFaces.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.face_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No enrolled faces found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadEnrolledFaces,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _enrolledFaces.length,
                itemBuilder: (context, index) {
                  final face = _enrolledFaces[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (face['staff_id'] != null)
                            Text('Staff ID: ${face['staff_id']}'),
                          if (face['email'] != null)
                            Text('Email: ${face['email']}'),
                          if (face['mobile'] != null)
                            Text('Mobile: ${face['mobile']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(face),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> face) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Face Enrollment'),
        content: Text(
          'Are you sure you want to delete the face enrollment for "${face['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFace(face['staff_id'] as int);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:skoolwala/features/face/services/face_api_service.dart';
import 'package:skoolwala/shared/services/session_manager.dart';

class EnrolledFacesListScreen extends StatefulWidget {
  const EnrolledFacesListScreen({super.key});

  @override
  State<EnrolledFacesListScreen> createState() =>
      _EnrolledFacesListScreenState();
}

class _EnrolledFacesListScreenState extends State<EnrolledFacesListScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // First check teacher profile to confirm enrollment flag
      final profile = await FaceApiService.teacherProfile();
      if (profile['status'] == 'success') {
        final data = profile['data'] as Map<String, dynamic>?;
        final faceEnrolled = (data?['face_enrolled'] ?? false) == true;
        if (!faceEnrolled) {
          setState(() {
            _rows = const [];
            _loading = false;
          });
          return;
        }
      }

      final resp = await FaceApiService.listEnrolledFaces();
      if (resp['status'] == 'success') {
        setState(() {
          _rows = (resp['data'] as List?) ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = resp['message']?.toString() ?? 'Failed to load faces';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        // Handle non-JSON or HTML server responses gracefully
        _error =
            'Error: $e\n\nIf this is HTML, the base URL may be wrong or the session expired.';
        _loading = false;
      });
    }
  }

  Future<void> _deleteFaceEnrollment(String userId, String userName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Face Enrollment'),
        content: Text(
          'Are you sure you want to delete the face enrollment for "$userName"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Deleting face enrollment...'),
          ],
        ),
      ),
    );

    try {
      final response = await FaceApiService.deleteFaceEnrollment(
        userId: userId,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response['status'] == 'success') {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Face enrollment for "$userName" deleted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload the list
        await _load();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete: ${response['message'] ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting face enrollment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFaceDataDetails(Map<String, dynamic> faceData) {
    final name = faceData['name']?.toString() ?? 'Unknown';
    final staffId = faceData['staff_id']?.toString() ?? '-';
    final model = faceData['model_name']?.toString() ?? 'mobilefacenet';
    final createdAt = faceData['created_at']?.toString() ?? 'Unknown';

    // Get embedding counts
    final embeddingCount = faceData['embedding_count'] ?? 0;
    final straightCount = faceData['embedding_straight_count'] ?? 0;
    final rightCount = faceData['embedding_right_count'] ?? 0;
    final leftCount = faceData['embedding_left_count'] ?? 0;

    // Get actual embedding data
    final embedding = faceData['embedding'] as List<dynamic>?;
    final embeddingStraight = faceData['embedding_straight'] as List<dynamic>?;
    final embeddingRight = faceData['embedding_right'] as List<dynamic>?;
    final embeddingLeft = faceData['embedding_left'] as List<dynamic>?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Face Data - $name'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Staff ID: $staffId'),
              Text('Model: $model'),
              Text('Enrolled: $createdAt'),
              const SizedBox(height: 16),
              const Text(
                'Face Embeddings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildEmbeddingSection('Basic', embeddingCount, embedding),
              _buildEmbeddingSection(
                'Straight',
                straightCount,
                embeddingStraight,
              ),
              _buildEmbeddingSection('Right', rightCount, embeddingRight),
              _buildEmbeddingSection('Left', leftCount, embeddingLeft),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddingSection(String label, int count, List<dynamic>? data) {
    final hasData = count > 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasData ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasData ? Colors.blue : Colors.grey,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasData ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: hasData ? Colors.blue[700] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                '$label Embedding',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasData ? Colors.blue[700] : Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                '$count dimensions',
                style: TextStyle(
                  fontSize: 12,
                  color: hasData ? Colors.blue[600] : Colors.grey[500],
                ),
              ),
            ],
          ),
          if (hasData && data != null && data.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Values: [${data.take(10).join(', ')}${data.length > 10 ? '...' : ''}]',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteCurrentUserFace() async {
    final sessionManager = SessionManager.instance;
    final currentTeacher = sessionManager.currentTeacher;

    if (currentTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No current user found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _deleteFaceEnrollment(
      currentTeacher.id.toString(),
      currentTeacher.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrolled Faces'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : (_rows.isEmpty
                ? const Center(child: Text('No enrolled faces'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, index) {
                        final row = _rows[index] as Map<String, dynamic>;
                        final name = row['name']?.toString() ?? '-';
                        final staffId = row['staff_id']?.toString() ?? '-';
                        final model =
                            row['model_name']?.toString() ?? 'mobilefacenet';
                        final createdAt = row['created_at']?.toString() ?? '';

                        // Get embedding counts for multi-angle data
                        final embeddingCount = row['embedding_count'] ?? 0;
                        final straightCount =
                            row['embedding_straight_count'] ?? 0;
                        final rightCount = row['embedding_right_count'] ?? 0;
                        final leftCount = row['embedding_left_count'] ?? 0;

                        // Check if this is the current user
                        final sessionManager = SessionManager.instance;
                        final currentTeacher = sessionManager.currentTeacher;
                        final isCurrentUser =
                            currentTeacher?.id.toString() == staffId;

                        return ListTile(
                          leading: Icon(
                            isCurrentUser ? Icons.person : Icons.person_outline,
                            color: isCurrentUser ? Colors.blue : null,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: isCurrentUser
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrentUser ? Colors.blue : null,
                            ),
                          ),
                          subtitle: Text(
                            'ID: $staffId  •  Model: $model\n'
                            'Face Data: Basic($embeddingCount) Straight($straightCount) Right($rightCount) Left($leftCount)\n'
                            '$createdAt',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'view') {
                                _showFaceDataDetails(row);
                              } else if (value == 'delete') {
                                _deleteFaceEnrollment(staffId, name);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('View Face Data'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete Enrollment'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _deleteCurrentUserFace,
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.delete_forever),
        label: const Text('Delete My Face'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:skoolwala/features/attendance/services/face_enrollment_service.dart';
import 'package:skoolwala/features/attendance/services/face_attendance_service.dart';
import 'package:skoolwala/shared/services/session_manager.dart';

/// Dashboard widget for face recognition and attendance management
class FaceRecognitionDashboard extends StatefulWidget {
  const FaceRecognitionDashboard({super.key});

  @override
  State<FaceRecognitionDashboard> createState() =>
      _FaceRecognitionDashboardState();
}

class _FaceRecognitionDashboardState extends State<FaceRecognitionDashboard> {
  bool _isLoading = true;
  bool _isEnrolled = false;
  Map<String, dynamic> _enrollmentStats = {};
  Map<String, dynamic> _attendanceStats = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current user
      final sessionManager = SessionManager.instance;
      final currentTeacher = sessionManager.currentTeacher;

      if (currentTeacher == null) {
        setState(() {
          _errorMessage = 'User session not found';
          _isLoading = false;
        });
        return;
      }

      final userId = currentTeacher.id.toString();

      // Check enrollment status
      _isEnrolled = await FaceEnrollmentService.isUserEnrolled(userId);

      // Load enrollment statistics
      _enrollmentStats = await FaceEnrollmentService.getEnrollmentStats();

      // Load attendance statistics
      _attendanceStats = await FaceAttendanceService.getAttendanceStats(userId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnrollmentStatusCard(),
            const SizedBox(height: 16),
            _buildStatisticsCard(),
            const SizedBox(height: 16),
            _buildQuickActionsCard(),
            const SizedBox(height: 16),
            _buildAttendanceHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isEnrolled ? Icons.face : Icons.face_retouching_off,
                  color: _isEnrolled ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Face Enrollment Status',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isEnrolled ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isEnrolled ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEnrolled ? Icons.check_circle : Icons.warning,
                    color: _isEnrolled ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEnrolled
                          ? 'Your face is enrolled and ready for attendance verification'
                          : 'Please enroll your face to use attendance verification',
                      style: TextStyle(
                        color: _isEnrolled
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isEnrolled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to face enrollment
                    Navigator.pushNamed(
                      context,
                      '/face-verification',
                      arguments: false,
                    );
                  },
                  icon: const Icon(Icons.face),
                  label: const Text('Enroll Face'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Statistics',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Enrollments',
                    '${_enrollmentStats['total_enrollments'] ?? 0}',
                    Icons.people,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Active Enrollments',
                    '${_enrollmentStats['active_enrollments'] ?? 0}',
                    Icons.face,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_attendanceStats.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'This Month',
                      '${_attendanceStats['this_month'] ?? 0}',
                      Icons.calendar_month,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      'This Week',
                      '${_attendanceStats['this_week'] ?? 0}',
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEnrolled) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/face-verification',
                          arguments: true,
                        );
                      },
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Mark Attendance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/face-verification',
                          arguments: false,
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Re-enroll'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/face-verification',
                      arguments: false,
                    );
                  },
                  icon: const Icon(Icons.face),
                  label: const Text('Enroll Face First'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHistoryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.indigo, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_enrollmentStats['last_enrollment'] != null) ...[
              ListTile(
                leading: const Icon(Icons.face, color: Colors.green),
                title: const Text('Last Face Enrollment'),
                subtitle: Text(_enrollmentStats['last_enrollment']),
                dense: true,
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('System Status'),
              subtitle: const Text('Face recognition system is operational'),
              dense: true,
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

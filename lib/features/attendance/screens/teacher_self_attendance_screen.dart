// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/teacher_self_attendance_service.dart';

class TeacherSelfAttendanceScreen extends StatefulWidget {
  const TeacherSelfAttendanceScreen({super.key});

  @override
  State<TeacherSelfAttendanceScreen> createState() =>
      _TeacherSelfAttendanceScreenState();
}

class _TeacherSelfAttendanceScreenState
    extends State<TeacherSelfAttendanceScreen> {
  bool _isLoading = false;
  String? _todayStatus;
  String? _checkInTime;
  String? _checkOutTime;
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final response = await TeacherSelfAttendanceService.getTodayAttendance();
      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          _todayStatus = response['data']['status'];
          _checkInTime = response['data']['in_time'];
          _checkOutTime = response['data']['out_time'];
        });
      }
    } catch (e) {
      debugPrint('Error loading today attendance: $e');
    }
  }

  Future<void> _checkIn() async {
    setState(() => _isLoading = true);

    try {
      final response = await TeacherSelfAttendanceService.checkIn(
        remark: _remarkController.text.isNotEmpty
            ? _remarkController.text
            : null,
      );

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Checked in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadTodayAttendance(); // Refresh data
        _remarkController.clear();
      } else {
        _showError(response['message'] ?? 'Failed to check in');
      }
    } catch (e) {
      _showError('Error checking in: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() => _isLoading = true);

    try {
      final response = await TeacherSelfAttendanceService.checkOut(
        remark: _remarkController.text.isNotEmpty
            ? _remarkController.text
            : null,
      );

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Checked out successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
        await _loadTodayAttendance(); // Refresh data
        _remarkController.clear();
      } else {
        _showError(response['message'] ?? 'Failed to check out');
      }
    } catch (e) {
      _showError('Error checking out: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAbsent() async {
    setState(() => _isLoading = true);

    try {
      final response = await TeacherSelfAttendanceService.markAbsent(
        remark: _remarkController.text.isNotEmpty
            ? _remarkController.text
            : null,
      );

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Marked as absent successfully!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadTodayAttendance(); // Refresh data
        _remarkController.clear();
      } else {
        _showError(response['message'] ?? 'Failed to mark absent');
      }
    } catch (e) {
      _showError('Error marking absent: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Status',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                    if (_checkInTime != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.login,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('Check In: $_checkInTime'),
                        ],
                      ),
                    ],
                    if (_checkOutTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('Check Out: $_checkOutTime'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Remark Field
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remark (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _remarkController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter any remarks...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue[600]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Check In Button
        if (_todayStatus != 'P' || _checkInTime == null)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _checkIn,
            icon: const Icon(Icons.login),
            label: const Text('Check In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

        if (_todayStatus != 'P' || _checkInTime == null)
          const SizedBox(height: 12),

        // Check Out Button
        if (_todayStatus == 'P' &&
            _checkInTime != null &&
            _checkOutTime == null)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _checkOut,
            icon: const Icon(Icons.logout),
            label: const Text('Check Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

        if (_todayStatus == 'P' &&
            _checkInTime != null &&
            _checkOutTime == null)
          const SizedBox(height: 12),

        // Mark Absent Button
        if (_todayStatus != 'A')
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _markAbsent,
            icon: const Icon(Icons.cancel),
            label: const Text('Mark Absent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (_todayStatus) {
      case 'P':
        return Icons.check_circle;
      case 'A':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor() {
    switch (_todayStatus) {
      case 'P':
        return Colors.green;
      case 'A':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_todayStatus) {
      case 'P':
        return 'Present';
      case 'A':
        return 'Absent';
      default:
        return 'Not Marked';
    }
  }
}

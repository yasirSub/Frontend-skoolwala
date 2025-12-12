import 'package:flutter/material.dart';
import 'package:skoolwala/shared/models/teacher.dart';
import 'package:skoolwala/shared/services/api_service.dart';
import 'package:skoolwala/features/auth/services/profile_service.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/features/auth/screens/login_screen.dart';
import 'package:skoolwala/shared/services/persistent_storage.dart';
import '../services/developer_attendance_service.dart';
import '../services/dummy_data_service.dart';

class DeveloperAttendanceFAB extends StatefulWidget {
  final Teacher teacher;

  const DeveloperAttendanceFAB({super.key, required this.teacher});

  @override
  State<DeveloperAttendanceFAB> createState() => _DeveloperAttendanceFABState();
}

class _DeveloperAttendanceFABState extends State<DeveloperAttendanceFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Menu items
        if (_isOpen) ...[
          // Generate attendance options
          _buildMenuItem(
            icon: Icons.add_circle,
            label: 'Generate Today',
            color: Colors.green,
            onTap: () => _generateAttendance('today'),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.calendar_today,
            label: 'Generate Month',
            color: Colors.blue,
            onTap: () => _generateAttendance('month'),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.event_note,
            label: 'Generate Year',
            color: Colors.indigo,
            onTap: () => _generateAttendance('year'),
          ),
          const SizedBox(height: 16),
          // Delete attendance options
          _buildMenuItem(
            icon: Icons.delete_outline,
            label: 'Delete Today',
            color: Colors.orange,
            onTap: () => _deleteAttendance('today'),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.calendar_month,
            label: 'Delete Month',
            color: Colors.red,
            onTap: () => _deleteAttendance('month'),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.date_range,
            label: 'Delete Range',
            color: Colors.purple,
            onTap: () => _deleteAttendance('range'),
          ),
          const SizedBox(height: 8),
          // Debug options
          _buildMenuItem(
            icon: Icons.bug_report,
            label: 'Test API',
            color: Colors.teal,
            onTap: () => _testApiConnection(),
          ),
          const SizedBox(height: 16),
          // Logout button
          _buildMenuItem(
            icon: Icons.logout,
            label: 'Logout',
            color: Colors.red.shade700,
            onTap: () => _handleLogout(),
          ),
          const SizedBox(height: 8),
        ],
        // Main FAB
        FloatingActionButton(
          onPressed: _toggleMenu,
          backgroundColor: _isOpen ? Colors.red : Colors.deepOrange,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isOpen ? Icons.close : Icons.developer_mode,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      scale: _animation,
      child: FloatingActionButton.small(
        onPressed: onTap,
        backgroundColor: color,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAttendance(String type) async {
    _toggleMenu(); // Close menu first

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate Attendance - ${type.toUpperCase()}'),
        content: Text(
          'Are you sure you want to generate attendance records for ${widget.teacher.name}?\n\n'
          'This will create dummy attendance data for $type.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog with debug info
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Generating $type attendance...'),
            const SizedBox(height: 8),
            Text(
              'API: ${ApiService.currentApiUrl}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Staff ID: ${widget.teacher.id}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      print('🚀 Starting attendance generation for ${widget.teacher.name}');
      print('📊 Type: $type');
      print('🆔 Staff ID: ${widget.teacher.id}');
      print('🌐 API URL: ${ApiService.currentApiUrl}');

      Map<String, dynamic> result = await DummyDataService.generateDummyData(
        staffId: int.parse(widget.teacher.id),
        type: type,
        pattern: 'mixed', // Default to mixed pattern
      );

      print('✅ Generation result: $result');

      // Close loading dialog
      Navigator.of(context).pop();

      // Show detailed result
      _showDetailedResult('Generate Attendance', result);
    } catch (e) {
      print('❌ Generation error: $e');

      // Close loading dialog
      Navigator.of(context).pop();

      // Show detailed error
      _showDetailedError('Generate Attendance', e);
    }
  }

  Future<void> _testApiConnection() async {
    _toggleMenu(); // Close menu first

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Testing API connection...'),
            const SizedBox(height: 8),
            Text(
              'API: ${ApiService.currentApiUrl}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      print('🔍 Testing API connection to: ${ApiService.currentApiUrl}');

      // Test basic connection
      final isConnected = await ApiService.testConnection();

      if (isConnected) {
        print('✅ Basic connection test passed');

        // Test specific endpoints
        final staffListResult = await DummyDataService.getStaffList();
        print(
          '✅ Staff list endpoint test passed: ${staffListResult.length} staff found',
        );

        // Close loading dialog
        Navigator.of(context).pop();

        // Show success
        _showDetailedResult('API Connection Test', {
          'status': 'success',
          'message': 'All API endpoints are working correctly',
          'details': {
            'api_url': ApiService.currentApiUrl,
            'basic_connection': 'OK',
            'staff_list_endpoint': 'OK',
            'staff_count': staffListResult.length,
            'current_staff_id': widget.teacher.id,
            'current_staff_name': widget.teacher.name,
          },
        });
      } else {
        throw Exception('Basic connection test failed');
      }
    } catch (e) {
      print('❌ API test error: $e');

      // Close loading dialog
      Navigator.of(context).pop();

      // Show detailed error
      _showDetailedError('API Connection Test', e);
    }
  }

  void _showDetailedResult(String operation, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$operation - Success'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ ${result['message'] ?? 'Operation completed successfully'}',
              ),
              if (result['generated_count'] != null) ...[
                const SizedBox(height: 8),
                Text('📊 Generated: ${result['generated_count']} records'),
              ],
              if (result['type'] != null) ...[
                const SizedBox(height: 4),
                Text('📅 Type: ${result['type']}'),
              ],
              if (result['pattern'] != null) ...[
                const SizedBox(height: 4),
                Text('🎯 Pattern: ${result['pattern']}'),
              ],
              if (result['staff_name'] != null) ...[
                const SizedBox(height: 4),
                Text('👤 Staff: ${result['staff_name']}'),
              ],
              const SizedBox(height: 12),
              const Text(
                '🔍 Debug Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.toString(),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Also show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Operation completed successfully'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDetailedError(String operation, dynamic error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$operation - Error'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('❌ ${error.toString()}'),
              const SizedBox(height: 12),
              const Text(
                '🔍 Debug Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('API URL: ${ApiService.currentApiUrl}'),
                    Text('Staff ID: ${widget.teacher.id}'),
                    Text('Staff Name: ${widget.teacher.name}'),
                    Text('Error Type: ${error.runtimeType}'),
                    Text('Timestamp: ${DateTime.now().toIso8601String()}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Also show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _deleteAttendance(String type) async {
    _toggleMenu(); // Close menu first

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Attendance - ${type.toUpperCase()}'),
        content: Text(
          'Are you sure you want to delete attendance records for ${widget.teacher.name}?\n\n'
          'This action cannot be undone.',
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

    // Show loading dialog with debug info
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Deleting $type attendance...'),
            const SizedBox(height: 8),
            Text(
              'API: ${ApiService.currentApiUrl}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Staff ID: ${widget.teacher.id}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      print('🗑️ Starting attendance deletion for ${widget.teacher.name}');
      print('📊 Type: $type');
      print('🆔 Staff ID: ${widget.teacher.id}');
      print('🌐 API URL: ${ApiService.currentApiUrl}');

      Map<String, dynamic> result;

      switch (type) {
        case 'today':
          result = await DeveloperAttendanceService.deleteTodayAttendance(
            int.parse(widget.teacher.id),
          );
          break;
        case 'month':
          final now = DateTime.now();
          result = await DeveloperAttendanceService.deleteMonthAttendance(
            int.parse(widget.teacher.id),
            now.year,
            now.month,
          );
          break;
        case 'range':
          result = await _showDateRangeDialog();
          break;
        default:
          result = {'status': 'error', 'message': 'Invalid type'};
      }

      print('✅ Deletion result: $result');

      // Close loading dialog
      Navigator.of(context).pop();

      // Show detailed result
      if (result['status'] == 'success') {
        _showDetailedResult('Delete Attendance', result);
      } else {
        _showDetailedError(
          'Delete Attendance',
          Exception(result['message'] ?? 'Unknown error'),
        );
      }
    } catch (e) {
      print('❌ Deletion error: $e');

      // Close loading dialog
      Navigator.of(context).pop();

      // Show detailed error
      _showDetailedError('Delete Attendance', e);
    }
  }

  Future<Map<String, dynamic>> _showDateRangeDialog() async {
    DateTime? startDate;
    DateTime? endDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Date Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(
                  startDate?.toIso8601String().split('T')[0] ?? 'Select date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        startDate ??
                        DateTime.now().subtract(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => startDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('End Date'),
                subtitle: Text(
                  endDate?.toIso8601String().split('T')[0] ?? 'Select date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => endDate = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop({'status': 'cancelled'}),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: startDate != null && endDate != null
                  ? () => Navigator.of(context).pop({
                      'status': 'success',
                      'start_date': startDate!.toIso8601String().split('T')[0],
                      'end_date': endDate!.toIso8601String().split('T')[0],
                    })
                  : null,
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    if (result?['status'] == 'success') {
      return await DeveloperAttendanceService.deleteDateRangeAttendance(
        int.parse(widget.teacher.id),
        result!['start_date'],
        result['end_date'],
      );
    } else {
      return {'status': 'cancelled', 'message': 'Operation cancelled'};
    }
  }

  Future<void> _handleLogout() async {
    _toggleMenu(); // Close menu first

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // Capture context before async operations
      final navigatorContext = context;
      try {
        // Call logout API if we have teacher data
        if (widget.teacher.username.isNotEmpty) {
          await ProfileService.logoutTeacher(username: widget.teacher.username);
        }

        // Clear session and persistent storage (but keep selected school)
        await SessionManager.instance.logout();

        // Get saved school name for login screen
        final savedSchool = await PersistentStorage.getSelectedSchool();
        final schoolName = savedSchool?['name'] ?? 'SKOOLWALA INSTITUTION';

        // Navigate to login screen (not school selection)
        if (mounted) {
          Navigator.of(navigatorContext).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => LoginScreen(schoolName: schoolName),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        // Even if logout fails, still clear session and navigate back
        await SessionManager.instance.logout();

        // Get saved school name for login screen
        final savedSchool = await PersistentStorage.getSelectedSchool();
        final schoolName = savedSchool?['name'] ?? 'SKOOLWALA INSTITUTION';

        if (mounted) {
          Navigator.of(navigatorContext).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => LoginScreen(schoolName: schoolName),
            ),
            (route) => false,
          );
        }
      }
    }
  }
}

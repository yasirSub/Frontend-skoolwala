import 'package:flutter/material.dart';
import 'package:skoolwala/shared/widgets/animated_face_scan.dart';
import 'package:skoolwala/features/attendance/services/attendance_service.dart';

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _markAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mark teacher self-attendance
      await AttendanceService.markTeacherAttendance(
        action: 'mark',
        status: 'P', // Present
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to mark attendance: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0A2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0A2A),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Mark Attendance'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0A2A), Color(0xFF1B1960)],
          ),
        ),
        child: Column(
          children: [
            const Expanded(child: Center(child: AnimatedFaceScan())),
            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    // ignore: deprecated_member_use
                    color: const Color(0xFF991B1B).withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Color(0xFF991B1B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10C69C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _markAttendance,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Mark Attendance'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:skoolwala/features/teacher_attendance/teacher_statistics_screen.dart';

import '../../../shared/services/session_manager.dart';

class TeacherSelfAttendanceScreen extends StatelessWidget {
  const TeacherSelfAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staffId = SessionManager.instance.teacherId;

    if (staffId == null || staffId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please login again to view attendance.')),
      );
    }

    // Unified Self Attendance (Insights + history) lives here.
    return TeacherStatisticsScreen(staffId: staffId);
  }
}

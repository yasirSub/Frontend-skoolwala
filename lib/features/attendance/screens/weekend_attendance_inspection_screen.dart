import 'package:flutter/material.dart';
import 'package:skoolwala/features/attendance/services/attendance_service.dart';
import 'package:skoolwala/features/teacher/screens/teacher_schedule_screen.dart';
import 'package:skoolwala/features/teacher_attendance/teacher_statistics_screen.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';

class WeekendAttendanceInspectionScreen extends StatefulWidget {
  const WeekendAttendanceInspectionScreen({super.key});

  @override
  State<WeekendAttendanceInspectionScreen> createState() =>
      _WeekendAttendanceInspectionScreenState();
}

class _WeekendAttendanceInspectionScreenState
    extends State<WeekendAttendanceInspectionScreen> {
  Future<_SelfAttendanceCounts>? _selfCountsFuture;

  @override
  void initState() {
    super.initState();
    _selfCountsFuture = _loadSelfAttendanceCounts();
  }

  Future<void> _refresh() async {
    setState(() {
      _selfCountsFuture = _loadSelfAttendanceCounts();
    });
    await _selfCountsFuture;
  }

  Future<_SelfAttendanceCounts> _loadSelfAttendanceCounts() async {
    final present = await AttendanceService.getTeacherPresentDaysCount();
    final absent = await AttendanceService.getTeacherAbsentDaysCount();

    int asInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    final presentDays = asInt(present['present_days'] ?? present['data']);
    final absentDays = asInt(absent['absent_days'] ?? absent['data']);

    return _SelfAttendanceCounts(
      presentDays: presentDays,
      absentDays: absentDays,
    );
  }

  void _openSelfAttendanceInsights() {
    final staffId = SessionManager.instance.teacherId;
    if (staffId == null || staffId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherStatisticsScreen(staffId: staffId),
      ),
    );
  }

  void _openStudentAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherScheduleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffId = SessionManager.instance.teacherId;
    final canOpenSelf = staffId != null && staffId.isNotEmpty;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Weekend Inspection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Pull to refresh',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.75),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            final selfPanel = _InspectionPanel(
              title: 'Self Attendance',
              subtitle: 'Your presence/absence overview',
              child: FutureBuilder<_SelfAttendanceCounts>(
                future: _selfCountsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: const LinearProgressIndicator(minHeight: 3),
                      ),
                    );
                  }

                  final counts =
                      snapshot.data ??
                      const _SelfAttendanceCounts(
                        presentDays: 0,
                        absentDays: 0,
                      );

                  final hasError = snapshot.hasError;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasError)
                        Text(
                          'Could not load counts right now.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (hasError) const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatTile(
                              label: 'Present',
                              value: counts.presentDays.toString(),
                              color: AppTheme.successGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStatTile(
                              label: 'Absent',
                              value: counts.absentDays.toString(),
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: _PrimaryGradientButton(
                          label: 'OPEN SELF ATTENDANCE',
                          icon: Icons.person_rounded,
                          onPressed: canOpenSelf
                              ? _openSelfAttendanceInsights
                              : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
            );

            final studentPanel = _InspectionPanel(
              title: 'Student Attendance',
              subtitle: 'Open schedule and mark attendance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use your schedule to open a class and mark attendance.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: _PrimaryGradientButton(
                      label: 'OPEN SCHEDULE',
                      icon: Icons.calendar_view_week_rounded,
                      onPressed: _openStudentAttendance,
                    ),
                  ),
                ],
              ),
            );

            final content = isWide
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: selfPanel),
                        const SizedBox(width: 16),
                        Expanded(child: studentPanel),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      selfPanel,
                      const SizedBox(height: 16),
                      studentPanel,
                    ],
                  );

            return RefreshIndicator(
              onRefresh: _refresh,
              color: Colors.white,
              backgroundColor: AppTheme.dashboardPrimary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '2 Sections',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  content,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InspectionPanel extends StatelessWidget {
  const _InspectionPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.buttonShadow,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textGray,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfAttendanceCounts {
  const _SelfAttendanceCounts({
    required this.presentDays,
    required this.absentDays,
  });

  final int presentDays;
  final int absentDays;
}

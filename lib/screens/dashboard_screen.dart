// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:skoolwala/features/attendance/screens/attendance_scan_screen.dart';
import 'package:skoolwala/features/dashboard/models/profile.dart';
import 'package:skoolwala/features/dashboard/services/dashboard_service.dart';
import 'package:skoolwala/features/teacher_attendance/simple_teacher_attendance.dart';
import 'package:skoolwala/shared/utils/safe_widget_operations.dart';
import 'package:skoolwala/shared/utils/layout_boundary_fix.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  final String password;

  const DashboardScreen({
    super.key,
    required this.username,
    required this.password,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SafeWidgetMixin, LayoutBoundaryMixin {
  Profile? _profile;
  bool _showSuccess = false;
  bool _showError = false;
  bool _isLoading = true;
  int _totalStudents = 0;
  int _totalPresent = 0;
  int _totalAbsent = 0;
  String? _schoolName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Load all dashboard data from multiple APIs
      final dashboardData = await DashboardService.fetchDashboardData(
        username: widget.username,
        password: widget.password,
      );

      // Convert Teacher to Profile for backward compatibility
      final profile = Profile.fromTeacher(
        dashboardData.teacher,
        presentDays: dashboardData.presentDays,
        absentDays: dashboardData.absentDays,
      );

      // Use safe setState to prevent layout boundary errors
      safeSetState(() {
        _profile = profile;
        _totalStudents = dashboardData.totalStudents;
        _totalPresent = dashboardData.presentDays;
        _totalAbsent = dashboardData.absentDays;
        _schoolName = dashboardData.school?.name;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      safeSetState(() {
        _isLoading = false;
      });
      // Show error to user safely
      safeShowSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openScan() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AttendanceScanScreen()),
    );
    if (!mounted) return;
    setState(() {
      _showSuccess = result == true;
      _showError = result == false;
    });
  }

  Future<void> _openTeacherAttendance() async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder: (_) => SimpleTeacherAttendance(
          staffId: _profile?.id, // pass logged-in staff id
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131247),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(profile: _profile, schoolName: _schoolName),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          _StatCardsRow(
                            presentDays: _profile?.presentDays ?? 0,
                            absentDays: _profile?.absentDays ?? 0,
                          ),
                          const SizedBox(height: 12),
                          _MarkAttendanceCard(onTap: _openScan),
                          const SizedBox(height: 10),
                          _TeacherAttendanceCard(onTap: _openTeacherAttendance),
                          const SizedBox(height: 10),
                          if (_showSuccess)
                            const _InfoBanner.success(
                              'Success! Marked Attendance successfully.',
                            ),
                          if (_showSuccess) const SizedBox(height: 8),
                          if (_showError)
                            const _InfoBanner.error(
                              'Error! Face not recognized.',
                            ),
                          SizedBox(height: 12),
                          _TotalStudentsCard(totalStudents: _totalStudents),
                          const SizedBox(height: 12),
                          const _StudentAttendanceCTA(),
                          const SizedBox(height: 12),
                          _TotalsRow(
                            totalPresent: _totalPresent,
                            totalAbsent: _totalAbsent,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Profile? profile;
  final String? schoolName;
  const _Header({this.profile, this.schoolName});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 240,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF221F73), Color(0xFF3E2CA2)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFF4E6A), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome back! 👋',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0E0E2C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile?.fullName ?? '—',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF1A1A48),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoleChip(
                        icon: Icons.work_outline,
                        label: profile?.role ?? 'Role',
                      ),
                      const SizedBox(width: 14),
                      const _DividerDot(),
                      const SizedBox(width: 14),
                      _RoleChip(
                        icon: Icons.location_pin,
                        label: schoolName ?? 'SkoolWala',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 0,
          right: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6C88), Color(0xFFFFB6C3)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              CircleAvatar(
                radius: 48,
                backgroundImage: profile == null
                    ? null
                    : AssetImage(profile!.avatarAssetPath),
                backgroundColor: const Color(0xFFEDEBFF),
                child: profile == null
                    ? const Icon(Icons.person, size: 36)
                    : null,
              ),
              Positioned(
                right: 12,
                bottom: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF1F2A60),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.remove_red_eye,
                    size: 18,
                    color: Color(0xFF1F2A60),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RoleChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5A5AA0)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2C2C66),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DividerDot extends StatelessWidget {
  const _DividerDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.5,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFFDFDFEF),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _StatCardsRow extends StatelessWidget {
  final int presentDays;
  final int absentDays;

  const _StatCardsRow({required this.presentDays, required this.absentDays});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            title: 'Present Days',
            value: presentDays.toString(),
            buttonText: 'View',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            title: 'Absent days',
            value: absentDays.toString(),
            buttonText: 'View',
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String buttonText;
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2376), Color(0xFF6D63B8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0E0E2C),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {},
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkAttendanceCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _MarkAttendanceCard({this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF241A78), Color(0xFF0E0D3A)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF38308E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mark Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mark Your Attendance',
                    style: TextStyle(
                      color: Color(0xFFBDB8FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _InOutChip(label: 'IN', active: true),
                const SizedBox(height: 8),
                _InOutChip(label: 'OUT', active: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InOutChip extends StatelessWidget {
  final String label;
  final bool active;
  const _InOutChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF1E175E) : Colors.white70,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TotalStudentsCard extends StatelessWidget {
  final int totalStudents;

  const _TotalStudentsCard({required this.totalStudents});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2376), Color(0xFF6D63B8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.engineering, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Students',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalStudents.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0E0E2C),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {},
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

class _StudentAttendanceCTA extends StatelessWidget {
  const _StudentAttendanceCTA();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10C69C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.group, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark Attendance',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mark Student Attendance',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final int totalPresent;
  final int totalAbsent;

  const _TotalsRow({required this.totalPresent, required this.totalAbsent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TotalBox(
            color: const Color(0xFF2BBE63),
            title: 'Total Present',
            value: totalPresent.toString(),
            icon: Icons.person,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TotalBox(
            color: const Color(0xFFFF4E6A),
            title: 'Total Absent',
            value: totalAbsent.toString(),
            icon: Icons.person_off,
          ),
        ),
      ],
    );
  }
}

class _TotalBox extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  final IconData icon;
  const _TotalBox({
    required this.color,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherAttendanceCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _TeacherAttendanceCard({this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10C69C), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Quick Check In/Out',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _InOutChip(label: 'IN', active: true),
                const SizedBox(height: 8),
                _InOutChip(label: 'OUT', active: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String text;

  const _InfoBanner.success(this.text)
    : bg = const Color(0xFFD9FBE7),
      fg = const Color(0xFF166534),
      icon = Icons.check_circle;

  const _InfoBanner.error(this.text)
    : bg = const Color(0xFFFEE2E2),
      fg = const Color(0xFF991B1B),
      icon = Icons.error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.close, size: 18, color: fg),
          ),
        ],
      ),
    );
  }
}

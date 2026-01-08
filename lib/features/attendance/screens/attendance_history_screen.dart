import 'package:flutter/material.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import '../services/attendance_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final int presentDays;
  final int absentDays;
  final String username;
  final String password;

  const AttendanceHistoryScreen({
    super.key,
    required this.presentDays,
    required this.absentDays,
    required this.username,
    required this.password,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Attendance type variables
  int _attendanceType = 0;
  String _attendanceTypeDisplay = 'Day-Wise Attendance';
  bool _attendanceTypeLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAttendanceType();
  }

  Future<void> _loadAttendanceType() async {
    try {
      final response = await AttendanceService.getAttendanceType();
      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          _attendanceType = response['data']['attendance_type'] ?? 0;
          _attendanceTypeDisplay =
              response['data']['type_display'] ?? 'Day-Wise Attendance';
          _attendanceTypeLoading = false;
        });
      }
    } catch (e) {
      print('Error loading attendance type: $e');
      setState(() {
        _attendanceTypeLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.presentDays + widget.absentDays;
    final attendancePercentage = totalDays > 0
        ? (widget.presentDays / totalDays * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Attendance History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Attendance Circle Progress
                  _AttendanceCircle(
                    percentage: double.parse(attendancePercentage),
                    presentDays: widget.presentDays,
                    absentDays: widget.absentDays,
                  ),
                  const SizedBox(height: 16),
                  // Attendance Type Badge
                  if (!_attendanceTypeLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _attendanceType == 0
                                ? Icons.calendar_today
                                : Icons.book,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _attendanceTypeDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryPurple,
                unselectedLabelColor: AppTheme.textGray,
                indicatorColor: AppTheme.primaryPurple,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Calendar'),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(
                    presentDays: widget.presentDays,
                    absentDays: widget.absentDays,
                  ),
                  _CalendarTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCircle extends StatelessWidget {
  final double percentage;
  final int presentDays;
  final int absentDays;

  const _AttendanceCircle({
    required this.percentage,
    required this.presentDays,
    required this.absentDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF10C69C),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Attendance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(
                icon: Icons.check_circle_rounded,
                label: 'Present',
                value: presentDays.toString(),
                color: const Color(0xFF10C69C),
              ),
              const SizedBox(width: 24),
              _StatBadge(
                icon: Icons.cancel_rounded,
                label: 'Absent',
                value: absentDays.toString(),
                color: const Color(0xFFFF4E6A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final int presentDays;
  final int absentDays;

  const _OverviewTab({required this.presentDays, required this.absentDays});

  @override
  Widget build(BuildContext context) {
    final totalDays = presentDays + absentDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          // Bar Chart
          _AttendanceBarChart(presentDays: presentDays, absentDays: absentDays),
          const SizedBox(height: 24),
          Text(
            'Monthly Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _MonthlyCard(
            month: 'Current Month',
            present: presentDays,
            absent: absentDays,
            total: totalDays,
          ),
          const SizedBox(height: 12),
          _InsightsCard(presentDays: presentDays, absentDays: absentDays),
        ],
      ),
    );
  }
}

class _AttendanceBarChart extends StatelessWidget {
  final int presentDays;
  final int absentDays;

  const _AttendanceBarChart({
    required this.presentDays,
    required this.absentDays,
  });

  @override
  Widget build(BuildContext context) {
    final total = presentDays + absentDays;
    final maxValue = total > 0 ? total : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.smallShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BarColumn(
                label: 'Present',
                value: presentDays,
                maxValue: maxValue,
                color: const Color(0xFF10C69C),
              ),
              _BarColumn(
                label: 'Absent',
                value: absentDays,
                maxValue: maxValue,
                color: const Color(0xFFFF4E6A),
              ),
              _BarColumn(
                label: 'Total',
                value: total,
                maxValue: maxValue,
                color: AppTheme.primaryPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const _BarColumn({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final height = maxValue > 0 ? (value / maxValue * 120.0) : 0.0;

    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height < 20 ? 20 : height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textGray,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MonthlyCard extends StatelessWidget {
  final String month;
  final int present;
  final int absent;
  final int total;

  const _MonthlyCard({
    required this.month,
    required this.present,
    required this.absent,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0
        ? (present / total * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.smallShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: AppTheme.primaryPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.check_circle_rounded,
                  label: 'Present',
                  value: present.toString(),
                  color: const Color(0xFF10C69C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  icon: Icons.cancel_rounded,
                  label: 'Absent',
                  value: absent.toString(),
                  color: const Color(0xFFFF4E6A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final int presentDays;
  final int absentDays;

  const _InsightsCard({required this.presentDays, required this.absentDays});

  @override
  Widget build(BuildContext context) {
    final total = presentDays + absentDays;
    final percentage = total > 0 ? (presentDays / total * 100) : 0.0;

    String message;
    IconData icon;
    Color color;

    if (percentage >= 90) {
      message = 'Excellent attendance! Keep up the great work! 🌟';
      icon = Icons.emoji_events_rounded;
      color = const Color(0xFF10C69C);
    } else if (percentage >= 75) {
      message = 'Good attendance! Try to improve further.';
      icon = Icons.thumb_up_rounded;
      color = AppTheme.primaryPurple;
    } else if (percentage >= 60) {
      message = 'Fair attendance. Focus on being more regular.';
      icon = Icons.warning_amber_rounded;
      color = AppTheme.warningOrange;
    } else {
      message = 'Low attendance. Please attend regularly.';
      icon = Icons.error_outline_rounded;
      color = AppTheme.errorRed;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight',
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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

class _CalendarTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 80,
              color: AppTheme.textGray,
            ),
            const SizedBox(height: 16),
            Text(
              'Calendar View',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calendar view with attendance marking will be available in the next update.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textGray),
            ),
          ],
        ),
      ),
    );
  }
}

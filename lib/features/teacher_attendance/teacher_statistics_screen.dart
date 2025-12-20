import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../shared/config/api_config.dart';
import '../../../shared/theme/app_theme.dart';

class TeacherStatisticsScreen extends StatefulWidget {
  final String staffId;

  const TeacherStatisticsScreen({super.key, required this.staffId});

  @override
  State<TeacherStatisticsScreen> createState() =>
      _TeacherStatisticsScreenState();
}

class _TeacherStatisticsScreenState extends State<TeacherStatisticsScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? statisticsData;
  bool isLoading = true;
  String? error;
  String selectedFilterType = 'month';
  String selectedFilterValue = DateTime.now().toString().substring(0, 7);

  // Animation controllers
  late AnimationController _loadingAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _staggerAnimationController;

  // Animations
  late Animation<double> _loadingAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _staggerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start loading animation
    _loadingAnimationController.forward();

    loadStatistics();
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    _contentAnimationController.dispose();
    _staggerAnimationController.dispose();
    super.dispose();
  }

  Future<void> loadStatistics() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final baseUrl = ApiConfig.getBaseUrl();
      final url = Uri.parse(
        '$baseUrl/getTeacherSelfAttendanceStats?staff_id=${widget.staffId}&filter_type=$selectedFilterType&filter_value=$selectedFilterValue',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              statisticsData = data['data'];
              isLoading = false;
            });

            // Start content animations
            _contentAnimationController.forward();
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) _staggerAnimationController.forward();
            });
          }
        } else {
          if (mounted) {
            setState(() {
              error = data['message'] ?? 'Failed to load statistics';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            error = 'Server error: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Error loading statistics: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadStatistics() async {
    _contentAnimationController.reset();
    _staggerAnimationController.reset();
    await loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? _buildAnimatedLoadingView()
                : error != null
                ? _buildErrorWidget()
                : _buildStatisticsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLoadingView() {
    return FadeTransition(
      opacity: _loadingAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryPurple,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing Attendance...',
              style: AppTheme.headingSmall.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('Gathering your latest insights', style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B61FF), Color(0xFF6246EA)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7B61FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              _buildFilterBadge(),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Attendance Insights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Performance and tracking analysis',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Text(
            selectedFilterValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 72,
              color: AppTheme.errorRed.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text('Oops! Something went wrong', style: AppTheme.headingSmall),
            const SizedBox(height: 8),
            Text(
              error ?? 'We couldn\'t load your statistics.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: loadStatistics,
              style: AppTheme.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent() {
    if (statisticsData == null) return const SizedBox();

    return FadeTransition(
      opacity: _contentAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(_contentAnimation),
        child: RefreshIndicator(
          onRefresh: _reloadStatistics,
          color: AppTheme.primaryPurple,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedSection(_buildTodayStatus(), 0.0, 0.3),
                const SizedBox(height: 28),
                _buildAnimatedSection(_buildOverviewGrid(), 0.2, 0.5),
                const SizedBox(height: 28),
                _buildAnimatedSection(_buildAttendanceChart(), 0.4, 0.7),
                const SizedBox(height: 28),
                _buildSectionHeader('Monthly Activity'),
                const SizedBox(height: 16),
                _buildAnimatedSection(_buildAttendanceRecords(), 0.6, 1.0),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(Widget child, double start, double end) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _staggerAnimationController,
              curve: Interval(start, end, curve: Curves.easeOutCubic),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerAnimationController,
          curve: Interval(start, end, curve: Curves.easeIn),
        ),
        child: child,
      ),
    );
  }

  Widget _buildTodayStatus() {
    final todayStatus = statisticsData!['today_status'] as Map<String, dynamic>;
    final status = todayStatus['status'] as String;

    Color statusColor;
    IconData statusIcon;
    List<Color> gradient;

    switch (status) {
      case 'P':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.verified_rounded;
        gradient = [const Color(0xFF00C49A), const Color(0xFF00B4D8)];
        break;
      case 'A':
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel_rounded;
        gradient = [const Color(0xFFFF4858), const Color(0xFFFF2A3A)];
        break;
      case 'H':
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.time_to_leave_rounded;
        gradient = [const Color(0xFFFFB020), const Color(0xFFFF8F00)];
        break;
      case 'L':
        statusColor = AppTheme.primaryPurple;
        statusIcon = Icons.timer_rounded;
        gradient = [const Color(0xFF7B61FF), const Color(0xFF6246EA)];
        break;
      default:
        statusColor = AppTheme.textGray;
        statusIcon = Icons.help_rounded;
        gradient = [AppTheme.textGray, AppTheme.textGray.withOpacity(0.8)];
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: statusColor.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Status',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todayStatus['status_text'] ?? 'Unknown',
                      style: AppTheme.headingSmall.copyWith(
                        color: statusColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (todayStatus['check_in_time'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      todayStatus['check_in_time'],
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('Check-in', style: AppTheme.bodySmall),
                  ],
                ),
            ],
          ),
          if (todayStatus['face_verified'] ||
              todayStatus['location_verified']) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (todayStatus['face_verified'])
                  _buildStatusChip(
                    'Face Verified',
                    Icons.face_retouching_natural_rounded,
                    Colors.teal,
                  ),
                if (todayStatus['location_verified'])
                  _buildStatusChip(
                    'Location Match',
                    Icons.location_on_rounded,
                    Colors.blue,
                  ),
                if (todayStatus['gps_verified'])
                  _buildStatusChip(
                    'GPS Fixed',
                    Icons.gps_fixed_rounded,
                    Colors.indigo,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid() {
    final summaryStats =
        statisticsData!['summary_stats'] as Map<String, dynamic>;

    return Row(
      children: [
        Expanded(
          child: _PremiumOverviewCard(
            title: 'Present',
            value: summaryStats['present_days'].toString(),
            subtitle: '${summaryStats['present_percentage']}% Rate',
            icon: Icons.check_circle_rounded,
            gradient: const [Color(0xFF00C49A), Color(0xFF00B4D8)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PremiumOverviewCard(
            title: 'Absent',
            value: summaryStats['absent_days'].toString(),
            subtitle: 'This Period',
            icon: Icons.cancel_rounded,
            gradient: const [Color(0xFFFF4858), Color(0xFFFFB020)],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    final summaryStats =
        statisticsData!['summary_stats'] as Map<String, dynamic>;
    final total = summaryStats['total_days'] as int;
    final present = summaryStats['present_days'] as int;
    final absent = summaryStats['absent_days'] as int;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: present,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C49A), Color(0xFF00B4D8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Expanded(flex: total - present, child: const SizedBox()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegend('Present', present, const Color(0xFF00C49A)),
              _buildLegend('Absent', absent, const Color(0xFFFF4858)),
              _buildLegend('Total Days', total, AppTheme.textGray),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.headingSmall.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    );
  }

  Widget _buildAttendanceRecords() {
    final records = statisticsData!['attendance_records'] as List;

    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: AppTheme.textGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No recent records found',
              style: TextStyle(color: AppTheme.textGray),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.take(10).length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildRecordListItem(record);
      },
    );
  }

  Widget _buildRecordListItem(Map<String, dynamic> record) {
    final status = record['status'] as String;
    Color color;
    switch (status) {
      case 'P':
        color = AppTheme.successGreen;
        break;
      case 'A':
        color = AppTheme.errorRed;
        break;
      case 'H':
        color = AppTheme.warningOrange;
        break;
      default:
        color = AppTheme.primaryPurple;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.smallShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _formatDay(record['date']),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _formatMonth(record['date']),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['status_text'] ?? 'Unknown',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (record['check_in_time'] != null)
                  Text(
                    'Time: ${record['check_in_time']}',
                    style: AppTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (record['face_verified'])
            Icon(
              Icons.face_unlock_rounded,
              color: Colors.teal.withOpacity(0.5),
              size: 20,
            ),
        ],
      ),
    );
  }

  String _formatDay(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return dt.day.toString();
    } catch (_) {
      return '--';
    }
  }

  String _formatMonth(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      return months[dt.month - 1];
    } catch (_) {
      return '---';
    }
  }
}

class _PremiumOverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _PremiumOverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 10,
              color: AppTheme.textGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

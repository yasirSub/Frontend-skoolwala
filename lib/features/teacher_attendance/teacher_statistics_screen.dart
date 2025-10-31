// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../shared/config/api_config.dart';

class TeacherStatisticsScreen extends StatefulWidget {
  final String staffId;

  const TeacherStatisticsScreen({
    super.key,
    required this.staffId,
  });

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
  String selectedFilterValue = '2025-10';

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
          setState(() {
            statisticsData = data['data'];
            isLoading = false;
          });

          // Start content animations
          _contentAnimationController.forward();
          Future.delayed(const Duration(milliseconds: 200), () {
            _staggerAnimationController.forward();
          });
        } else {
          setState(() {
            error = data['message'] ?? 'Failed to load statistics';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading statistics: $e';
        isLoading = false;
      });
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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [
                    Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    Theme.of(context).primaryColor.withValues(alpha: 0.02),
                  ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated container with pulsing effect
              AnimatedBuilder(
                animation: _loadingAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (_loadingAnimation.value * 0.2),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Animated text
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _loadingAnimationController,
                        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _loadingAnimationController,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Loading Statistics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fetching your attendance insights...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
        16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics & Analytics',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your attendance insights',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error ?? 'Unknown error',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loadStatistics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
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
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_contentAnimation),
        child: RefreshIndicator(
          onRefresh: _reloadStatistics,
          color: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).cardColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedTodayStatus(),
                const SizedBox(height: 28),
                _buildAnimatedOverviewCards(),
                const SizedBox(height: 28),
                _buildAnimatedAttendanceChart(),
                const SizedBox(height: 28),
                _buildAnimatedAttendanceRecords(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTodayStatus() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _staggerAnimationController,
              curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerAnimationController,
          curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
        ),
        child: _buildTodayStatus(),
      ),
    );
  }

  Widget _buildAnimatedOverviewCards() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _staggerAnimationController,
              curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerAnimationController,
          curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
        ),
        child: _buildOverviewCards(),
      ),
    );
  }

  Widget _buildAnimatedAttendanceChart() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _staggerAnimationController,
              curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerAnimationController,
          curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
        ),
        child: _buildAttendanceChart(),
      ),
    );
  }

  Widget _buildAnimatedAttendanceRecords() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _staggerAnimationController,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerAnimationController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        ),
        child: _buildAttendanceRecords(),
      ),
    );
  }

  Widget _buildTodayStatus() {
    final todayStatus = statisticsData!['today_status'] as Map<String, dynamic>;

    Color statusColor;
    IconData statusIcon;

    switch (todayStatus['status']) {
      case 'P':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'A':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'H':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'L':
        statusColor = Colors.blue;
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(todayStatus['date'])} - ${todayStatus['status_text']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (todayStatus['check_in_time'] != null ||
              todayStatus['check_out_time'] != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                if (todayStatus['check_in_time'] != null) ...[
                  Expanded(
                    child: _buildTimeInfo(
                      'Check In',
                      todayStatus['check_in_time'],
                      Icons.login,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (todayStatus['check_out_time'] != null)
                  Expanded(
                    child: _buildTimeInfo(
                      'Check Out',
                      todayStatus['check_out_time'],
                      Icons.logout,
                      Colors.blue,
                    ),
                  ),
              ],
            ),
          ],
          if (todayStatus['working_hours'] != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Working Hours: ${todayStatus['working_hours']} hrs',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (todayStatus['face_verified'])
                _buildVerificationChip('Face', Icons.face, Colors.teal),
              if (todayStatus['location_verified'])
                _buildVerificationChip(
                  'Location',
                  Icons.location_on,
                  Colors.purple,
                ),
              if (todayStatus['gps_verified'])
                _buildVerificationChip('GPS', Icons.gps_fixed, Colors.indigo),
              if (!todayStatus['face_verified'] &&
                  !todayStatus['location_verified'] &&
                  !todayStatus['gps_verified'])
                _buildVerificationChip('Manual', Icons.back_hand, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationChip(String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final summaryStats =
        statisticsData!['summary_stats'] as Map<String, dynamic>;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                title: 'Attendance Rate',
                value: '${summaryStats['present_percentage']}%',
                icon: Icons.trending_up,
                color: const Color(0xFF2BBE63),
                subtitle:
                    '${summaryStats['present_days']}/${summaryStats['total_days']} days',
                isAnimated: true,
                animationDelay: const Duration(milliseconds: 200),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewCard(
                title: 'Present Days',
                value: summaryStats['present_days'].toString(),
                icon: Icons.check_circle,
                color: const Color(0xFF10C69C),
                subtitle: 'This ${statisticsData!['filter_info']['type']}',
                isAnimated: true,
                animationDelay: const Duration(milliseconds: 400),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                title: 'Absent Days',
                value: summaryStats['absent_days'].toString(),
                icon: Icons.cancel,
                color: const Color(0xFFFF4E6A),
                subtitle: 'This ${statisticsData!['filter_info']['type']}',
                isAnimated: true,
                animationDelay: const Duration(milliseconds: 600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewCard(
                title: 'Half Days',
                value: summaryStats['half_days'].toString(),
                icon: Icons.schedule,
                color: const Color(0xFFFF9500),
                subtitle: 'This ${statisticsData!['filter_info']['type']}',
                isAnimated: true,
                animationDelay: const Duration(milliseconds: 800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    final summaryStats =
        statisticsData!['summary_stats'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: summaryStats['present_days'],
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2BBE63),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: summaryStats['absent_days'],
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4E6A),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendItem(
                color: const Color(0xFF2BBE63),
                label: 'Present (${summaryStats['present_days']})',
                isAnimated: true,
                animationDelay: const Duration(milliseconds: 1400),
              ),
              _LegendItem(
                color: const Color(0xFFFF4E6A),
                label: 'Absent (${summaryStats['absent_days']})',
                isAnimated: true,
                animationDelay: const Duration(milliseconds: 1600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecords() {
    final records = statisticsData!['attendance_records'] as List;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Attendance Records',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          if (records.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    Theme.of(context).primaryColor.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attendance records will appear here once marked.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...records
                .take(5)
                .map((record) => _buildAttendanceRecordCard(record))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecordCard(Map<String, dynamic> record) {
    Color statusColor;
    switch (record['status']) {
      case 'P':
        statusColor = Colors.green;
        break;
      case 'A':
        statusColor = Colors.red;
        break;
      case 'H':
        statusColor = Colors.orange;
        break;
      case 'L':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(record['status']),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatDate(record['date'])} - ${record['status_text']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (record['check_in_time'] != null ||
                    record['check_out_time'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${record['check_in_time'] ?? 'N/A'} - ${record['check_out_time'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (record['face_verified'])
                Icon(Icons.face, size: 16, color: Colors.teal),
              if (record['location_verified'])
                Icon(Icons.location_on, size: 16, color: Colors.purple),
              if (record['gps_verified'])
                Icon(Icons.gps_fixed, size: 16, color: Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'P':
        return Icons.check_circle;
      case 'A':
        return Icons.cancel;
      case 'H':
        return Icons.schedule;
      case 'L':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}.${_getMonthAbbr(dateTime.month)}.${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isAnimated;
  final Duration animationDelay;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.isAnimated = false,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isAnimated;
  final Duration animationDelay;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isAnimated = false,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}

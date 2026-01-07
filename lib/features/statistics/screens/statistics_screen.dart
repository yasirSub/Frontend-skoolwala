// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/shared/animations/animations.dart';
import 'package:skoolwala/features/statistics/services/statistics_service.dart';
import 'package:skoolwala/features/profile/services/developer_attendance_service.dart';
import 'package:skoolwala/features/profile/services/dummy_data_service.dart';
import 'package:skoolwala/shared/utils/safe_widget_operations.dart';
import 'package:skoolwala/shared/utils/layout_boundary_fix.dart';

class StatisticsScreen extends StatefulWidget {
  final String username;
  final String password;

  const StatisticsScreen({
    super.key,
    required this.username,
    required this.password,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin, SafeWidgetMixin, LayoutBoundaryMixin {
  StatisticsData? _statisticsData;
  bool _isLoading = true;
  String? _error;

  // Animation controllers
  late AnimationController _devAnimationController;
  late AnimationController _loadingAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _staggerAnimationController;

  // Animations
  late Animation<double> _devAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _contentAnimation;

  // Dev options state
  bool _isDevMenuOpen = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _devAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

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
    _devAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_devAnimationController);

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

    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final data = await StatisticsService.fetchStatisticsData(
        username: widget.username,
        password: widget.password,
      );

      // Use comprehensive layout boundary protection
      safeSetState(() {
        _statisticsData = data;
        _isLoading = false;
      });

      // Start content animations with comprehensive protection
      safeAnimationOperation(() {
        SafeWidgetOperations.safeAnimationForward(_contentAnimationController);
      });

      // Use safe delayed operation with comprehensive protection
      safeDelayedOperation(const Duration(milliseconds: 200), () {
        safeAnimationOperation(() {
          SafeWidgetOperations.safeAnimationForward(
            _staggerAnimationController,
          );
        });
      });
    } catch (e) {
      safeSetState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Safely dispose animation controllers
    safeExecute(() {
      SafeWidgetOperations.safeDisposeAnimationControllers([
        _devAnimationController,
        _loadingAnimationController,
        _contentAnimationController,
        _staggerAnimationController,
      ]);
    });
    super.dispose();
  }

  void _toggleDevMenu() {
    setState(() {
      _isDevMenuOpen = !_isDevMenuOpen;
    });
    if (_isDevMenuOpen) {
      _devAnimationController.forward();
    } else {
      _devAnimationController.reverse();
    }
  }

  Future<void> _deleteAttendance(String type) async {
    if (_statisticsData == null) return;

    _toggleDevMenu(); // Close menu first

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Attendance - ${type.toUpperCase()}'),
        content: Text(
          'Are you sure you want to delete attendance records for ${_statisticsData!.teacher.name}?\n\n'
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

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic> result;

      switch (type) {
        case 'today':
          result = await DeveloperAttendanceService.deleteTodayAttendance(
            int.parse(_statisticsData!.teacher.id),
          );
          break;
        case 'month':
          final now = DateTime.now();
          result = await DeveloperAttendanceService.deleteMonthAttendance(
            int.parse(_statisticsData!.teacher.id),
            now.year,
            now.month,
          );
          break;
        case 'year':
          final now = DateTime.now();
          result = await DeveloperAttendanceService.deleteDateRangeAttendance(
            int.parse(_statisticsData!.teacher.id),
            '${now.year}-01-01',
            '${now.year}-12-31',
          );
          break;
        default:
          result = {'status': 'error', 'message': 'Invalid type'};
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Operation completed'),
          backgroundColor: result['status'] == 'success'
              ? Colors.green
              : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reload statistics if successful
      if (result['status'] == 'success') {
        _reloadStatistics();
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _generateAttendance(String type) async {
    if (_statisticsData == null) return;

    _toggleDevMenu(); // Close menu first

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate Attendance - ${type.toUpperCase()}'),
        content: Text(
          'Are you sure you want to generate dummy attendance records for ${_statisticsData!.teacher.name}?\n\n'
          'This will create realistic attendance data for testing.',
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

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await DummyDataService.generateDummyData(
        staffId: int.parse(_statisticsData!.teacher.id),
        type: type,
        pattern: 'mixed', // Use mixed pattern for realistic data
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Data generated successfully'),
          backgroundColor: result['status'] == 'success'
              ? Colors.green
              : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reload statistics if successful
      if (result['status'] == 'success') {
        _reloadStatistics();
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _reloadStatistics() async {
    // Safely reset animations with comprehensive protection
    safeAnimationOperation(() {
      SafeWidgetOperations.safeAnimationReset(_contentAnimationController);
      SafeWidgetOperations.safeAnimationReset(_staggerAnimationController);
    });

    // Reload data
    await _loadStatistics();
  }

  /// Safely calculates progress percentage, handling division by zero
  double _calculateProgress(int numerator, int denominator) {
    if (denominator == 0) {
      return 0.0; // Return 0% if no data
    }
    final progress = numerator / denominator;
    return progress.clamp(0.0, 1.0); // Ensure it's between 0.0 and 1.0
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildAnimatedLoadingView()
                : _error != null
                ? _buildErrorWidget()
                : _buildStatisticsContent(),
          ),
        ],
      ),
      floatingActionButton: _buildDevOptionsFAB(),
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
                    Theme.of(context).primaryColor.withOpacity(0.05),
                    Theme.of(context).primaryColor.withOpacity(0.02),
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
                            ).primaryColor.withOpacity(0.1),
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

  Widget _buildDevOptionsFAB() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Menu items
        if (_isDevMenuOpen) ...[
          Positioned(
            right: 0,
            bottom:
                100, // Increased space above the main FAB for larger buttons
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Generate options
                _buildDevMenuItem(
                  icon: Icons.add_circle_outline,
                  label: 'Gen Today',
                  color: Colors.green,
                  onTap: () => _generateAttendance('today'),
                ),
                const SizedBox(height: 12), // Increased spacing
                _buildDevMenuItem(
                  icon: Icons.add_circle_outline,
                  label: 'Gen Month',
                  color: Colors.blue,
                  onTap: () => _generateAttendance('month'),
                ),
                const SizedBox(height: 12), // Increased spacing
                _buildDevMenuItem(
                  icon: Icons.add_circle_outline,
                  label: 'Gen Year',
                  color: Colors.indigo,
                  onTap: () => _generateAttendance('year'),
                ),
                const SizedBox(height: 20), // Increased spacing
                // Delete options
                _buildDevMenuItem(
                  icon: Icons.today,
                  label: 'Delete Today',
                  color: Colors.orange,
                  onTap: () => _deleteAttendance('today'),
                ),
                const SizedBox(height: 12), // Increased spacing
                _buildDevMenuItem(
                  icon: Icons.calendar_month,
                  label: 'Delete Month',
                  color: Colors.red,
                  onTap: () => _deleteAttendance('month'),
                ),
                const SizedBox(height: 12), // Increased spacing
                _buildDevMenuItem(
                  icon: Icons.date_range,
                  label: 'Delete Year',
                  color: Colors.purple,
                  onTap: () => _deleteAttendance('year'),
                ),
              ],
            ),
          ),
        ],
        // Main FAB
        FloatingActionButton(
          onPressed: _toggleDevMenu,
          backgroundColor: _isDevMenuOpen ? Colors.red : Colors.deepOrange,
          child: AnimatedRotation(
            turns: _isDevMenuOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isDevMenuOpen ? Icons.close : Icons.developer_mode,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDevMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      scale: _devAnimation,
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: color,
        mini: false, // Make it regular size instead of mini
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24), // Increased icon size
            const SizedBox(height: 4), // Increased spacing
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12, // Increased font size
                fontWeight: FontWeight.bold,
              ),
            ),
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
        16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.25),
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
                    color: Colors.white.withOpacity(0.8),
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
              color: Colors.white.withOpacity(0.2),
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
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                    _error ?? 'Unknown error',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadStatistics,
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
    if (_statisticsData == null) return const SizedBox();

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
                _buildAnimatedOverviewCards(),
                const SizedBox(height: 28),
                _buildAnimatedAttendanceChart(),
                const SizedBox(height: 28),
                _buildAnimatedWeeklyAttendance(),
                const SizedBox(height: 28),
                _buildAnimatedSchoolStats(),
                const SizedBox(height: 28),
                _buildAnimatedMonthlyTrend(),
                const SizedBox(height: 20), // Extra space at bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOverviewCards() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _staggerAnimationController,
              curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerAnimationController,
          curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
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
              curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerAnimationController,
          curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
        ),
        child: _buildAttendanceChart(),
      ),
    );
  }

  Widget _buildAnimatedWeeklyAttendance() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero)
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
        child: _buildWeeklyAttendance(),
      ),
    );
  }

  Widget _buildAnimatedSchoolStats() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _staggerAnimationController,
              curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerAnimationController,
          curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
        ),
        child: _buildSchoolStats(),
      ),
    );
  }

  Widget _buildAnimatedMonthlyTrend() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _staggerAnimationController,
              curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerAnimationController,
          curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
        ),
        child: _buildMonthlyTrend(),
      ),
    );
  }

  Widget _buildOverviewCards() {
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
                value:
                    '${_statisticsData!.attendancePercentage.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: const Color(0xFF2BBE63),
                subtitle:
                    '${_statisticsData!.presentDays}/${_statisticsData!.totalWorkingDays} days',
                isAnimated: true,
                animationDelay: const Duration(milliseconds: 200),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewCard(
                title: 'Total Students',
                value: _statisticsData!.totalStudents > 0
                    ? _statisticsData!.totalStudents.toString()
                    : 'No Data',
                icon: Icons.people,
                color: _statisticsData!.totalStudents > 0
                    ? AppTheme.primaryPurple
                    : const Color(0xFF9CA3AF),
                isAnimated: _statisticsData!.totalStudents > 0,
                animationDelay: const Duration(milliseconds: 400),
                subtitle: _statisticsData!.totalClasses > 0
                    ? '${_statisticsData!.totalClasses} classes'
                    : 'Not assigned',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                title: 'Present Days',
                value: _statisticsData!.presentDays.toString(),
                icon: Icons.check_circle,
                color: const Color(0xFF10C69C),
                subtitle: 'This month',
                isAnimated: true,
                animationDelay: const Duration(milliseconds: 600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewCard(
                title: 'Absent Days',
                value: _statisticsData!.absentDays.toString(),
                icon: Icons.cancel,
                color: const Color(0xFFFF4E6A),
                subtitle: 'This month',
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                  flex: _statisticsData!.presentDays,
                  child: AnimatedProgressBar(
                    progress: 1.0,
                    backgroundColor: Colors.transparent,
                    progressColor: const Color(0xFF2BBE63),
                    height: 12,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                    delay: const Duration(milliseconds: 1000),
                  ),
                ),
                Expanded(
                  flex: _statisticsData!.absentDays,
                  child: AnimatedProgressBar(
                    progress: 1.0,
                    backgroundColor: Colors.transparent,
                    progressColor: const Color(0xFFFF4E6A),
                    height: 12,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    delay: const Duration(milliseconds: 1200),
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
                label: 'Present (${_statisticsData!.presentDays})',
                isAnimated: true,
                animationDelay: const Duration(milliseconds: 1400),
              ),
              _LegendItem(
                color: const Color(0xFFFF4E6A),
                label: 'Absent (${_statisticsData!.absentDays})',
                isAnimated: true,
                animationDelay: const Duration(milliseconds: 1600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAttendance() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
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
            'This Week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _statisticsData!.weeklyAttendance.entries.map((entry) {
              final isPresent = entry.value == 1;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isPresent
                            ? const Color(0xFF2BBE63).withValues(alpha: 0.1)
                            : const Color(0xFFFF4E6A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isPresent
                              ? const Color(0xFF2BBE63)
                              : const Color(0xFFFF4E6A),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isPresent ? Icons.check : Icons.close,
                        color: isPresent
                            ? const Color(0xFF2BBE63)
                            : const Color(0xFFFF4E6A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
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
            'School Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          _statisticsData!.totalStudents > 0 ||
                  _statisticsData!.totalClasses > 0
              ? Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.school,
                        title: 'Classes',
                        value: _statisticsData!.totalClasses > 0
                            ? _statisticsData!.totalClasses.toString()
                            : '0',
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.view_list,
                        title: 'Sections',
                        value: _statisticsData!.totalSections > 0
                            ? _statisticsData!.totalSections.toString()
                            : '0',
                        color: const Color(0xFF10C69C),
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.people,
                        title: 'Students',
                        value: _statisticsData!.totalStudents > 0
                            ? _statisticsData!.totalStudents.toString()
                            : '0',
                        color: const Color(0xFF2BBE63),
                      ),
                    ),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.all(24),
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
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Class Assignment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You haven\'t been assigned to any classes yet.\nContact your administrator for class assignments.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
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
            'Monthly Trend (Last 6 Months)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          ...(_statisticsData!.monthlyAttendance
              .take(6)
              .map(
                (month) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          month['month'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _calculateProgress(
                              month['percentage'] as int,
                              100,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPurple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${month['percentage']}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A48),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList()),
        ],
      ),
    );
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
            color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                child: isAnimated
                    ? (value.contains('%')
                          ? AnimatedPercentage(
                              targetPercentage:
                                  double.tryParse(value.replaceAll('%', '')) ??
                                  0.0,
                              delay: animationDelay,
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            )
                          : AnimatedCounter(
                              targetValue:
                                  int.tryParse(
                                    value.replaceAll(RegExp(r'[^\d]'), ''),
                                  ) ??
                                  0,
                              suffix: value.contains('days') ? ' days' : '',
                              delay: animationDelay,
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ))
                    : Text(
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
        isAnimated
            ? AnimatedCounter(
                targetValue:
                    int.tryParse(label.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
                prefix: label.contains('Present') ? 'Present (' : 'Absent (',
                suffix: ')',
                delay: animationDelay,
                textStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              )
            : Text(
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

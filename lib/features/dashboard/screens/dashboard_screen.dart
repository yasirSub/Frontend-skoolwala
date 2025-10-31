// ignore_for_file: use_build_context_synchronously, unused_element, deprecated_member_use, unused_element_parameter, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skoolwala/shared/theme/theme_provider.dart';
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/features/dashboard/services/dashboard_service.dart';
import 'package:skoolwala/features/dashboard/models/profile.dart';
import 'package:skoolwala/features/attendance/screens/face_verification_screen.dart';
import 'package:skoolwala/features/attendance/screens/simple_enroll_screen.dart';
import 'package:skoolwala/features/attendance/screens/quick_attendance_screen.dart';
import 'package:skoolwala/features/attendance/screens/multi_angle_enroll_screen.dart';
import 'package:skoolwala/features/attendance/screens/face_3d_enroll_screen.dart';
import 'package:skoolwala/features/face_enrollment/screens/simple_face_enrollment_home_screen.dart';
import 'package:skoolwala/features/attendance/screens/enrolled_faces_list_screen.dart';
import 'package:skoolwala/features/profile/screens/profile_screen.dart';
import 'package:skoolwala/features/teacher_attendance/simple_teacher_attendance.dart';
import 'package:skoolwala/shared/models/teacher.dart';
import 'package:skoolwala/features/profile/models/teacher_profile.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/routes/app_routes.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Modern color palette for cleaner look
class _AppColors {
  static const Color primary = Color(0xFF1A1F3E);
  static const Color primaryLight = Color(0xFF2A3441);
  static const Color accent = Color(0xFF00B4D8);
  static const Color accentLight = Color(0xFF90E0EF);
  static const Color success = Color(0xFF06FFA5);
  static const Color warning = Color(0xFFFFBE0B);
  static const Color error = Color(0xFFFB5607);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}

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
    with SingleTickerProviderStateMixin {
  Profile? _profile;
  Teacher? _teacher;
  TeacherProfile? _teacherProfile;
  bool _showSuccess = false;
  bool _showError = false;
  bool _showEnrollSuccess = false;
  bool _isLoading = true;
  bool _isEnrolled = false;
  bool _isCheckedIn = false;
  final GlobalKey<_WorkingTimerCardState> _timerKey =
      GlobalKey<_WorkingTimerCardState>();
  int _totalStudents = 0;
  int _totalPresent = 0;
  int _totalAbsent = 0;
  String? _schoolName;
  bool _isDevOptionsExpanded = false;
  int _selectedIndex = 0; // Track selected bottom navigation item

  // Animation controller for hiding/showing bars
  late AnimationController _barsAnimationController;
  late Animation<double> _appBarAnimation;
  late Animation<double> _bottomBarAnimation;
  bool _showBars = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for bars
    _barsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _appBarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _barsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _bottomBarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _barsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _barsAnimationController.forward();

    _load();
  }

  @override
  void dispose() {
    _barsAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh timer when dashboard becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTimer();
    });
  }

  // Method to refresh timer manually
  void _refreshTimer() {
    if (_timerKey.currentState != null) {
      _timerKey.currentState!.refreshTimer();
    }
    _checkAttendanceStatus();
  }

  // Method to check if user is checked in
  Future<void> _checkAttendanceStatus() async {
    if (_teacher == null) return;

    try {
      final baseUrl = ApiConfig.getBaseUrl().replaceAll('/api', '/index.php');
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/getTeacherSelfAttendanceStats?staff_id=${_teacher!.id}&filter_type=date&filter_value=${DateTime.now().toIso8601String().split('T')[0]}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final todayStatus = data['data']['today_status'];
          final isCheckedIn =
              todayStatus['status'] == 'P' &&
              todayStatus['check_in_time'] != null;

          if (mounted) {
            setState(() {
              _isCheckedIn = isCheckedIn;
            });
          }
        }
      }
    } catch (e) {
      print('🕐 Dashboard Debug - Error checking attendance status: $e');
    }
  }

  Future<void> _load() async {
    try {
      print(
        '🔍 Dashboard Debug - Starting load with username: ${widget.username}',
      );
      print(
        '🔍 Dashboard Debug - Session Manager logged in: ${SessionManager.instance.isLoggedIn}',
      );
      print(
        '🔍 Dashboard Debug - Session Manager has valid session: ${SessionManager.instance.hasValidSession}',
      );

      // Load all dashboard data from multiple APIs
      final dashboardData = await DashboardService.fetchDashboardData(
        username: widget.username,
        password: widget.password,
      );

      // Convert Teacher to Profile for backward compatibility
      print('🔍 Dashboard Debug - Present Days: ${dashboardData.presentDays}');
      print('🔍 Dashboard Debug - Absent Days: ${dashboardData.absentDays}');
      final profile = Profile.fromTeacher(
        dashboardData.teacher,
        presentDays: dashboardData.presentDays,
        absentDays: dashboardData.absentDays,
      );
      print(
        '🔍 Dashboard Debug - Profile Present Days: ${profile.presentDays}',
      );
      print('🔍 Dashboard Debug - Profile Absent Days: ${profile.absentDays}');

      setState(() {
        _profile = profile;
        _teacher = dashboardData.teacher;
        _teacherProfile = dashboardData.teacherProfile;
        _totalStudents = dashboardData.totalStudents;
        _totalPresent = dashboardData.presentDays;
        _totalAbsent = dashboardData.absentDays;
        _schoolName = dashboardData.school?.name;
        _isLoading = false;
      });

      // Use backend face enrollment status instead of local check
      if (mounted) {
        setState(() {
          _isEnrolled = dashboardData.teacher.faceEnrolled;
        });
      }

      // Refresh timer after dashboard data is loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshTimer();
      });
    } catch (e) {
      print('🔍 Dashboard Debug - ERROR in _load(): $e');
      print('🔍 Dashboard Debug - Error type: ${e.runtimeType}');
      print('🔍 Dashboard Debug - Stack trace: ${StackTrace.current}');

      setState(() {
        _isLoading = false;
      });
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openScan() async {
    // If not enrolled: open enrollment flow and refresh status only (no success banner)
    if (!_isEnrolled) {
      // Use simple enroll screen for face enrollment
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const SimpleEnrollScreen()),
      );
      // Refresh enrollment state after returning - reload dashboard data
      try {
        final dashboardData = await DashboardService.fetchDashboardData(
          username: widget.username,
          password: widget.password,
        );
        if (mounted) {
          setState(() {
            _isEnrolled = dashboardData.teacher.faceEnrolled;
            _showSuccess = false;
            _showError = false;
          });
        }
      } catch (_) {}
      return;
    }

    // If already enrolled: open verify+mark flow and show banners based on result
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const FaceVerificationScreen(verifyMode: true),
      ),
    );
    if (!mounted) return;
    setState(() {
      _showSuccess = result == true;
      _showError = result == false;
    });
  }

  Future<void> _openFaceVerification() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FaceVerificationScreen()),
    );
    if (!mounted) return;
    setState(() {
      _showSuccess = result == true;
      _showError = result == false;
    });
  }

  Future<void> _openFaceVerificationVerifyMode() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const FaceVerificationScreen(verifyMode: true),
      ),
    );
    if (!mounted) return;
    setState(() {
      _showSuccess = result == true;
      _showError = result == false;
    });
  }

  Future<void> _openQuickAttendance(String mode) async {
    if (!_isEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enroll your face first to use Quick Attendance',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuickAttendanceScreen(forceMode: mode)),
    );

    // Refresh dashboard data after returning
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openTeacherAttendance() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SimpleTeacherAttendance(
          staffId: _teacher?.id, // pass logged-in staff id
        ),
      ),
    );

    // Refresh attendance status when returning from attendance screen
    // Add a small delay to ensure API has processed the check-in
    await Future.delayed(const Duration(milliseconds: 500));
    _refreshTimer();
  }

  // (F2F navigation removed per request)

  Future<void> _openProfile() async {
    print('🔍 Profile Debug - _openProfile called');
    print('🔍 Profile Debug - _teacher: $_teacher');
    print('🔍 Profile Debug - _profile: $_profile');

    if (_teacher != null) {
      print('🔍 Profile Debug - Navigating to profile with teacher data');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            teacher: _teacher!,
            schoolName: _schoolName,
            teacherProfile: _teacherProfile,
          ),
        ),
      );
    } else {
      print('🔍 Profile Debug - Teacher data is null, showing error');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile data not available. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openStatistics() async {
    print('🔍 Statistics Debug - _openStatistics called');
    print('🔍 Statistics Debug - Username: ${widget.username}');
    print('🔍 Statistics Debug - Teacher: $_teacher');

    if (_teacher != null) {
      print(
        '🔍 Statistics Debug - Navigating to Teacher Statistics with staff ID: ${_teacher!.id}',
      );
      AppRoutes.toTeacherStatistics(
        context,
        staffId: _teacher!.id,
        baseUrl: ApiConfig.getBaseUrl().replaceAll('/api', '/index.php'),
      );
    } else {
      print('🔍 Statistics Debug - Teacher data is null, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher data not available. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_AppColors.primary, _AppColors.primary.withOpacity(0.95)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: _AppColors.accentLight,
          unselectedItemColor: Colors.white.withOpacity(0.5),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            letterSpacing: 0.3,
          ),
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedIndex == 0
                      ? _AppColors.accentLight.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  _selectedIndex == 0
                      ? Icons.home_rounded
                      : Icons.home_outlined,
                  size: _selectedIndex == 0 ? 26 : 24,
                ),
              ),
              label: 'Home',
              tooltip: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedIndex == 1
                      ? _AppColors.accentLight.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  _selectedIndex == 1
                      ? Icons.fact_check_rounded
                      : Icons.fact_check_outlined,
                  size: _selectedIndex == 1 ? 26 : 24,
                ),
              ),
              label: 'Attendance',
              tooltip: 'Check In/Out',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedIndex == 2
                      ? _AppColors.accentLight.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  _selectedIndex == 2
                      ? Icons.class_rounded
                      : Icons.class_outlined,
                  size: _selectedIndex == 2 ? 26 : 24,
                ),
              ),
              label: 'Classes',
              tooltip: 'View Classes',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedIndex == 3
                      ? _AppColors.accentLight.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  _selectedIndex == 3
                      ? Icons.school_rounded
                      : Icons.school_outlined,
                  size: _selectedIndex == 3 ? 26 : 24,
                ),
              ),
              label: 'Students',
              tooltip: 'View Students',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedIndex == 4
                      ? _AppColors.accentLight.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  _selectedIndex == 4
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  size: _selectedIndex == 4 ? 26 : 24,
                ),
              ),
              label: 'Profile',
              tooltip: 'My Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Handle bottom navigation tap
  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to appropriate screen based on index
    switch (index) {
      case 0: // Home - already on dashboard
        // Scroll to top or refresh
        break;
      case 1: // Attendance
        _openTeacherAttendance();
        break;
      case 2: // Classes
        _openClasses();
        break;
      case 3: // Students
        _openStudentsList();
        break;
      case 4: // Profile
        _openProfile();
        break;
    }
  }

  // Navigate to classes screen
  Future<void> _openClasses() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.129:8080/index.php/api/getClassList'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ClassesScreen(classes: data['data'] ?? []),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to load classes'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Navigate to teachers list screen
  void _openTeachersList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _TeachersListScreen()),
    );
  }

  // Navigate to students list screen
  void _openStudentsList() {
    // First load classes, then sections, then students
    _openClassSelectionForStudents();
  }

  // Open class selection to view students
  Future<void> _openClassSelectionForStudents() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.129:8080/index.php/api/getClassList'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _StudentsSelectionScreen(classes: data['data'] ?? []),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading classes: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit the app when back button is pressed on dashboard
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _AppColors.primary,
                    _AppColors.primary.withOpacity(0.95),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                automaticallyImplyLeading: false,
                title: Text(
                  _schoolName ?? 'School',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return IconButton(
                        onPressed: () => themeProvider.toggleTheme(),
                        icon: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? _ModernLoadingView()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF2A2376),
                  backgroundColor: Colors.white,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        final offset = notification.metrics.pixels;

                        if (offset > _lastScrollOffset + 5 && _showBars) {
                          // Scrolling down - hide bars
                          setState(() => _showBars = false);
                          _barsAnimationController.reverse();
                        } else if (offset < _lastScrollOffset - 5 &&
                            !_showBars) {
                          // Scrolling up - show bars
                          setState(() => _showBars = true);
                          _barsAnimationController.forward();
                        } else if (offset < 50 && !_showBars) {
                          // Near top - always show bars
                          setState(() => _showBars = true);
                          _barsAnimationController.forward();
                        }

                        _lastScrollOffset = offset;
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 20),
                              _ProfileCard(
                                profile: _profile,
                                onProfileTap: _openProfile,
                                isEnrolled: _isEnrolled,
                              ),
                              const SizedBox(height: 20),
                              if (_teacher != null)
                                _WorkingTimerCard(
                                  key: _timerKey,
                                  teacher: _teacher,
                                  baseUrl: ApiConfig.getBaseUrl().replaceAll(
                                    '/api',
                                    '/index.php',
                                  ),
                                ),
                              if (_teacher != null) const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Your Statistics',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _StatCardsRow(
                                  presentDays: _profile?.presentDays ?? 0,
                                  absentDays: _profile?.absentDays ?? 0,
                                  onAnalyticsTap: _openStatistics,
                                ),
                                const SizedBox(height: 20),
                                // Check In/Out buttons hidden per request
                                // Column(
                                //   children: [
                                //     Row(
                                //       children: [
                                //         Expanded(
                                //           child: _CheckInOutButton(
                                //             title: 'Check In',
                                //             icon: Icons.login_rounded,
                                //             color: Colors.green[600]!,
                                //             onTap: _isEnrolled
                                //                 ? () => _openQuickAttendance(
                                //                     'checkin',
                                //                   )
                                //                 : null,
                                //           ),
                                //         ),
                                //         const SizedBox(width: 12),
                                //         Expanded(
                                //           child: _CheckInOutButton(
                                //             title: 'Check Out',
                                //             icon: Icons.logout_rounded,
                                //             color: Colors.red[600]!,
                                //             onTap: _isEnrolled
                                //                 ? () => _openQuickAttendance(
                                //                     'checkout',
                                //                   )
                                //                 : null,
                                //           ),
                                //         ),
                                //       ],
                                //     ),
                                //     // Manual Mark attendance card hidden per request
                                //     // F2F registration/analyzer hidden per request
                                //   ],
                                // ),
                                const SizedBox(height: 16),
                                _TeacherAttendanceCard(
                                  onTap: _openTeacherAttendance,
                                  isEnrolled: _isEnrolled,
                                  isCheckedIn: _isCheckedIn,
                                ),
                                const SizedBox(height: 20),
                                const SizedBox(height: 16),
                                if (_showSuccess)
                                  const _InfoBanner.success(
                                    'Success! Marked Attendance successfully.',
                                  ),
                                if (_showSuccess) const SizedBox(height: 16),
                                if (_showEnrollSuccess)
                                  const _InfoBanner.success(
                                    'Success! Face enrolled successfully.',
                                  ),
                                if (_showEnrollSuccess)
                                  const SizedBox(height: 16),
                                if (_showError)
                                  const _InfoBanner.error(
                                    'Error! Face not recognized.',
                                  ),
                                if (_showError) const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: _bottomBarAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 70 * (1 - _bottomBarAnimation.value)),
              child: Opacity(
                opacity: _bottomBarAnimation.value,
                child: _buildBottomNavigationBar(),
              ),
            );
          },
        ),
        floatingActionButton: _ExpandableFloatingButton(
          isExpanded: _isDevOptionsExpanded,
          onToggle: () {
            setState(() {
              _isDevOptionsExpanded = !_isDevOptionsExpanded;
            });
          },
          onSimpleEnroll: () async {
            final enrollResult = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const SimpleEnrollScreen()),
            );
            // Refresh enrolled status after returning - reload dashboard data
            try {
              final dashboardData = await DashboardService.fetchDashboardData(
                username: widget.username,
                password: widget.password,
              );
              if (mounted) {
                setState(() {
                  _isEnrolled = dashboardData.teacher.faceEnrolled;
                  _showEnrollSuccess = enrollResult == true;
                });

                // Auto-hide enrollment success message after 3 seconds
                if (enrollResult == true) {
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _showEnrollSuccess = false;
                      });
                    }
                  });
                }
              }
            } catch (_) {}
          },
          onMultiAngleEnroll: () async {
            final enrollResult = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const MultiAngleEnrollScreen()),
            );
            // Refresh enrolled status after returning
            try {
              final dashboardData = await DashboardService.fetchDashboardData(
                username: widget.username,
                password: widget.password,
              );
              if (mounted) {
                setState(() {
                  _isEnrolled = dashboardData.teacher.faceEnrolled;
                  _showEnrollSuccess = enrollResult == true;
                });

                if (enrollResult == true) {
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _showEnrollSuccess = false;
                      });
                    }
                  });
                }
              }
            } catch (_) {}
          },
          on3DFaceEnroll: () async {
            final enrollResult = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const Face3DEnrollScreen()),
            );
            // Refresh enrolled status after returning
            try {
              final dashboardData = await DashboardService.fetchDashboardData(
                username: widget.username,
                password: widget.password,
              );
              if (mounted) {
                setState(() {
                  _isEnrolled = dashboardData.teacher.faceEnrolled;
                  _showEnrollSuccess = enrollResult == true;
                });

                if (enrollResult == true) {
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _showEnrollSuccess = false;
                      });
                    }
                  });
                }
              }
            } catch (_) {}
          },
          onSimpleFaceEnrollHome: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SimpleFaceEnrollmentHomeScreen(),
              ),
            );
          },
          onEnrolledList: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EnrolledFacesListScreen(),
              ),
            );
          },
          // Analyzer and F2F actions removed per request
          onLogout: () {}, // Logout disabled
        ),
      ),
    );
  }
}

// Modern loading view with better design
class _ModernLoadingView extends StatefulWidget {
  const _ModernLoadingView();

  @override
  State<_ModernLoadingView> createState() => _ModernLoadingViewState();
}

class _ModernLoadingViewState extends State<_ModernLoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Colors.grey[900]!, Colors.grey[800]!]
              : [
                  _AppColors.primary.withValues(alpha: 0.05),
                  _AppColors.accent.withValues(alpha: 0.05),
                ],
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: _AppColors.accent.withValues(alpha: 0.1),
                        blurRadius: 50,
                        offset: const Offset(0, 25),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_AppColors.primary, _AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_AppColors.primary, _AppColors.accent],
                  ).createShader(bounds),
                  child: const Text(
                    'Loading Dashboard...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please wait while we fetch your data',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _AppColors.accent,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Profile? profile;
  final VoidCallback? onProfileTap;
  final bool isEnrolled;

  const _ProfileCard({
    this.profile,
    this.onProfileTap,
    this.isEnrolled = false,
  });

  String _getDisplayName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'Teacher';

    // If the fullName contains an email (has @ symbol), extract just the name part
    if (fullName.contains('@')) {
      // Split by common separators and take the first part
      final parts = fullName.split(RegExp(r'[@\s]+'));
      return parts.first.isNotEmpty ? parts.first : 'Teacher';
    }

    return fullName;
  }

  Future<void> _openMultiEnroll(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MultiAngleEnrollScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          print('🔍 ProfileCard Debug - Card tapped');
          onProfileTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.25),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFF764BA2).withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Row(
            children: [
              // Enhanced Profile Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                    // Enhanced verification badge
                    Container(
                      decoration: BoxDecoration(
                        color: isEnrolled ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (isEnrolled ? Colors.green : Colors.orange)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        isEnrolled ? Icons.verified : Icons.schedule,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Enhanced Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getDisplayName(profile?.fullName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Enhanced badges - removed role badge
                  ],
                ),
              ),
              // Multi-enroll shortcut (only show when not enrolled)
              if (!isEnrolled)
                GestureDetector(
                  onTap: () => _openMultiEnroll(context),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(
                              0.4 + (value * 0.3),
                            ),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.5 * value),
                              blurRadius: 15,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.face_retouching_natural,
                          color: Colors.white.withOpacity(1.0),
                          size: 20,
                        ),
                      );
                    },
                    onEnd: () {
                      // Restart animation
                    },
                  ),
                ),
              const SizedBox(width: 8),
              // Enhanced arrow button
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
  final VoidCallback? onAnalyticsTap;

  const _StatCardsRow({
    required this.presentDays,
    required this.absentDays,
    this.onAnalyticsTap,
  });

  @override
  Widget build(BuildContext context) {
    print(
      '🔍 UI Debug - StatCardsRow Present: $presentDays, Absent: $absentDays',
    );
    return InkWell(
      onTap: () {
        print('🔍 StatisticsButton Debug - Card tapped');
        onAnalyticsTap?.call();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2376), Color(0xFF6D63B8)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CompactStatItem(
              icon: Icons.check_circle_outline,
              label: 'Present',
              value: presentDays.toString(),
              color: Colors.green[300]!,
            ),
            Container(
              width: 1,
              height: 30,
              color: Colors.white.withOpacity(0.3),
            ),
            _CompactStatItem(
              icon: Icons.cancel_outlined,
              label: 'Absent',
              value: absentDays.toString(),
              color: Colors.red[300]!,
            ),
            Container(
              width: 1,
              height: 30,
              color: Colors.white.withOpacity(0.3),
            ),
            _CompactStatItem(
              icon: Icons.analytics_rounded,
              label: 'Analytics',
              value: '',
              color: Colors.blue[300]!,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CompactStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  String _getSymbol(String label) {
    switch (label.toLowerCase()) {
      case 'present':
        return '';
      case 'absent':
        return '';
      case 'analytics':
        return '📊';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getSymbol(label),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        else if (label.toLowerCase() == 'analytics')
          Icon(Icons.analytics_rounded, color: color, size: 24),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;

  const _MiniStatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkAttendanceCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final IconData icon;
  final bool showInOutButtons;
  final bool showSubtitle;
  final bool enabled;
  const _MarkAttendanceCard({
    this.onTap,
    this.title = 'Mark Attendance',
    this.icon = Icons.camera_alt,
    this.showInOutButtons = true,
    this.showSubtitle = true,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? onTap
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enroll your face to enable Quick Mark'),
                ),
              );
            },
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
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    showSubtitle
                        ? (enabled
                              ? 'Mark Your Attendance'
                              : 'Enroll face to enable')
                        : '',
                    style: const TextStyle(
                      color: Color(0xFFBDB8FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (showInOutButtons)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InOutChip(label: 'IN', active: enabled),
                  const SizedBox(height: 6),
                  _InOutChip(label: 'OUT', active: false),
                ],
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _StatisticsButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        print('🔍 StatisticsButton Debug - Button tapped');
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10C69C), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text(
              'View Statistics',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF1E175E) : Colors.white70,
          fontWeight: FontWeight.w900,
          fontSize: 12,
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
            backgroundColor: Colors.white.withValues(alpha: 0.2),
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
              color: Colors.white.withValues(alpha: 0.2),
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
            backgroundColor: Colors.white.withValues(alpha: 0.25),
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
        border: Border.all(color: fg.withValues(alpha: 0.25)),
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

class _ProfileButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ProfileButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700), // Gold/Yellow
            Color(0xFFFFA500), // Orange
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View My Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'See your complete profile information',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
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
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelfAttendanceButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _SelfAttendanceButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Attendance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check in/out and mark attendance',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CompactFaceCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final IconData icon;

  const _CompactFaceCard({this.onTap, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAttendanceCard extends StatelessWidget {
  final VoidCallback? onTap;
  final bool enabled;

  const _QuickAttendanceCard({this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? onTap
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please enroll your face to enable Quick Attendance',
                  ),
                ),
              );
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.flash_on_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    enabled
                        ? 'Auto-detect check-in/out with face scan'
                        : 'Enroll face to enable',
                    style: const TextStyle(
                      color: Color(0xFFE8F5E8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    enabled ? 'AUTO' : 'LOCKED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactF2FCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final String subtitle;
  final IconData icon;

  const _CompactF2FCard({
    this.onTap,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInOutButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CheckInOutButton({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enroll your face to enable attendance'),
              ),
            );
          },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8), color.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title == 'Check In' ? 'Start your day' : 'End your day',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherAttendanceCard extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isEnrolled;
  final bool isCheckedIn;
  const _TeacherAttendanceCard({
    this.onTap,
    this.isEnrolled = false,
    this.isCheckedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnrolled
          ? onTap
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please enroll your face first to use attendance. Go to Profile > Face Enrollment',
                  ),
                  duration: Duration(seconds: 4),
                  backgroundColor: Colors.orange,
                ),
              );
            },
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isEnrolled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCheckedIn
                  ? [
                      const Color(0xFFEF4444),
                      const Color(0xFFDC2626),
                    ] // Red gradient for check out
                  : [
                      const Color(0xFF10C69C),
                      const Color(0xFF059669),
                    ], // Green gradient for check in
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isCheckedIn
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10C69C))
                        .withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? 'Check Out' : 'Check In',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEnrolled
                          ? (isCheckedIn
                                ? 'Quick Check Out with Face Recognition'
                                : 'Quick Check In with Face Recognition')
                          : 'Face enrollment required',
                      style: TextStyle(
                        color: isEnrolled
                            ? const Color(0xFFE8F5E8)
                            : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                      isEnrolled
                          ? (isCheckedIn ? Icons.logout : Icons.login)
                          : Icons.lock,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEnrolled ? (isCheckedIn ? '' : 'CHECK IN') : 'LOCKED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableFloatingButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onSimpleEnroll;
  final VoidCallback onMultiAngleEnroll;
  final VoidCallback on3DFaceEnroll;
  final VoidCallback onSimpleFaceEnrollHome;
  final VoidCallback onEnrolledList;
  final VoidCallback onLogout;

  const _ExpandableFloatingButton({
    required this.isExpanded,
    required this.onToggle,
    required this.onSimpleEnroll,
    required this.onMultiAngleEnroll,
    required this.on3DFaceEnroll,
    required this.onSimpleFaceEnrollHome,
    required this.onEnrolledList,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanded Options
        if (isExpanded) ...[
          // Face Enrollment Options
          FloatingActionButton.extended(
            heroTag: 'fab-enroll-simple',
            onPressed: onSimpleEnroll,
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.face_outlined),
            label: const Text('Simple Enroll'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'fab-enroll-multi',
            onPressed: onMultiAngleEnroll,
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.view_in_ar),
            label: const Text('Multi-Angle'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'fab-enroll-3d',
            onPressed: on3DFaceEnroll,
            backgroundColor: Colors.purple[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.view_in_ar_outlined),
            label: const Text('3D Face'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'fab-enroll-home',
            onPressed: onSimpleFaceEnrollHome,
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.home_outlined),
            label: const Text('Enroll Home'),
          ),
          const SizedBox(height: 12),

          // Management Options
          FloatingActionButton.extended(
            heroTag: 'fab-list',
            onPressed: onEnrolledList,
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('Enrolled List'),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 12),
          // Logout button
          // Logout button removed per user request
          // FloatingActionButton.extended(
          //   heroTag: 'fab-logout',
          //   onPressed: onLogout,
          //   backgroundColor: Colors.red[700],
          //   foregroundColor: Colors.white,
          //   icon: const Icon(Icons.logout),
          //   label: const Text('Logout'),
          // ),
          // const SizedBox(height: 12),
        ],
        // Main Toggle Button
        FloatingActionButton(
          heroTag: 'fab-dev-toggle',
          onPressed: onToggle,
          backgroundColor: _AppColors.primary,
          foregroundColor: Colors.white,
          child: AnimatedRotation(
            turns: isExpanded ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isExpanded ? Icons.close : Icons.developer_mode,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

// Working Timer Card Widget
class _WorkingTimerCard extends StatefulWidget {
  final Teacher? teacher;
  final String baseUrl;

  const _WorkingTimerCard({
    super.key,
    required this.teacher,
    required this.baseUrl,
  });

  @override
  State<_WorkingTimerCard> createState() => _WorkingTimerCardState();
}

class _WorkingTimerCardState extends State<_WorkingTimerCard> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _checkInTime;
  bool _isCheckedIn = false;
  bool _isLoading = true;
  bool _isExpanded = false;
  bool _isCheckingOut = false;

  // Method to refresh timer data
  void refreshTimer() {
    print('🕐 Timer Debug - Manual refresh called');
    setState(() {
      _isLoading = true;
    });
    _loadTodayStatus();
  }

  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
  }

  @override
  void didUpdateWidget(_WorkingTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when widget is updated (e.g., when navigating back to dashboard)
    if (oldWidget.teacher?.id != widget.teacher?.id) {
      _loadTodayStatus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always refresh timer data when dependencies change (e.g., when navigating back to dashboard)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTodayStatus() async {
    if (widget.teacher == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse(
        '${widget.baseUrl}/api/getTeacherSelfAttendanceStats?staff_id=${widget.teacher!.id}&filter_type=month&filter_value=${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final todayStatus = data['data']['today_status'];

          setState(() {
            _isCheckedIn =
                todayStatus['status'] == 'P' &&
                todayStatus['check_in_time'] != null;
            if (_isCheckedIn) {
              _checkInTime = _parseTime(todayStatus['check_in_time']);
              _startTimer();
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading today status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _parseTime(String? timeString) {
    if (timeString == null) return null;

    try {
      final now = DateTime.now();

      // Handle 12-hour format with AM/PM (e.g., "5:30:45 PM")
      if (timeString.contains('AM') || timeString.contains('PM')) {
        final parts = timeString.split(' ');
        final timePart = parts[0]; // "5:30:45"
        final period = parts[1]; // "AM" or "PM"

        final timeParts = timePart.split(':');
        if (timeParts.length >= 2) {
          int hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length >= 3 ? int.parse(timeParts[2]) : 0;

          // Convert to 24-hour format
          if (period == 'PM' && hour != 12) {
            hour += 12;
          } else if (period == 'AM' && hour == 12) {
            hour = 0;
          }

          final checkInDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
            second,
          );

          return checkInDateTime;
        }
      } else {
        // Handle 24-hour format (fallback)
        final timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length >= 3 ? int.parse(timeParts[2]) : 0;
          final checkInDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
            second,
          );

          return checkInDateTime;
        }
      }
    } catch (e) {
      // Error parsing time
    }
    return null;
  }

  void _startTimer() {
    if (_checkInTime == null) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final now = DateTime.now();
        final elapsed = now.difference(_checkInTime!);
        setState(() {
          _elapsedTime = elapsed;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    // Format: "0:04 min" or "5:30 min" etc.
    return '${totalMinutes}:${seconds.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    // Build debug removed - timer is working correctly

    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Hide the entire timer section if not checked in
    if (!_isCheckedIn) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.15),
            Colors.green.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Working Timer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Checked in at ${_checkInTime?.hour.toString().padLeft(2, '0')}:${_checkInTime?.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_filled, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_elapsedTime),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: Colors.green[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Working since ${_checkInTime?.hour.toString().padLeft(2, '0')}:${_checkInTime?.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _checkOut() async {
    if (widget.teacher == null) return;

    setState(() {
      _isCheckingOut = true;
    });

    try {
      // Get current location
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.lowest,
              timeLimit: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Location error during checkout: $e');
      }

      // Prepare checkout data
      final checkoutData = {
        'staff_id': widget.teacher!.id,
        'validated_face': true,
        'attendance_type': 'check_out',
        'user_latitude': position?.latitude,
        'user_longitude': position?.longitude,
      };

      print('=== CHECKOUT REQUEST ===');
      print('Staff ID: ${widget.teacher!.id}');
      print('Location: ${position?.latitude}, ${position?.longitude}');
      print('Attendance Type: check_out');

      // Send checkout request
      final url = Uri.parse('${widget.baseUrl}/api/attendanceForTeacher');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(checkoutData),
      );

      print('Checkout Response Status: ${response.statusCode}');
      print('Checkout Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Checked out successfully at ${data['time']}'),
              backgroundColor: Colors.green,
            ),
          );

          // Stop timer and update state
          _timer?.cancel();
          setState(() {
            _isCheckedIn = false;
            _isExpanded = false;
            _elapsedTime = Duration.zero;
            _checkInTime = null;
          });

          // Refresh today's status
          await _loadTodayStatus();
        } else {
          throw Exception(data['message'] ?? 'Checkout failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Checkout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCheckingOut = false;
      });
    }
  }
}

// Classes Screen Widget
class _ClassesScreen extends StatelessWidget {
  final List<dynamic> classes;

  const _ClassesScreen({required this.classes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: classes.isEmpty
          ? const Center(
              child: Text(
                'No classes found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classItem = classes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_AppColors.primary, _AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.class_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      classItem['class_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text('Class ID: ${classItem['class_id']}'),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: _AppColors.primary,
                    ),
                    onTap: () {
                      // Navigate to sections for this class
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _SectionsScreen(
                            classId: classItem['class_id'].toString(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// Sections Screen Widget
class _SectionsScreen extends StatefulWidget {
  final String classId;

  const _SectionsScreen({required this.classId});

  @override
  State<_SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<_SectionsScreen> {
  bool _isLoading = true;
  List<dynamic> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.31.129:8080/index.php/api/getSectionListByClass',
        ),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'class_id=${widget.classId}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _sections = data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sections'),
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sections.isEmpty
          ? const Center(child: Text('No sections found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: _AppColors.accent,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      section['section_name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Section ID: ${section['section_id']}'),
                    trailing: const Icon(
                      Icons.people,
                      color: _AppColors.primary,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Teachers List Screen Widget
class _TeachersListScreen extends StatefulWidget {
  const _TeachersListScreen();

  @override
  State<_TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends State<_TeachersListScreen> {
  bool _isLoading = true;
  List<dynamic> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);

    try {
      // Note: This endpoint currently returns all staff. In future,
      // you may want to create a dedicated endpoint for teachers only
      final response = await http.post(
        Uri.parse('http://192.168.31.129:8080/index.php/api/getStaffList'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔍 Teachers List API Response Status: ${response.statusCode}');
      print('🔍 Teachers List API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 Teachers List Data: $data');

        if (data['status'] == 'success') {
          final teachersList = data['data'] ?? [];
          print('🔍 Teachers Count: ${teachersList.length}');

          setState(() {
            _teachers = teachersList;
            _isLoading = false;
          });
        } else {
          print('🔍 API returned error status: ${data['message']}');
          setState(() => _isLoading = false);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Failed to load teachers'),
              ),
            );
          }
        }
      } else {
        print('🔍 API returned status code: ${response.statusCode}');
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load teachers')),
          );
        }
      }
    } catch (e) {
      print('🔍 Error loading teachers: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading teachers: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers & Staff'),
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teachers.isEmpty
          ? const Center(child: Text('No teachers found'))
          : RefreshIndicator(
              onRefresh: _loadTeachers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _teachers.length,
                itemBuilder: (context, index) {
                  final teacher = _teachers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _AppColors.accent.withOpacity(0.2),
                        child: Icon(Icons.person, color: _AppColors.primary),
                      ),
                      title: Text(
                        teacher['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (teacher['designation'] != null)
                            Text(teacher['designation']),
                          if (teacher['department'] != null)
                            Text('Department: ${teacher['department']}'),
                          if (teacher['mobileno'] != null)
                            Text('Phone: ${teacher['mobileno']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// Students Selection Screen - Choose Class then Section then View Students
class _StudentsSelectionScreen extends StatelessWidget {
  final List<dynamic> classes;

  const _StudentsSelectionScreen({required this.classes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Class'),
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: classes.isEmpty
          ? const Center(child: Text('No classes found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classItem = classes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_AppColors.primary, _AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.class_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      classItem['class_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text('Class ID: ${classItem['class_id']}'),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: _AppColors.primary,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _StudentsSectionScreen(
                            classId: classItem['class_id'].toString(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _StudentsSectionScreen extends StatefulWidget {
  final String classId;

  const _StudentsSectionScreen({required this.classId});

  @override
  State<_StudentsSectionScreen> createState() => _StudentsSectionScreenState();
}

class _StudentsSectionScreenState extends State<_StudentsSectionScreen> {
  bool _isLoading = true;
  List<dynamic> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.31.129:8080/index.php/api/getSectionListByClass',
        ),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'class_id=${widget.classId}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _sections = data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Section'),
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sections.isEmpty
          ? const Center(child: Text('No sections found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: _AppColors.accent,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      section['section_name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Section ID: ${section['section_id']}'),
                    trailing: const Icon(
                      Icons.people,
                      color: _AppColors.primary,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _StudentsListScreen(
                            classId: widget.classId,
                            sectionId: section['section_id'].toString(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _StudentsListScreen extends StatefulWidget {
  final String classId;
  final String sectionId;

  const _StudentsListScreen({required this.classId, required this.sectionId});

  @override
  State<_StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<_StudentsListScreen> {
  bool _isLoading = true;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.129:8080/index.php/api/getStudentList'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
            'class_id=${widget.classId}&section_id=${widget.sectionId}&date=${DateTime.now().toIso8601String().split('T')[0]}',
      );

      print('🔍 Students List API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _students = data['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('🔍 Error loading students: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? const Center(child: Text('No students found'))
          : RefreshIndicator(
              onRefresh: _loadStudents,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  final isPresent = student['attendance_status'] == 'P';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _AppColors.accent.withOpacity(0.2),
                        child: Text(
                          (student['name'] ?? 'N')[0].toUpperCase(),
                          style: TextStyle(
                            color: _AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        student['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Roll: ${student['roll'] ?? 'N/A'}'),
                          Text('Register: ${student['register_no'] ?? 'N/A'}'),
                          if (student['attendance_status'] != null &&
                              student['attendance_status'].isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isPresent ? '✓ Present' : '✗ Absent',
                                style: TextStyle(
                                  color: isPresent ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

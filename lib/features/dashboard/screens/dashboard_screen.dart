// ignore_for_file: use_build_context_synchronously, unused_element, deprecated_member_use, unused_element_parameter, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/features/dashboard/services/dashboard_service.dart';
import 'package:skoolwala/features/dashboard/models/profile.dart';
import 'package:skoolwala/features/attendance/screens/face_analyzer_screen.dart';
import 'package:skoolwala/features/attendance/screens/face_verification_screen.dart';
import 'package:skoolwala/features/attendance/screens/quick_attendance_screen.dart';
import 'package:skoolwala/features/attendance/screens/multi_angle_enroll_screen.dart';
import 'package:skoolwala/features/attendance/screens/enrolled_faces_list_screen.dart';
import 'package:skoolwala/features/profile/screens/profile_screen.dart';
import 'package:skoolwala/features/teacher_attendance/simple_teacher_attendance.dart';
import 'package:skoolwala/shared/models/teacher.dart';
import 'package:skoolwala/features/profile/models/teacher_profile.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/routes/app_routes.dart';
import 'package:skoolwala/shared/widgets/custom_app_bar.dart';
import 'package:skoolwala/shared/widgets/custom_bottom_nav_bar.dart';
import 'package:skoolwala/shared/widgets/app_sidebar.dart';
import 'package:skoolwala/features/dashboard/widgets/index.dart';
import 'package:skoolwala/features/teacher/screens/my_classes_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final GlobalKey<WorkingTimerCardState> _timerKey =
      GlobalKey<WorkingTimerCardState>();
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
      final baseUrl = ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/getTeacherSelfAttendanceStats?staff_id=${_teacher!.id}&filter_type=date&filter_value=${DateTime.now().toIso8601String().split('T')[0]}',
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

  /// Logout and navigate to login screen
  Future<void> _logout() async {
    try {
      // Clear session
      await SessionManager.instance.logout();

      // Navigate back to login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
          arguments: {'schoolName': _schoolName ?? 'SkoolWala'},
        );
      }
    } catch (e) {
      print('❌ Dashboard Debug - Error logging out: $e');
      // Clear session anyway and navigate
      await SessionManager.instance.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
          arguments: {'schoolName': _schoolName ?? 'SkoolWala'},
        );
      }
    }
  }

  Future<void> _load() async {
    try {
      // Use SessionManager credentials if available, otherwise use widget params
      final username = widget.username.isNotEmpty
          ? widget.username
          : (SessionManager.instance.currentUsername ?? '');
      final password = widget.password.isNotEmpty
          ? widget.password
          : (SessionManager.instance.currentPassword ?? '');

      print('🔍 Dashboard Debug - Starting load with username: $username');
      print(
        '🔍 Dashboard Debug - Session Manager logged in: ${SessionManager.instance.isLoggedIn}',
      );
      print(
        '🔍 Dashboard Debug - Session Manager has valid session: ${SessionManager.instance.hasValidSession}',
      );

      // Validate credentials
      if (username.isEmpty || password.isEmpty) {
        print('❌ Dashboard Debug - Username or password is empty!');
        print('❌ Widget username: ${widget.username}');
        print(
          '❌ Widget password: ${widget.password.isEmpty ? "empty" : "provided"}',
        );
        print('❌ Session username: ${SessionManager.instance.currentUsername}');

        // If no credentials available, show error and redirect to login
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Redirecting to login...'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Ensure user is logged out and sent back to login screen
        await _logout();
        return;
      }

      // Load all dashboard data from multiple APIs
      final dashboardData = await DashboardService.fetchDashboardData(
        username: username,
        password: password,
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
      // Use multi-angle enroll screen for face enrollment
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const MultiAngleEnrollScreen()),
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

  // Build bottom navigation bar using reusable widget
  // Navigation is now handled automatically by CustomBottomNavBar
  Widget _buildBottomNavigationBar() {
    return CustomBottomNavBar(
      currentIndex: _selectedIndex,
      primaryColor: AppTheme.dashboardPrimary,
      accentColor: AppTheme.dashboardAccentLight,
      items: BottomNavConfigs.dashboardItems,
      // Custom onTap for dashboard-specific actions (refresh on home tap)
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        if (index == 0) {
          // Home - already on dashboard, just refresh or scroll to top
          return;
        }

        // For other tabs, use centralized navigation
        // But we can still keep custom methods if needed
        switch (index) {
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
      },
      autoNavigation: false, // Dashboard has custom navigation logic
    );
  }

  // Navigate to classes screen
  Future<void> _openClasses() async {
    try {
      final baseUrl = ApiConfig.getBaseUrl().replaceAll('/api', '/index.php');
      final response = await http.post(
        Uri.parse('$baseUrl/api/getClassList'),
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
    // Navigate to My Classes screen first, where user can select a class
    // Then they can view students for that class
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyClassesScreen()),
    );
  }

  // Deprecated: Old class selection method - keeping for reference
  // Open class selection to view students
  Future<void> _openClassSelectionForStudents() async {
    try {
      final baseUrl = ApiConfig.getBaseUrl().replaceAll('/api', '/index.php');
      final response = await http.post(
        Uri.parse('$baseUrl/api/getClassList'),
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
        drawer: const AppSidebar(),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: CustomAppBar(
            title: _schoolName ?? 'School',
            primaryColor: AppTheme.dashboardPrimary,
            showThemeToggle: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              // Logout button - shows when user is NOT logged in (to get unstuck)
              if (!SessionManager.instance.isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () async {
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
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true && mounted) {
                      await _logout();
                    }
                  },
                  tooltip: 'Logout',
                ),
            ],
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const ModernLoadingView()
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
                              ProfileCard(
                                profile: _profile,
                                onProfileTap: _openProfile,
                                isEnrolled: _isEnrolled,
                              ),
                              const SizedBox(height: 20),
                              if (_teacher != null)
                                WorkingTimerCard(
                                  key: _timerKey,
                                  teacher: _teacher,
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
                                // Quick Actions section hidden per request
                                // const SizedBox(height: 20),
                                // // Teacher Features Menu
                                // const TeacherFeaturesMenu(),
                                // const SizedBox(height: 20),
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
                                  username: widget.username,
                                  password: widget.password,
                                  onEnrollmentComplete: (success) async {
                                    // Refresh enrollment status after enrollment
                                    if (success) {
                                      try {
                                        final dashboardData =
                                            await DashboardService.fetchDashboardData(
                                              username: widget.username,
                                              password: widget.password,
                                            );
                                        if (mounted) {
                                          setState(() {
                                            _isEnrolled = dashboardData
                                                .teacher
                                                .faceEnrolled;
                                            _showEnrollSuccess = true;
                                          });

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Face enrolled successfully! You can now use attendance.',
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 3),
                                            ),
                                          );

                                          // Auto-hide success message
                                          Future.delayed(
                                            const Duration(seconds: 3),
                                            () {
                                              if (mounted) {
                                                setState(() {
                                                  _showEnrollSuccess = false;
                                                });
                                              }
                                            },
                                          );
                                        }
                                      } catch (e) {
                                        print(
                                          'Error refreshing enrollment status: $e',
                                        );
                                      }
                                    }
                                  },
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
        // Floating dev tools button hidden as requested (kept in code but not shown)
        floatingActionButton: null,
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
  final String? username;
  final String? password;
  final Function(bool)? onEnrollmentComplete;
  const _TeacherAttendanceCard({
    this.onTap,
    this.isEnrolled = false,
    this.isCheckedIn = false,
    this.username,
    this.password,
    this.onEnrollmentComplete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnrolled
          ? onTap
          : () async {
              // Navigate to multi-angle enrollment screen when locked
              final enrollResult = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const MultiAngleEnrollScreen(),
                ),
              );

              // If enrollment was successful, refresh the enrollment status via callback
              if (enrollResult == true && context.mounted) {
                // Call the callback to refresh enrollment status
                if (onEnrollmentComplete != null) {
                  onEnrollmentComplete!(true);
                }
              }
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
  final VoidCallback onMultiAngleEnroll;
  // Removed: on3DFaceEnroll
  // Removed: onSimpleFaceEnrollHome
  // Removed: onSimpleEnroll - using only multi-angle enroll
  final VoidCallback onFaceAnalyzer;
  final VoidCallback onEnrolledList;
  final VoidCallback onLogout;

  const _ExpandableFloatingButton({
    required this.isExpanded,
    required this.onToggle,
    required this.onMultiAngleEnroll,
    required this.onFaceAnalyzer,
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
          // Compact icon-only tools
          FloatingActionButton.small(
            heroTag: 'fab-enroll-multi',
            onPressed: onMultiAngleEnroll,
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            tooltip: 'Multi-Angle Enroll',
            child: const Icon(Icons.view_in_ar),
          ),
          const SizedBox(height: 6),
          FloatingActionButton.small(
            heroTag: 'fab-analyzer',
            onPressed: onFaceAnalyzer,
            backgroundColor: Colors.indigo[600],
            foregroundColor: Colors.white,
            tooltip: 'Face Analyzer',
            child: const Icon(Icons.analytics),
          ),
          const SizedBox(height: 6),
          FloatingActionButton.small(
            heroTag: 'fab-list',
            onPressed: onEnrolledList,
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
            tooltip: 'Enrolled List',
            child: const Icon(Icons.list_alt_rounded),
          ),
          const SizedBox(height: 8),
          // Logout button (visible in expanded state)
          FloatingActionButton.extended(
            heroTag: 'fab-logout',
            onPressed: onLogout,
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
          const SizedBox(height: 12),
        ],
        // Main Toggle Button
        FloatingActionButton(
          heroTag: 'fab-dev-toggle',
          onPressed: onToggle,
          backgroundColor: AppTheme.dashboardPrimary,
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

// Classes Screen Widget
class _ClassesScreen extends StatelessWidget {
  final List<dynamic> classes;

  const _ClassesScreen({required this.classes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        backgroundColor: AppTheme.dashboardPrimary,
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
                          colors: [
                            AppTheme.dashboardPrimary,
                            AppTheme.dashboardAccent,
                          ],
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
                      color: AppTheme.dashboardPrimary,
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
          '${ApiConfig.getBaseUrl().replaceAll('/api', '/index.php')}/api/getSectionListByClass',
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
        backgroundColor: AppTheme.dashboardPrimary,
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
                        color: AppTheme.dashboardAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: AppTheme.dashboardAccent,
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
                      color: AppTheme.dashboardPrimary,
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
        Uri.parse(
          '${ApiConfig.getBaseUrl().replaceAll('/api', '/index.php')}/api/getStaffList',
        ),
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
        backgroundColor: AppTheme.dashboardPrimary,
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
                        backgroundColor: AppTheme.dashboardAccent.withOpacity(
                          0.2,
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppTheme.dashboardPrimary,
                        ),
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
        backgroundColor: AppTheme.dashboardPrimary,
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
                          colors: [
                            AppTheme.dashboardPrimary,
                            AppTheme.dashboardAccent,
                          ],
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
                      color: AppTheme.dashboardPrimary,
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
          '${ApiConfig.getBaseUrl().replaceAll('/api', '/index.php')}/api/getSectionListByClass',
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
        backgroundColor: AppTheme.dashboardPrimary,
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
                        color: AppTheme.dashboardAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: AppTheme.dashboardAccent,
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
                      color: AppTheme.dashboardPrimary,
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
        Uri.parse(
          '${ApiConfig.getBaseUrl().replaceAll('/api', '/index.php')}/api/getStudentList',
        ),
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
        backgroundColor: AppTheme.dashboardPrimary,
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
                        backgroundColor: AppTheme.dashboardAccent.withOpacity(
                          0.2,
                        ),
                        child: Text(
                          (student['name'] ?? 'N')[0].toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.dashboardPrimary,
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

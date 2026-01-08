// ignore_for_file: use_build_context_synchronously, unused_element, deprecated_member_use, unused_element_parameter, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/features/dashboard/services/dashboard_service.dart';
import 'package:skoolwala/features/dashboard/models/profile.dart';

import 'package:skoolwala/features/attendance/screens/face_verification_screen.dart';
import 'package:skoolwala/features/attendance/screens/quick_attendance_screen.dart';
import 'package:skoolwala/features/attendance/screens/multi_angle_enroll_screen.dart';

import 'package:skoolwala/features/profile/screens/profile_screen.dart';
import 'package:skoolwala/features/teacher_attendance/simple_teacher_attendance.dart';
import 'package:skoolwala/shared/models/teacher.dart';
import 'package:skoolwala/features/profile/models/teacher_profile.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/routes/app_routes.dart';
import 'package:skoolwala/shared/widgets/custom_app_bar.dart';
import 'package:skoolwala/shared/widgets/animated_bottom_nav_bar.dart';
import 'package:skoolwala/features/dashboard/widgets/index.dart';
import 'package:skoolwala/features/dashboard/widgets/single_class_widget.dart';
import 'package:skoolwala/features/teacher/screens/my_classes_screen.dart';
import 'package:skoolwala/features/teacher/screens/teacher_schedule_screen.dart';
import 'package:skoolwala/shared/widgets/app_loading_indicator.dart';
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
    with TickerProviderStateMixin {
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
  final bool _showBars = true;
  final double _lastScrollOffset = 0;

  // Staggered Entrance Animations
  late AnimationController _entranceController;
  late Animation<double> _profileAnimation;
  late Animation<double> _timerAnimation;
  late Animation<double> _classAnimation;
  late Animation<double> _statsTitleAnimation;
  late Animation<double> _statsContentAnimation;
  late Animation<double> _attendanceCardAnimation;

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

    // Initialize Entrance Animation Controller
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _profileAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    _timerAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    );

    _classAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    );

    _statsTitleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    );

    _statsContentAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
    );

    _attendanceCardAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    // Play initial animation
    _playEntranceAnimation();

    _load();
  }

  void _playEntranceAnimation() {
    _entranceController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _entranceController.dispose();
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
      _playEntranceAnimation();
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
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(
                teacher: _teacher!,
                schoolName: _schoolName,
                teacherProfile: _teacherProfile,
              ),
            ),
          )
          .then((_) {
            _load();
            _playEntranceAnimation();
          });
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
      ).then((_) {
        _load();
        _playEntranceAnimation();
      });
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
    // Get navigation items based on user role
    final userRole = SessionManager.instance.currentTeacher?.role;
    final navItems = BottomNavConfigs.getItemsForRole(userRole);

    // Check if user is a teacher (role can be numeric like "3" or string like "Teacher")
    // Role 3 is typically teacher role ID, or check if role contains 'teacher'/'instructor'
    final isTeacher =
        userRole != null &&
        (userRole == '3' || // Numeric teacher role ID
            userRole.toLowerCase().contains('teacher') ||
            userRole.toLowerCase().contains('instructor') ||
            userRole.toLowerCase().contains('staff') // Staff are teachers
            );

    print('\n🔍 Bottom Nav Debug:');
    print('👨‍🏫 User Role: $userRole (type: ${userRole.runtimeType})');
    print('🏷️ Is Teacher: $isTeacher');
    print('📋 Nav Items Count: ${navItems.length}');

    return AnimatedBottomNavBar(
      currentIndex: 0, // Dashboard is always Home (index 0)
      items: navItems,
      // Custom onTap for dashboard-specific actions
      onTap: (index) {
        print('\n🔘 Bottom Nav Tapped - Index: $index');
        print('🏷️ Is Teacher: $isTeacher');

        // Make sure index is valid
        if (index >= navItems.length) {
          print('❌ Index $index is out of bounds for ${navItems.length} items');
          return;
        }

        // Don't change _selectedIndex - we use push navigation, not tab switching
        // The target screen will have its own bottom bar with its own index

        // Get the label of the tapped item to determine navigation
        final itemLabel = navItems[index].label.toLowerCase().trim();
        print(
          '📍 Index $index: "${navItems[index].label}" (label: "$itemLabel")',
        );

        // Navigate based on item label (works for all roles)
        if (itemLabel.contains('home')) {
          print('📍 Home tapped');
          return; // Already on dashboard
        } else if (itemLabel.contains('attendance')) {
          print('📍 Attendance tapped');
          _openTeacherAttendance();
        } else if (itemLabel.contains('schedule')) {
          print('📍 Schedule tapped - Opening TeacherScheduleScreen');
          _openTeacherSchedule();
        } else if (itemLabel.contains('class')) {
          print('📍 Classes tapped');
          _openClasses();
        } else if (itemLabel.contains('student')) {
          print('📍 Students tapped');
          _openStudentsList();
        } else if (itemLabel.contains('profile')) {
          print('📍 Profile tapped');
          _openProfile();
        } else {
          print('❌ Unknown label: $itemLabel');
        }
      },
      autoNavigation: false, // Dashboard has custom navigation logic
      collapsible:
          false, // Disable collapse on dashboard - always show full bar
      notificationCount: 0, // Pass notification count if needed
    );
  }

  // Navigate to teacher schedule screen
  Future<void> _openTeacherSchedule() async {
    try {
      print('\n🔍 DEBUG: _openTeacherSchedule called');
      print(
        '📱 Current user role: ${SessionManager.instance.currentTeacher?.role}',
      );
      print('👨‍🏫 Teacher ID: ${SessionManager.instance.currentTeacher?.id}');
      print('📝 Teacher Name: ${SessionManager.instance.currentTeacher?.name}');

      if (mounted) {
        print('✅ Context is mounted, pushing TeacherScheduleScreen');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TeacherScheduleScreen(),
            settings: const RouteSettings(name: 'teacher_schedule'),
          ),
        ).then((_) {
          print('✅ TeacherScheduleScreen popped (returned)');
          _load(); // Refresh dashboard data
          _playEntranceAnimation();
        });
      } else {
        print('❌ Context is not mounted!');
      }
    } catch (e) {
      print('❌ Error navigating to schedule: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Navigate to classes screen (Today's Schedule)
  Future<void> _openClasses() async {
    // Navigate to Teacher Schedule screen (Today's Schedule with Classes/View tabs)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherScheduleScreen()),
    ).then((_) {
      _load();
      _playEntranceAnimation();
    }); // Refresh dashboard data on return
  }

  // Navigate to teachers list screen
  void _openTeachersList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _TeachersListScreen()),
    ).then((_) => _playEntranceAnimation());
  }

  // Navigate to students list screen
  void _openStudentsList() {
    // Navigate to My Classes screen where teacher can select a class to view students
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyClassesScreen()),
    ).then((_) => _playEntranceAnimation());
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
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: CustomAppBar(
            title: _schoolName ?? 'School',
            backgroundColor: Colors.transparent,
            gradient: const LinearGradient(
              colors: [Colors.transparent, Colors.transparent],
            ),
            elevation: 0,
            showRoundedCorners: false,
            showThemeToggle: true,
            automaticallyImplyLeading: false,
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
        // drawer: const AppSidebar(),
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
        body: Stack(
          children: [
            // Background - Uses image with blur if set, otherwise gradient
            AppTheme.buildBackground(webBaseUrl: ApiConfig.getWebBaseUrl()),
            // Decorative shapes
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            SafeArea(
              child: _isLoading
                  ? const ModernLoadingView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: Colors.white,
                      backgroundColor: AppTheme.dashboardPrimary,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          // Bars hiding logic removed as per request
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
                                  // Show ProfileCard only if NOT enrolled/verified
                                  if (!_isEnrolled)
                                    AnimatedBuilder(
                                      animation: _profileAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            30 * (1 - _profileAnimation.value),
                                          ),
                                          child: Opacity(
                                            opacity: _profileAnimation.value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: ProfileCard(
                                        profile: _profile,
                                        onProfileTap: _openProfile,
                                        isEnrolled: _isEnrolled,
                                      ),
                                    ),
                                  if (!_isEnrolled) const SizedBox(height: 20),
                                  // Show Working Timer only for teachers (role 3, 4, 5) and principal (role 2)
                                  // Hide for other roles like superadmin
                                  if (_teacher != null &&
                                      (_teacher!.role == '2' ||
                                          _teacher!.role == '3' ||
                                          _teacher!.role == '4' ||
                                          _teacher!.role == '5'))
                                    AnimatedBuilder(
                                      animation: _timerAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            30 * (1 - _timerAnimation.value),
                                          ),
                                          child: Opacity(
                                            opacity: _timerAnimation.value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: WorkingTimerCard(
                                        key: _timerKey,
                                        teacher: _teacher,
                                      ),
                                    ),
                                  if (_teacher != null &&
                                      (_teacher!.role == '2' ||
                                          _teacher!.role == '3' ||
                                          _teacher!.role == '4' ||
                                          _teacher!.role == '5'))
                                    const SizedBox(height: 20),

                                  // Attendance Rate Overview - directly below the top Check In/Out area
                                  // Single Class Widget - Shows either current (if ongoing) or next class
                                  if (_teacher != null &&
                                      (_teacher!.role == '2' ||
                                          _teacher!.role == '3' ||
                                          _teacher!.role == '4' ||
                                          _teacher!.role == '5') &&
                                      _isCheckedIn)
                                    AnimatedBuilder(
                                      animation: _classAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            30 * (1 - _classAnimation.value),
                                          ),
                                          child: Opacity(
                                            opacity: _classAnimation.value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: const SingleClassWidget(),
                                    ),
                                  if (_teacher != null &&
                                      (_teacher!.role == '2' ||
                                          _teacher!.role == '3' ||
                                          _teacher!.role == '4' ||
                                          _teacher!.role == '5') &&
                                      _isCheckedIn)
                                    const SizedBox(height: 20),
                                ],
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  20,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _statsTitleAnimation,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity:
                                                  _statsTitleAnimation.value,
                                              child: child,
                                            );
                                          },
                                          child: const Text(
                                            'Your Statistics',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    AnimatedBuilder(
                                      animation: _statsContentAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            30 *
                                                (1 -
                                                    _statsContentAnimation
                                                        .value),
                                          ),
                                          child: Opacity(
                                            opacity:
                                                _statsContentAnimation.value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _StatCardsRow(
                                        presentDays: _profile?.presentDays ?? 0,
                                        absentDays: _profile?.absentDays ?? 0,
                                        onAnalyticsTap: _openStatistics,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Attendance Rate Overview - Inside Statistics Section
                                    // (Moved below WorkingTimerCard per request)
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
                                    AnimatedBuilder(
                                      animation: _attendanceCardAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            30 *
                                                (1 -
                                                    _attendanceCardAnimation
                                                        .value),
                                          ),
                                          child: Opacity(
                                            opacity:
                                                _attendanceCardAnimation.value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _TeacherAttendanceCard(
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
                                                    backgroundColor:
                                                        Colors.green,
                                                    duration: Duration(
                                                      seconds: 3,
                                                    ),
                                                  ),
                                                );

                                                // Auto-hide success message
                                                Future.delayed(
                                                  const Duration(seconds: 3),
                                                  () {
                                                    if (mounted) {
                                                      setState(() {
                                                        _showEnrollSuccess =
                                                            false;
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
                                    ),
                                    const SizedBox(height: 20),
                                    if (_teacher != null &&
                                        (_teacher!.role == '2' ||
                                            _teacher!.role == '3' ||
                                            _teacher!.role == '4' ||
                                            _teacher!.role == '5'))
                                      AnimatedBuilder(
                                        animation: _attendanceCardAnimation,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(
                                              0,
                                              30 *
                                                  (1 -
                                                      _attendanceCardAnimation
                                                          .value),
                                            ),
                                            child: Opacity(
                                              opacity: _attendanceCardAnimation
                                                  .value,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: _AttendanceRateOverview(
                                          presentDays:
                                              _profile?.presentDays ?? 0,
                                          absentDays: _profile?.absentDays ?? 0,
                                        ),
                                      ),

                                    const SizedBox(height: 20),
                                    if (_showSuccess)
                                      const _InfoBanner.success(
                                        'Success! Marked Attendance successfully.',
                                      ),
                                    if (_showSuccess)
                                      const SizedBox(height: 16),
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
          ],
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
        Icon(icon, size: 18, color: AppTheme.primaryPurple),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textDark,
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
        color: AppTheme.borderGray,
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
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.primaryGradient,
          boxShadow: AppTheme.buttonShadow,
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
        gradient: AppTheme.primaryGradient,
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
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: AppTheme.darkPurple,
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
                    style: TextStyle(
                      color: AppTheme.lightPurple.withOpacity(0.9),
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
          color: active ? AppTheme.darkPurple : Colors.white70,
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
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.buttonShadow,
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
              foregroundColor: AppTheme.textDark,
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
        color: AppTheme.accentGreen,
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
            color: AppTheme.successGreen,
            title: 'Total Present',
            value: totalPresent.toString(),
            icon: Icons.person,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TotalBox(
            color: AppTheme.errorRed,
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
        gradient: AppTheme.warningGradient,
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
          gradient: AppTheme.successGradient,
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
          gradient: AppTheme.primaryGradient,
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
          gradient: AppTheme.successGradient,
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
          gradient: AppTheme.successGradient,
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
              colors: [
                Colors.white.withOpacity(0.14),
                Colors.white.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? AppTheme.accentRed
                      : AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? 'Check Out' : 'Check In',
                      style: TextStyle(
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
                        color: Colors.white.withOpacity(0.8),
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
                  gradient: isEnrolled
                      ? (isCheckedIn
                            ? AppTheme.errorGradient
                            : AppTheme.successGradient)
                      : null,
                  color: isEnrolled ? null : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
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
                      isEnrolled
                          ? (isCheckedIn ? 'CHECK OUT' : 'CHECK IN')
                          : 'LOCKED',
                      style: TextStyle(
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
                        gradient: LinearGradient(
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
                    trailing: Icon(
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
          ? const AppLoadingIndicator()
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
                      child: Icon(
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
                    trailing: Icon(
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
          ? const AppLoadingIndicator()
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
                        gradient: LinearGradient(
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
                    trailing: Icon(
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
          ? const AppLoadingIndicator()
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
                      child: Icon(
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
                    trailing: Icon(
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
          ? const AppLoadingIndicator()
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

class _AttendanceRateOverview extends StatelessWidget {
  final int presentDays;
  final int absentDays;

  const _AttendanceRateOverview({
    required this.presentDays,
    required this.absentDays,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = presentDays + absentDays;
    final attendanceRate = totalDays > 0
        ? (presentDays / totalDays) * 100
        : 0.0;

    final Color rateColor = attendanceRate >= 75
        ? AppTheme.successGreen
        : attendanceRate >= 50
        ? AppTheme.warningOrange
        : AppTheme.errorRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.14),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress + Percentage (Smaller)
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 4,
                  ),
                ),
              ),
              SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(
                  value: (attendanceRate / 100).clamp(0.0, 1.0),
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attendanceRate.toStringAsFixed(0),
                    style: TextStyle(
                      color: rateColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      attendanceRate >= 75
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: rateColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ATTENDANCE RATE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  totalDays == 0
                      ? 'No data yet'
                      : attendanceRate >= 90
                      ? 'Excellent performance!'
                      : attendanceRate >= 75
                      ? 'Good standing'
                      : 'Keep improving',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (totalDays > 0)
                  Text(
                    '$presentDays Present out of $totalDays days',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.3),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _AttendanceStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AttendanceStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

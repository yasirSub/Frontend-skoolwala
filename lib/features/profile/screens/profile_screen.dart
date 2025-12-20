// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skoolwala/shared/models/teacher.dart';
import 'package:skoolwala/features/auth/services/profile_service.dart';
import 'package:skoolwala/features/auth/screens/login_screen.dart';
import 'package:skoolwala/features/profile/widgets/developer_attendance_fab.dart';
import 'package:skoolwala/features/school/screens/school_selection_screen.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/services/persistent_storage.dart';
import '../models/teacher_profile.dart';
import '../services/teacher_profile_service.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
// import '../widgets/set_location_widget.dart';

class ProfileScreen extends StatefulWidget {
  final Teacher teacher;
  final String? schoolName;
  final TeacherProfile? teacherProfile;

  const ProfileScreen({
    super.key,
    required this.teacher,
    this.schoolName,
    this.teacherProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _staggerController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _staggerAnimation;

  // Refresh functionality
  bool _isRefreshing = false;
  TeacherProfile? _refreshedTeacherProfile;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show logout options dialog
    final logoutType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Choose logout option:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('logout'),
            child: const Text('Logout'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('complete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Complete Logout'),
          ),
        ],
      ),
    );

    if (logoutType == null || logoutType == 'cancel' || !mounted) {
      return;
    }

    // Capture context before async operations
    final navigatorContext = context;
    final isCompleteLogout = logoutType == 'complete';

    try {
      // Call logout API if we have teacher data
      if (widget.teacher.username.isNotEmpty) {
        await ProfileService.logoutTeacher(username: widget.teacher.username);
      }

      if (isCompleteLogout) {
        // Complete logout: Clear everything including selected school
        await SessionManager.instance.completeLogout();

        // Navigate to school selection screen
        if (mounted) {
          Navigator.of(navigatorContext).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SchoolSelectionScreen()),
            (route) => false,
          );
        }
      } else {
        // Regular logout: Keep selected school
        await SessionManager.instance.logout();

        // Get saved school info for login screen
        final savedSchool = await PersistentStorage.getSelectedSchool();
        final schoolName = savedSchool?['name'] ?? 'SKOOLWALA INSTITUTION';
        final mainLogo = savedSchool?['main_logo'];
        final branchId = savedSchool?['id'];

        // Navigate to login screen with selected school info
        if (mounted) {
          Navigator.of(navigatorContext).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => LoginScreen(
                schoolName: schoolName,
                mainLogo: mainLogo,
                branchId: branchId, // Pass branch_id so roles load correctly
              ),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('❌ Logout error: $e');
      // Even if logout fails, still clear session and navigate
      if (isCompleteLogout) {
        await SessionManager.instance.completeLogout();
        if (mounted) {
          Navigator.of(navigatorContext).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SchoolSelectionScreen()),
            (route) => false,
          );
        }
      } else {
        await SessionManager.instance.logout();
        final savedSchool = await PersistentStorage.getSelectedSchool();
        final schoolName = savedSchool?['name'] ?? 'SKOOLWALA INSTITUTION';
        final mainLogo = savedSchool?['main_logo'];
        final branchId = savedSchool?['id'];

        if (mounted) {
          Navigator.of(navigatorContext).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => LoginScreen(
                schoolName: schoolName,
                mainLogo: mainLogo,
                branchId: branchId,
              ),
            ),
            (route) => false,
          );
        }
      }
    }
  }

  /// Refresh profile data from server
  Future<void> _refreshProfileData() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    setState(() {
      _isRefreshing = true;
    });

    try {
      print('🔄 Refreshing profile data...');

      // Fetch fresh teacher profile data
      final refreshedProfile = await TeacherProfileService.getTeacherProfile(
        teacherId: widget.teacher.id,
        username: widget.teacher.username,
      );

      if (mounted) {
        setState(() {
          _refreshedTeacherProfile = refreshedProfile;
          _isRefreshing = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile data refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        print('✅ Profile data refreshed successfully');
      }
    } catch (e) {
      print('❌ Error refreshing profile data: $e');

      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show edit profile dialog
  void _showEditProfileDialog(BuildContext context, Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text(
          'Profile editing functionality will be implemented soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use refreshed data if available, otherwise use original data
    final displayData =
        (_refreshedTeacherProfile?.toTeacher() ??
        widget.teacherProfile?.toTeacher() ??
        widget.teacher);

    // Debug: Print data being used
    print(
      '🔍 Profile Debug - Using TeacherProfile: ${widget.teacherProfile != null}',
    );
    print('🔍 Profile Debug - Teacher Name: ${displayData.name}');
    print('🔍 Profile Debug - Teacher Email: ${displayData.email}');
    print('🔍 Profile Debug - Teacher Religion: ${displayData.religion}');
    print('🔍 Profile Debug - Teacher Blood Group: ${displayData.bloodGroup}');
    print('🔍 Profile Debug - Teacher Mobile: ${displayData.mobileNo}');
    print('🔍 Profile Debug - Teacher Designation: ${displayData.designation}');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.dashboardPrimary,
              AppTheme.dashboardPrimary.withBlue(100).withRed(40),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'My Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              // Edit button
              IconButton(
                onPressed: () => _showEditProfileDialog(context, displayData),
                icon: const Icon(
                  Icons.mode_edit_outline_outlined,
                  color: Colors.white,
                ),
                tooltip: 'Edit Profile',
              ),
              // Logout button
              IconButton(
                onPressed: () => _handleLogout(context),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.errorRed,
                ),
                tooltip: 'Logout',
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Floating developer attendance button returns when running in debug mode
          floatingActionButton: kDebugMode
              ? DeveloperAttendanceFAB(teacher: displayData)
              : null,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshProfileData,
              color: AppTheme.primaryPurple,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Enhanced Header with fade animation
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _EnhancedProfileHeader(
                        teacher: displayData,
                        schoolName: widget.schoolName,
                        onLogout: _handleLogout,
                      ),
                    ),
                  ),

                  // Profile details with slide animation
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _staggerAnimation,
                            child: _ProfileDetails(
                              teacher: displayData,
                              schoolName: widget.schoolName,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconTurns = _controller.drive(Tween<double>(begin: 0.0, end: 0.5));
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header (Clickable)
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.children,
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

class _EnhancedProfileHeader extends StatelessWidget {
  final Teacher teacher;
  final String? schoolName;
  final Future<void> Function(BuildContext) onLogout;

  const _EnhancedProfileHeader({
    required this.teacher,
    this.schoolName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      child: Column(
        children: [
          // Avatar with depth and glow ring
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Avatar Container
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Hero(
                  tag: 'profile_avatar',
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: teacher.photo.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              'https://skoolwala.com/uploads/staff/${teacher.photo}',
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name with dramatic shadow
          Text(
            teacher.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Designation / Role Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  teacher.designation.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (teacher.role == '3')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warningOrange.withOpacity(0.3),
                        AppTheme.warningOrange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.warningOrange.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'FACULTY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.warningOrange,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              if (schoolName != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.successGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schoolName!.split(' ').take(2).join(' ').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Quick Action Icons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickAction(
                Icons.call_rounded,
                AppTheme.successGreen,
                () => _launchUrl('tel:${teacher.mobileNo}'),
              ),
              const SizedBox(width: 16),
              _buildQuickAction(
                Icons.chat_bubble_rounded,
                const Color(0xFF25D366), // WhatsApp color
                () => _launchUrl('https://wa.me/${teacher.mobileNo}'),
              ),
              const SizedBox(width: 16),
              _buildQuickAction(
                Icons.email_rounded,
                AppTheme.infoBlue,
                () => _launchUrl('mailto:${teacher.email}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? label,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ProfileDetails extends StatelessWidget {
  final Teacher teacher;
  final String? schoolName;

  const _ProfileDetails({required this.teacher, this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Information Card (Expandable)
        _SectionCard(
          title: 'Personal Information',
          icon: Icons.person_outline,
          initiallyExpanded: false,
          children: [
            _AnimatedProfileDetailItem(
              label: 'E-mail',
              value: teacher.email,
              icon: Icons.email_outlined,
              index: 0,
            ),
            _AnimatedProfileDetailItem(
              label: 'Mobile No',
              value: teacher.mobileNo,
              icon: Icons.phone_outlined,
              index: 1,
            ),
            _AnimatedProfileDetailItem(
              label: 'Gender',
              value: _capitalizeFirst(teacher.sex),
              icon: Icons.person_outline,
              index: 2,
            ),
            _AnimatedProfileDetailItem(
              label: 'Blood Group',
              value: teacher.bloodGroup,
              icon: Icons.bloodtype_outlined,
              index: 3,
            ),
            _AnimatedProfileDetailItem(
              label: 'Religion',
              value: _capitalizeFirst(teacher.religion),
              icon: Icons.church_outlined,
              index: 4,
            ),
            _AnimatedProfileDetailItem(
              label: 'D.O.B',
              value: _formatDate(teacher.birthday),
              icon: Icons.cake_outlined,
              index: 5,
            ),
            _AnimatedProfileDetailItem(
              label: 'Present Address',
              value: teacher.presentAddress,
              icon: Icons.location_on_outlined,
              index: 6,
            ),
            _AnimatedProfileDetailItem(
              label: 'Permanent Address',
              value: teacher.permanentAddress,
              icon: Icons.home_outlined,
              index: 7,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Dynamic Professional/Faculty Information Card (Expandable)
        _SectionCard(
          title: teacher.role == '3'
              ? 'Faculty Information'
              : 'Professional Information',
          icon: Icons.work_outline,
          initiallyExpanded: false,
          children: [
            _AnimatedProfileDetailItem(
              label: 'Branch',
              value: schoolName ?? 'SkoolWala',
              icon: Icons.business_outlined,
              index: 8,
            ),
            _AnimatedProfileDetailItem(
              label: 'Designation',
              value: teacher.designation,
              icon: Icons.badge_outlined,
              index: 9,
            ),
            _AnimatedProfileDetailItem(
              label: 'Department',
              value: teacher.department,
              icon: Icons.account_tree_outlined,
              index: 10,
            ),
            _AnimatedProfileDetailItem(
              label: 'Joining Date',
              value: _formatDate(teacher.joiningDate),
              icon: Icons.calendar_today_outlined,
              index: 11,
            ),
            _AnimatedProfileDetailItem(
              label: 'Qualification',
              value: teacher.qualification,
              icon: Icons.school_outlined,
              index: 12,
            ),
            _AnimatedProfileDetailItem(
              label: 'Experience',
              value: '${teacher.totalExperience} years',
              icon: Icons.timeline_outlined,
              index: 13,
            ),
            _AnimatedProfileDetailItem(
              label: 'Experience Details',
              value: teacher.experienceDetails,
              icon: Icons.description_outlined,
              index: 14,
            ),
            _AnimatedProfileDetailItem(
              label: 'Staff ID',
              value: teacher.staffId,
              icon: Icons.credit_card_outlined,
              index: 15,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Social Media Card (Expandable)
        if (teacher.facebookUrl.isNotEmpty ||
            teacher.linkedinUrl.isNotEmpty ||
            teacher.twitterUrl.isNotEmpty)
          _SectionCard(
            title: 'Social Media',
            icon: Icons.share_outlined,
            initiallyExpanded: false,
            children: [
              if (teacher.facebookUrl.isNotEmpty) ...[
                _AnimatedProfileDetailItem(
                  label: 'Facebook',
                  value: teacher.facebookUrl,
                  icon: Icons.facebook_outlined,
                  index: 16,
                ),
              ],
              if (teacher.linkedinUrl.isNotEmpty) ...[
                _AnimatedProfileDetailItem(
                  label: 'LinkedIn',
                  value: teacher.linkedinUrl,
                  icon: Icons.link,
                  index: 17,
                ),
              ],
              if (teacher.twitterUrl.isNotEmpty) ...[
                _AnimatedProfileDetailItem(
                  label: 'Twitter',
                  value: teacher.twitterUrl,
                  icon: Icons.alternate_email,
                  index: 18,
                ),
              ],
            ],
          ),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _AnimatedProfileDetailItem extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final int index;

  const _AnimatedProfileDetailItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.index,
  });

  @override
  State<_AnimatedProfileDetailItem> createState() =>
      _AnimatedProfileDetailItemState();
}

class _AnimatedProfileDetailItemState extends State<_AnimatedProfileDetailItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Staggered animation based on index
    Future.delayed(Duration(milliseconds: 200 + (widget.index * 100)), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: _ProfileDetailItem(
              label: widget.label,
              value: widget.value,
              icon: widget.icon,
            ),
          ),
        );
      },
    );
  }
}

class _ProfileDetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileDetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        if (value.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label copied to clipboard'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              width: 250,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (value.isNotEmpty)
                        Icon(
                          Icons.copy_rounded,
                          size: 10,
                          color: Colors.white.withOpacity(0.4),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value.isEmpty ? 'Not Provided' : value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            if (value.isNotEmpty &&
                (label.contains('E-mail') || label.contains('Mobile')))
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

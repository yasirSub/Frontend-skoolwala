// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skoolwala/shared/models/teacher.dart';
import 'package:skoolwala/features/auth/services/profile_service.dart';
import 'package:skoolwala/features/auth/screens/login_screen.dart';
import 'package:skoolwala/features/school/screens/school_selection_screen.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/services/persistent_storage.dart';
import '../models/teacher_profile.dart';
import '../services/teacher_profile_service.dart';
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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
            MaterialPageRoute(
              builder: (_) => const SchoolSelectionScreen(),
            ),
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
            MaterialPageRoute(
              builder: (_) => const SchoolSelectionScreen(),
            ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
        ),
        actions: [
          // Edit button
          IconButton(
            onPressed: () => _showEditProfileDialog(context, displayData),
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Profile',
          ),
          // Logout button
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      // Floating developer attendance button hidden as requested (kept in codebase but not shown)
      floatingActionButton: null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfileData,
          color: const Color(0xFF6366F1),
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
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),

              // Horizontal layout: Profile picture on left, details on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile picture on left
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: teacher.photo.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                'https://skoolwala.com/uploads/staff/${teacher.photo}',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Theme.of(context).primaryColor,
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 35,
                              color: Theme.of(context).primaryColor,
                            ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Details on right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          teacher.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            teacher.role,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // School info
                        if (schoolName != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.school,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  schoolName!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
        // Personal Information Card
        _SectionCard(
          title: 'Personal Information',
          icon: Icons.person_outline,
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

        // Professional Information Card
        _SectionCard(
          title: 'Professional Information',
          icon: Icons.work_outline,
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

        // Social Media Card (only if there are social media links)
        if (teacher.facebookUrl.isNotEmpty ||
            teacher.linkedinUrl.isNotEmpty ||
            teacher.twitterUrl.isNotEmpty)
          _SectionCard(
            title: 'Social Media',
            icon: Icons.share_outlined,
            children: [
              if (teacher.facebookUrl.isNotEmpty)
                _AnimatedProfileDetailItem(
                  label: 'Facebook',
                  value: teacher.facebookUrl,
                  icon: Icons.facebook_outlined,
                  index: 16,
                ),
              if (teacher.linkedinUrl.isNotEmpty)
                _AnimatedProfileDetailItem(
                  label: 'LinkedIn',
                  value: teacher.linkedinUrl,
                  icon: Icons
                      .link, // Use a generic link icon since Icons.linkedin_outlined does not exist
                  index: 17,
                ),
              if (teacher.twitterUrl.isNotEmpty)
                _AnimatedProfileDetailItem(
                  label: 'Twitter',
                  value: teacher.twitterUrl,
                  icon: Icons.alternate_email,
                  index: 18,
                ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'N/A' : value,
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
    );
  }
}

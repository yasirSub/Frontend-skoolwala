// ignore_for_file: deprecated_member_use, ambiguous_import, invocation_of_non_function, prefix_shadowed_by_local_declaration

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skoolwala/features/auth/services/profile_service.dart';
import 'package:skoolwala/features/auth/services/role_service.dart';
import 'package:skoolwala/features/auth/screens/forget_password_screen.dart';
import 'package:skoolwala/features/dashboard/screens/dashboard_screen.dart';
import 'package:skoolwala/shared/models/role.dart';
import 'package:skoolwala/shared/services/persistent_storage.dart';
import 'package:skoolwala/shared/widgets/error_handler.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/shared/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.schoolName,
    this.mainLogo,
    this.branchId,
  });

  final String schoolName;
  final String? mainLogo;
  final String? branchId; // Pass branch_id directly from school selection

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final RoleService _roleService = const RoleService();
  bool _obscure = true;
  Role? _selectedRole;
  List<Role> _roles = [];
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    // Debug: Log branch_id immediately
    print('🔍 LoginScreen initState: widget.branchId = ${widget.branchId}');
    print('   School Name: ${widget.schoolName}');

    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _loadPrefill();
    _loadRoles();

    // Log logo information for debugging
    print('🔍 Login Screen - Logo Debug:');
    print('   School Name: ${widget.schoolName}');
    print('   ⚙️ SYSTEM LOGO (mainLogo) URL: ${widget.mainLogo ?? 'null'}');
    print('   System Logo is empty: ${widget.mainLogo?.isEmpty ?? true}');
    print('   System Logo length: ${widget.mainLogo?.length ?? 0}');
    if (widget.mainLogo != null && widget.mainLogo!.isNotEmpty) {
      print('   ✅ SYSTEM LOGO (mainLogo) will be displayed on login screen');
      print('   📍 Logo URL: ${widget.mainLogo}');
    } else {
      print('   ❌ No SYSTEM LOGO available - will show school name text only');
      print('   ⚠️  WARNING: System Logo is missing!');
    }
    print('   ============================================');
  }

  Future<void> _loadRoles() async {
    setState(() {
      // Roles are still loaded, but we don't need a separate loader in the UI now
    });

    try {
      // First try to use branch_id passed directly from school selection
      // If not provided, fall back to persistent storage
      String? branchId = widget.branchId;

      if (branchId == null) {
        final selectedSchool = await PersistentStorage.getSelectedSchool();
        branchId = selectedSchool?['id'];
        print(
          '🔍 LoginScreen: Using branch_id from persistent storage: $branchId',
        );
        print('   Selected school: ${selectedSchool?['name']}');
      } else {
        print(
          '🔍 LoginScreen: Using branch_id passed from school selection: $branchId',
        );
        print('   School Name: ${widget.schoolName}');
      }

      if (branchId == null || branchId.isEmpty) {
        print('⚠️ LoginScreen: No branch_id found! Cannot load roles.');
        if (mounted) {
          setState(() {
            _errorMessage = 'Please select a school first';
          });
        }
        return;
      }

      final roles = await _roleService.fetchRoles(branchId: branchId);

      if (mounted) {
        print('✅ LoginScreen: Loaded ${roles.length} roles');
        setState(() {
          _roles = roles;
          // Set default role to first available role or teacher if available
          if (_roles.isNotEmpty) {
            _selectedRole = _roles.firstWhere(
              (role) => role.slug == 'teacher',
              orElse: () => _roles.first,
            );
            print('   Default selected role: ${_selectedRole?.name}');
          } else {
            print('⚠️ LoginScreen: No roles loaded!');
          }
        });
      }
    } catch (e) {
      print('❌ LoginScreen: Error loading roles: $e');
    }
  }

  Future<void> _loadPrefill() async {
    // Set default credentials for real API
    setState(() {
      _userController.text = 'teacher+2@skoolwala.com';
      _passwordController.text = '12345678';
      _errorMessage = null; // Clear any previous errors
    });
  }

  Future<void> _handleLogin() async {
    // Validate inputs
    if (_userController.text.trim().isEmpty) {
      ErrorHandler.showError(context, ErrorMessages.emptyUsername);
      return;
    }

    if (_passwordController.text.isEmpty) {
      ErrorHandler.showError(context, ErrorMessages.emptyPassword);
      return;
    }

    // Role is auto-selected (default to teacher)
    if (_selectedRole == null && _roles.isNotEmpty) {
      _selectedRole = _roles.firstWhere(
        (role) => role.slug == 'teacher',
        orElse: () => _roles.first,
      );
    }

    if (_selectedRole == null) {
      ErrorHandler.showError(context, 'Unable to determine account type');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use generic authentication for all roles
      // The authLogin API endpoint handles all role types (teacher, student, parent, admin, etc.)
      await ProfileService.authenticateUser(
        username: _userController.text.trim(),
        password: _passwordController.text,
        schoolName: widget.schoolName,
        role: _selectedRole!,
      );

      // Show success message
      if (mounted) {
        // Refresh theme from backend to pick up any color changes
        if (widget.branchId != null) {
          Provider.of<ThemeProvider>(
            context,
            listen: false,
          ).refreshDynamicTheme(widget.branchId!);
        }

        ErrorHandler.showSuccess(
          context,
          'Login successful! Welcome back.',
          duration: const Duration(seconds: 2),
        );

        // Navigate to dashboard
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DashboardScreen(
                username: _userController.text.trim(),
                password: _passwordController.text,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Parse and show user-friendly error message
        final errorMsg = ErrorMessages.getErrorMessage(e);
        ErrorHandler.showError(context, errorMsg);

        // Also update the UI error message
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Test users data
  static const List<Map<String, String>> _testUsers = [
    {'role': 'Admin', 'email': 'support@skoolwala.com', 'password': '12345678'},
    {
      'role': 'Teacher',
      'email': 'teacher@skoolwala.com',
      'password': '12345678',
    },
    {
      'role': 'Accounts',
      'email': 'accounts@skoolwala.com',
      'password': '12345678',
    },
    {
      'role': 'Librarian',
      'email': 'librarian@skoolwala.com',
      'password': '12345678',
    },
    {
      'role': 'Receptionist',
      'email': 'receptionist@skoolwala.com',
      'password': '12345678',
    },
    {
      'role': 'Student',
      'email': 'student@skoolwala.com',
      'password': '12345678',
    },
    {
      'role': 'Parents',
      'email': 'parent@skoolwala.com',
      'password': '12345678',
    },
  ];

  void _showTestUsersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Demo Accounts', style: AppTheme.headingMedium),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.borderGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppTheme.textDark,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderGray),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _testUsers.length,
                itemBuilder: (context, index) {
                  final user = _testUsers[index];
                  return _buildTestUserCard(user);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Quick Tip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap any account to instantly fill the credentials. Use Auto Login for one-tap access.',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestUserCard(Map<String, String> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray, width: 1.5),
        boxShadow: AppTheme.smallShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _fillCredentials(user['email']!, user['password']!);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user['role']!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _fillCredentials(user['email']!, user['password']!);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _handleLogin();
                        });
                      },
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                      label: const Text('Auto Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentGreen,
                        backgroundColor: AppTheme.accentGreen.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCredentialRow(
                  'ID / Email',
                  user['email']!,
                  Icons.person_pin_rounded,
                ),
                const SizedBox(height: 10),
                _buildCredentialRow(
                  'Password',
                  user['password']!,
                  Icons.key_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppTheme.textGray),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(fontSize: 10, height: 1),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 16),
          color: AppTheme.textGray.withOpacity(0.5),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied'),
                behavior: SnackBarBehavior.floating,
                width: 150,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: AppTheme.textDark,
              ),
            );
          },
        ),
      ],
    );
  }

  void _fillCredentials(String email, String password) {
    setState(() {
      _userController.text = email;
      _passwordController.text = password;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: child,
            ),
          );
        },
        child: FloatingActionButton.extended(
          onPressed: _showTestUsersBottomSheet,
          backgroundColor: Colors.white,
          elevation: 8,
          highlightElevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(Icons.bolt_rounded, color: AppTheme.primaryPurple),
          label: Text(
            'Quick Login',
            style: TextStyle(
              color: AppTheme.primaryPurple,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient and Shapes
          const _AnimatedBackground(),

          SafeArea(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  ),
                );
              },
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Brand Logo/Name Section
                      const SizedBox(height: 20),
                      _buildLogo(),
                      const SizedBox(height: 24),
                      Text(
                        widget.schoolName,
                        style: AppTheme.headingMedium.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Attendance Management System',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Login Card (Glassmorphism)
                      _buildLoginCard(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.mainLogo != null && widget.mainLogo!.isNotEmpty
                ? Image.network(
                    widget.mainLogo!,
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.school_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.school_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              const _DividerWithText(text: 'to Your Account'),
              const SizedBox(height: 32),

              // Role Selector - Hidden (auto-detect from backend)
              // if (_roles.isNotEmpty) ...[
              //   _buildLabel('Account Type'),
              //   _buildRoleDropdown(),
              //   const SizedBox(height: 24),
              // ],

              // Username Field
              _buildLabel('Username / Email'),
              _buildTextField(
                controller: _userController,
                hint: 'Enter username',
                icon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 20),

              // Password Field
              _buildLabel('Password'),
              _buildTextField(
                controller: _passwordController,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ForgetPasswordScreen(
                          email: _userController.text.trim(),
                          role: _selectedRole?.slug ?? 'teacher',
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.white70,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Error Message
              if (_errorMessage != null) ...[
                _buildErrorMessage(),
                const SizedBox(height: 20),
              ],

              // Login Button
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: DropdownButton<Role>(
        value: _selectedRole,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF2A2D33).withOpacity(0.95),
        icon: const Icon(Icons.expand_more_rounded, color: Colors.white70),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        items: _roles.map((role) {
          return DropdownMenuItem<Role>(
            value: role,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getRoleIcon(role.slug),
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(role.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (Role? newRole) {
          if (newRole != null) {
            setState(() {
              _selectedRole = newRole;
            });
          }
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscure,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          fillColor: Colors.white.withOpacity(0.12),
          filled: true,
          prefixIcon: Icon(icon, size: 20, color: Colors.white70),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2A2D33),
          disabledBackgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primaryPurple,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SIGN IN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  IconData _getRoleIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'teacher':
        return Icons.school_rounded;
      case 'student':
        return Icons.face_6_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'parent':
        return Icons.family_restroom_rounded;
      case 'principal':
        return Icons.person_4_rounded;
      case 'librarian':
        return Icons.library_books_rounded;
      case 'receptionist':
        return Icons.call_rounded;
      case 'accounts':
        return Icons.account_balance_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Container(
          height: size.height,
          width: size.width,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2D33), Color(0xFF1A1C1E)],
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryPurple.withOpacity(0.3),
                  AppTheme.primaryPurple.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.2,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryPurple.withOpacity(0.15),
                  AppTheme.primaryPurple.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DividerWithText extends StatelessWidget {
  final String text;
  const _DividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

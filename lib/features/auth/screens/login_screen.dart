// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skoolwala/features/auth/services/profile_service.dart';
import 'package:skoolwala/features/auth/services/role_service.dart';
import 'package:skoolwala/features/auth/screens/forget_password_screen.dart';
import 'package:skoolwala/features/dashboard/screens/dashboard_screen.dart';
import 'package:skoolwala/shared/models/role.dart';
import 'package:skoolwala/shared/services/persistent_storage.dart';
import 'package:skoolwala/shared/widgets/error_handler.dart';

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

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final RoleService _roleService = const RoleService();
  bool _obscure = true;
  Role? _selectedRole;
  List<Role> _roles = [];
  bool _isLoadingRoles = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

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
      _isLoadingRoles = true;
    });

    try {
      // First try to use branch_id passed directly from school selection
      // If not provided, fall back to persistent storage
      String? branchId = widget.branchId;
      
      if (branchId == null) {
        final selectedSchool = await PersistentStorage.getSelectedSchool();
        branchId = selectedSchool?['id'];
        print('🔍 LoginScreen: Using branch_id from persistent storage: $branchId');
        print('   Selected school: ${selectedSchool?['name']}');
      } else {
        print('🔍 LoginScreen: Using branch_id passed from school selection: $branchId');
        print('   School Name: ${widget.schoolName}');
      }
      
      if (branchId == null || branchId.isEmpty) {
        print('⚠️ LoginScreen: No branch_id found! Cannot load roles.');
        if (mounted) {
          setState(() {
            _isLoadingRoles = false;
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
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      print('❌ LoginScreen: Error loading roles: $e');
      if (mounted) {
        setState(() {
          _isLoadingRoles = false;
        });
      }
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

    if (_selectedRole == null) {
      ErrorHandler.showError(context, 'Please select a role');
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
    {
      'role': 'Admin',
      'email': 'support@skoolwala.com',
      'password': '12345678',
    },
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
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Test Users',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A48),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Users list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _testUsers.length,
                itemBuilder: (context, index) {
                  final user = _testUsers[index];
                  return _buildTestUserCard(user);
                },
              ),
            ),
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Color(0xFF6B7280)),
                      SizedBox(width: 8),
                      Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A48),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If Auto Login does not work, tap on the user card to fill credentials manually.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
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

  Widget _buildTestUserCard(Map<String, String> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // Dark card background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF374151),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _fillCredentials(user['email']!, user['password']!);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      user['role']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF), // Faded purple/grey
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _fillCredentials(user['email']!, user['password']!);
                      // Auto login after a short delay
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _handleLogin();
                      });
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Auto Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
                'Email',
                user['email']!,
                Icons.email_outlined,
              ),
              const SizedBox(height: 8),
              _buildCredentialRow(
                'Password',
                user['password']!,
                Icons.lock_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF), // Faded purple/grey
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          color: const Color(0xFF9CA3AF),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied to clipboard'),
                duration: const Duration(seconds: 1),
                backgroundColor: const Color(0xFF10B981),
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
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton.extended(
          onPressed: _showTestUsersBottomSheet,
          backgroundColor: const Color(0xFF6D63B8),
          icon: const Icon(Icons.people, color: Colors.white),
          label: const Text(
            'Test Users',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: Container(
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6D63B8), Color(0xFF2A2376)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Display main logo (System Logo) if available - Responsive container
                if (widget.mainLogo != null && widget.mainLogo!.isNotEmpty)
                  Builder(
                    builder: (context) {
                      print(
                        '🖼️ Login Screen - Attempting to load SYSTEM LOGO (mainLogo): ${widget.mainLogo}',
                      );
                      print(
                        '   📌 This is the SYSTEM LOGO from API (main_logo field)',
                      );
                      return Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                          minHeight: 80,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        alignment: Alignment.center,
                        child: Image.network(
                          widget.mainLogo!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print(
                                '✅ Login Screen - Main Logo loaded successfully',
                              );
                              return child;
                            }
                            print(
                              '⏳ Login Screen - Loading Main Logo... ${(loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) * 100).toStringAsFixed(0)}%',
                            );
                            return const SizedBox.shrink();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print(
                              '❌ Login Screen - Main Logo failed to load: $error',
                            );
                            print('   URL was: ${widget.mainLogo}');
                            // If image fails to load, show nothing - just return empty container
                            return const SizedBox.shrink();
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                // School name display
                Text(
                  widget.schoolName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Attendance Management System',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                // Login Card
                Container(
                  width: size.width,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Welcome back! ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A48),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text('👋', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login to access your attendance dashboard',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Role selection
                      const Text(
                        'Select Role',
                        style: TextStyle(
                          color: Color(0xFF1A1A48),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingRoles)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else if (_roles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFFC107).withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'No roles available. Please contact administrator.',
                            style: TextStyle(
                              color: Color(0xFF856404),
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<Role>(
                          value: _selectedRole,
                          items: _roles
                              .map(
                                (role) => DropdownMenuItem<Role>(
                                  value: role,
                                  child: Text(
                                    role.name,
                                    style: const TextStyle(
                                      color: Color(0xFF1A1A48),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (role) {
                            if (role == null) return;
                            setState(() => _selectedRole = role);
                            _loadPrefill();
                          },
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            color: Color(0xFF1A1A48),
                            fontWeight: FontWeight.w600,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF1F2A60),
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1F2A60),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'Username',
                        style: TextStyle(
                          color: Color(0xFF1A1A48),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _userController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white70,
                          ),
                          filled: true,
                          fillColor: Colors.black,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Password',
                        style: TextStyle(
                          color: Color(0xFF1A1A48),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: '•••••••••',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white70,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          filled: true,
                          fillColor: Colors.black,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
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
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF6D63B8),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF991B1B).withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: Color(0xFF991B1B),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  _handleLogin();
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      ),
                    ],
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

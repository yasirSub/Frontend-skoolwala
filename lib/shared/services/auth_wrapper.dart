import 'package:flutter/material.dart';
import 'session_manager.dart';
import 'persistent_storage.dart';
import '../../features/school/screens/school_selection_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/splash/screens/splash_screen.dart';

/// Authentication wrapper that handles app startup routing based on login status
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isFirstLaunch = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    try {
      // Initialize persistent storage
      await PersistentStorage.init();

      // Check if this is the first launch
      final isFirstLaunch = await PersistentStorage.isFirstLaunch();

      if (isFirstLaunch) {
        // First time user - show splash screen
        setState(() {
          _isFirstLaunch = true;
          _isLoading = false;
        });
        print('🔐 Auth Wrapper: First launch detected, showing splash');

        // Wait for splash screen to complete (3.5 seconds for animation + delay)
        await Future.delayed(const Duration(milliseconds: 3500));

        // Re-check first launch status after splash completes
        final stillFirstLaunch = await PersistentStorage.isFirstLaunch();
        if (!stillFirstLaunch && mounted) {
          // Splash completed, now check auth status again
          await _checkAuthAfterSplash();
        } else if (mounted) {
          // Fallback: if still first launch but mounted, proceed anyway after timeout
          await _checkAuthAfterSplash();
        }
        return;
      }

      // Check if there's a stored session
      final hasStoredSession = await SessionManager.hasStoredSession();

      if (hasStoredSession) {
        // Try to restore the session
        final sessionRestored = await SessionManager.instance.restoreSession();

        if (sessionRestored && SessionManager.instance.hasValidSession) {
          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });

          print('🔐 Auth Wrapper: User session restored successfully');
        } else {
          // Session restoration failed, clear storage and show login
          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });

          print('🔐 Auth Wrapper: Session restoration failed, showing login');
        }
      } else {
        // No stored session, show login
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });

        print('🔐 Auth Wrapper: No stored session, showing login');
      }
    } catch (e) {
      print('🔐 Auth Wrapper: Error checking auth status: $e');

      // On error, clear everything and show login
      await SessionManager.instance.logout();
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  /// Check auth status after splash screen completes
  Future<void> _checkAuthAfterSplash() async {
    try {
      // Check if there's a stored session
      final hasStoredSession = await SessionManager.hasStoredSession();

      if (hasStoredSession) {
        // Try to restore the session
        final sessionRestored = await SessionManager.instance.restoreSession();

        if (sessionRestored && SessionManager.instance.hasValidSession) {
          if (mounted) {
            setState(() {
              _isLoggedIn = true;
              _isFirstLaunch = false;
              _isLoading = false;
            });
          }
          print('🔐 Auth Wrapper: User session restored after splash');
        } else {
          // Session restoration failed, clear storage and show login
          if (mounted) {
            setState(() {
              _isLoggedIn = false;
              _isFirstLaunch = false;
              _isLoading = false;
            });
          }
          print('🔐 Auth Wrapper: Session restoration failed after splash');
        }
      } else {
        // No stored session, show login
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _isFirstLaunch = false;
            _isLoading = false;
          });
        }
        print('🔐 Auth Wrapper: No stored session after splash');
      }
    } catch (e) {
      print('🔐 Auth Wrapper: Error checking auth after splash: $e');
      // On error, clear everything and show login
      await SessionManager.instance.logout();
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isFirstLaunch = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen while loading or if first launch
    if (_isLoading || _isFirstLaunch) {
      return const SplashScreen();
    }

    if (_isLoggedIn && SessionManager.instance.hasValidSession) {
      // User is logged in, redirect to dashboard
      return DashboardScreen(
        username: SessionManager.instance.currentUsername!,
        password: SessionManager.instance.currentPassword!,
      );
    } else {
      // User is not logged in
      // Check if there's a saved school, if yes go directly to login
      return FutureBuilder<Map<String, String>?>(
        future: PersistentStorage.getSelectedSchool(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final savedSchool = snapshot.data;
          if (savedSchool != null) {
            // Log saved school logo information
            print('🔍 Auth Wrapper - Using saved school:');
            print('   School Name: ${savedSchool['name']}');
            print('   Text Logo URL: ${savedSchool['text_logo'] ?? 'null'}');
            print('   Main Logo URL: ${savedSchool['main_logo'] ?? 'null'}');

            // School already selected, go directly to login
            return LoginScreen(
              schoolName: savedSchool['name']!,
              mainLogo: savedSchool['main_logo'],
              branchId: savedSchool['id'], // Pass branch_id from saved school
            );
          } else {
            // No school selected, show school selection
            return const SchoolSelectionScreen();
          }
        },
      );
    }
  }
}

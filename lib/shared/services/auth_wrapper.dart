import 'package:flutter/material.dart';
import 'session_manager.dart';
import 'persistent_storage.dart';
import '../../features/school/screens/school_selection_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking login status...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_isFirstLaunch) {
      // First time user - show splash screen
      return const SplashScreen();
    } else if (_isLoggedIn && SessionManager.instance.hasValidSession) {
      // User is logged in, redirect to dashboard
      return DashboardScreen(
        username: SessionManager.instance.currentUsername!,
        password: SessionManager.instance.currentPassword!,
      );
    } else {
      // User is not logged in, show school selection
      return const SchoolSelectionScreen();
    }
  }
}

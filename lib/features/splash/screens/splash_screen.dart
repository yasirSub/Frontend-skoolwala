import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/services/persistent_storage.dart';
import '../../../shared/widgets/app_loading_indicator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  Future<void> _startSplash() async {
    // Wait for splash duration
    await Future.delayed(const Duration(milliseconds: 2000));

    // Mark first launch as completed
    await PersistentStorage.setFirstLaunchCompleted();

    // Note: Navigation is handled by AuthWrapper
    // Don't navigate from here to avoid conflicts
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C), // Dark gray background
      body: const Center(child: AppLoadingIndicator()),
    );
  }
}

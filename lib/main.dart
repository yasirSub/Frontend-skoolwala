import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'shared/services/auth_wrapper.dart';
import 'shared/services/api_service.dart';
import 'shared/config/api_config.dart'; // Using centralized config for production
import 'shared/theme/theme_provider.dart';
import 'shared/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'features/notifications/services/local_notifications_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //===================================================================================//
  ///////////////////////////////-API CONFIGURATION-////////////////////////////////////
  //==================================================================================//

  // You can use the centralized config file:
  // 1. Uncomment the import above: import 'shared/config/api_config.dart';
  // 2. Then use: ApiService.setOverrideBaseUrl(ApiConfig.developmentBaseUrl);
  // 3. Or use: ApiService.setOverrideBaseUrl(ApiConfig.productionBaseUrl);
  // 4. Or switch environments: ApiService.setOverrideBaseUrl(ApiConfig.getBaseUrl());
  //
  // Available options in api_config.dart:
  // - ApiConfig.productionBaseUrl
  // - ApiConfig.developmentBaseUrl
  // - ApiConfig.localhostBaseUrl
  // - ApiConfig.androidEmulatorUrl
  // - ApiConfig.iosSimulatorUrl
  // ============================================================

  // Auto-pick local API base for development
  // try {
  //   if (Platform.isAndroid) {
  //     // Android emulator maps host to 10.0.2.2
  //     ApiService.setOverrideBaseUrl('http://10.0.2.2:8000/api');
  //   } else if (Platform.isIOS) {
  //     // iOS simulator can use loopback
  //     ApiService.setOverrideBaseUrl('http://127.0.0.1:8000/api');
  //   } else {
  //     // Desktop/web default
  //     ApiService.setOverrideBaseUrl('http://localhost:8000/api');
  //   }
  // } catch (_) {
  //   // Fallback if Platform not available
  //   ApiService.setOverrideBaseUrl('http://localhost:8000/api');
  // }

  // Use production API URL from config

  ApiService.setOverrideBaseUrl(ApiConfig.getBaseUrl());

  // Debug which base URL is active
  // ignore: avoid_print
  print('🔧 Using API base: ${ApiService.currentApiUrl}');

  // Initialize OS-level local notifications (sound + history triggers)
  LocalNotificationsService.instance.init();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppThemeDark.darkTheme,
            themeMode: themeProvider.themeMode,
            onGenerateRoute: AppRoutes.generateRoute,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

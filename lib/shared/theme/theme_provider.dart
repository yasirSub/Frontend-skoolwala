import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'package:skoolwala/shared/services/theme_service.dart';
import 'package:skoolwala/shared/models/app_theme_settings.dart';

/// Theme provider for managing dark/light theme switching
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemeFromPrefs();
    _loadDynamicTheme();
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    } catch (e) {
      // Default to light theme if loading fails
      _themeMode = ThemeMode.light;
    }
  }

  /// Load dynamic theme settings from storage (new app theme first, then legacy)
  Future<void> _loadDynamicTheme() async {
    try {
      // First try to load app-specific theme settings (new API)
      final appThemeSettings = await ThemeService.getSavedAppThemeSettings();
      if (appThemeSettings != null) {
        AppTheme.applyAppTheme(appThemeSettings);
        notifyListeners();
        return;
      }

      // Fallback to legacy theme settings
      final settings = await ThemeService.getSavedThemeSettings();
      if (settings != null) {
        AppTheme.applyTheme(settings);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading dynamic theme: $e');
    }
  }

  /// Refresh app theme from API (new app-specific theme API)
  Future<void> refreshAppTheme(String branchId) async {
    try {
      final settings = await ThemeService().fetchAppThemeSettings(branchId);
      if (settings != null) {
        AppTheme.applyAppTheme(settings);
        notifyListeners();
        print('🎨 ThemeProvider: App theme refreshed from API');
      } else {
        // Fallback to default settings if API fails
        print('⚠️ ThemeProvider: Using default app theme (API returned null)');
        AppTheme.applyAppTheme(AppThemeSettings.defaultSettings());
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing app theme: $e');
      // Apply default settings on error
      AppTheme.applyAppTheme(AppThemeSettings.defaultSettings());
      notifyListeners();
    }
  }

  /// Refresh theme from API (legacy - for backward compatibility)
  Future<void> refreshDynamicTheme(String branchId) async {
    // Use new app theme API
    await refreshAppTheme(branchId);
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await _saveThemeToPrefs();
    notifyListeners();
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeToPrefs();
    notifyListeners();
  }

  /// Get the current theme data based on theme mode
  ThemeData getCurrentTheme(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.dark:
        return AppThemeDark.darkTheme;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark
            ? AppThemeDark.darkTheme
            : AppTheme.lightTheme;
    }
  }
}

/// Dark theme for the app
class AppThemeDark {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.white,
        primary: Colors.white,
        secondary: AppTheme.accentGreen,
        error: AppTheme.errorRed,
        surface: const Color(0xFF1C1C1E),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        bodySmall: TextStyle(color: Colors.white60, fontSize: 12),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        titleSmall: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        labelLarge: TextStyle(color: Colors.white, fontSize: 14),
        labelMedium: TextStyle(color: Colors.white70, fontSize: 12),
        labelSmall: TextStyle(color: Colors.white60, fontSize: 11),
      ),
      // Set default text color for all Text widgets
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.white),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      primaryIconTheme: const IconThemeData(color: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2C2C2E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLarge),
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space2XL,
            vertical: AppTheme.spaceL,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMedium),
          elevation: 0,
          shadowColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        border: OutlineInputBorder(
          borderRadius: AppTheme.radiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.radiusMedium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTheme.radiusMedium,
          borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
        ),
      ),
    );
  }
}

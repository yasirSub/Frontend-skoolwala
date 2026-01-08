import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:skoolwala/shared/models/theme_settings.dart';
import 'package:skoolwala/shared/models/app_theme_settings.dart';

/// App-wide theme configuration for SkoolWala
class AppTheme {
  // Primary Colors (Neutral Gray by default, can be overridden by backend)
  static Color primaryPurple = const Color(
    0xFF757575,
  ); // Primary color from backend
  static Color darkPurple = const Color(
    0xFF424242,
  ); // Darker variant of primary
  static Color lightPurple = const Color(0xFFF5F5F7); // Light variant

  // Backend-controlled colors (from App Theme Settings)
  static Color secondaryColor = const Color(0xFF512DA8);
  static Color accentColor = const Color(0xFF7C4DFF);
  static Color backgroundColor = const Color(0xFFF5F5F5);
  static Color cardColor = Colors.white;
  static Color menuBackground = const Color(
    0xFFFFFFFF,
  ); // Menu BG Color from backend
  static Color buttonHover = const Color(
    0xFF757575,
  ); // Button Hover Color from backend
  static Color textPrimary = const Color(0xFF232323); // Text Color from backend
  static Color textSecondary = const Color(
    0xFF8D8D8D,
  ); // Text Secondary Color from backend
  static Color footerBackground = const Color(
    0xFF383838,
  ); // Footer BG Color from backend
  static Color footerText = const Color(
    0xFF8D8D8D,
  ); // Footer Text Color from backend

  // Status Colors (from App Theme Settings)
  static Color successColor = const Color(0xFF4CAF50);
  static Color errorColor = const Color(0xFFF44336);
  static Color warningColor = const Color(0xFFFFC107);

  // Navigation Bar Colors (from App Theme Settings)
  static Color navbarColor = const Color(0xFF673AB7);
  static Color navbarActiveColor = const Color(0xFF7C4DFF);
  static Color navbarInactiveColor = const Color(0xFFBDBDBD);

  // Button Colors (from App Theme Settings)
  static Color buttonColor = const Color(0xFF673AB7);
  static Color buttonTextColor = Colors.white;

  // Gradient Colors (from App Theme Settings)
  static Color gradientStartColor = const Color(0xFF512DA8);
  static Color gradientEndColor = const Color(0xFF673AB7);

  // Background Image (from App Theme Settings)
  static String? backgroundImageUrl;
  static double backgroundBlur = 0;

  // Dark Mode flag
  static bool isDarkMode = false;

  // Accent Colors
  static const Color accentCyan = Color(0xFF8E8E93); // Gray-Blue
  static const Color accentGreen = Color(0xFF34C759); // Standard Green
  static const Color accentRed = Color(0xFFFF3B30); // Standard Red
  static const Color accentOrange = Color(0xFFFF9500); // Standard Orange

  // Semantic Colors (const for backward compatibility)
  static const Color successGreen = Color(0xFF34C759);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color infoBlue = Color(0xFF007AFF);

  // Dynamic semantic colors (from app theme settings)
  static Color get dynamicSuccessGreen => successColor;
  static Color get dynamicErrorRed => errorColor;
  static Color get dynamicWarningOrange => warningColor;

  // Neutral Colors (Light & Gray)
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // Dynamic background colors (from app theme settings)
  static Color get dynamicBackgroundLight => backgroundColor;
  static Color get dynamicCardWhite => cardColor;
  static const Color textDark = Color(0xFF1C1C1E); // Dark Text Gray
  static Color textGray = const Color(
    0xFF8E8E93,
  ); // Secondary Text Gray (alias for textSecondary)
  static const Color borderGray = Color(0xFFD1D1D6); // Border Gray

  /// Apply app-specific theme settings from backend (NEW API)
  /// This is separate from website theme and controls all app colors
  static void applyAppTheme(AppThemeSettings? settings) {
    if (settings == null) return;

    // Primary colors
    primaryPurple = settings.primaryColor;
    secondaryColor = settings.secondaryColor;
    accentColor = settings.accentColor;
    darkPurple = settings.secondaryColor; // Use secondary as dark variant
    lightPurple = _lightenColor(settings.primaryColor, 0.7);

    // Background colors
    backgroundColor = settings.backgroundColor;
    cardColor = settings.cardColor;

    // Text colors
    textPrimary = settings.textPrimaryColor;
    textSecondary = settings.textSecondaryColor;
    textGray = settings.textSecondaryColor;

    // Status colors
    successColor = settings.successColor;
    errorColor = settings.errorColor;
    warningColor = settings.warningColor;

    // Navigation bar colors
    navbarColor = settings.navbarColor;
    navbarActiveColor = settings.navbarActiveColor;
    navbarInactiveColor = settings.navbarInactiveColor;

    // Button colors
    buttonColor = settings.buttonColor;
    buttonTextColor = settings.buttonTextColor;
    buttonHover = _lightenColor(settings.buttonColor, 0.1);

    // Gradient colors
    gradientStartColor = settings.gradientStartColor;
    gradientEndColor = settings.gradientEndColor;

    // Background image
    backgroundImageUrl = settings.backgroundImage;
    backgroundBlur = settings.backgroundBlur;

    // Dark mode
    isDarkMode = settings.isDarkMode;

    print(
      '🎨 AppTheme: Applied app theme settings (Primary: #${settings.primaryColor.value.toRadixString(16).substring(2)}, Navbar: #${settings.navbarColor.value.toRadixString(16).substring(2)}, BgImage: ${settings.backgroundImage ?? "none"}, Blur: ${settings.backgroundBlur})',
    );
  }

  /// Apply theme settings from website backend (legacy, kept for backward compatibility)
  static void applyTheme(ThemeSettings? settings) {
    if (settings == null) return;

    // Primary color (used for buttons, app bar, accents)
    primaryPurple = settings.primaryColor;
    buttonHover = settings.hoverColor;

    // Calculate dark variant (darken primary by 20%)
    darkPurple = _darkenColor(settings.primaryColor, 0.2);

    // Calculate light variant (lighten primary by 80%)
    lightPurple = _lightenColor(settings.primaryColor, 0.8);

    // Menu/Navigation colors
    menuBackground = settings.menuColor;

    // Text colors
    textPrimary = settings.textColor;
    textSecondary = settings.textSecondaryColor;
    textGray = settings.textSecondaryColor; // Alias

    // Footer colors
    footerBackground = settings.footerBackgroundColor;
    footerText = settings.footerTextColor;

    print(
      '🎨 AppTheme: Applied legacy theme (Primary: #${settings.primaryColor.value.toRadixString(16).substring(2)})',
    );
  }

  /// Darken a color by a percentage (0.0 to 1.0)
  static Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  /// Lighten a color by a percentage (0.0 to 1.0)
  static Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  // Modern Dashboard Color Palette (Light & Gray)
  static Color get dashboardPrimary => primaryPurple; // Primary from backend
  static Color get dashboardPrimaryLight => textSecondary; // Medium Gray
  static Color get dashboardAccent => textSecondary; // Medium Gray
  static const Color dashboardAccentLight = Color(0xFFF2F2F7); // Light Gray
  static const Color dashboardSuccess = Color(0xFF52C41A); // Green
  static const Color dashboardWarning = Color(0xFFFAAD14); // Orange
  static const Color dashboardError = Color(0xFFF5222D); // Red
  static const Color dashboardBackground = Color(0xFFF5F5F5); // Light Gray
  static const Color dashboardSurface = Colors.white; // White
  static const Color dashboardBackgroundDark = Color(0xFF2A2D33);
  static const Color dashboardBackgroundAccent = Color(0xFF3A3F4C);
  static Color get dashboardPrimaryDark => primaryPurple.withOpacity(0.8);
  static const Color dashboardTextPrimary = Color(0xFF262626); // Dark Gray
  static const Color dashboardTextSecondary = Color(0xFF8C8C8C); // Medium Gray
  static const Color dashboardBorder = Color(0xFFD9D9D9); // Light Gray Border

  // Gradient Definitions - Uses colors from App Theme Settings
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gradientStartColor, // From app theme settings
      gradientEndColor, // From app theme settings
    ],
  );

  /// Check if a background image is configured
  static bool get hasBackgroundImage =>
      backgroundImageUrl != null && backgroundImageUrl!.isNotEmpty;

  /// Get background decoration for screens
  /// Uses background image if set, otherwise uses gradient
  static BoxDecoration getBackgroundDecoration({
    String? webBaseUrl,
    BoxFit fit = BoxFit.cover,
  }) {
    if (hasBackgroundImage && webBaseUrl != null) {
      final imageUrl = backgroundImageUrl!.startsWith('http')
          ? backgroundImageUrl!
          : '$webBaseUrl/$backgroundImageUrl';
      return BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: fit,
          colorFilter: isDarkMode
              ? ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                )
              : null,
        ),
      );
    }

    // Fallback to gradient
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStartColor, gradientEndColor],
      ),
    );
  }

  /// Build a background widget with optional blur support
  /// Use this instead of Container with getBackgroundDecoration when blur is needed
  static Widget buildBackground({
    required String? webBaseUrl,
    Widget? child,
    BoxFit fit = BoxFit.cover,
  }) {
    if (hasBackgroundImage && webBaseUrl != null && backgroundBlur > 0) {
      final imageUrl = backgroundImageUrl!.startsWith('http')
          ? backgroundImageUrl!
          : '$webBaseUrl/$backgroundImageUrl';

      return Stack(
        fit: StackFit.expand,
        children: [
          // Background image with blur
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(imageUrl), fit: fit),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: backgroundBlur,
                sigmaY: backgroundBlur,
              ),
              child: Container(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          // Content
          if (child != null) child,
        ],
      );
    }

    // No blur needed, use simple decoration
    return Container(
      decoration: getBackgroundDecoration(webBaseUrl: webBaseUrl, fit: fit),
      child: child,
    );
  }

  /// Create a gradient using the primary color
  static LinearGradient get primaryColorGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gradientStartColor,
      gradientEndColor,
      _lightenColor(gradientEndColor, 0.1),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  static LinearGradient get dashboardBackgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      dashboardBackgroundDark,
      dashboardBackgroundAccent,
      dashboardPrimaryDark,
      dashboardBackground,
    ],
    stops: const [0.0, 0.3, 0.6, 1.0],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF52C41A), Color(0xFF389E0D)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD93D), Color(0xFFFFC53D)],
  );

  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5DADE2), Color(0xFF40B0E8)],
  );

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.2,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textDark,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textGray,
    height: 1.5,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textGray,
    height: 1.5,
  );

  // Box Shadows (Softer, more modern)
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: textGray.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryPurple.withOpacity(0.25),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get smallShadow => [
    BoxShadow(
      color: textGray.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // Border Radius
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMedium = BorderRadius.all(
    Radius.circular(16),
  ); // Increased rounding
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(24));

  // Spacing
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 12;
  static const double spaceL = 16;
  static const double spaceXL = 24;
  static const double space2XL = 32;

  // Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardWhite,
    borderRadius: radiusMedium,
    boxShadow: cardShadow,
    border: Border.all(color: Colors.white, width: 1), // Subtle border
  );

  static BoxDecoration get gradientCardDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: radiusMedium,
    boxShadow: buttonShadow,
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: bodyMedium.copyWith(color: textGray.withOpacity(0.7)),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9F9FB),
      border: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: borderGray, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: borderGray, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: BorderSide(color: primaryPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spaceL,
        vertical: spaceL,
      ),
    );
  }

  // Button Style
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryPurple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: space2XL, vertical: spaceL),
    shape: RoundedRectangleBorder(borderRadius: radiusMedium),
    elevation: 0,
    shadowColor:
        Colors.transparent, // Handled by box shadow often, or keep null
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      fontFamily: 'SF Pro Display',
    ),
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: lightPurple,
    foregroundColor: primaryPurple,
    padding: const EdgeInsets.symmetric(horizontal: space2XL, vertical: spaceL),
    shape: RoundedRectangleBorder(borderRadius: radiusMedium),
    elevation: 0,
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      fontFamily: 'SF Pro Display',
    ),
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        primary: primaryPurple,
        secondary: accentCyan,
        tertiary: accentGreen,
        error: errorRed,
        surface: cardWhite,
      ),
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'SF Pro Display',
      textTheme: TextTheme(
        bodyLarge: const TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textGray),
        bodySmall: TextStyle(color: textGray),
        titleLarge: const TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: const TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textDark,
          fontFamily: 'SF Pro Display',
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: radiusMedium),
        shadowColor: const Color(0xFF131336).withOpacity(0.05),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F7FA),
        border: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: Color(0xFFD1D1E9), width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: Color(0xFFD1D1E9), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: primaryPurple, width: 2),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// App-wide theme configuration for SkoolWala
class AppTheme {
  // Primary Colors (More Vibrant)
  static const Color primaryPurple = Color(0xFF6246EA); // Richer Violet
  static const Color darkPurple = Color(0xFF2B1C55); // Deep Indigo
  static const Color lightPurple = Color(0xFFE0D9FA); // Soft Lavender

  // Accent Colors
  static const Color accentCyan = Color(0xFF00B4D8);
  static const Color accentGreen = Color(0xFF00C49A); // Vibrant Mint
  static const Color accentRed = Color(0xFFFF4858); // Coral Red
  static const Color accentOrange = Color(0xFFFFB020);

  // Semantic Colors
  static const Color successGreen = Color(0xFF27AE60);
  static const Color errorRed = Color(0xFFEB5757);
  static const Color warningOrange = Color(0xFFF2994A);
  static const Color infoBlue = Color(0xFF2F80ED);

  // Neutral Colors (Cleaner)
  static const Color backgroundLight = Color(
    0xFFF7F7FA,
  ); // Very cool grey-white
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF131336); // Almost black navy
  static const Color textGray = Color(0xFF6E7191);
  static const Color borderGray = Color(0xFFEBEBF5);

  // Modern Dashboard Color Palette (Vibrant Update)
  static const Color dashboardPrimary = Color(
    0xFF6246EA,
  ); // Matches primaryPurple
  static const Color dashboardPrimaryLight = Color(
    0xFF7B61FF,
  ); // Lighter violet
  static const Color dashboardAccent = Color(0xFF00B4D8); // Matches accentCyan
  static const Color dashboardAccentLight = Color(
    0xFFE0D9FA,
  ); // Matches lightPurple
  static const Color dashboardSuccess = Color(
    0xFF27AE60,
  ); // Matches successGreen
  static const Color dashboardWarning = Color(
    0xFFF2994A,
  ); // Matches warningOrange
  static const Color dashboardError = Color(0xFFEB5757); // Matches errorRed
  static const Color dashboardBackground = Color(
    0xFFF7F7FA,
  ); // Matches backgroundLight
  static const Color dashboardSurface = Colors.white;
  static const Color dashboardTextPrimary = Color(0xFF131336);
  static const Color dashboardTextSecondary = Color(0xFF6E7191);
  static const Color dashboardBorder = Color(0xFFEBEBF5);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B61FF), Color(0xFF6246EA)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C49A), Color(0xFF00A884)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4858), Color(0xFFFF2A3A)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB020), Color(0xFFFF8F00)],
  );

  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
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

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textGray,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textGray,
    height: 1.5,
  );

  // Box Shadows (Softer, more modern)
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0xFF131336).withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryPurple.withOpacity(0.25),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> smallShadow = [
    BoxShadow(
      color: Color(0xFF131336).withOpacity(0.03),
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
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardWhite,
    borderRadius: radiusMedium,
    boxShadow: cardShadow,
    border: Border.all(color: Colors.white, width: 1), // Subtle border
  );

  static BoxDecoration gradientCardDecoration = BoxDecoration(
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
      fillColor: const Color(0xFFF7F7FA),
      border: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: Color(0xFFD1D1E9), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: Color(0xFFD1D1E9), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: errorRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spaceL,
        vertical: spaceL,
      ),
    );
  }

  // Button Style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
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

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
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
        background: backgroundLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textGray),
        bodySmall: TextStyle(color: textGray),
        titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
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
        shape: RoundedRectangleBorder(borderRadius: radiusMedium),
        shadowColor: Color(0xFF131336).withOpacity(0.05),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F7FA),
        border: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: Color(0xFFD1D1E9), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: Color(0xFFD1D1E9), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
      ),
    );
  }
}

// Dark theme stub if needed, or you can implement similar logic

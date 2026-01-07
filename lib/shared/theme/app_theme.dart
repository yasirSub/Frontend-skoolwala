import 'package:flutter/material.dart';

/// App-wide theme configuration for SkoolWala
class AppTheme {
  // Primary Colors (Neutral Gray)
  static const Color primaryPurple = Color(
    0xFF757575,
  ); // Primary Gray (Lighter)
  static const Color darkPurple = Color(0xFF424242); // Dark Gray (Lighter)
  static const Color lightPurple = Color(0xFFF5F5F7); // Light Gray

  // Accent Colors
  static const Color accentCyan = Color(0xFF8E8E93); // Gray-Blue
  static const Color accentGreen = Color(0xFF34C759); // Standard Green
  static const Color accentRed = Color(0xFFFF3B30); // Standard Red
  static const Color accentOrange = Color(0xFFFF9500); // Standard Orange

  // Semantic Colors
  static const Color successGreen = Color(0xFF34C759);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color infoBlue = Color(0xFF007AFF);

  // Neutral Colors (Light & Gray)
  static const Color backgroundLight = Color(0xFFF2F2F7); // Lightest Gray
  static const Color cardWhite = Color(0xFFFFFFFF); // White
  static const Color textDark = Color(0xFF1C1C1E); // Dark Text Gray
  static const Color textGray = Color(0xFF8E8E93); // Secondary Text Gray
  static const Color borderGray = Color(0xFFD1D1D6); // Border Gray

  // Modern Dashboard Color Palette (Light & Gray)
  static const Color dashboardPrimary = primaryPurple; // Neutral Gray
  static const Color dashboardPrimaryLight = textGray; // Medium Gray
  static const Color dashboardAccent = textGray; // Medium Gray
  static const Color dashboardAccentLight = backgroundLight; // Light Gray
  static const Color dashboardSuccess = Color(0xFF52C41A); // Green
  static const Color dashboardWarning = Color(0xFFFAAD14); // Orange
  static const Color dashboardError = Color(0xFFF5222D); // Red
  static const Color dashboardBackground = Color(0xFFF5F5F5); // Light Gray
  static const Color dashboardSurface = Colors.white; // White
  static const Color dashboardBackgroundDark = Color(0xFF2A2D33);
  static const Color dashboardBackgroundAccent = Color(0xFF3A3F4C);
  static const Color dashboardPrimaryDark = Color(0xFF5E5E63);
  static const Color dashboardTextPrimary = Color(0xFF262626); // Dark Gray
  static const Color dashboardTextSecondary = Color(0xFF8C8C8C); // Medium Gray
  static const Color dashboardBorder = Color(0xFFD9D9D9); // Light Gray Border

  // Gradient Definitions (Light & Soft)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [textGray, primaryPurple],
  );

  static const LinearGradient dashboardBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      dashboardBackgroundDark,
      dashboardBackgroundAccent,
      dashboardPrimaryDark,
      dashboardBackground,
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
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
      color: textGray.withOpacity(0.12),
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

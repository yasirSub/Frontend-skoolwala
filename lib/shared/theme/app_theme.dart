import 'package:flutter/material.dart';

/// App-wide theme configuration for SkoolWala
class AppTheme {
  // Primary Colors
  static const Color primaryPurple = Color(0xFF6D63B8);
  static const Color darkPurple = Color(0xFF2A2376);
  static const Color lightPurple = Color(0xFFEDEBFF);

  // Accent Colors
  static const Color accentGreen = Color(0xFF10C69C);
  static const Color accentRed = Color(0xFFFF4E6A);
  static const Color accentOrange = Color(0xFFFFB020);

  // Semantic Colors
  static const Color successGreen = Color(0xFF2BBE63);
  static const Color errorRed = Color(0xFFFF4E6A);
  static const Color warningOrange = Color(0xFFFFB020);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Neutral Colors
  static const Color backgroundLight = Color(0xFFF5F6FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A48);
  static const Color textGray = Color(0xFF6B7280);
  static const Color borderGray = Color(0xFFE5E7EB);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, darkPurple],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10C69C), Color(0xFF0EA378)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4E6A), Color(0xFFFF6C88)],
  );

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: textDark,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: -0.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: textDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textGray,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textGray,
  );

  // Box Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: darkPurple.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryPurple.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> smallShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Border Radius
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMedium = BorderRadius.all(
    Radius.circular(12),
  );
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXLarge = BorderRadius.all(
    Radius.circular(20),
  );

  // Spacing
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 12;
  static const double spaceL = 16;
  static const double spaceXL = 20;
  static const double space2XL = 24;
  static const double space3XL = 32;

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardWhite,
    borderRadius: radiusLarge,
    boxShadow: cardShadow,
  );

  static BoxDecoration gradientCardDecoration = BoxDecoration(
    gradient: primaryGradient,
    borderRadius: radiusLarge,
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
      hintStyle: bodyMedium,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: backgroundLight,
      border: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: BorderSide.none,
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
    shadowColor: primaryPurple.withValues(alpha: 0.3),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: backgroundLight,
    foregroundColor: primaryPurple,
    padding: const EdgeInsets.symmetric(horizontal: space2XL, vertical: spaceL),
    shape: RoundedRectangleBorder(borderRadius: radiusMedium),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        primary: primaryPurple,
        secondary: accentGreen,
        error: errorRed,
        surface: cardWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'SF Pro Display', // You can change this
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textGray),
        bodySmall: TextStyle(color: textGray),
        titleLarge: TextStyle(color: textDark),
        titleMedium: TextStyle(color: textDark),
        titleSmall: TextStyle(color: textGray),
        headlineLarge: TextStyle(color: textDark),
        headlineMedium: TextStyle(color: textDark),
        headlineSmall: TextStyle(color: textDark),
        labelLarge: TextStyle(color: textDark),
        labelMedium: TextStyle(color: textGray),
        labelSmall: TextStyle(color: textGray),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryPurple,
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
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radiusLarge),
        shadowColor: darkPurple.withValues(alpha: 0.08),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundLight,
        border: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
      ),
    );
  }
}

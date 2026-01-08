import 'package:flutter/material.dart';

/// App-specific theme settings fetched from backend
/// Separate from website theme settings (front_cms_setting)
class AppThemeSettings {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Color navbarColor;
  final Color navbarActiveColor;
  final Color navbarInactiveColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final bool isDarkMode;
  final String? backgroundImage; // Optional background image URL
  final double backgroundBlur; // Background blur intensity (0-20)

  AppThemeSettings({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.navbarColor,
    required this.navbarActiveColor,
    required this.navbarInactiveColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.gradientStartColor,
    required this.gradientEndColor,
    required this.isDarkMode,
    this.backgroundImage,
    this.backgroundBlur = 0,
  });

  /// Default theme settings (fallback when API fails)
  factory AppThemeSettings.defaultSettings() {
    return AppThemeSettings(
      primaryColor: const Color(0xFF673AB7),
      secondaryColor: const Color(0xFF512DA8),
      accentColor: const Color(0xFF7C4DFF),
      backgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textPrimaryColor: const Color(0xFF212121),
      textSecondaryColor: const Color(0xFF757575),
      successColor: const Color(0xFF4CAF50),
      errorColor: const Color(0xFFF44336),
      warningColor: const Color(0xFFFFC107),
      navbarColor: const Color(0xFF673AB7),
      navbarActiveColor: const Color(0xFF7C4DFF),
      navbarInactiveColor: const Color(0xFFBDBDBD),
      buttonColor: const Color(0xFF673AB7),
      buttonTextColor: Colors.white,
      gradientStartColor: const Color(0xFF512DA8),
      gradientEndColor: const Color(0xFF673AB7),
      isDarkMode: false,
      backgroundImage: null,
      backgroundBlur: 0,
    );
  }

  factory AppThemeSettings.fromJson(Map<String, dynamic> json) {
    return AppThemeSettings(
      primaryColor: _parseColor(json['primary_color']),
      secondaryColor: _parseColor(json['secondary_color']),
      accentColor: _parseColor(json['accent_color']),
      backgroundColor: _parseColor(json['background_color']),
      cardColor: _parseColor(json['card_color']),
      textPrimaryColor: _parseColor(json['text_primary_color']),
      textSecondaryColor: _parseColor(json['text_secondary_color']),
      successColor: _parseColor(json['success_color']),
      errorColor: _parseColor(json['error_color']),
      warningColor: _parseColor(json['warning_color']),
      navbarColor: _parseColor(json['navbar_color']),
      navbarActiveColor: _parseColor(json['navbar_active_color']),
      navbarInactiveColor: _parseColor(json['navbar_inactive_color']),
      buttonColor: _parseColor(json['button_color']),
      buttonTextColor: _parseColor(json['button_text_color']),
      gradientStartColor: _parseColor(json['gradient_start_color']),
      gradientEndColor: _parseColor(json['gradient_end_color']),
      isDarkMode: json['is_dark_mode'] == 1 || json['is_dark_mode'] == true,
      backgroundImage: json['background_image']?.toString().isNotEmpty == true
          ? json['background_image'].toString()
          : null,
      backgroundBlur:
          double.tryParse(json['background_blur']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_color': _colorToHex(primaryColor),
      'secondary_color': _colorToHex(secondaryColor),
      'accent_color': _colorToHex(accentColor),
      'background_color': _colorToHex(backgroundColor),
      'card_color': _colorToHex(cardColor),
      'text_primary_color': _colorToHex(textPrimaryColor),
      'text_secondary_color': _colorToHex(textSecondaryColor),
      'success_color': _colorToHex(successColor),
      'error_color': _colorToHex(errorColor),
      'warning_color': _colorToHex(warningColor),
      'navbar_color': _colorToHex(navbarColor),
      'navbar_active_color': _colorToHex(navbarActiveColor),
      'navbar_inactive_color': _colorToHex(navbarInactiveColor),
      'button_color': _colorToHex(buttonColor),
      'button_text_color': _colorToHex(buttonTextColor),
      'gradient_start_color': _colorToHex(gradientStartColor),
      'gradient_end_color': _colorToHex(gradientEndColor),
      'is_dark_mode': isDarkMode ? 1 : 0,
      'background_image': backgroundImage ?? '',
      'background_blur': backgroundBlur,
    };
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty)
      return const Color(0xFF673AB7); // Default purple
    try {
      String cleanHex = hex.replaceFirst('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return const Color(0xFF673AB7);
    }
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

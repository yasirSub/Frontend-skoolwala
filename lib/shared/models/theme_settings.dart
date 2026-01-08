import 'package:flutter/material.dart';

class ThemeSettings {
  final Color primaryColor;
  final Color menuColor;
  final Color hoverColor;
  final Color textColor;
  final Color textSecondaryColor;
  final Color footerBackgroundColor;
  final Color footerTextColor;
  final Color copyrightBgColor;
  final Color copyrightTextColor;
  final double borderRadius;

  ThemeSettings({
    required this.primaryColor,
    required this.menuColor,
    required this.hoverColor,
    required this.textColor,
    required this.textSecondaryColor,
    required this.footerBackgroundColor,
    required this.footerTextColor,
    required this.copyrightBgColor,
    required this.copyrightTextColor,
    required this.borderRadius,
  });

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      primaryColor: _parseColor(json['primary_color']),
      menuColor: _parseColor(json['menu_color']),
      hoverColor: _parseColor(json['hover_color']),
      textColor: _parseColor(json['text_color']),
      textSecondaryColor: _parseColor(json['text_secondary_color']),
      footerBackgroundColor: _parseColor(json['footer_background_color']),
      footerTextColor: _parseColor(json['footer_text_color']),
      copyrightBgColor: _parseColor(json['copyright_bg_color']),
      copyrightTextColor: _parseColor(json['copyright_text_color']),
      borderRadius:
          double.tryParse(json['border_radius']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_color': _colorToHex(primaryColor),
      'menu_color': _colorToHex(menuColor),
      'hover_color': _colorToHex(hoverColor),
      'text_color': _colorToHex(textColor),
      'text_secondary_color': _colorToHex(textSecondaryColor),
      'footer_background_color': _colorToHex(footerBackgroundColor),
      'footer_text_color': _colorToHex(footerTextColor),
      'copyright_bg_color': _colorToHex(copyrightBgColor),
      'copyright_text_color': _colorToHex(copyrightTextColor),
      'border_radius': borderRadius,
    };
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blue; // Default
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

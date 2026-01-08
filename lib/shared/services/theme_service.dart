import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skoolwala/shared/models/theme_settings.dart';
import 'package:skoolwala/shared/models/app_theme_settings.dart';
import 'package:skoolwala/shared/services/persistent_storage.dart';
import 'package:skoolwala/shared/config/api_config.dart';

class ThemeService {
  static const String _themeStorageKey = 'app_theme_settings';
  static const String _appThemeStorageKey = 'mobile_app_theme_settings';

  /// Fetch app-specific theme settings from new API
  Future<AppThemeSettings?> fetchAppThemeSettings(String branchId) async {
    try {
      final url = Uri.parse('${ApiConfig.getBaseUrl()}/getAppThemeSettings');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'branch_id': branchId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final settings = AppThemeSettings.fromJson(data['data']);
          await saveAppThemeSettings(settings);
          return settings;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching app theme settings: $e');
      return null;
    }
  }

  Future<void> saveAppThemeSettings(AppThemeSettings settings) async {
    await PersistentStorage.setString(
      _appThemeStorageKey,
      json.encode(settings.toJson()),
    );
  }

  static Future<AppThemeSettings?> getSavedAppThemeSettings() async {
    final data = await PersistentStorage.getString(_appThemeStorageKey);
    if (data != null) {
      try {
        return AppThemeSettings.fromJson(json.decode(data));
      } catch (e) {
        print('Error parsing saved app theme settings: $e');
      }
    }
    return null;
  }

  static Future<void> clearAppThemeSettings() async {
    await PersistentStorage.remove(_appThemeStorageKey);
  }

  /// Legacy: Fetch website theme settings (kept for backward compatibility)
  Future<ThemeSettings?> fetchThemeSettings(String branchId) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.getBaseUrl()}/getThemeSettings?branch_id=$branchId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final settings = ThemeSettings.fromJson(data['data']);
          await saveThemeSettings(settings);
          return settings;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching theme settings: $e');
      return null;
    }
  }

  Future<void> saveThemeSettings(ThemeSettings settings) async {
    await PersistentStorage.setString(
      _themeStorageKey,
      json.encode(settings.toJson()),
    );
  }

  static Future<ThemeSettings?> getSavedThemeSettings() async {
    final data = await PersistentStorage.getString(_themeStorageKey);
    if (data != null) {
      try {
        return ThemeSettings.fromJson(json.decode(data));
      } catch (e) {
        print('Error parsing saved theme settings: $e');
      }
    }
    return null;
  }

  static Future<void> clearThemeSettings() async {
    await PersistentStorage.remove(_themeStorageKey);
  }
}

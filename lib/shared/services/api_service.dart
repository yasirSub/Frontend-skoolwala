// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// Only used on non-web targets
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'session_manager.dart';

class ApiService {
  static const bool _debugLogs = false; // disable verbose logs
  // ONLINE API URL (COMMENTED OUT)
  // static const String localBaseUrl = 'https://school.firmbeginners.com/api';

  // LOCAL DEVELOPMENT API URL
  static const String localBaseUrl = 'http://localhost/skoolwala/api';

  // Platform-specific local URLs for development
  static const String androidLocalUrl =
      'http://localhost/skoolwala/api'; // Android emulator
  // static const String androidLocalUrl = 'http://10.0.2.2/skoolwala/api'; // Alternative for real device
  static const String iosLocalUrl =
      'http://localhost/skoolwala/api'; // iOS simulator
  // static const String iosLocalUrl = 'http://127.0.0.1/skoolwala/api'; // Alternative for real device

  // Optional runtime override (e.g., real device over Wi‑Fi: http://192.168.x.x:8080/api)
  static String? _overrideBaseUrl;
  static void setOverrideBaseUrl(String? url) {
    _overrideBaseUrl = (url != null && url.trim().isNotEmpty)
        ? url.trim()
        : null;
  }

  // Use online production API
  static String get apiBaseUrl {
    // Highest priority: runtime override
    if (_overrideBaseUrl != null) return _overrideBaseUrl!;

    // During local testing prefer local backend per platform
    if (kIsWeb) {
      return localBaseUrl; // Flutter web runs in the browser on localhost
    }

    try {
      if (Platform.isAndroid) return androidLocalUrl;
      if (Platform.isIOS) return iosLocalUrl;
    } catch (_) {
      // Platform not available (shouldn't happen outside web which is handled above)
    }

    // Fallback to localhost
    return localBaseUrl;
  }

  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
  };

  // Generic HTTP POST method
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? body,
    Map<String, String>? headers,
    bool requireAuth = false,
  }) async {
    try {
      final url = Uri.parse('$apiBaseUrl/$endpoint');
      final requestHeaders = {...defaultHeaders, ...?headers};

      // Add authentication headers if required
      Map<String, String> finalHeaders = {...requestHeaders};
      if (requireAuth && SessionManager.instance.hasValidSession) {
        final authHeaders = SessionManager.instance.getAuthHeaders();
        finalHeaders.addAll(authHeaders);
      }

      // Debug: Print the URL being called
      if (_debugLogs) {
        print('🌐 API Call: POST $url');
        if (body != null) {
          print('📤 Request Body: $body');
        }
      }

      final response = await http.post(url, headers: finalHeaders, body: body);

      if (_debugLogs) {
        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}\nResponse: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e\nURL: $apiBaseUrl/$endpoint', 0);
    }
  }

  // Generic HTTP GET method
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      var url = Uri.parse('$apiBaseUrl/$endpoint');
      if (queryParams != null) {
        url = url.replace(queryParameters: queryParams);
      }

      final requestHeaders = {...defaultHeaders, ...?headers};

      // Debug: Print the URL being called
      if (_debugLogs) print('🌐 API Call: GET $url');

      final response = await http.get(url, headers: requestHeaders);

      if (_debugLogs) {
        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}\nResponse: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e\nURL: $apiBaseUrl/$endpoint', 0);
    }
  }

  // Test connection to localhost
  static Future<bool> testConnection() async {
    try {
      if (_debugLogs) print('🔍 Testing connection to: $apiBaseUrl');
      final response = await http
          .get(Uri.parse('$apiBaseUrl/test'), headers: defaultHeaders)
          .timeout(const Duration(seconds: 5));

      if (_debugLogs) {
        print('📥 Test Response Status: ${response.statusCode}');
        print('📥 Test Response Body: ${response.body}');
      }

      // Check if response is HTML (error page)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<!doctype') ||
          response.body.trim().startsWith('<html')) {
        if (_debugLogs) print('❌ Server returned HTML instead of JSON');
        return false;
      }

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (_debugLogs) print('✅ Connection test successful: ${data['message']}');
          return true;
        } catch (e) {
          if (_debugLogs) print('❌ Failed to parse test response: $e');
          return false;
        }
      } else {
        if (_debugLogs) print('❌ Test endpoint returned status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (_debugLogs) print('❌ Connection test failed: $e');
      return false;
    }
  }

  // Get current API base URL for debugging
  static String get currentApiUrl => apiBaseUrl;
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

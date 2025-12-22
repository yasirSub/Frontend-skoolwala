import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_manager.dart';
import '../config/api_config.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;
  HttpClient._internal();

  static String get baseUrl => ApiConfig.getBaseUrl();
  String? _sessionCookie;
  static const bool _debugLogs =
      false; // disable debug logs (authentication issue fixed)

  // Set session cookie from login response
  void setSessionCookie(String cookie) {
    _sessionCookie = cookie;
    if (_debugLogs) print('🍪 Session Cookie Set: $cookie');
  }

  // Clear session cookie
  void clearSessionCookie() {
    _sessionCookie = null;
    if (_debugLogs) print('🍪 Session Cookie Cleared');
  }

  // POST request with session management
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? body,
    Map<String, String>? headers,
    bool requireAuth = false,
  }) async {
    if (_debugLogs) print('🚀 POST Request to: $baseUrl/$endpoint');
    try {
      final url = Uri.parse('$baseUrl/$endpoint');

      // Prepare headers
      final requestHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        ...?headers,
      };

      // Add session cookie if available (prefer in-memory, fallback to persisted session)
      final cookie = _sessionCookie ?? SessionManager.instance.sessionCookie;
      if (cookie != null) {
        _sessionCookie ??= cookie;
        requestHeaders['Cookie'] = cookie;
      }

      // Prepare request body
      var requestBody = body ?? {};

      // Add auth credentials to body if required (PHP expects them in POST body, not headers)
      if (requireAuth && SessionManager.instance.hasValidSession) {
        final authData = SessionManager.instance.getAuthBody();
        requestBody.addAll(authData);
        if (_debugLogs) {
          print('🔐 Adding auth credentials to request body:');
          print('   Username: ${authData['username']}');
          print(
            '   Password: ${authData['password'] != null ? '***' : 'null'}',
          );
        }
      }

      // Debug: Print the request
      if (_debugLogs) {
        print('🌐 API Call: POST $url');
        print('📤 Headers: $requestHeaders');
        if (requestBody.isNotEmpty) {
          print('📤 Body keys: ${requestBody.keys.toList()}');
        }
        print('🔍 Testing connection to: $baseUrl');
        print('📡 Sending HTTP request...');
      }
      final response = await http
          .post(
            url,
            headers: requestHeaders,
            body: requestBody.isNotEmpty
                ? requestBody.entries
                      .map(
                        (e) =>
                            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
                      )
                      .join('&')
                : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⏰ Request timed out after 30 seconds');
              throw HttpException('Request timeout after 30 seconds', 0);
            },
          );
      if (_debugLogs) print('✅ HTTP response received: ${response.statusCode}');

      // Extract and store session cookie from response
      final setCookieHeader = response.headers['set-cookie'];
      if (setCookieHeader != null) {
        // Extract rm_session cookie
        final cookieMatch = RegExp(
          r'rm_session=([^;]+)',
        ).firstMatch(setCookieHeader);
        if (cookieMatch != null) {
          final sessionCookie = 'rm_session=${cookieMatch.group(1)}';
          setSessionCookie(sessionCookie);
        }
      }

      if (_debugLogs) {
        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
      }

      // Check if response is HTML (error page) instead of JSON
      final responseBody = response.body.trim();
      if (responseBody.startsWith('<!') || responseBody.startsWith('<html')) {
        throw HttpException(
          'Server returned HTML instead of JSON. The endpoint may not exist or there was a server error.\n'
          'URL: $url\n'
          'Status: ${response.statusCode}\n'
          'Response preview: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}',
          response.statusCode,
        );
      }

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw HttpException(
            'Failed to parse JSON response: $e\n'
            'URL: $url\n'
            'Response preview: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}',
            response.statusCode,
          );
        }
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}\nResponse: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (_debugLogs) {
        print('❌ Exception caught in POST: $e');
        print('❌ Exception type: ${e.runtimeType}');
      }
      if (e is HttpException) rethrow;
      throw HttpException('Network error: $e\nURL: $baseUrl/$endpoint', 0);
    }
  }

  // POST JSON request with session management
  Future<Map<String, dynamic>> postJson(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requireAuth = false,
  }) async {
    if (_debugLogs) print('🚀 POST JSON Request to: $baseUrl/$endpoint');
    try {
      final url = Uri.parse('$baseUrl/$endpoint');

      // Prepare headers
      final requestHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      };

      // Add session cookie if available (prefer in-memory, fallback to persisted session)
      final cookie = _sessionCookie ?? SessionManager.instance.sessionCookie;
      if (cookie != null) {
        _sessionCookie ??= cookie;
        requestHeaders['Cookie'] = cookie;
      }

      // Add auth credentials if required
      if (requireAuth && SessionManager.instance.hasValidSession) {
        final authData = SessionManager.instance.getAuthHeaders();
        requestHeaders.addAll(authData);
      }

      // Debug: Print the request
      if (_debugLogs) {
        print('🌐 API Call: POST $url');
        print('📤 Headers: $requestHeaders');
        if (body != null) {
          print('📤 JSON Body: $body');
        }
      }

      final response = await http
          .post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⏰ JSON request timed out after 30 seconds');
              throw HttpException('Request timeout after 30 seconds', 0);
            },
          );

      if (_debugLogs) {
        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
      }

      // Check if response is HTML (error page) instead of JSON
      final responseBody = response.body.trim();
      if (responseBody.startsWith('<!') || responseBody.startsWith('<html')) {
        throw HttpException(
          'Server returned HTML instead of JSON. The endpoint may not exist or there was a server error.\n'
          'URL: $url\n'
          'Status: ${response.statusCode}\n'
          'Response preview: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}',
          response.statusCode,
        );
      }

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw HttpException(
            'Failed to parse JSON response: $e\n'
            'URL: $url\n'
            'Response preview: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}',
            response.statusCode,
          );
        }
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}\nResponse: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (_debugLogs) print('❌ Exception caught in POST JSON: $e');
      if (e is HttpException) rethrow;
      throw HttpException('Network error: $e\nURL: $baseUrl/$endpoint', 0);
    }
  }

  // GET request with session management
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool requireAuth = false,
  }) async {
    try {
      var url = Uri.parse('$baseUrl/$endpoint');
      if (queryParams != null) {
        url = url.replace(queryParameters: queryParams);
      }

      // Prepare headers
      final requestHeaders = {'Accept': 'application/json', ...?headers};

      // Add session cookie if available
      if (_sessionCookie != null) {
        requestHeaders['Cookie'] = _sessionCookie!;
      }

      // Add auth credentials if required
      if (requireAuth && SessionManager.instance.hasValidSession) {
        final authData = SessionManager.instance.getAuthBody();
        requestHeaders.addAll(authData);
      }

      if (_debugLogs) print('🌐 API Call: GET $url');

      final response = await http.get(url, headers: requestHeaders);

      // Extract and store session cookie from response
      final setCookieHeader = response.headers['set-cookie'];
      if (setCookieHeader != null) {
        final cookieMatch = RegExp(
          r'rm_session=([^;]+)',
        ).firstMatch(setCookieHeader);
        if (cookieMatch != null) {
          final sessionCookie = 'rm_session=${cookieMatch.group(1)}';
          setSessionCookie(sessionCookie);
        }
      }

      if (_debugLogs) {
        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
      }

      // Check if response is HTML (error page) instead of JSON
      final responseBody = response.body.trim();
      if (responseBody.startsWith('<!') || responseBody.startsWith('<html')) {
        throw HttpException(
          'Server returned HTML instead of JSON. The endpoint may not exist or there was a server error.\n'
          'URL: $url\n'
          'Status: ${response.statusCode}\n'
          'Response preview: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}',
          response.statusCode,
        );
      }

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw HttpException(
            'Failed to parse JSON response: $e\n'
            'URL: $url\n'
            'Response preview: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}',
            response.statusCode,
          );
        }
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}\nResponse: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Network error: $e\nURL: $baseUrl/$endpoint', 0);
    }
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;

  const HttpException(this.message, this.statusCode);

  @override
  String toString() => 'HttpException: $message (Status: $statusCode)';
}

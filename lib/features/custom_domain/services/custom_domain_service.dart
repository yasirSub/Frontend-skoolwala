import '../../../shared/services/http_client.dart';
import '../../../shared/services/session_manager.dart';

class CustomDomainService {
  final HttpClient _client = HttpClient();

  Future<List<dynamic>> getCustomDomains() async {
    try {
      final authData = SessionManager.instance.getAuthBody();
      final response = await _client.postJson(
        'getCustomDomainList',
        body: {
          'username': authData['username'],
          'password': authData['password'],
        },
        requireAuth: false,
      );

      if (response['status'] == 'success') {
        return response['data'] as List<dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to load custom domains');
      }
    } catch (e) {
      print('Error fetching custom domains: $e');
      rethrow;
    }
  }
}

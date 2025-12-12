import '../../../shared/services/http_client.dart';
import '../../../shared/config/api_config.dart';
import '../screens/message_screen.dart';

/// Message Service
/// Handles all message/notification-related API calls
class MessageService {
  /// Get list of all messages
  static Future<List<Message>> getMessages() async {
    try {
      final response = await HttpClient().get(
        ApiConfig.getMessages,
        requireAuth: true,
      );

      if (response['status'] == 'success') {
        final messagesList =
            response['data']?['messages'] as List<dynamic>? ?? [];
        return messagesList
            .map((item) => Message.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load messages');
      }
    } catch (e) {
      // Return empty list on error (for placeholder)
      return [];
    }
  }

  /// Mark message as read
  static Future<void> markAsRead(String messageId) async {
    try {
      await HttpClient().post(
        ApiConfig.markMessageAsRead,
        body: {'message_id': messageId},
        requireAuth: true,
      );
    } catch (e) {
      // Silently fail
    }
  }
}

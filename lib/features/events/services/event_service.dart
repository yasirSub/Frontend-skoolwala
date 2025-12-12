import '../../../shared/services/http_client.dart';
import '../../../shared/config/api_config.dart';
import '../screens/event_calendar_screen.dart';

/// Event Service
/// Handles all event-related API calls
class EventService {
  /// Get list of all events
  static Future<List<Event>> getEvents() async {
    try {
      final response = await HttpClient().get(
        ApiConfig.getEvents,
        requireAuth: true,
      );

      if (response['status'] == 'success') {
        final eventsList = response['data']?['events'] as List<dynamic>? ?? [];
        return eventsList
            .map((item) => Event.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load events');
      }
    } catch (e) {
      // Return empty list on error (for placeholder)
      return [];
    }
  }

  /// Create a new event
  static Future<void> createEvent({
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
  }) async {
    try {
      final response = await HttpClient().post(
        ApiConfig.createEvent,
        body: {
          'title': title,
          if (description != null) 'description': description,
          'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
          if (location != null) 'location': location,
        },
        requireAuth: true,
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to create event');
      }
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }
}

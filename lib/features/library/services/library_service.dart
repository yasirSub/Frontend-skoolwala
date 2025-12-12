import '../../../shared/services/http_client.dart';
import '../../../shared/config/api_config.dart';
import '../screens/book_list_screen.dart';

/// Library Service
/// Handles all library-related API calls
class LibraryService {
  /// Get list of all books
  static Future<List<Book>> getBookList() async {
    try {
      final response = await HttpClient().get(
        ApiConfig.getBookList,
        requireAuth: true,
      );

      if (response['status'] == 'success') {
        final booksList = response['data']?['books'] as List<dynamic>? ?? [];
        return booksList
            .map((item) => Book.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load books');
      }
    } catch (e) {
      // Return empty list on error (for placeholder)
      return [];
    }
  }

  /// Issue a book to a student
  static Future<void> issueBook({
    required String bookId,
    required String studentId,
    required DateTime issueDate,
    required DateTime dueDate,
  }) async {
    try {
      final response = await HttpClient().post(
        ApiConfig.issueBook,
        body: {
          'book_id': bookId,
          'student_id': studentId,
          'issue_date': issueDate.toIso8601String().split('T')[0],
          'due_date': dueDate.toIso8601String().split('T')[0],
        },
        requireAuth: true,
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to issue book');
      }
    } catch (e) {
      throw Exception('Failed to issue book: $e');
    }
  }

  /// Get issued books list
  static Future<List<Map<String, dynamic>>> getIssuedBooks() async {
    try {
      final response = await HttpClient().get(
        ApiConfig.getIssuedBooks,
        requireAuth: true,
      );

      if (response['status'] == 'success') {
        return List<Map<String, dynamic>>.from(
          response['data']?['issued_books'] ?? [],
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to load issued books');
      }
    } catch (e) {
      return [];
    }
  }
}

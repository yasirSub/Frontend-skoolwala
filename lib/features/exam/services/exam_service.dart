import '../../../shared/services/api_service.dart';
import '../models/exam.dart';

class ExamService {
  static Future<List<Exam>> getExamList() async {
    try {
      final data = await ApiService.get('getExamList');

      if (data['status'] == 'success') {
        final List<dynamic> list = data['data'];
        return list.map((json) => Exam.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load exams');
      }
    } catch (e) {
      throw Exception('Error fetching exam list: $e');
    }
  }
}

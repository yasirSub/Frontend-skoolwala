import 'package:skoolwala/shared/services/http_client.dart';
import '../models/student.dart';
import '../models/class_model.dart';

/// Student Service
/// Handles all API calls related to students, classes, and sections
class StudentService {
  /// Get list of all classes
  static Future<List<ClassModel>> getClassList() async {
    try {
      final response = await HttpClient().post('getClassList');

      if (response['status'] == 'success' || response['status'] == true) {
        final classesList = response['data'] ?? [];
        final classes = classesList
            .map<ClassModel>((item) {
              try {
                return ClassModel.fromJson(item);
              } catch (e) {
                return null;
              }
            })
            .whereType<ClassModel>()
            .toList();
        return classes;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get list of sections for a specific class
  static Future<List<SectionModel>> getSectionList(String classId) async {
    try {
      final response = await HttpClient().post(
        'getSectionListByClass',
        body: {'class_id': classId},
      );

      if (response['status'] == 'success' || response['status'] == true) {
        final sectionsList = response['data'] ?? [];
        final sections = sectionsList
            .map<SectionModel>((item) {
              try {
                return SectionModel.fromJson(item);
              } catch (e) {
                return null;
              }
            })
            .whereType<SectionModel>()
            .toList();
        return sections;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get list of students for a specific class and section
  static Future<List<Student>> getStudentList({
    required String classId,
    required String sectionId,
    String? date,
  }) async {
    try {
      final selectedDate =
          date ?? DateTime.now().toIso8601String().split('T')[0];

      final response = await HttpClient().post(
        'getStudentList',
        body: {
          'class_id': classId,
          'section_id': sectionId,
          'date': selectedDate,
        },
      );

      if (response['status'] == 'success' || response['status'] == true) {
        final studentsList = response['data'] ?? [];
        final students = studentsList
            .map<Student>((item) {
              try {
                return Student.fromJson(item);
              } catch (e) {
                return null;
              }
            })
            .whereType<Student>()
            .toList();
        return students;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Search students by name, roll, or register number
  static Future<List<Student>> searchStudents({
    required String classId,
    required String sectionId,
    required String query,
  }) async {
    try {
      final students = await getStudentList(
        classId: classId,
        sectionId: sectionId,
      );

      final searchQuery = query.toLowerCase();
      return students.where((student) {
        final name = student.name?.toLowerCase() ?? '';
        final roll = student.roll?.toLowerCase() ?? '';
        final registerNo = student.registerNo?.toLowerCase() ?? '';

        return name.contains(searchQuery) ||
            roll.contains(searchQuery) ||
            registerNo.contains(searchQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

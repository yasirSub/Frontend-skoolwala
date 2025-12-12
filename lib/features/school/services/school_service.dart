// ignore_for_file: avoid_print

import 'dart:async';
import '../../../shared/models/school.dart';
import 'school_data_service.dart';

class SchoolService {
  const SchoolService();

  // Fetch schools from API
  Future<List<School>> fetchSchools() async {
    try {
      final response = await SchoolDataService.getSchoolsList();

      // Parse the response directly since data is a list
      if (response['status'] == 'success' && response['data'] != null) {
        final schoolsData = response['data'] as List<dynamic>? ?? [];
        final schools = schoolsData.map((schoolData) {
          // Debug: Print logo URLs for each school
          print('🏫 School: ${schoolData['school_name']}');
          print('   📝 Text Logo: ${schoolData['text_logo'] ?? 'null'}');
          print('   ⚙️ Main Logo: ${schoolData['main_logo'] ?? 'null'}');
          return School.fromApiResponse(schoolData);
        }).toList();
        print('✅ Loaded ${schools.length} schools with logos');
        return schools;
      } else {
        throw Exception(
          'Failed to fetch schools: ${response['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('Error fetching schools: $e');
      rethrow;
    }
  }

  // Fetch real school info from API
  Future<Map<String, dynamic>> fetchSchoolInfo() async {
    try {
      final response = await SchoolDataService.getSchoolInfo();
      return response;
    } catch (e) {
      print('Error fetching school info: $e');
      rethrow; // Let the error bubble up instead of returning dummy data
    }
  }

  // Fetch class list from API
  Future<List<Map<String, dynamic>>> fetchClassList() async {
    try {
      final response = await SchoolDataService.getClassList();
      final classes = response['classes'] as List<dynamic>? ?? [];
      return classes.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching class list: $e');
      rethrow; // Let the error bubble up instead of returning dummy data
    }
  }

  // Fetch section list by class from API
  Future<List<Map<String, dynamic>>> fetchSectionListByClass(
    String classId,
  ) async {
    try {
      final response = await SchoolDataService.getSectionListByClass(
        classId: classId,
      );
      final sections = response['sections'] as List<dynamic>? ?? [];
      return sections.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching section list: $e');
      rethrow; // Let the error bubble up instead of returning dummy data
    }
  }

  // Fetch student list from API
  Future<List<Map<String, dynamic>>> fetchStudentList({
    required String classId,
    required String sectionId,
  }) async {
    try {
      final response = await SchoolDataService.getStudentList(
        classId: classId,
        sectionId: sectionId,
      );
      final students = response['students'] as List<dynamic>? ?? [];
      return students.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching student list: $e');
      rethrow; // Let the error bubble up instead of returning dummy data
    }
  }
}

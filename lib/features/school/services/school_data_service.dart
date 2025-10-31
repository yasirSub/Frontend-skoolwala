import '../../../shared/services/http_client.dart';

class SchoolDataService {
  // Get Schools List API (for school selection) - using getSchoolInfo endpoint
  static Future<Map<String, dynamic>> getSchoolsList() async {
    try {
      final response = await HttpClient().get('getSchoolInfo');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get School Info API
  static Future<Map<String, dynamic>> getSchoolInfo() async {
    try {
      final response = await HttpClient().post(
        'getSchoolInfo',
        body: {'action': 'mark', 'status': 'P'},
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get Class List API
  static Future<Map<String, dynamic>> getClassList() async {
    try {
      final response = await HttpClient().post(
        'getClassList',
        body: {'action': 'mark', 'status': 'P'},
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get Section List By Class API
  static Future<Map<String, dynamic>> getSectionListByClass({
    required String classId,
  }) async {
    try {
      final response = await HttpClient().post(
        'getSectionListByClass',
        body: {'class_id': classId},
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get Student List API
  static Future<Map<String, dynamic>> getStudentList({
    required String classId,
    required String sectionId,
  }) async {
    try {
      final response = await HttpClient().post(
        'getStudentList',
        body: {'class_id': classId, 'section_id': sectionId},
        requireAuth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

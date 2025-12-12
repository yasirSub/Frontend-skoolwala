import '../../../shared/services/api_service.dart';
import '../models/employee.dart';

class EmployeeService {
  static Future<List<Employee>> getEmployeeList({String? roleId}) async {
    try {
      final queryParams = roleId != null ? {'role_id': roleId} : null;
      // ApiService.get returns a decoded Map<String, dynamic>
      final data = await ApiService.get(
        'getEmployeeList',
        queryParams: queryParams,
      );

      if (data['status'] == 'success') {
        final List<dynamic> employeesData = data['data'];
        return employeesData.map((json) => Employee.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load employees');
      }
    } catch (e) {
      throw Exception('Error fetching employee list: $e');
    }
  }
}

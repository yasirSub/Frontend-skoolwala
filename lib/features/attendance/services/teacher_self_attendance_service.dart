import '../../../shared/services/http_client.dart';

class TeacherSelfAttendanceService {
  // Mark teacher self-attendance (Check In/Out)
  static Future<Map<String, dynamic>> markSelfAttendance({
    required String action, // 'mark' for check-in, 'checkout' for check-out
    required String status, // 'P' for present, 'A' for absent
    String? remark,
  }) async {
    try {
      final body = {'action': action, 'status': status};

      if (remark != null && remark.isNotEmpty) {
        body['remark'] = remark;
      }

      final response = await HttpClient().post(
        'teacherSelfAttendance',
        body: body,
        requireAuth: true, // Uses session from login
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get current attendance status for today
  static Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final response = await HttpClient().post(
        'teacherSelfAttendance',
        body: {'action': 'get_today'},
        requireAuth: true,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Check in (mark as present)
  static Future<Map<String, dynamic>> checkIn({String? remark}) async {
    return await markSelfAttendance(
      action: 'mark',
      status: 'P',
      remark: remark,
    );
  }

  // Check out
  static Future<Map<String, dynamic>> checkOut({String? remark}) async {
    return await markSelfAttendance(
      action: 'checkout',
      status: 'P',
      remark: remark,
    );
  }

  // Mark as absent
  static Future<Map<String, dynamic>> markAbsent({String? remark}) async {
    return await markSelfAttendance(
      action: 'mark',
      status: 'A',
      remark: remark,
    );
  }
}

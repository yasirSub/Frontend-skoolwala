import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skoolwala/shared/services/session_manager.dart';

/// Service to determine current attendance status and next action
class AttendanceStatusService {
  static const String _baseUrl = 'http://192.168.31.129:8080/api';

  /// Get current attendance status for today
  static Future<AttendanceStatus> getCurrentStatus() async {
    try {
      final sessionManager = SessionManager.instance;
      final currentTeacher = sessionManager.currentTeacher;

      if (currentTeacher == null) {
        return AttendanceStatus(
          status: AttendanceState.notLoggedIn,
          message: 'Please login first',
          nextAction: 'login',
        );
      }

      final userId = currentTeacher.id.toString();
      print('🔍 Checking attendance status for user: $userId');

      // Get today's attendance records
      final todayAttendance = await _getTodayAttendance(userId);

      if (todayAttendance.isEmpty) {
        // No attendance marked today - can check in
        return AttendanceStatus(
          status: AttendanceState.canCheckIn,
          message: 'Ready to check in',
          nextAction: 'check_in',
          lastAttendance: null,
        );
      }

      // Check if user has checked in but not checked out
      final hasCheckIn = todayAttendance.any(
        (record) => record['attendance_type'] == 'check_in',
      );
      final hasCheckOut = todayAttendance.any(
        (record) => record['attendance_type'] == 'check_out',
      );

      if (hasCheckIn && !hasCheckOut) {
        // User has checked in but not checked out - can check out
        final checkInRecord = todayAttendance.firstWhere(
          (record) => record['attendance_type'] == 'check_in',
        );

        return AttendanceStatus(
          status: AttendanceState.canCheckOut,
          message: 'Ready to check out',
          nextAction: 'check_out',
          lastAttendance: checkInRecord,
        );
      } else if (hasCheckIn && hasCheckOut) {
        // User has already completed both check-in and check-out
        final checkOutRecord = todayAttendance.firstWhere(
          (record) => record['attendance_type'] == 'check_out',
        );

        return AttendanceStatus(
          status: AttendanceState.completed,
          message: 'Attendance completed for today',
          nextAction: 'none',
          lastAttendance: checkOutRecord,
        );
      } else {
        // Only check-out exists (shouldn't happen normally)
        return AttendanceStatus(
          status: AttendanceState.canCheckIn,
          message: 'Ready to check in',
          nextAction: 'check_in',
          lastAttendance: null,
        );
      }
    } catch (e) {
      print('❌ Failed to get attendance status: $e');
      return AttendanceStatus(
        status: AttendanceState.error,
        message: 'Unable to check attendance status: $e',
        nextAction: 'retry',
      );
    }
  }

  /// Get today's attendance records for a user
  static Future<List<Map<String, dynamic>>> _getTodayAttendance(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/attendance/today/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        print('❌ Failed to get today\'s attendance: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Failed to get today\'s attendance: $e');
      return [];
    }
  }

  /// Get attendance summary for today
  static Future<AttendanceSummary> getTodaySummary() async {
    try {
      final sessionManager = SessionManager.instance;
      final currentTeacher = sessionManager.currentTeacher;

      if (currentTeacher == null) {
        return AttendanceSummary(
          hasCheckedIn: false,
          hasCheckedOut: false,
          checkInTime: null,
          checkOutTime: null,
          totalHours: null,
        );
      }

      final userId = currentTeacher.id.toString();
      final todayAttendance = await _getTodayAttendance(userId);

      bool hasCheckedIn = false;
      bool hasCheckedOut = false;
      DateTime? checkInTime;
      DateTime? checkOutTime;

      for (final record in todayAttendance) {
        if (record['attendance_type'] == 'check_in') {
          hasCheckedIn = true;
          checkInTime = DateTime.tryParse(record['created_at'] ?? '');
        } else if (record['attendance_type'] == 'check_out') {
          hasCheckedOut = true;
          checkOutTime = DateTime.tryParse(record['created_at'] ?? '');
        }
      }

      // Calculate total hours if both check-in and check-out exist
      Duration? totalHours;
      if (checkInTime != null && checkOutTime != null) {
        totalHours = checkOutTime.difference(checkInTime);
      }

      return AttendanceSummary(
        hasCheckedIn: hasCheckedIn,
        hasCheckedOut: hasCheckedOut,
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        totalHours: totalHours,
      );
    } catch (e) {
      print('❌ Failed to get today\'s summary: $e');
      return AttendanceSummary(
        hasCheckedIn: false,
        hasCheckedOut: false,
        checkInTime: null,
        checkOutTime: null,
        totalHours: null,
      );
    }
  }
}

/// Current attendance status
class AttendanceStatus {
  final AttendanceState status;
  final String message;
  final String nextAction;
  final Map<String, dynamic>? lastAttendance;

  AttendanceStatus({
    required this.status,
    required this.message,
    required this.nextAction,
    this.lastAttendance,
  });
}

/// Attendance states
enum AttendanceState { notLoggedIn, canCheckIn, canCheckOut, completed, error }

/// Today's attendance summary
class AttendanceSummary {
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final Duration? totalHours;

  AttendanceSummary({
    required this.hasCheckedIn,
    required this.hasCheckedOut,
    this.checkInTime,
    this.checkOutTime,
    this.totalHours,
  });

  /// Get formatted total hours
  String get formattedTotalHours {
    if (totalHours == null) return 'N/A';

    final hours = totalHours!.inHours;
    final minutes = totalHours!.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get formatted check-in time
  String get formattedCheckInTime {
    if (checkInTime == null) return 'Not checked in';
    return '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted check-out time
  String get formattedCheckOutTime {
    if (checkOutTime == null) return 'Not checked out';
    return '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}';
  }
}

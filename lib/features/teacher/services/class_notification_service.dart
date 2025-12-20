import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skoolwala/features/teacher/models/class_schedule.dart';
import 'package:skoolwala/shared/services/http_client.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/config/api_config.dart';

/// Service to manage class schedule notifications
/// Notifies teachers 10 minutes before their class starts
/// Only shows notifications if teacher is present in school
class ClassNotificationService {
  static final ClassNotificationService _instance =
      ClassNotificationService._internal();

  factory ClassNotificationService() {
    return _instance;
  }

  ClassNotificationService._internal();

  Timer? _notificationTimer;
  Timer? _attendanceCheckTimer;
  final List<ClassSchedule> _todayClasses = [];
  VoidCallback? _onClassReminder;
  bool _isTeacherPresent = false;
  bool _hasCheckedAttendance = false;

  /// Start monitoring for upcoming classes
  void startMonitoring(List<ClassSchedule> classes) {
    _todayClasses.clear();
    _todayClasses.addAll(classes);

    // Check attendance first
    _checkTeacherAttendance();

    // Check attendance every 5 minutes
    _attendanceCheckTimer?.cancel();
    _attendanceCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkTeacherAttendance(),
    );

    // Check every minute for upcoming classes
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkUpcomingClasses(),
    );

    print(
      '🔔 Class Notification Service: Started monitoring ${classes.length} classes',
    );
  }

  /// Check if teacher is present today
  Future<void> _checkTeacherAttendance() async {
    try {
      final authData = SessionManager.instance.getAuthBody();
      
      final response = await HttpClient().postJson(
        ApiConfig.checkTeacherPresentToday,
        body: {
          'username': authData['username'],
          'password': authData['password'],
        },
        requireAuth: false,
      );

      if (response['status'] == 'success') {
        _isTeacherPresent = response['data']['is_present'] ?? false;
        _hasCheckedAttendance = true;
        print(
          '🔔 Attendance Check: Teacher is ${_isTeacherPresent ? "PRESENT" : "NOT PRESENT"}',
        );
      }
    } catch (e) {
      print('🔔 Error checking attendance: $e');
      // Don't block notifications if check fails, but don't show if we know they're not present
      if (!_hasCheckedAttendance) {
        _isTeacherPresent = false;
      }
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _notificationTimer?.cancel();
    _attendanceCheckTimer?.cancel();
    _notificationTimer = null;
    _attendanceCheckTimer = null;
    _todayClasses.clear();
    _isTeacherPresent = false;
    _hasCheckedAttendance = false;
    print('🔔 Class Notification Service: Stopped monitoring');
  }

  /// Check for classes starting in 10 minutes
  void _checkUpcomingClasses() {
    // Only check if teacher is present
    if (!_isTeacherPresent) {
      return;
    }

    final now = DateTime.now();

    for (final classSchedule in _todayClasses) {
      final classTime = classSchedule.startTime;

      // Check if class starts in exactly 10 minutes (with 1 minute tolerance)
      final minutesDifference = classTime.difference(now).inMinutes;

      if (minutesDifference >= 9 && minutesDifference <= 11) {
        _notifyClassReminder(classSchedule);
      }
    }
  }

  /// Trigger notification for class reminder
  void _notifyClassReminder(ClassSchedule classSchedule) {
    print(
      '🔔 Class Reminder: ${classSchedule.className} starts in 10 minutes!',
    );

    // Call callback if registered
    _onClassReminder?.call();

    // You can also use local notifications here if flutter_local_notifications is added
  }

  /// Register callback for class reminders
  void setOnClassReminderCallback(VoidCallback callback) {
    _onClassReminder = callback;
  }

  /// Get classes starting within the next N minutes
  List<ClassSchedule> getUpcomingClasses(int withinMinutes) {
    final now = DateTime.now();
    return _todayClasses.where((classSchedule) {
      final minutesDifference = classSchedule.startTime
          .difference(now)
          .inMinutes;
      return minutesDifference > 0 && minutesDifference <= withinMinutes;
    }).toList();
  }

  /// Get next class
  ClassSchedule? getNextClass() {
    final upcomingClasses = getUpcomingClasses(1440); // Next 24 hours
    if (upcomingClasses.isEmpty) return null;
    return upcomingClasses.first;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _onClassReminder = null;
  }
}

/// Model for class schedule information
class ClassSchedule {
  final String id;
  final String className;
  final String sectionName;
  final String roomNumber;
  final DateTime startTime;
  final DateTime endTime;
  final String? teacherName;
  final int totalStudents;

  ClassSchedule({
    required this.id,
    required this.className,
    required this.sectionName,
    required this.roomNumber,
    required this.startTime,
    required this.endTime,
    this.teacherName,
    this.totalStudents = 0,
  });

  /// Duration of the class in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// Time until class starts (in minutes), negative if already started
  int get minutesUntilStart => startTime.difference(DateTime.now()).inMinutes;

  /// Check if class is happening now
  bool get isHappeningNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if class is upcoming
  bool get isUpcoming => startTime.isAfter(DateTime.now());

  /// Check if class has passed
  bool get isPassed => endTime.isBefore(DateTime.now());

  /// Get formatted time display (HH:MM AM/PM)
  String get timeDisplay {
    final hour = startTime.hour % 12 == 0 ? 12 : startTime.hour % 12;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = startTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Create from JSON
  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      sectionName: json['sectionName']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      teacherName: json['teacherName']?.toString(),
      totalStudents:
          int.tryParse(json['totalStudents']?.toString() ?? '0') ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'className': className,
      'sectionName': sectionName,
      'roomNumber': roomNumber,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'teacherName': teacherName,
      'totalStudents': totalStudents,
    };
  }

  /// Helper to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

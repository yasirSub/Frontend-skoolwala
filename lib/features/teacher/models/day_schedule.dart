import 'class_item.dart';

/// Model for day schedule (full week)
class DaySchedule {
  final String day;
  final String dayKey;
  final List<ClassItem> classes;
  final int totalClasses;

  DaySchedule({
    required this.day,
    required this.dayKey,
    required this.classes,
    required this.totalClasses,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      day: json['day']?.toString() ?? '',
      dayKey: json['day_key']?.toString() ?? '',
      classes: (json['classes'] as List?)
              ?.map((item) => ClassItem.fromJson(item))
              .toList() ??
          [],
      totalClasses: json['total_classes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'day_key': dayKey,
      'classes': classes.map((c) => c.toJson()).toList(),
      'total_classes': totalClasses,
    };
  }
}


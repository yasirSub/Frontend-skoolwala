/// Model for individual class item in schedule
class ClassItem {
  final int id;
  final int classId;
  final String className;
  final int sectionId;
  final String sectionName;
  final int? subjectId;
  final String? subjectName;
  final String? subjectCode;
  final String startTime;
  final String endTime;
  final String timeDisplay;
  final String roomNumber;
  final bool isBreak;
  final String day;
  final String classSection;

  ClassItem({
    required this.id,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
    required this.startTime,
    required this.endTime,
    required this.timeDisplay,
    required this.roomNumber,
    required this.isBreak,
    required this.day,
    required this.classSection,
  });

  factory ClassItem.fromJson(Map<String, dynamic> json) {
    return ClassItem(
      id: json['id'] ?? 0,
      classId: json['class_id'] ?? 0,
      className: json['class_name']?.toString() ?? '',
      sectionId: json['section_id'] ?? 0,
      sectionName: json['section_name']?.toString() ?? '',
      subjectId: json['subject_id'],
      subjectName: json['subject_name']?.toString(),
      subjectCode: json['subject_code']?.toString(),
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      timeDisplay: json['time_display']?.toString() ?? '',
      roomNumber: json['room_number']?.toString() ?? 'TBA',
      isBreak: json['is_break'] ?? false,
      day: json['day']?.toString() ?? '',
      classSection: json['class_section']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'class_name': className,
      'section_id': sectionId,
      'section_name': sectionName,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'start_time': startTime,
      'end_time': endTime,
      'time_display': timeDisplay,
      'room_number': roomNumber,
      'is_break': isBreak,
      'day': day,
      'class_section': classSection,
    };
  }
}


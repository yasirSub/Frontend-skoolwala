/// Model for today's class information
class TodayClass {
  final int id;
  final int classId;
  final String className;
  final int sectionId;
  final String sectionName;
  final String? subjectName;
  final int? subjectId;
  final String startTime;
  final String endTime;
  final String roomNumber;
  final String day;
  final String classSection;
  final String timeSlot;

  TodayClass({
    required this.id,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    this.subjectName,
    this.subjectId,
    required this.startTime,
    required this.endTime,
    required this.roomNumber,
    required this.day,
    required this.classSection,
    required this.timeSlot,
  });

  factory TodayClass.fromJson(Map<String, dynamic> json) {
    return TodayClass(
      id: json['id'] ?? 0,
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? '',
      sectionId: json['section_id'] ?? 0,
      sectionName: json['section_name'] ?? '',
      subjectName: json['subject_name']?.toString(),
      subjectId: json['subject_id'] != null
          ? int.tryParse(json['subject_id'].toString())
          : null,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      roomNumber: json['room_number']?.toString() ?? 'TBA',
      day: json['day']?.toString() ?? '',
      classSection: json['class_section']?.toString() ?? '',
      timeSlot: json['time_slot']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'class_name': className,
      'section_id': sectionId,
      'section_name': sectionName,
      'subject_name': subjectName,
      'subject_id': subjectId,
      'start_time': startTime,
      'end_time': endTime,
      'room_number': roomNumber,
      'day': day,
      'class_section': classSection,
      'time_slot': timeSlot,
    };
  }
}

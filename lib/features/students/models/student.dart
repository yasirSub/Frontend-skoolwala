/// Student Model
/// Represents a student in the school system
class Student {
  final String? id;
  final String? name;
  final String? roll;
  final String? registerNo;
  final String? classId;
  final String? className;
  final String? sectionId;
  final String? sectionName;
  final String? mobileNo;
  final String? parentMobile;
  final String? email;
  final String? address;
  final String? attendanceStatus;
  final DateTime? date;

  const Student({
    this.id,
    this.name,
    this.roll,
    this.registerNo,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    this.mobileNo,
    this.parentMobile,
    this.email,
    this.address,
    this.attendanceStatus,
    this.date,
  });

  /// Create Student from JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? json['student_id']?.toString(),
      name: json['name']?.toString(),
      roll: json['roll']?.toString() ?? json['roll_no']?.toString(),
      registerNo:
          json['register_no']?.toString() ?? json['register_no']?.toString(),
      classId: json['class_id']?.toString(),
      className: json['class_name']?.toString(),
      sectionId: json['section_id']?.toString(),
      sectionName: json['section_name']?.toString(),
      mobileNo: json['mobile_no']?.toString() ?? json['mobile']?.toString(),
      parentMobile: json['parent_mobile']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      attendanceStatus: json['attendance_status']?.toString(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
    );
  }

  /// Convert Student to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roll': roll,
      'register_no': registerNo,
      'class_id': classId,
      'class_name': className,
      'section_id': sectionId,
      'section_name': sectionName,
      'mobile_no': mobileNo,
      'parent_mobile': parentMobile,
      'email': email,
      'address': address,
      'attendance_status': attendanceStatus,
      'date': date?.toIso8601String(),
    };
  }

  /// Get initial letter for avatar
  String get initial =>
      name != null && name!.isNotEmpty ? name![0].toUpperCase() : 'S';

  /// Check if student is present today
  bool get isPresent =>
      attendanceStatus == 'P' || attendanceStatus == 'Present';

  /// Get attendance badge color
  String get attendanceBadgeText {
    if (attendanceStatus == null || attendanceStatus!.isEmpty) {
      return 'Not Marked';
    }
    return isPresent ? 'Present' : 'Absent';
  }
}

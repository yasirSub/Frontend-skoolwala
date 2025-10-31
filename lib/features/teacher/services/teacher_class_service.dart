import '../../../shared/services/http_client.dart';
import '../../../shared/config/api_config.dart';

/// Model for Teacher Class Assignment
class TeacherClass {
  final int allocationId;
  final int classId;
  final int sectionId;
  final String className;
  final String? classNumber;
  final String sectionName;
  final String displayName;
  final int studentCount;

  TeacherClass({
    required this.allocationId,
    required this.classId,
    required this.sectionId,
    required this.className,
    this.classNumber,
    required this.sectionName,
    required this.displayName,
    required this.studentCount,
  });

  factory TeacherClass.fromJson(Map<String, dynamic> json) {
    return TeacherClass(
      allocationId: int.parse(json['allocation_id'].toString()),
      classId: int.parse(json['class_id'].toString()),
      sectionId: int.parse(json['section_id'].toString()),
      className: json['class_name']?.toString() ?? '',
      classNumber: json['class_number']?.toString(),
      sectionName: json['section_name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      studentCount: int.parse(json['student_count']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allocation_id': allocationId,
      'class_id': classId,
      'section_id': sectionId,
      'class_name': className,
      'class_number': classNumber,
      'section_name': sectionName,
      'display_name': displayName,
      'student_count': studentCount,
    };
  }
}

/// Model for Teacher Student
class TeacherStudent {
  final int studentId;
  final int enrollId;
  final String name;
  final String admissionNo;
  final String? roll;
  final String photo;
  final String? mobile;
  final String? email;
  final String? gender;
  final int classId;
  final int sectionId;
  final String className;
  final String sectionName;
  final String displayClass;

  TeacherStudent({
    required this.studentId,
    required this.enrollId,
    required this.name,
    required this.admissionNo,
    this.roll,
    required this.photo,
    this.mobile,
    this.email,
    this.gender,
    required this.classId,
    required this.sectionId,
    required this.className,
    required this.sectionName,
    required this.displayClass,
  });

  factory TeacherStudent.fromJson(Map<String, dynamic> json) {
    return TeacherStudent(
      studentId: int.parse(json['student_id'].toString()),
      enrollId: int.parse(json['enroll_id'].toString()),
      name: json['name']?.toString() ?? '',
      admissionNo: json['admission_no']?.toString() ?? '',
      roll: json['roll']?.toString(),
      photo: json['photo']?.toString() ?? '',
      mobile: json['mobile']?.toString(),
      email: json['email']?.toString(),
      gender: json['gender']?.toString(),
      classId: int.parse(json['class_id'].toString()),
      sectionId: int.parse(json['section_id'].toString()),
      className: json['class_name']?.toString() ?? '',
      sectionName: json['section_name']?.toString() ?? '',
      displayClass: json['display_class']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'enroll_id': enrollId,
      'name': name,
      'admission_no': admissionNo,
      'roll': roll,
      'photo': photo,
      'mobile': mobile,
      'email': email,
      'gender': gender,
      'class_id': classId,
      'section_id': sectionId,
      'class_name': className,
      'section_name': sectionName,
      'display_class': displayClass,
    };
  }
}

/// Response model for getMyClasses
class TeacherClassesResponse {
  final String status;
  final List<TeacherClass> classes;
  final int totalClasses;
  final int teacherId;
  final String message;

  TeacherClassesResponse({
    required this.status,
    required this.classes,
    required this.totalClasses,
    required this.teacherId,
    required this.message,
  });

  factory TeacherClassesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final classesList = data['classes'] as List<dynamic>? ?? [];

    return TeacherClassesResponse(
      status: json['status']?.toString() ?? '',
      classes: classesList
          .map((item) => TeacherClass.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalClasses: int.parse(data['total_classes']?.toString() ?? '0'),
      teacherId: int.parse(data['teacher_id']?.toString() ?? '0'),
      message: json['message']?.toString() ?? '',
    );
  }

  bool get isSuccess => status == 'success';
}

/// Response model for getMyStudents
class TeacherStudentsResponse {
  final String status;
  final List<TeacherStudent> students;
  final int totalStudents;
  final int teacherId;
  final Map<String, dynamic>? filter;
  final String message;

  TeacherStudentsResponse({
    required this.status,
    required this.students,
    required this.totalStudents,
    required this.teacherId,
    this.filter,
    required this.message,
  });

  factory TeacherStudentsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final studentsList = data['students'] as List<dynamic>? ?? [];

    return TeacherStudentsResponse(
      status: json['status']?.toString() ?? '',
      students: studentsList
          .map((item) => TeacherStudent.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalStudents: int.parse(data['total_students']?.toString() ?? '0'),
      teacherId: int.parse(data['teacher_id']?.toString() ?? '0'),
      filter: data['filter'] as Map<String, dynamic>?,
      message: json['message']?.toString() ?? '',
    );
  }

  bool get isSuccess => status == 'success';
}

/// Service for Teacher Class and Student Management
class TeacherClassService {
  /// Get all classes assigned to the logged-in teacher
  static Future<TeacherClassesResponse> getMyClasses() async {
    try {
      // Use GET request as it's a read operation
      final response = await HttpClient().get(
        ApiConfig.getMyClasses,
        requireAuth: true,
      );

      return TeacherClassesResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get teacher classes: $e');
    }
  }

  /// Get all students in classes assigned to the logged-in teacher
  static Future<TeacherStudentsResponse> getMyStudents({
    int? classId,
    int? sectionId,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {};
      if (classId != null) queryParams['class_id'] = classId.toString();
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();

      final response = await HttpClient().get(
        ApiConfig.getMyStudents,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      return TeacherStudentsResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get teacher students: $e');
    }
  }

  /// Get students for a specific class-section
  static Future<TeacherStudentsResponse> getClassStudents({
    required int classId,
    required int sectionId,
  }) async {
    return getMyStudents(classId: classId, sectionId: sectionId);
  }
}


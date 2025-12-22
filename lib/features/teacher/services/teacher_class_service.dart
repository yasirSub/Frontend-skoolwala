import '../../../shared/services/http_client.dart';
import '../../../shared/config/api_config.dart';
import 'package:flutter/foundation.dart';

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
    final className = json['class_name']?.toString() ?? '';
    final sectionName = json['section_name']?.toString() ?? '';
    final classSection = json['class_section']?.toString();
    final displayName =
        json['display_name']?.toString() ??
        classSection ??
        (className.isNotEmpty && sectionName.isNotEmpty
            ? '$className - $sectionName'
            : (className.isNotEmpty ? className : sectionName));

    return TeacherClass(
      // Backend may return allocation_id (newer) OR id (older getTeacherClasses)
      allocationId:
          int.tryParse((json['allocation_id'] ?? json['id'] ?? 0).toString()) ??
          0,
      classId: int.tryParse((json['class_id'] ?? 0).toString()) ?? 0,
      sectionId: int.tryParse((json['section_id'] ?? 0).toString()) ?? 0,
      className: className,
      classNumber: json['class_number']?.toString(),
      sectionName: sectionName,
      displayName: displayName,
      studentCount: int.tryParse((json['student_count'] ?? 0).toString()) ?? 0,
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
    final dynamic data = json['data'];

    // Backward-compatible parsing:
    // - Some endpoints return: { data: [ ...classes ] }
    // - Others return: { data: { classes: [ ...classes ], teacher_id, total_classes } }
    final List<dynamic> classesList;
    final int teacherId;
    final int totalClasses;

    if (data is List) {
      classesList = data;
      teacherId = int.tryParse((json['teacher_id'] ?? 0).toString()) ?? 0;
      totalClasses =
          int.tryParse(
            (json['total_classes'] ?? classesList.length).toString(),
          ) ??
          classesList.length;
    } else if (data is Map<String, dynamic>) {
      classesList = (data['classes'] as List<dynamic>?) ?? const [];
      teacherId = int.tryParse((data['teacher_id'] ?? 0).toString()) ?? 0;
      totalClasses =
          int.tryParse(
            (data['total_classes'] ?? classesList.length).toString(),
          ) ??
          classesList.length;
    } else {
      classesList = const [];
      teacherId = 0;
      totalClasses = 0;
    }

    return TeacherClassesResponse(
      status: json['status']?.toString() ?? '',
      classes: classesList
          .map((item) => TeacherClass.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalClasses: totalClasses,
      teacherId: teacherId,
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
      // Backend currently exposes this as getTeacherClasses.
      // Keep parsing backward-compatible in case older/newer servers differ.
      final response = await HttpClient().post(
        ApiConfig.getTeacherClasses,
        requireAuth: true,
      );

      if (kDebugMode) {
        final status = response['status'];
        final message = response['message'];
        final data = response['data'];
        final count = data is List
            ? data.length
            : (data is Map ? (data['classes'] as List?)?.length : null);
        print(
          '🧪 getTeacherClasses: status=$status, message=$message, count=${count ?? 'n/a'}',
        );
      }
      return TeacherClassesResponse.fromJson(response);
    } catch (e) {
      try {
        final response = await HttpClient().get(
          ApiConfig.getTeacherClasses,
          requireAuth: true,
        );

        if (kDebugMode) {
          final status = response['status'];
          final message = response['message'];
          final data = response['data'];
          final count = data is List
              ? data.length
              : (data is Map ? (data['classes'] as List?)?.length : null);
          print(
            '🧪 getTeacherClasses(GET): status=$status, message=$message, count=${count ?? 'n/a'}',
          );
        }
        return TeacherClassesResponse.fromJson(response);
      } catch (getError) {
        // Compatibility fallback for any servers that *do* implement getMyClasses.
        try {
          final response = await HttpClient().post(
            ApiConfig.getMyClasses,
            requireAuth: true,
          );

          if (kDebugMode) {
            final status = response['status'];
            final message = response['message'];
            final data = response['data'];
            final count = data is List
                ? data.length
                : (data is Map ? (data['classes'] as List?)?.length : null);
            print(
              '🧪 getMyClasses: status=$status, message=$message, count=${count ?? 'n/a'}',
            );
          }
          return TeacherClassesResponse.fromJson(response);
        } catch (legacyPostError) {
          try {
            final response = await HttpClient().get(
              ApiConfig.getMyClasses,
              requireAuth: true,
            );

            if (kDebugMode) {
              final status = response['status'];
              final message = response['message'];
              final data = response['data'];
              final count = data is List
                  ? data.length
                  : (data is Map ? (data['classes'] as List?)?.length : null);
              print(
                '🧪 getMyClasses(GET): status=$status, message=$message, count=${count ?? 'n/a'}',
              );
            }
            return TeacherClassesResponse.fromJson(response);
          } catch (legacyGetError) {
            throw Exception(
              'Failed to get teacher classes: $e (GET fallback also failed: $getError) '
              '(legacy getMyClasses POST failed: $legacyPostError, GET failed: $legacyGetError)',
            );
          }
        }
      }
    }
  }

  /// Get all students in classes assigned to the logged-in teacher
  static Future<TeacherStudentsResponse> getMyStudents({
    int? classId,
    int? sectionId,
  }) async {
    try {
      // Build body parameters for POST request
      final Map<String, String> bodyParams = {};
      if (classId != null) bodyParams['class_id'] = classId.toString();
      if (sectionId != null) bodyParams['section_id'] = sectionId.toString();

      // Try POST first (as other endpoints use POST)
      final response = await HttpClient().post(
        ApiConfig.getMyStudents,
        body: bodyParams.isNotEmpty ? bodyParams : null,
        requireAuth: true,
      );

      return TeacherStudentsResponse.fromJson(response);
    } catch (e) {
      // If POST fails, try GET as fallback
      try {
        final Map<String, String> queryParams = {};
        if (classId != null) queryParams['class_id'] = classId.toString();
        if (sectionId != null) queryParams['section_id'] = sectionId.toString();

        final response = await HttpClient().get(
          ApiConfig.getMyStudents,
          queryParams: queryParams.isNotEmpty ? queryParams : null,
          requireAuth: true,
        );
        return TeacherStudentsResponse.fromJson(response);
      } catch (getError) {
        throw Exception(
          'Failed to get teacher students: $e (GET fallback also failed: $getError)',
        );
      }
    }
  }

  /// Get students for a specific class-section
  static Future<TeacherStudentsResponse> getClassStudents({
    required int classId,
    required int sectionId,
  }) async {
    return getMyStudents(classId: classId, sectionId: sectionId);
  }

  /// Get subjects for a class-section
  static Future<Map<String, dynamic>> getSubjectsForClassSection({
    required int classId,
    required int sectionId,
    String? date,
  }) async {
    try {
      final queryParams = <String, String>{
        'class_id': classId.toString(),
        'section_id': sectionId.toString(),
      };

      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      final response = await HttpClient().get(
        ApiConfig.getSubjectsForClassSection,
        queryParams: queryParams,
        requireAuth: true,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to get subjects: $e');
    }
  }
}

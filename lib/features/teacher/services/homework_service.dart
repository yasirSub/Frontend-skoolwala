import '../../../shared/services/http_client.dart';
import '../../../shared/config/api_config.dart';
import 'dart:io';

/// Model for Homework
class Homework {
  final int id;
  final int classId;
  final int sectionId;
  final int subjectId;
  final String subjectName;
  final String className;
  final String sectionName;
  final String displayClass;
  final String dateOfHomework;
  final String dateOfSubmission;
  final String description;
  final String? document;
  final String status; // 'published' or 'pending'
  final String? scheduleDate;
  final bool smsNotification;
  final int studentCount;
  final int submissionCount;
  final int evaluationCount;
  final int pendingEvaluation;

  Homework({
    required this.id,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.subjectName,
    required this.className,
    required this.sectionName,
    required this.displayClass,
    required this.dateOfHomework,
    required this.dateOfSubmission,
    required this.description,
    this.document,
    required this.status,
    this.scheduleDate,
    required this.smsNotification,
    required this.studentCount,
    required this.submissionCount,
    required this.evaluationCount,
    required this.pendingEvaluation,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: int.parse(json['id']?.toString() ?? '0'),
      classId: int.parse(json['class_id']?.toString() ?? '0'),
      sectionId: int.parse(json['section_id']?.toString() ?? '0'),
      subjectId: int.parse(json['subject_id']?.toString() ?? '0'),
      subjectName: json['subject_name']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      sectionName: json['section_name']?.toString() ?? '',
      displayClass: json['display_class']?.toString() ?? '',
      dateOfHomework: json['date_of_homework']?.toString() ?? '',
      dateOfSubmission: json['date_of_submission']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      document: json['document']?.toString(),
      status: json['status']?.toString() ?? 'published',
      scheduleDate: json['schedule_date']?.toString(),
      smsNotification: json['sms_notification'] == true || json['sms_notification'] == 1,
      studentCount: int.parse(json['student_count']?.toString() ?? '0'),
      submissionCount: int.parse(json['submission_count']?.toString() ?? '0'),
      evaluationCount: int.parse(json['evaluation_count']?.toString() ?? '0'),
      pendingEvaluation: int.parse(json['pending_evaluation']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'section_id': sectionId,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'class_name': className,
      'section_name': sectionName,
      'display_class': displayClass,
      'date_of_homework': dateOfHomework,
      'date_of_submission': dateOfSubmission,
      'description': description,
      'document': document,
      'status': status,
      'schedule_date': scheduleDate,
      'sms_notification': smsNotification,
      'student_count': studentCount,
      'submission_count': submissionCount,
      'evaluation_count': evaluationCount,
      'pending_evaluation': pendingEvaluation,
    };
  }
}

/// Model for Homework Submission
class HomeworkSubmission {
  final int enrollId;
  final int studentId;
  final String studentName;
  final String registerNo;
  final String? roll;
  final String photo;
  final bool submitted;
  final String? submissionDate;
  final String? submissionMessage;
  final String? submissionFile;
  final bool evaluated;
  final String? evaluationStatus;
  final String? evaluationRemark;
  final String? evaluationRank;

  HomeworkSubmission({
    required this.enrollId,
    required this.studentId,
    required this.studentName,
    required this.registerNo,
    this.roll,
    required this.photo,
    required this.submitted,
    this.submissionDate,
    this.submissionMessage,
    this.submissionFile,
    required this.evaluated,
    this.evaluationStatus,
    this.evaluationRemark,
    this.evaluationRank,
  });

  factory HomeworkSubmission.fromJson(Map<String, dynamic> json) {
    return HomeworkSubmission(
      enrollId: int.parse(json['enroll_id']?.toString() ?? '0'),
      studentId: int.parse(json['student_id']?.toString() ?? '0'),
      studentName: json['student_name']?.toString() ?? '',
      registerNo: json['register_no']?.toString() ?? '',
      roll: json['roll']?.toString(),
      photo: json['photo']?.toString() ?? '',
      submitted: json['submitted'] == true || json['submitted'] == 1,
      submissionDate: json['submission_date']?.toString(),
      submissionMessage: json['submission_message']?.toString(),
      submissionFile: json['submission_file']?.toString(),
      evaluated: json['evaluated'] == true || json['evaluated'] == 1,
      evaluationStatus: json['evaluation_status']?.toString(),
      evaluationRemark: json['evaluation_remark']?.toString(),
      evaluationRank: json['evaluation_rank']?.toString(),
    );
  }
}

/// Response for getMyHomeworks
class HomeworksResponse {
  final String status;
  final List<Homework> homeworks;
  final int totalHomeworks;
  final int teacherId;
  final String message;

  HomeworksResponse({
    required this.status,
    required this.homeworks,
    required this.totalHomeworks,
    required this.teacherId,
    required this.message,
  });

  factory HomeworksResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final homeworksList = data['homeworks'] as List<dynamic>? ?? [];

    return HomeworksResponse(
      status: json['status']?.toString() ?? '',
      homeworks: homeworksList
          .map((item) => Homework.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalHomeworks: int.parse(data['total_homeworks']?.toString() ?? '0'),
      teacherId: int.parse(data['teacher_id']?.toString() ?? '0'),
      message: json['message']?.toString() ?? '',
    );
  }

  bool get isSuccess => status == 'success';
}

/// Response for getHomeworkSubmissions
class HomeworkSubmissionsResponse {
  final String status;
  final Homework homework;
  final List<HomeworkSubmission> submissions;
  final int totalStudents;
  final int submittedCount;
  final int evaluatedCount;
  final String message;

  HomeworkSubmissionsResponse({
    required this.status,
    required this.homework,
    required this.submissions,
    required this.totalStudents,
    required this.submittedCount,
    required this.evaluatedCount,
    required this.message,
  });

  factory HomeworkSubmissionsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final homeworkData = data['homework'] as Map<String, dynamic>? ?? {};
    final submissionsList = data['submissions'] as List<dynamic>? ?? [];

    // Create a minimal Homework object for the homework details
    final homework = Homework.fromJson({
      ...homeworkData,
      'id': homeworkData['id'],
      'class_id': 0,
      'section_id': 0,
      'subject_id': 0,
      'student_count': data['total_students'] ?? 0,
      'submission_count': data['submitted_count'] ?? 0,
      'evaluation_count': data['evaluated_count'] ?? 0,
      'pending_evaluation': (data['total_students'] ?? 0) - (data['evaluated_count'] ?? 0),
      'display_class': '${homeworkData['class_name']} - ${homeworkData['section_name']}',
      'status': 'published',
      'sms_notification': false,
    });

    return HomeworkSubmissionsResponse(
      status: json['status']?.toString() ?? '',
      homework: homework,
      submissions: submissionsList
          .map((item) =>
              HomeworkSubmission.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalStudents: int.parse(data['total_students']?.toString() ?? '0'),
      submittedCount: int.parse(data['submitted_count']?.toString() ?? '0'),
      evaluatedCount: int.parse(data['evaluated_count']?.toString() ?? '0'),
      message: json['message']?.toString() ?? '',
    );
  }

  bool get isSuccess => status == 'success';
}

/// Service for Homework Management
class HomeworkService {
  /// Create a new homework assignment
  static Future<Homework> createHomework({
    required int classId,
    required int sectionId,
    required int subjectId,
    required String dateOfHomework,
    required String dateOfSubmission,
    required String description,
    String? scheduleDate,
    String status = 'published', // 'published' or 'pending'
    bool smsNotification = false,
    File? attachmentFile,
  }) async {
    try {
      // For file upload, we'll need to use multipart/form-data
      // For now, using JSON - file upload will be handled separately if needed
      final response = await HttpClient().postJson(
        ApiConfig.createHomework,
        body: {
          'class_id': classId.toString(),
          'section_id': sectionId.toString(),
          'subject_id': subjectId.toString(),
          'date_of_homework': dateOfHomework,
          'date_of_submission': dateOfSubmission,
          'description': description,
          if (scheduleDate != null) 'schedule_date': scheduleDate,
          'status': status,
          'sms_notification': smsNotification,
        },
        requireAuth: true,
      );

      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        // Convert to full Homework object
        return Homework.fromJson({
          ...data,
          'student_count': 0,
          'submission_count': 0,
          'evaluation_count': 0,
          'pending_evaluation': 0,
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to create homework');
      }
    } catch (e) {
      throw Exception('Failed to create homework: $e');
    }
  }

  /// Get list of homeworks created by teacher
  static Future<HomeworksResponse> getMyHomeworks({
    int? classId,
    int? sectionId,
    int? subjectId,
    String? status, // 'published' or 'pending'
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (classId != null) queryParams['class_id'] = classId.toString();
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (subjectId != null) queryParams['subject_id'] = subjectId.toString();
      if (status != null) queryParams['status'] = status;

      final response = await HttpClient().get(
        ApiConfig.getMyHomeworks,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        requireAuth: true,
      );

      return HomeworksResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get homeworks: $e');
    }
  }

  /// Get homework submissions
  static Future<HomeworkSubmissionsResponse> getHomeworkSubmissions({
    required int homeworkId,
  }) async {
    try {
      final response = await HttpClient().get(
        ApiConfig.getHomeworkSubmissions,
        queryParams: {'homework_id': homeworkId.toString()},
        requireAuth: true,
      );

      return HomeworkSubmissionsResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get homework submissions: $e');
    }
  }

  /// Evaluate homework submission
  static Future<bool> evaluateHomework({
    required int homeworkId,
    required int studentId,
    required String status, // 'c' = completed, 'i' = incomplete
    String? remark,
    String? rank,
  }) async {
    try {
      final response = await HttpClient().postJson(
        ApiConfig.evaluateHomework,
        body: {
          'homework_id': homeworkId.toString(),
          'student_id': studentId.toString(),
          'status': status,
          if (remark != null) 'remark': remark,
          if (rank != null) 'rank': rank,
        },
        requireAuth: true,
      );

      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to evaluate homework: $e');
    }
  }
}


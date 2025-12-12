class FeeInvoice {
  final String enrollId;
  final String studentName;
  final String className;
  final String sectionName;
  final String registerNo;
  final String? mobileNo;
  final String? roll;
  final String status; // unpaid, partly, total
  final String feeGroups;
  final String? photo;

  FeeInvoice({
    required this.enrollId,
    required this.studentName,
    required this.className,
    required this.sectionName,
    required this.registerNo,
    this.mobileNo,
    this.roll,
    required this.status,
    required this.feeGroups,
    this.photo,
  });

  factory FeeInvoice.fromJson(Map<String, dynamic> json) {
    return FeeInvoice(
      enrollId: json['enroll_id']?.toString() ?? '',
      studentName: json['student_name'] ?? '',
      className: json['class_name'] ?? '',
      sectionName: json['section_name'] ?? '',
      registerNo: json['register_no'] ?? '',
      mobileNo: json['mobile_no'],
      roll: json['roll'],
      status: json['status'] ?? 'unpaid',
      feeGroups: json['fee_groups'] ?? '',
      photo: json['photo'],
    );
  }
}

class Exam {
  final String id;
  final String name;
  final String? termId;
  final String? typeId;
  final String? remark;
  final String? branchName;

  Exam({
    required this.id,
    required this.name,
    this.termId,
    this.typeId,
    this.remark,
    this.branchName,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      termId: json['term_id']?.toString(),
      typeId: json['type_id']?.toString(),
      remark: json['remark'],
      branchName: json['branch_name'],
    );
  }
}

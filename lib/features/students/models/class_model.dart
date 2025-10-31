/// Class Model
/// Represents a class in the school system
class ClassModel {
  final String? classId;
  final String? className;
  final String? classCode;
  final List<SectionModel>? sections;

  const ClassModel({
    this.classId,
    this.className,
    this.classCode,
    this.sections,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      classId: json['class_id']?.toString(),
      className: json['class_name']?.toString(),
      classCode: json['class_code']?.toString(),
      sections: json['sections'] != null
          ? (json['sections'] as List)
                .map((s) => SectionModel.fromJson(s))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_name': className,
      'class_code': classCode,
      'sections': sections?.map((s) => s.toJson()).toList(),
    };
  }
}

/// Section Model
/// Represents a section within a class
class SectionModel {
  final String? sectionId;
  final String? sectionName;
  final String? sectionCode;
  final String? classId;

  const SectionModel({
    this.sectionId,
    this.sectionName,
    this.sectionCode,
    this.classId,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      sectionId: json['section_id']?.toString(),
      sectionName: json['section_name']?.toString(),
      sectionCode: json['section_code']?.toString(),
      classId: json['class_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section_id': sectionId,
      'section_name': sectionName,
      'section_code': sectionCode,
      'class_id': classId,
    };
  }
}

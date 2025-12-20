class Teacher {
  final String id;
  final String staffId;
  final String name;
  final String email;
  final String mobileNo;
  final String sex;
  final String religion;
  final String bloodGroup;
  final String birthday;
  final String presentAddress;
  final String permanentAddress;
  final String photo;
  final String designation;
  final String department;
  final String joiningDate;
  final String qualification;
  final String experienceDetails;
  final String totalExperience;
  final String facebookUrl;
  final String linkedinUrl;
  final String twitterUrl;
  final String username;
  final String role;
  final String branchId;
  final bool active;
  final bool faceEnrolled;

  const Teacher({
    required this.id,
    required this.staffId,
    required this.name,
    required this.email,
    required this.mobileNo,
    required this.sex,
    required this.religion,
    required this.bloodGroup,
    required this.birthday,
    required this.presentAddress,
    required this.permanentAddress,
    required this.photo,
    required this.designation,
    required this.department,
    required this.joiningDate,
    required this.qualification,
    required this.experienceDetails,
    required this.totalExperience,
    required this.facebookUrl,
    required this.linkedinUrl,
    required this.twitterUrl,
    required this.username,
    required this.role,
    required this.branchId,
    required this.active,
    required this.faceEnrolled,
  });

  static bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes' || s == 'y';
  }

  Teacher copyWith({
    String? id,
    String? staffId,
    String? name,
    String? email,
    String? mobileNo,
    String? sex,
    String? religion,
    String? bloodGroup,
    String? birthday,
    String? presentAddress,
    String? permanentAddress,
    String? photo,
    String? designation,
    String? department,
    String? joiningDate,
    String? qualification,
    String? experienceDetails,
    String? totalExperience,
    String? facebookUrl,
    String? linkedinUrl,
    String? twitterUrl,
    String? username,
    String? role,
    String? branchId,
    bool? active,
    bool? faceEnrolled,
  }) {
    return Teacher(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      name: name ?? this.name,
      email: email ?? this.email,
      mobileNo: mobileNo ?? this.mobileNo,
      sex: sex ?? this.sex,
      religion: religion ?? this.religion,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      birthday: birthday ?? this.birthday,
      presentAddress: presentAddress ?? this.presentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      photo: photo ?? this.photo,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      joiningDate: joiningDate ?? this.joiningDate,
      qualification: qualification ?? this.qualification,
      experienceDetails: experienceDetails ?? this.experienceDetails,
      totalExperience: totalExperience ?? this.totalExperience,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      username: username ?? this.username,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      active: active ?? this.active,
      faceEnrolled: faceEnrolled ?? this.faceEnrolled,
    );
  }

  factory Teacher.fromJson(Map<String, dynamic> data) {
    return Teacher(
      id:
          data['id']?.toString() ??
          data['user_id']?.toString() ??
          data['teacher_id']?.toString() ??
          '',
      staffId: data['staff_id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      mobileNo:
          data['mobile_no']?.toString() ?? data['mobile']?.toString() ?? '',
      sex: data['sex']?.toString() ?? '',
      religion: data['religion']?.toString() ?? '',
      bloodGroup: data['blood_group']?.toString() ?? '',
      birthday: data['birthday']?.toString() ?? '',
      presentAddress: data['present_address']?.toString() ?? '',
      permanentAddress: data['permanent_address']?.toString() ?? '',
      photo: data['photo']?.toString() ?? '',
      designation: data['designation']?.toString() ?? '',
      department: data['department']?.toString() ?? '',
      joiningDate: data['joining_date']?.toString() ?? '',
      qualification: data['qualification']?.toString() ?? '',
      experienceDetails: data['experience_details']?.toString() ?? '',
      totalExperience: data['total_experience']?.toString() ?? '',
      facebookUrl: data['facebook_url']?.toString() ?? '',
      linkedinUrl: data['linkedin_url']?.toString() ?? '',
      twitterUrl: data['twitter_url']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      branchId: data['branch_id']?.toString() ?? '',
      active: data['active'] == true,
      faceEnrolled: _isTruthy(data['face_enrolled']),
    );
  }

  factory Teacher.fromApiResponse(Map<String, dynamic> data) {
    return Teacher(
      id:
          data['id']?.toString() ??
          data['user_id']?.toString() ??
          data['teacher_id']?.toString() ??
          '',
      staffId: data['staff_id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      mobileNo:
          data['mobile_no']?.toString() ?? data['mobile']?.toString() ?? '',
      sex: data['sex']?.toString() ?? '',
      religion: data['religion']?.toString() ?? '',
      bloodGroup: data['blood_group']?.toString() ?? '',
      birthday: data['birthday']?.toString() ?? '',
      presentAddress: data['present_address']?.toString() ?? '',
      permanentAddress: data['permanent_address']?.toString() ?? '',
      photo: data['photo']?.toString() ?? '',
      designation: data['designation']?.toString() ?? '',
      department: data['department']?.toString() ?? '',
      joiningDate: data['joining_date']?.toString() ?? '',
      qualification: data['qualification']?.toString() ?? '',
      experienceDetails: data['experience_details']?.toString() ?? '',
      totalExperience: data['total_experience']?.toString() ?? '',
      facebookUrl: data['facebook_url']?.toString() ?? '',
      linkedinUrl: data['linkedin_url']?.toString() ?? '',
      twitterUrl: data['twitter_url']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      branchId: data['branch_id']?.toString() ?? '',
      active: data['active'] == true,
      faceEnrolled: _isTruthy(data['face_enrolled']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'name': name,
      'email': email,
      'mobile_no': mobileNo,
      'sex': sex,
      'religion': religion,
      'blood_group': bloodGroup,
      'birthday': birthday,
      'present_address': presentAddress,
      'permanent_address': permanentAddress,
      'photo': photo,
      'designation': designation,
      'department': department,
      'joining_date': joiningDate,
      'qualification': qualification,
      'experience_details': experienceDetails,
      'total_experience': totalExperience,
      'facebook_url': facebookUrl,
      'linkedin_url': linkedinUrl,
      'twitter_url': twitterUrl,
      'username': username,
      'role': role,
      'branch_id': branchId,
      'active': active,
      'face_enrolled': faceEnrolled,
    };
  }

  @override
  String toString() {
    return 'Teacher(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Teacher && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

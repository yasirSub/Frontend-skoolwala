import '../../../shared/models/teacher.dart';

/// Teacher Profile Model - Based on API response from t-profile.txt
class TeacherProfile {
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

  const TeacherProfile({
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

  /// Create TeacherProfile from API response
  factory TeacherProfile.fromApiResponse(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      final data = response['data'];
      return TeacherProfile(
        id: data['id']?.toString() ?? '',
        staffId: data['staff_id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        mobileNo: data['mobile_no']?.toString() ?? '',
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
        faceEnrolled: data['face_enrolled'] == true,
      );
    }
    throw Exception('Invalid API response format');
  }

  /// Convert to Teacher object for compatibility
  Teacher toTeacher() {
    return Teacher(
      id: id,
      staffId: staffId,
      name: name,
      email: email,
      mobileNo: mobileNo,
      sex: sex,
      religion: religion,
      bloodGroup: bloodGroup,
      birthday: birthday,
      presentAddress: presentAddress,
      permanentAddress: permanentAddress,
      photo: photo,
      designation: designation,
      department: department,
      joiningDate: joiningDate,
      qualification: qualification,
      experienceDetails: experienceDetails,
      totalExperience: totalExperience,
      facebookUrl: facebookUrl,
      linkedinUrl: linkedinUrl,
      twitterUrl: twitterUrl,
      username: username,
      role: role,
      branchId: branchId,
      active: active,
      faceEnrolled: faceEnrolled,
    );
  }

  /// Convert to JSON (for API calls)
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

  /// Get formatted display name
  String get displayName => name;

  /// Get formatted phone number
  String get formattedPhone => mobileNo;

  /// Get age from birthday
  int? get age {
    try {
      final birthDate = DateTime.parse(birthday);
      final now = DateTime.now();
      return now.year - birthDate.year;
    } catch (e) {
      return null;
    }
  }

  /// Get years of experience as integer
  int? get experienceYears {
    try {
      return int.parse(totalExperience);
    } catch (e) {
      return null;
    }
  }

  /// Get joining date as DateTime
  DateTime? get joiningDateTime {
    try {
      return DateTime.parse(joiningDate);
    } catch (e) {
      return null;
    }
  }

  /// Get birthday as DateTime
  DateTime? get birthDateTime {
    try {
      return DateTime.parse(birthday);
    } catch (e) {
      return null;
    }
  }

  /// Check if teacher has social media links
  bool get hasSocialMedia =>
      facebookUrl.isNotEmpty || linkedinUrl.isNotEmpty || twitterUrl.isNotEmpty;

  /// Get full photo URL
  String get fullPhotoUrl {
    if (photo.isEmpty) return '';
    return 'https://skoolwala.com/uploads/teachers/$photo';
  }

  /// Get gender display text
  String get genderDisplay {
    switch (sex.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return sex;
    }
  }

  /// Get blood group with Rh factor
  String get bloodGroupDisplay {
    if (bloodGroup.isEmpty) return 'Not specified';
    return bloodGroup;
  }

  /// Get experience display text
  String get experienceDisplay {
    final years = experienceYears;
    if (years == null) return totalExperience;
    if (years == 1) return '$years year';
    return '$years years';
  }

  /// Get joining date display
  String get joiningDateDisplay {
    final date = joiningDateTime;
    if (date == null) return joiningDate;

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  /// Get birthday display
  String get birthdayDisplay {
    final date = birthDateTime;
    if (date == null) return birthday;

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Check if addresses are the same
  bool get hasSameAddress => presentAddress == permanentAddress;

  /// Get primary address (present address)
  String get primaryAddress => presentAddress;

  /// Get secondary address (permanent address if different)
  String? get secondaryAddress {
    if (hasSameAddress) return null;
    return permanentAddress;
  }

  @override
  String toString() {
    return 'TeacherProfile(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeacherProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// API Response wrapper for TeacherProfile
class TeacherProfileResponse {
  final String status;
  final TeacherProfile? data;
  final String message;

  const TeacherProfileResponse({
    required this.status,
    this.data,
    required this.message,
  });

  factory TeacherProfileResponse.fromApiResponse(
    Map<String, dynamic> response,
  ) {
    return TeacherProfileResponse(
      status: response['status']?.toString() ?? '',
      data: response['data'] != null
          ? TeacherProfile.fromApiResponse(response)
          : null,
      message: response['message']?.toString() ?? '',
    );
  }

  bool get isSuccess => status == 'success';
  bool get hasData => data != null;
}

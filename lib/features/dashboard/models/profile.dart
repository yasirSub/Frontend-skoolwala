import '../../../shared/models/teacher.dart';

/// Profile model for dashboard display
class Profile {
  final String id;
  final String fullName;
  final String role;
  final String username;
  final String email;
  final String phone;
  final String avatarAssetPath;
  final int? presentDays;
  final int? absentDays;

  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.username,
    required this.email,
    required this.phone,
    required this.avatarAssetPath,
    this.presentDays,
    this.absentDays,
  });

  // Convert from Teacher model
  factory Profile.fromTeacher(
    Teacher teacher, {
    int? presentDays,
    int? absentDays,
  }) {
    return Profile(
      id: teacher.id,
      fullName: teacher.name,
      role: teacher.role,
      username: teacher.username,
      email: teacher.email,
      phone: teacher.mobileNo,
      avatarAssetPath: teacher.photo.isNotEmpty ? teacher.photo : '',
      presentDays: presentDays,
      absentDays: absentDays,
    );
  }

  // Copy with method for easy updates
  Profile copyWith({
    String? id,
    String? fullName,
    String? role,
    String? username,
    String? email,
    String? phone,
    String? avatarAssetPath,
    int? presentDays,
    int? absentDays,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarAssetPath: avatarAssetPath ?? this.avatarAssetPath,
      presentDays: presentDays ?? this.presentDays,
      absentDays: absentDays ?? this.absentDays,
    );
  }
}

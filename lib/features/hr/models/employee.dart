class Employee {
  final String id;
  final String staffId;
  final String name;
  final String role;
  final String roleId;
  final String? designation;
  final String? department;
  final String? mobileNo;
  final String? email;
  final String? photo;
  final String? joiningDate;

  Employee({
    required this.id,
    required this.staffId,
    required this.name,
    required this.role,
    required this.roleId,
    this.designation,
    this.department,
    this.mobileNo,
    this.email,
    this.photo,
    this.joiningDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      staffId: json['staff_id']?.toString() ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      roleId: json['role_id']?.toString() ?? '',
      designation: json['designation'],
      department: json['department'],
      mobileNo: json['mobile_no'],
      email: json['email'],
      photo: json['photo'],
      joiningDate: json['joining_date'],
    );
  }
}

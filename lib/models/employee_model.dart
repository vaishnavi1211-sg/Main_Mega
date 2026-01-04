// lib/models/employee_model.dart
class Employee {
  final String id;
  final String empId;
  final String fullName;
  final String email;
  final String? phone;
  final String? position;
  final String? branch;
  final String? district;
  final DateTime? joiningDate;
  final String status;
  final int? salary;
  final String role;
  final double? performance;
  final double? attendance;
  final String? userId;
  final DateTime createdAt;
  final String? profileImage;
  final int? roleId;

  Employee({
    required this.id,
    required this.empId,
    required this.fullName,
    required this.email,
    this.phone,
    this.position,
    this.branch,
    this.district,
    this.joiningDate,
    required this.status,
    this.salary,
    required this.role,
    this.performance,
    this.attendance,
    this.userId,
    required this.createdAt,
    this.profileImage,
    this.roleId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      empId: json['emp_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      position: json['position'] as String?,
      branch: json['branch'] as String?,
      district: json['district'] as String?,
      joiningDate: json['joining_date'] != null 
          ? DateTime.parse(json['joining_date'] as String)
          : null,
      status: json['status'] as String,
      salary: json['salary'] as int?,
      role: json['role'] as String,
      performance: json['performance'] != null 
          ? (json['performance'] as num).toDouble()
          : null,
      attendance: json['attendance'] != null
          ? (json['attendance'] as num).toDouble()
          : null,
      userId: json['user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      profileImage: json['profile_image'] as String?,
      roleId: json['role_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emp_id': empId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'position': position,
      'branch': branch,
      'district': district,
      'joining_date': joiningDate?.toIso8601String(),
      'status': status,
      'salary': salary,
      'role': role,
      'performance': performance,
      'attendance': attendance,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'profile_image': profileImage,
      'role_id': roleId,
    };
  }
}
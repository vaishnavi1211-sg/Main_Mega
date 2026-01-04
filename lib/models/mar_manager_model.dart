// lib/models/marketing_manager_model.dart
class MarketingManager {
  final String id;
  final String empId;
  final String fullName;
  final String email;
  final String? phone;
  final String? position;
  final String? branch;
  final String? district;
  final String status;
  final String role;

  MarketingManager({
    required this.id,
    required this.empId,
    required this.fullName,
    required this.email,
    this.phone,
    this.position,
    this.branch,
    this.district,
    required this.status,
    required this.role,
  });

  factory MarketingManager.fromJson(Map<String, dynamic> json) {
    return MarketingManager(
      id: json['id'] as String,
      empId: json['emp_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      position: json['position'] as String?,
      branch: json['branch'] as String?,
      district: json['district'] as String?,
      status: json['status'] as String,
      role: json['role'] as String,
    );
  }
}

// lib/models/marketing_target_model.dart
class MarketingTarget {
  final String id;
  final String managerId;
  final String branch;
  final DateTime targetMonth;
  final int revenueTarget;
  final int orderTarget;
  final String? remarks;
  final String? assignedBy;
  final DateTime assignedAt;
  final String status;
  final int achievedRevenue;
  final int achievedOrders;
  final MarketingManager? manager;

  MarketingTarget({
    required this.id,
    required this.managerId,
    required this.branch,
    required this.targetMonth,
    required this.revenueTarget,
    required this.orderTarget,
    this.remarks,
    this.assignedBy,
    required this.assignedAt,
    required this.status,
    required this.achievedRevenue,
    required this.achievedOrders,
    this.manager,
  });

  factory MarketingTarget.fromJson(Map<String, dynamic> json) {
    return MarketingTarget(
      id: json['id'] as String,
      managerId: json['manager_id'] as String,
      branch: json['branch'] as String,
      targetMonth: DateTime.parse(json['target_month'] as String),
      revenueTarget: json['revenue_target'] as int,
      orderTarget: json['order_target'] as int,
      remarks: json['remarks'] as String?,
      assignedBy: json['assigned_by'] as String?,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      status: json['status'] as String,
      achievedRevenue: json['achieved_revenue'] as int? ?? 0,
      achievedOrders: json['achieved_orders'] as int? ?? 0,
      manager: json['manager'] != null 
          ? MarketingManager.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manager_id': managerId,
      'branch': branch,
      'target_month': targetMonth.toIso8601String(),
      'revenue_target': revenueTarget,
      'order_target': orderTarget,
      'remarks': remarks,
      'assigned_by': assignedBy,
      'assigned_at': assignedAt.toIso8601String(),
      'status': status,
      'achieved_revenue': achievedRevenue,
      'achieved_orders': achievedOrders,
    };
  }

  double get revenueProgress {
    return revenueTarget > 0 ? (achievedRevenue / revenueTarget) * 100 : 0;
  }

  double get orderProgress {
    return orderTarget > 0 ? (achievedOrders / orderTarget) * 100 : 0;
  }

  bool get isCompleted {
    return achievedRevenue >= revenueTarget && achievedOrders >= orderTarget;
  }
}
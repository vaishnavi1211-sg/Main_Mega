// lib/models/dashboard_metrics_model.dart
class DashboardMetrics {
  final String id;
  final DateTime metricDate;
  final int totalRevenue;
  final int totalOrders;
  final int activeEmployees;
  final DateTime createdAt;

  DashboardMetrics({
    required this.id,
    required this.metricDate,
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeEmployees,
    required this.createdAt,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      id: json['id'] as String,
      metricDate: DateTime.parse(json['metric_date'] as String),
      totalRevenue: json['total_revenue'] as int,
      totalOrders: json['total_orders'] as int,
      activeEmployees: json['active_employees'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metric_date': metricDate.toIso8601String(),
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'active_employees': activeEmployees,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
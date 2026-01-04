// lib/models/dashboard_data_model.dart
class DashboardData {
  final int totalRevenue;
  final int totalOrders;
  final int activeEmployees;
  final int pendingOrders;
  final double revenueGrowth;
  final double orderGrowth;
  final double employeeGrowth;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> recentActivities;

  DashboardData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeEmployees,
    required this.pendingOrders,
    required this.revenueGrowth,
    required this.orderGrowth,
    required this.employeeGrowth,
    required this.topProducts,
    required this.recentActivities,
  });

  factory DashboardData.empty() {
    return DashboardData(
      totalRevenue: 0,
      totalOrders: 0,
      activeEmployees: 0,
      pendingOrders: 0,
      revenueGrowth: 0,
      orderGrowth: 0,
      employeeGrowth: 0,
      topProducts: [],
      recentActivities: [],
    );
  }
}
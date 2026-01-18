// lib/models/own_dashboard_model.dart

class DashboardData {
  final double totalRevenue;
  final int totalOrders;
  final int activeEmployees;
  final int pendingOrders;
  final double revenueGrowth;
  final double orderGrowth;
  final double employeeGrowth;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> recentActivities;
  final List<Map<String, dynamic>> revenueChartData;
  
  // Profit metrics from production dashboard
  final double totalRawMaterialCost;
  final double totalProfit;
  final double profitMargin;
  final Map<String, double> materialCostBreakdown;
  final List<Map<String, dynamic>> profitChartData;
  final double productionToday;
  final double productionTarget;
  final int completedOrdersThisMonth;

  const DashboardData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeEmployees,
    required this.pendingOrders,
    required this.revenueGrowth,
    required this.orderGrowth,
    required this.employeeGrowth,
    required this.topProducts,
    required this.recentActivities,
    required this.revenueChartData,
    required this.totalRawMaterialCost,
    required this.totalProfit,
    required this.profitMargin,
    required this.materialCostBreakdown,
    required this.profitChartData,
    required this.productionToday,
    required this.productionTarget,
    required this.completedOrdersThisMonth,
  });

  DashboardData.empty()
      : totalRevenue = 0.0,
        totalOrders = 0,
        activeEmployees = 0,
        pendingOrders = 0,
        revenueGrowth = 0.0,
        orderGrowth = 0.0,
        employeeGrowth = 0.0,
        topProducts = [],
        recentActivities = [],
        revenueChartData = [],
        totalRawMaterialCost = 0.0,
        totalProfit = 0.0,
        profitMargin = 0.0,
        materialCostBreakdown = {},
        profitChartData = [],
        productionToday = 0.0,
        productionTarget = 0.0,
        completedOrdersThisMonth = 0;

  DashboardData copyWith({
    double? totalRevenue,
    int? totalOrders,
    int? activeEmployees,
    int? pendingOrders,
    double? revenueGrowth,
    double? orderGrowth,
    double? employeeGrowth,
    List<Map<String, dynamic>>? topProducts,
    List<Map<String, dynamic>>? recentActivities,
    List<Map<String, dynamic>>? revenueChartData,
    double? totalRawMaterialCost,
    double? totalProfit,
    double? profitMargin,
    Map<String, double>? materialCostBreakdown,
    List<Map<String, dynamic>>? profitChartData,
    double? productionToday,
    double? productionTarget,
    int? completedOrdersThisMonth,
  }) {
    return DashboardData(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalOrders: totalOrders ?? this.totalOrders,
      activeEmployees: activeEmployees ?? this.activeEmployees,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      revenueGrowth: revenueGrowth ?? this.revenueGrowth,
      orderGrowth: orderGrowth ?? this.orderGrowth,
      employeeGrowth: employeeGrowth ?? this.employeeGrowth,
      topProducts: topProducts ?? this.topProducts,
      recentActivities: recentActivities ?? this.recentActivities,
      revenueChartData: revenueChartData ?? this.revenueChartData,
      totalRawMaterialCost: totalRawMaterialCost ?? this.totalRawMaterialCost,
      totalProfit: totalProfit ?? this.totalProfit,
      profitMargin: profitMargin ?? this.profitMargin,
      materialCostBreakdown: materialCostBreakdown ?? this.materialCostBreakdown,
      profitChartData: profitChartData ?? this.profitChartData,
      productionToday: productionToday ?? this.productionToday,
      productionTarget: productionTarget ?? this.productionTarget,
      completedOrdersThisMonth: completedOrdersThisMonth ?? this.completedOrdersThisMonth,
    );
  }
}

class DistrictRevenueData {
  final String district;
  final String branch;
  final double revenue;
  final int orders;
  final double growth;
  final List<String> topProducts;

  const DistrictRevenueData({
    required this.district,
    required this.branch,
    required this.revenue,
    required this.orders,
    required this.growth,
    required this.topProducts,
  });
}

// Keep other classes as they are...

// // lib/models/dashboard_data_model.dart
// class DashboardData {
//   final int totalRevenue;
//   final int totalOrders;
//   final int activeEmployees;
//   final int pendingOrders;
//   final double revenueGrowth;
//   final double orderGrowth;
//   final double employeeGrowth;
//   final List<Map<String, dynamic>> topProducts;
//   final List<Map<String, dynamic>> recentActivities;

//   DashboardData({
//     required this.totalRevenue,
//     required this.totalOrders,
//     required this.activeEmployees,
//     required this.pendingOrders,
//     required this.revenueGrowth,
//     required this.orderGrowth,
//     required this.employeeGrowth,
//     required this.topProducts,
//     required this.recentActivities,
//   });

//   factory DashboardData.empty() {
//     return DashboardData(
//       totalRevenue: 0,
//       totalOrders: 0,
//       activeEmployees: 0,
//       pendingOrders: 0,
//       revenueGrowth: 0,
//       orderGrowth: 0,
//       employeeGrowth: 0,
//       topProducts: [],
//       recentActivities: [],
//     );
//   }
// }
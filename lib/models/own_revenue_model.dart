
class DistrictRevenueData {
  final String district;
  final String branch;
  final double revenue;
  final int orders;
  final double growth;
  final List<String> topProducts;

  DistrictRevenueData({
    required this.district,
    required this.branch,
    required this.revenue,
    required this.orders,
    required this.growth,
    required this.topProducts,
  });

  factory DistrictRevenueData.fromJson(Map<String, dynamic> json) {
    return DistrictRevenueData(
      district: json['district'] ?? '',
      branch: json['branch'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
      growth: (json['growth'] ?? 0).toDouble(),
      topProducts: List<String>.from(json['top_products'] ?? []),
    );
  }
}

class OrderDetail {
  final String id;
  final String customerName;
  final String status;
  final double amount;
  final DateTime date;
  final String product;
  final int quantity;
  final String branch;
  final String district;

  OrderDetail({
    required this.id,
    required this.customerName,
    required this.status,
    required this.amount,
    required this.date,
    required this.product,
    required this.quantity,
    required this.branch,
    required this.district,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] ?? '',
      customerName: json['customer_name'] ?? '',
      status: json['status'] ?? 'pending',
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      product: json['product'] ?? '',
      quantity: json['quantity'] ?? 0,
      branch: json['branch'] ?? '',
      district: json['district'] ?? '',
    );
  }
}

class EmployeeDetail {
  final String id;
  final String name;
  final String position;
  final String branch;
  final String district;
  final String status;
  final double performance;
  final int completedOrders;
  final double revenueGenerated;
  final DateTime joinDate;

  EmployeeDetail({
    required this.id,
    required this.name,
    required this.position,
    required this.branch,
    required this.district,
    required this.status,
    required this.performance,
    required this.completedOrders,
    required this.revenueGenerated,
    required this.joinDate,
  });

  factory EmployeeDetail.fromJson(Map<String, dynamic> json) {
    return EmployeeDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      branch: json['branch'] ?? '',
      district: json['district'] ?? '',
      status: json['status'] ?? 'active',
      performance: (json['performance'] ?? 0).toDouble(),
      completedOrders: json['completed_orders'] ?? 0,
      revenueGenerated: (json['revenue_generated'] ?? 0).toDouble(),
      joinDate: DateTime.parse(json['join_date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class PendingOrder {
  final String id;
  final String customerName;
  final String product;
  final int quantity;
  final double amount;
  final DateTime orderDate;
  final String branch;
  final String district;
  final String reason;
  final String priority;

  PendingOrder({
    required this.id,
    required this.customerName,
    required this.product,
    required this.quantity,
    required this.amount,
    required this.orderDate,
    required this.branch,
    required this.district,
    required this.reason,
    required this.priority,
  });

  factory PendingOrder.fromJson(Map<String, dynamic> json) {
    return PendingOrder(
      id: json['id'] ?? '',
      customerName: json['customer_name'] ?? '',
      product: json['product'] ?? '',
      quantity: json['quantity'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      orderDate: DateTime.parse(json['order_date'] ?? DateTime.now().toIso8601String()),
      branch: json['branch'] ?? '',
      district: json['district'] ?? '',
      reason: json['reason'] ?? '',
      priority: json['priority'] ?? 'medium',
    );
  }
}
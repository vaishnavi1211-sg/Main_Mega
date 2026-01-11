class OrderDetails {
  final String id;
  final String customerName;
  final String status;
  final double amount;
  final DateTime date;
  final String? products;
  final String? paymentMethod;

  OrderDetails({
    required this.id,
    required this.customerName,
    required this.status,
    required this.amount,
    required this.date,
    this.products,
    this.paymentMethod,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Unknown',
      status: json['status']?.toString() ?? 'pending',
      amount: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      products: json['feed_category']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
    );
  }
}

class EmployeeDetails {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final DateTime joinDate;
  final String role;
  final String? district;
  final int totalOrders;
  final double totalRevenue;

  EmployeeDetails({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.joinDate,
    required this.role,
    this.district,
    this.totalOrders = 0,
    this.totalRevenue = 0.0,
  });

  factory EmployeeDetails.fromJson(Map<String, dynamic> json) {
    return EmployeeDetails(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      joinDate: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      role: json['role']?.toString() ?? 'Employee',
      district: json['district']?.toString(),
      totalOrders: (json['total_orders'] as int?) ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
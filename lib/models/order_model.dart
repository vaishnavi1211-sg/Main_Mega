// lib/models/order_model.dart
class Order {
  final String id;
  final String? employeeId;
  final String customerName;
  final String customerMobile;
  final String customerAddress;
  final String feedCategory;
  final int bags;
  final int weightPerBag;
  final String weightUnit;
  final int totalWeight;
  final int pricePerBag;
  final int totalPrice;
  final String? remarks;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? orderNumber;

  Order({
    required this.id,
    this.employeeId,
    required this.customerName,
    required this.customerMobile,
    required this.customerAddress,
    required this.feedCategory,
    required this.bags,
    required this.weightPerBag,
    required this.weightUnit,
    required this.totalWeight,
    required this.pricePerBag,
    required this.totalPrice,
    this.remarks,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.orderNumber,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String?,
      customerName: json['customer_name'] as String,
      customerMobile: json['customer_mobile'] as String,
      customerAddress: json['customer_address'] as String,
      feedCategory: json['feed_category'] as String,
      bags: json['bags'] as int,
      weightPerBag: json['weight_per_bag'] as int,
      weightUnit: json['weight_unit'] as String,
      totalWeight: json['total_weight'] as int,
      pricePerBag: json['price_per_bag'] as int,
      totalPrice: json['total_price'] as int,
      remarks: json['remarks'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      orderNumber: json['order_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'customer_name': customerName,
      'customer_mobile': customerMobile,
      'customer_address': customerAddress,
      'feed_category': feedCategory,
      'bags': bags,
      'weight_per_bag': weightPerBag,
      'weight_unit': weightUnit,
      'total_weight': totalWeight,
      'price_per_bag': pricePerBag,
      'total_price': totalPrice,
      'remarks': remarks,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'order_number': orderNumber,
    };
  }
}
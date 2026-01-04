// lib/models/order_item_model.dart
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final int pricePerUnit;
  final int totalPrice;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      pricePerUnit: json['price_per_unit'] as int,
      totalPrice: json['total_price'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
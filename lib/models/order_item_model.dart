import 'package:flutter/material.dart';

class ProductionOrderItem {
  final String id;
  final String customerName;
  final String customerMobile;
  final String customerAddress;
  final String district; // Added district field
  final String productName;
  final int bags;
  final int weightPerBag;
  final String weightUnit;
  final int totalWeight;
  final int pricePerBag;
  final int totalPrice;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? employeeId;
  final String? remarks;

  ProductionOrderItem({
    required this.id,
    required this.customerName,
    required this.customerMobile,
    required this.customerAddress,
    required this.district, // Added district parameter
    required this.productName,
    required this.bags,
    required this.weightPerBag,
    required this.weightUnit,
    required this.totalWeight,
    required this.pricePerBag,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.employeeId,
    this.remarks,
  });

  factory ProductionOrderItem.fromMap(Map<String, dynamic> map) {
    return ProductionOrderItem(
      id: map['id'].toString(),
      customerName: map['customer_name']?.toString() ?? 'N/A',
      customerMobile: map['customer_mobile']?.toString() ?? '',
      customerAddress: map['customer_address']?.toString() ?? '',
      district: map['district']?.toString() ?? '', // Added district mapping
      productName: map['feed_category']?.toString() ?? 'N/A',
      bags: (map['bags'] ?? 0) as int,
      weightPerBag: (map['weight_per_bag'] ?? 0) as int,
      weightUnit: map['weight_unit']?.toString() ?? 'kg',
      totalWeight: (map['total_weight'] ?? 0) as int,
      pricePerBag: (map['price_per_bag'] ?? 0) as int,
      totalPrice: (map['total_price'] ?? 0) as int,
      status: (map['status'] ?? 'Pending')?.toString() ?? 'Pending',
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'].toString()) 
          : null,
      employeeId: map['employee_id']?.toString(),
      remarks: map['remarks']?.toString(),
    );
  }

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'packing':
        return 'Packing';
      case 'ready_for_dispatch':
        return 'Ready for Dispatch';
      case 'dispatched':
        return 'Dispatched';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get displayQuantity {
    return '$bags Bags';
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'packing':
        return Colors.blue;
      case 'ready_for_dispatch':
        return Colors.purple;
      case 'dispatched':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'packing':
        return Icons.inventory;
      case 'ready_for_dispatch':
        return Icons.local_shipping;
      case 'dispatched':
        return Icons.directions_car;
      case 'delivered':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }
}









// // lib/models/order_item_model.dart
// class OrderItem {
//   final String id;
//   final String orderId;
//   final String productId;
//   final int quantity;
//   final int pricePerUnit;
//   final int totalPrice;
//   final DateTime createdAt;

//   OrderItem({
//     required this.id,
//     required this.orderId,
//     required this.productId,
//     required this.quantity,
//     required this.pricePerUnit,
//     required this.totalPrice,
//     required this.createdAt,
//   });

//   factory OrderItem.fromJson(Map<String, dynamic> json) {
//     return OrderItem(
//       id: json['id'] as String,
//       orderId: json['order_id'] as String,
//       productId: json['product_id'] as String,
//       quantity: json['quantity'] as int,
//       pricePerUnit: json['price_per_unit'] as int,
//       totalPrice: json['total_price'] as int,
//       createdAt: DateTime.parse(json['created_at'] as String),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'order_id': orderId,
//       'product_id': productId,
//       'quantity': quantity,
//       'price_per_unit': pricePerUnit,
//       'total_price': totalPrice,
//       'created_at': createdAt.toIso8601String(),
//     };
//   }
// }
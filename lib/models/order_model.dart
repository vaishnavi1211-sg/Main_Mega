// models/order_model.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Order {
  final String id;
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
  final DateTime? updatedAt;
  final String? orderNumber;
  
  Order({
    required this.id,
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
    this.updatedAt,
    this.orderNumber,
  });
  
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerMobile: json['customer_mobile'] ?? '',
      customerAddress: json['customer_address'] ?? '',
      feedCategory: json['feed_category'] ?? '',
      bags: (json['bags'] ?? 0).toInt(),
      weightPerBag: (json['weight_per_bag'] ?? 0).toInt(),
      weightUnit: json['weight_unit'] ?? 'kg',
      totalWeight: (json['total_weight'] ?? 0).toInt(),
      pricePerBag: (json['price_per_bag'] ?? 0).toInt(),
      totalPrice: (json['total_price'] ?? 0).toInt(),
      remarks: json['remarks'],
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      orderNumber: json['order_number'],
    );
  }
  
  // Helper getters for UI
  String get displayStatus {
    switch (status) {
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
  
  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'packing':
        return Colors.blue;
      case 'ready_for_dispatch':
        return Colors.purple;
      case 'dispatched':
        return Colors.indigo;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData get statusIcon {
    switch (status) {
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
  
  String get displayQuantity => '$bags Bags';
  
  String get productName => feedCategory;
  
  String get formattedCreatedAt {
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
  }
  
  String get formattedUpdatedAt {
    return updatedAt != null 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(updatedAt!)
        : 'Never updated';
  }
}
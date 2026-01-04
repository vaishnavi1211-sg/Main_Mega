// lib/models/product_model.dart
class Product {
  final String id;
  final String name;
  final String category;
  final int pricePerBag;
  final int weightPerBag;
  final String weightUnit;
  final int stock;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerBag,
    required this.weightPerBag,
    this.weightUnit = 'kg',
    required this.stock,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      pricePerBag: json['price_per_bag'] as int,
      weightPerBag: json['weight_per_bag'] as int,
      weightUnit: json['weight_unit'] as String,
      stock: json['stock'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price_per_bag': pricePerBag,
      'weight_per_bag': weightPerBag,
      'weight_unit': weightUnit,
      'stock': stock,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
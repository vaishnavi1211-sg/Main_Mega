import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryItem {
  final String id;
  final String name;
  final String? nameHindi;
  final double weightPerBag; // Weight per bag in kg
  final String unit;
  final double pricePerBag; // Price per bag
  double bags; // Number of bags in stock
  final double minBagsStock; // Minimum bags in stock
  final String category;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.name,
    this.nameHindi,
    required this.weightPerBag,
    this.unit = 'kg',
    required this.pricePerBag,
    required this.bags,
    required this.minBagsStock,
    this.category = 'Animal Feed',
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      nameHindi: map['name_hindi'] as String?,
      weightPerBag: (map['weight_per_bag'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'kg',
      pricePerBag: (map['price_per_bag'] as num).toDouble(),
      bags: (map['bags'] as num).toDouble(),
      minBagsStock: (map['min_bags_stock'] as num).toDouble(),
      category: map['category'] as String? ?? 'Animal Feed',
      description: map['description'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'name_hindi': nameHindi,
      'weight_per_bag': weightPerBag,
      'unit': unit,
      'price_per_bag': pricePerBag,
      'bags': bags,
      'min_bags_stock': minBagsStock,
      'category': category,
      'description': description,
      'is_active': isActive,
    };
  }

  // Calculated properties
  double get tons => (bags * weightPerBag) / 1000; // Convert kg to tons
  double get stock => bags * weightPerBag; // Total weight in kg
  double get pricePerTon => (pricePerBag * 1000) / weightPerBag; // Price per ton
  bool get isLowStock => bags <= minBagsStock;
  double get totalValue => bags * pricePerBag;
  
  // Legacy properties for backward compatibility
  double get weight => weightPerBag;
  double get price => pricePerBag;
  double get minStock => minBagsStock;
  String get displayName => nameHindi != null ? '$name / $nameHindi' : name;
}

class InventoryProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<InventoryItem> _inventoryItems = [];
  bool _isLoading = false;
  String? _error;

  List<InventoryItem> get inventoryItems => _inventoryItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered items
  List<InventoryItem> get activeItems => 
      _inventoryItems.where((item) => item.isActive).toList();
  
  List<InventoryItem> get lowStockItems => 
      _inventoryItems.where((item) => item.isLowStock && item.isActive).toList();

  // Initialize provider
  InventoryProvider() {
    _loadInventory();
    _setupRealtimeSubscription();
  }

  // Load inventory from Supabase
  Future<void> _loadInventory() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('production_products')
          .select('*')
          .order('name', ascending: true);

      _inventoryItems = (response as List)
          .map((item) => InventoryItem.fromMap(item))
          .toList();
        } catch (e) {
      _error = 'Failed to load inventory: $e';
      print('Error loading inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set up realtime subscription
  void _setupRealtimeSubscription() {
    _supabase
        .from('production_products')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> updates) {
          for (final update in updates) {
            final index = _inventoryItems.indexWhere((item) => item.id == update['id']);
            
            if (index != -1) {
              _inventoryItems[index] = InventoryItem.fromMap(update);
            } else {
              _inventoryItems.add(InventoryItem.fromMap(update));
            }
          }
          notifyListeners();
        });
  }

  // Add new product
  Future<void> addProduct(InventoryItem product) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      
      final response = await _supabase
          .from('production_products')
          .insert({
            ...product.toMap(),
            'created_by': user?.id,
          })
          .select();

      if (response.isNotEmpty) {
        // Add log
        await _supabase.from('inventory_logs').insert({
          'product_id': response[0]['id'],
          'action': 'add',
          'new_value': product.toMap(),
          'performed_by': user?.id,
        });

        await _loadInventory(); // Reload to get the new item
      }
    } catch (e) {
      _error = 'Failed to add product: $e';
      print('Error adding product: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update product
  Future<void> updateProduct(String id, InventoryItem updatedProduct) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      final oldProduct = _inventoryItems.firstWhere((item) => item.id == id);

      await _supabase
          .from('production_products')
          .update(updatedProduct.toMap())
          .eq('id', id);

      // Add log
      await _supabase.from('inventory_logs').insert({
        'product_id': id,
        'action': 'update',
        'old_value': oldProduct.toMap(),
        'new_value': updatedProduct.toMap(),
        'performed_by': user?.id,
      });

      await _loadInventory();
    } catch (e) {
      _error = 'Failed to update product: $e';
      print('Error updating product: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete product (soft delete by setting isActive to false)
  Future<void> deleteProduct(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      final product = _inventoryItems.firstWhere((item) => item.id == id);

      await _supabase
          .from('production_products')
          .update({'is_active': false})
          .eq('id', id);

      // Add log
      await _supabase.from('inventory_logs').insert({
        'product_id': id,
        'action': 'delete',
        'old_value': product.toMap(),
        'performed_by': user?.id,
      });

      await _loadInventory();
    } catch (e) {
      _error = 'Failed to delete product: $e';
      print('Error deleting product: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update stock by bags
  Future<void> updateStock(String id, double newBags, {String? notes}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      final oldProduct = _inventoryItems.firstWhere((item) => item.id == id);
      final quantityChange = newBags - oldProduct.bags;

      await _supabase
          .from('production_products')
          .update({'bags': newBags})
          .eq('id', id);

      // Add log
      await _supabase.from('inventory_logs').insert({
        'product_id': id,
        'action': 'stock_update',
        'old_value': {'bags': oldProduct.bags},
        'new_value': {'bags': newBags},
        'quantity_change': quantityChange,
        'performed_by': user?.id,
      });

      await _loadInventory();
    } catch (e) {
      _error = 'Failed to update stock: $e';
      print('Error updating stock: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search products
  List<InventoryItem> searchProducts(String query) {
    if (query.isEmpty) return activeItems;
    
    return activeItems.where((item) {
      final name = item.name.toLowerCase();
      final hindiName = item.nameHindi?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      
      return name.contains(searchQuery) || 
             hindiName.contains(searchQuery) ||
             item.category.toLowerCase().contains(searchQuery);
    }).toList();
  }

  // Get inventory summary
  Map<String, dynamic> getInventorySummary() {
    final activeProducts = activeItems;
    final lowStock = lowStockItems.length;
    final totalProducts = activeProducts.length;
    final totalBags = activeProducts.fold(0.0, (sum, item) => sum + item.bags);
    final totalTons = activeProducts.fold(0.0, (sum, item) => sum + item.tons);
    final totalValue = activeProducts.fold(0.0, (sum, item) => sum + item.totalValue);
    
    return {
      'totalProducts': totalProducts,
      'lowStockItems': lowStock,
      'totalBags': totalBags,
      'totalTons': totalTons,
      'totalValue': totalValue,
    };
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadInventory();
  }
}
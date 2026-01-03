// lib/providers/production_orders_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductionOrderItem {
  final String id;
  final String customerName;
  final String customerMobile;
  final String customerAddress;
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
    print('ProductionOrderItem.fromMap: ${map['id']} - Status: ${map['status']}');
    return ProductionOrderItem(
      id: map['id'].toString(),
      customerName: map['customer_name']?.toString() ?? 'N/A',
      customerMobile: map['customer_mobile']?.toString() ?? '',
      customerAddress: map['customer_address']?.toString() ?? '',
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

class ProductionOrdersProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<ProductionOrderItem> _orders = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'all';

  List<ProductionOrderItem> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;

  List<ProductionOrderItem> get filteredOrders {
    switch (_filter) {
      case 'pending':
        return _orders.where((order) => order.status.toLowerCase() == 'pending').toList();
      case 'packing':
        return _orders.where((order) => order.status.toLowerCase() == 'packing').toList();
      case 'ready_for_dispatch':
        return _orders.where((order) => order.status.toLowerCase() == 'ready_for_dispatch').toList();
      case 'dispatched':
        return _orders.where((order) => order.status.toLowerCase() == 'dispatched').toList();
      case 'delivered':
        return _orders.where((order) => order.status.toLowerCase() == 'delivered').toList();
      case 'completed':
        return _orders.where((order) => order.status.toLowerCase() == 'completed').toList();
      case 'cancelled':
        return _orders.where((order) => order.status.toLowerCase() == 'cancelled').toList();
      default:
        return _orders;
    }
  }

  ProductionOrdersProvider() {
    print('🔄 ProductionOrdersProvider initialized');
    _loadOrders();
    _setupRealtimeSubscription();
  }

  Future<void> _loadOrders() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('📡 Loading ALL orders from emp_mar_orders table...');
      
      // Check current user
      final user = _supabase.auth.currentUser;
      print('👤 Current user: ${user?.email} (${user?.id})');
      print('👤 User role: ${user?.appMetadata?['role']}');
      
      // Fetch ALL orders without filtering by employee_id
      print('🔍 Query: SELECT * FROM emp_mar_orders ORDER BY created_at DESC');
      final response = await _supabase
          .from('emp_mar_orders')
          .select('*')
          .order('created_at', ascending: false);

      print('✅ Query successful');
      print('📊 Response type: ${response.runtimeType}');
      
      if (response is List) {
        print('📦 Found ${response.length} orders in total');
        
        if (response.isNotEmpty) {
          print('📋 First 3 orders:');
          for (int i = 0; i < (response.length > 3 ? 3 : response.length); i++) {
            final order = response[i];
            print('   ${i + 1}. ID: ${order['id']}, Customer: ${order['customer_name']}, Status: ${order['status']}');
          }
        } else {
          print('⚠️ No orders found in the table');
        }
        
        final ordersList = (response)
            .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item as Map<String, dynamic>))
            .toList();

        print('🎉 Successfully created ${ordersList.length} ProductionOrderItem objects');
        _orders = ordersList;
      } else {
        print('❌ Unexpected response type: $response');
        _orders = [];
      }
      
    } catch (e) {
      _error = 'Failed to load orders: $e';
      print('❌ Error loading orders: $e');
      print('📝 Stack trace: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('🏁 _loadOrders completed. Total orders: ${_orders.length}');
    }
  }

  void _setupRealtimeSubscription() {
    print('🔔 Setting up realtime subscription...');
    try {
      _supabase
          .from('emp_mar_orders')
          .stream(primaryKey: ['id'])
          .listen(
            (List<Map<String, dynamic>> updates) {
              print('🔄 Realtime update: ${updates.length} order(s) changed');
              _handleOrderUpdates(updates);
            },
            onError: (error) {
              print('❌ Realtime subscription error: $error');
            },
          );
      print('✅ Realtime subscription established');
    } catch (e) {
      print('❌ Failed to set up realtime subscription: $e');
    }
  }

  void _handleOrderUpdates(List<Map<String, dynamic>> updates) {
    print('🔄 Processing ${updates.length} realtime updates');
    for (final update in updates) {
      final orderId = update['id'].toString();
      final index = _orders.indexWhere((order) => order.id == orderId);
      
      if (index != -1) {
        print('📝 Updating existing order: $orderId');
        _orders[index] = ProductionOrderItem.fromMap(update);
      } else {
        print('➕ Adding new order: $orderId');
        _orders.insert(0, ProductionOrderItem.fromMap(update));
      }
    }
    
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
    print('✅ Orders updated. Total: ${_orders.length}');
  }

  Future<void> updateOrderStatus(ProductionOrderItem order, String newStatus) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔄 Updating order ${order.id} status from "${order.status}" to "$newStatus"');
      
      await _supabase
          .from('emp_mar_orders')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', order.id);
      
      print('✅ Order status update successful');
      
    } catch (e) {
      _error = 'Failed to update order status: $e';
      print('❌ Error updating order status: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBulkOrderStatus(List<String> orderIds, String newStatus) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔄 Bulk updating ${orderIds.length} orders to status: $newStatus');
      
      // Update orders one by one
      for (final orderId in orderIds) {
        print('   📝 Updating order: $orderId');
        await _supabase
            .from('emp_mar_orders')
            .update({
              'status': newStatus,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId);
      }

      print('✅ Bulk update complete, reloading orders...');
      await _loadOrders();
      
    } catch (e) {
      _error = 'Failed to update bulk order status: $e';
      print('❌ Error updating bulk order status: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> getNextStatusOptions(ProductionOrderItem order) {
    // ALL status options available for any current status
    return ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled'];
  }

  void setFilter(String filter) {
    print('🔍 Setting filter to: $filter');
    _filter = filter;
    notifyListeners();
  }

  Future<void> refresh() async {
    print('🔄 Manual refresh triggered');
    await _loadOrders();
  }

  Map<String, int> getStatistics() {
    final stats = {
      'total': _orders.length,
      'pending': _orders.where((order) => order.status.toLowerCase() == 'pending').length,
      'packing': _orders.where((order) => order.status.toLowerCase() == 'packing').length,
      'ready_for_dispatch': _orders.where((order) => order.status.toLowerCase() == 'ready_for_dispatch').length,
      'dispatched': _orders.where((order) => order.status.toLowerCase() == 'dispatched').length,
      'delivered': _orders.where((order) => order.status.toLowerCase() == 'delivered').length,
      'completed': _orders.where((order) => order.status.toLowerCase() == 'completed').length,
      'cancelled': _orders.where((order) => order.status.toLowerCase() == 'cancelled').length,
    };
    
    print('📊 Statistics calculated: $stats');
    return stats;
  }
}






// // lib/providers/orders_provider.dart
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class OrderItem {
//   final String id;
//   final String orderType; // 'employee' or 'manager'
//   final String customerName;
//   final String? customerMobile;
//   final String? customerAddress;
//   final String? district;
//   final String? taluka;
//   final String? enterpriseName;
//   final String productName;
//   final double quantity; // Tons for manager, Bags for employee
//   final String unit; // 'tons' or 'bags'
//   final double? weightPerBag;
//   final double? pricePerBag;
//   final double? totalWeight;
//   final double? totalPrice;
//   final String status;
//   final DateTime createdAt;
//   final DateTime? updatedAt;
//   final String? managerName;
//   final String? employeeId;
//   final String? remarks;

//   OrderItem({
//     required this.id,
//     required this.orderType,
//     required this.customerName,
//     this.customerMobile,
//     this.customerAddress,
//     this.district,
//     this.taluka,
//     this.enterpriseName,
//     required this.productName,
//     required this.quantity,
//     required this.unit,
//     this.weightPerBag,
//     this.pricePerBag,
//     this.totalWeight,
//     this.totalPrice,
//     required this.status,
//     required this.createdAt,
//     this.updatedAt,
//     this.managerName,
//     this.employeeId,
//     this.remarks,
//   });

//   factory OrderItem.fromMap(Map<String, dynamic> map) {
//     final isManagerOrder = map.containsKey('quantity_tons');
    
//     return OrderItem(
//       id: map['id'].toString(),
//       orderType: isManagerOrder ? 'manager' : 'employee',
//       customerName: map['customer_name'] ?? map['manager_name'] ?? 'N/A',
//       customerMobile: map['customer_mobile'],
//       customerAddress: map['customer_address'],
//       district: map['district'],
//       taluka: map['taluka'],
//       enterpriseName: map['enterprise_name'],
//       productName: isManagerOrder 
//           ? map['product_name'] 
//           : map['feed_category'],
//       quantity: isManagerOrder 
//           ? (map['quantity_tons'] as num).toDouble()
//           : (map['bags'] as num).toDouble(),
//       unit: isManagerOrder ? 'tons' : 'bags',
//       weightPerBag: isManagerOrder ? null : (map['weight_per_bag'] as num?)?.toDouble(),
//       pricePerBag: isManagerOrder ? null : (map['price_per_bag'] as num?)?.toDouble(),
//       totalWeight: isManagerOrder ? null : (map['total_weight'] as num?)?.toDouble(),
//       totalPrice: isManagerOrder ? null : (map['total_price'] as num?)?.toDouble(),
//       status: (isManagerOrder ? map['order_status'] : map['status']) ?? 'Pending',
//       createdAt: DateTime.parse(map['created_at'] as String),
//       updatedAt: map['updated_at'] != null 
//           ? DateTime.parse(map['updated_at'] as String) 
//           : null,
//       managerName: map['manager_name'],
//       employeeId: map['employee_id']?.toString(),
//       remarks: map['remarks'],
//     );
//   }

//   String get displayStatus {
//     switch (status.toLowerCase()) {
//       case 'in_progress':
//         return 'In Progress';
//       case 'packing':
//         return 'Packing';
//       case 'ready_for_dispatch':
//         return 'Ready for Dispatch';
//       case 'dispatched':
//         return 'Dispatched';
//       case 'delivered':
//         return 'Delivered';
//       default:
//         return status;
//     }
//   }

//   String get displayQuantity {
//     if (unit == 'tons') {
//       return '${quantity.toStringAsFixed(1)} Tons';
//     } else {
//       return '${quantity.toInt()} Bags';
//     }
//   }

//   Color get statusColor {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Colors.orange;
//       case 'in_progress':
//       case 'packing':
//         return Colors.blue;
//       case 'ready_for_dispatch':
//         return Colors.purple;
//       case 'dispatched':
//         return Colors.indigo;
//       case 'delivered':
//       case 'completed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData get statusIcon {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Icons.pending_actions;
//       case 'in_progress':
//         return Icons.build;
//       case 'packing':
//         return Icons.inventory;
//       case 'ready_for_dispatch':
//         return Icons.local_shipping;
//       case 'dispatched':
//         return Icons.directions_car;
//       case 'delivered':
//         return Icons.check_circle;
//       case 'completed':
//         return Icons.done_all;
//       case 'cancelled':
//         return Icons.cancel;
//       default:
//         return Icons.receipt;
//     }
//   }
// }

// class OrdersProvider extends ChangeNotifier {
//   final SupabaseClient _supabase = Supabase.instance.client;
  
//   List<OrderItem> _orders = [];
//   bool _isLoading = false;
//   String? _error;
//   String _filter = 'all'; // all, pending, in_progress, completed

//   List<OrderItem> get orders => _orders;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   String get filter => _filter;

//   // Filtered orders
//   List<OrderItem> get filteredOrders {
//     switch (_filter) {
//       case 'pending':
//         return _orders.where((order) => 
//           order.status.toLowerCase() == 'pending').toList();
//       case 'in_progress':
//         return _orders.where((order) => 
//           order.status.toLowerCase() == 'in_progress' ||
//           order.status.toLowerCase() == 'packing' ||
//           order.status.toLowerCase() == 'ready_for_dispatch').toList();
//       case 'completed':
//         return _orders.where((order) => 
//           order.status.toLowerCase() == 'completed' ||
//           order.status.toLowerCase() == 'delivered').toList();
//       case 'dispatched':
//         return _orders.where((order) => 
//           order.status.toLowerCase() == 'dispatched').toList();
//       case 'cancelled':
//         return _orders.where((order) => 
//           order.status.toLowerCase() == 'cancelled').toList();
//       default:
//         return _orders;
//     }
//   }

//   // Initialize provider
//   OrdersProvider() {
//     _loadOrders();
//     _setupRealtimeSubscription();
//   }

//   // Load orders from Supabase
//   Future<void> _loadOrders() async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();

//       // Fetch employee orders
//       final empResponse = await _supabase
//           .from('emp_orders')
//           .select('*')
//           .order('created_at', ascending: false);

//       // Fetch manager orders
//       final managerResponse = await _supabase
//           .from('manager_orders')
//           .select('*')
//           .order('created_at', ascending: false);

//       // Combine and convert to OrderItem objects
//       final allOrders = [
//         ...(empResponse as List).map((item) => OrderItem.fromMap(item)),
//         ...(managerResponse as List).map((item) => OrderItem.fromMap(item)),
//       ];

//       // Sort by creation date (newest first)
//       allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

//       _orders = allOrders;
//     } catch (e) {
//       _error = 'Failed to load orders: $e';
//       print('Error loading orders: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Set up realtime subscription
//   void _setupRealtimeSubscription() {
//     // Subscribe to emp_orders table
//     _supabase
//         .from('emp_orders')
//         .stream(primaryKey: ['id'])
//         .listen((List<Map<String, dynamic>> updates) {
//           _handleOrderUpdates(updates, 'employee');
//         });

//     // Subscribe to manager_orders table
//     _supabase
//         .from('manager_orders')
//         .stream(primaryKey: ['id'])
//         .listen((List<Map<String, dynamic>> updates) {
//           _handleOrderUpdates(updates, 'manager');
//         });
//   }

//   void _handleOrderUpdates(List<Map<String, dynamic>> updates, String orderType) {
//     for (final update in updates) {
//       final orderId = update['id'].toString();
//       final index = _orders.indexWhere((order) => order.id == orderId);
      
//       if (index != -1) {
//         // Update existing order
//         _orders[index] = OrderItem.fromMap(update);
//       } else {
//         // Add new order
//         _orders.insert(0, OrderItem.fromMap(update));
//       }
//     }
    
//     // Re-sort by creation date
//     _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//     notifyListeners();
//   }

//   // Update order status
//   Future<void> updateOrderStatus(OrderItem order, String newStatus) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       final isManagerOrder = order.orderType == 'manager';
//       final tableName = isManagerOrder ? 'manager_orders' : 'emp_orders';
//       final statusField = isManagerOrder ? 'order_status' : 'status';

//       await _supabase
//           .from(tableName)
//           .update({
//             statusField: newStatus,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', order.id);

//       // The realtime subscription will automatically update the UI
      
//     } catch (e) {
//       _error = 'Failed to update order status: $e';
//       print('Error updating order status: $e');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Get next status options based on current status
//   List<String> getNextStatusOptions(OrderItem order) {
//     final currentStatus = order.status.toLowerCase();
//     final isManagerOrder = order.orderType == 'manager';
    
//     if (isManagerOrder) {
//       switch (currentStatus) {
//         case 'pending':
//           return ['In Progress', 'Completed', 'Cancelled'];
//         case 'in_progress':
//           return ['Completed', 'Cancelled'];
//         case 'completed':
//           return ['In Progress', 'Cancelled'];
//         case 'cancelled':
//           return ['Pending', 'In Progress'];
//         default:
//           return ['Pending', 'In Progress', 'Completed', 'Cancelled'];
//       }
//     } else {
//       // Employee orders workflow
//       switch (currentStatus) {
//         case 'pending':
//           return ['Packing', 'Cancelled'];
//         case 'packing':
//           return ['Ready for Dispatch', 'Cancelled'];
//         case 'ready_for_dispatch':
//           return ['Dispatched', 'Cancelled'];
//         case 'dispatched':
//           return ['Delivered', 'Cancelled'];
//         case 'delivered':
//           return ['Completed', 'Dispatched'];
//         case 'completed':
//           return ['Delivered', 'Cancelled'];
//         case 'cancelled':
//           return ['Pending', 'Packing'];
//         default:
//           return ['Pending', 'Packing', 'Ready for Dispatch', 'Dispatched', 'Delivered', 'Completed', 'Cancelled'];
//       }
//     }
//   }

//   // Set filter
//   void setFilter(String filter) {
//     _filter = filter;
//     notifyListeners();
//   }

//   // Refresh data
//   Future<void> refresh() async {
//     await _loadOrders();
//   }

//   // Get statistics
//   Map<String, int> getStatistics() {
//     return {
//       'total': _orders.length,
//       'pending': _orders.where((order) => order.status.toLowerCase() == 'pending').length,
//       'in_progress': _orders.where((order) => 
//         order.status.toLowerCase() == 'in_progress' ||
//         order.status.toLowerCase() == 'packing' ||
//         order.status.toLowerCase() == 'ready_for_dispatch').length,
//       'dispatched': _orders.where((order) => order.status.toLowerCase() == 'dispatched').length,
//       'completed': _orders.where((order) => 
//         order.status.toLowerCase() == 'completed' ||
//         order.status.toLowerCase() == 'delivered').length,
//       'cancelled': _orders.where((order) => order.status.toLowerCase() == 'cancelled').length,
//     };
//   }
// }
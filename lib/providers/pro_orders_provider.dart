import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mega_pro/models/order_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductionOrdersProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<ProductionOrderItem> _orders = [];
  bool _isLoading = false;
  bool _isQuickLoading = false;
  String? _error;
  String _filter = 'all';
  
  // Pagination variables
  bool _hasMoreData = true;
  int _page = 0;
  int _limit = 20;
  bool _initialLoadComplete = false;
  bool _isLoadingMore = false;
  StreamSubscription? _realtimeSubscription;
  
  // Track pending updates to prevent realtime conflicts
  final Set<String> _pendingUpdates = {};
  
  // ========================
  // AUTO NOTIFICATION SETTINGS
  // ========================
  bool _autoSendWhatsApp = true;
  bool _autoSendEmail = true;
  
  // Callback for sending notifications
  Function(Map<String, dynamic>, String, {String? notes})? _onSendWhatsAppNotification;
  Function(Map<String, dynamic>, String, {String? notes})? _onSendEmailNotification;

  // Getters
  List<ProductionOrderItem> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get isQuickLoading => _isQuickLoading;
  String? get error => _error;
  String get filter => _filter;
  bool get hasMoreData => _hasMoreData;
  bool get initialLoadComplete => _initialLoadComplete;
  bool get autoSendWhatsApp => _autoSendWhatsApp;
  bool get autoSendEmail => _autoSendEmail;

  List<ProductionOrderItem> get filteredOrders {
    if (_filter == 'all') {
      return _orders;
    }
    return _orders.where((order) => 
      order.status.toLowerCase() == _filter.toLowerCase()
    ).toList();
  }

  List<ProductionOrderItem> get completedOrders {
    return _orders.where((order) => order.status.toLowerCase() == 'completed').toList();
  }

  ProductionOrdersProvider() {
    print('🔄 ProductionOrdersProvider initialized');
    _initializeData();
    _setupRealtimeSubscription();
  }

  void setAutoSendWhatsApp(bool value) {
    _autoSendWhatsApp = value;
    notifyListeners();
    print('📱 Auto WhatsApp notifications: $_autoSendWhatsApp');
  }
  
  void setAutoSendEmail(bool value) {
    _autoSendEmail = value;
    notifyListeners();
    print('📧 Auto Email notifications: $_autoSendEmail');
  }
  
  void setNotificationCallbacks({
    Function(Map<String, dynamic>, String, {String? notes})? onWhatsApp,
    Function(Map<String, dynamic>, String, {String? notes})? onEmail,
  }) {
    _onSendWhatsAppNotification = onWhatsApp;
    _onSendEmailNotification = onEmail;
    print('✅ Notification callbacks registered');
    print('   WhatsApp callback exists: ${onWhatsApp != null}');
    print('   Email callback exists: ${onEmail != null}');
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _quickLoad();
    await _loadOrders();
  }

  Future<void> _quickLoad() async {
    if (_initialLoadComplete) return;
    
    try {
      _isQuickLoading = true;
      _error = null;
      notifyListeners();

      print('⚡ Quick loading recent orders...');
      
      final response = await _supabase
          .from('emp_mar_orders')
          .select('id, order_number, status, customer_name, customer_email, customer_mobile, customer_address, district, feed_category, bags, weight_per_bag, weight_unit, total_weight, price_per_bag, total_price, remarks, tracking_id, tracking_token, created_at, updated_at')
          .order('created_at', ascending: false)
          .limit(10);

      print('✅ Quick load successful, found ${response.length} orders');
      
      if (response.isNotEmpty) {
        _orders = (response as List)
            .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item))
            .toList();
        notifyListeners();
      }
      
    } catch (e) {
      _error = 'Failed to load orders: $e';
      print('❌ Quick load error: $e');
    } finally {
      _isQuickLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadOrders() async {
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      notifyListeners();

      print('📡 Loading orders with pagination (page $_page)...');
      
      final response = await _supabase
          .from('emp_mar_orders')
          .select()
          .order('created_at', ascending: false)
          .range(_page * _limit, (_page + 1) * _limit - 1);

      print('✅ Query successful, found ${response.length} orders');
      
      if (response.isNotEmpty) {
        final ordersList = (response as List)
            .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item))
            .toList();
        
        if (_page == 0) {
          _orders = ordersList;
        } else {
          _orders.addAll(ordersList);
        }
        
        _hasMoreData = ordersList.length == _limit;
        _initialLoadComplete = true;
        notifyListeners();
      } else {
        _hasMoreData = false;
      }
          
    } catch (e) {
      _error = 'Failed to load orders: $e';
      print('❌ Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMoreData || _isLoading || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    await _loadOrders();
    _isLoadingMore = false;
  }

  Future<void> refresh() async {
    print('🔄 Manual refresh triggered');
    _page = 0;
    _hasMoreData = true;
    _initialLoadComplete = false;
    _orders.clear();
    _error = null;
    notifyListeners();
    await _quickLoad();
    await _loadOrders();
  }

  void _setupRealtimeSubscription() {
    print('🔔 Setting up realtime subscription...');
    try {
      _realtimeSubscription = _supabase
          .from('emp_mar_orders')
          .stream(primaryKey: ['id'])
          .listen(
            (List<Map<String, dynamic>> updates) {
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
    bool hasChanges = false;
    for (final update in updates) {
      try {
        final updatedOrder = ProductionOrderItem.fromMap(update);
        final index = _orders.indexWhere((order) => order.id == updatedOrder.id);
        if (index != -1) {
          if (_pendingUpdates.contains(updatedOrder.id)) {
            _pendingUpdates.remove(updatedOrder.id);
            continue;
          }
          _orders[index] = updatedOrder;
          hasChanges = true;
        } else {
          _orders.insert(0, updatedOrder);
          hasChanges = true;
        }
      } catch (e) {
        print('❌ Error processing update: $e');
      }
    }
    if (hasChanges) {
      notifyListeners();
    }
  }

  Future<void> _sendAutoStatusUpdateNotification(ProductionOrderItem order, String newStatus, {String? notes}) async {
    print('🔔 ========== AUTO NOTIFICATION TRIGGERED ==========');
    print('📦 Order: ${order.orderNumber}');
    print('📱 WhatsApp enabled: $_autoSendWhatsApp');
    print('📧 Email enabled: $_autoSendEmail');
    print('👤 Customer: ${order.customerName}');
    print('📞 Mobile: ${order.customerMobile}');
    print('✉️ Email: ${order.customerEmail}');
    print('🔄 New Status: $newStatus');
    print('📞 WhatsApp callback exists: ${_onSendWhatsAppNotification != null}');
    print('✉️ Email callback exists: ${_onSendEmailNotification != null}');
    
    try {
      final orderData = {
        'id': order.id,
        'order_number': order.orderNumber,
        'customer_name': order.customerName,
        'customer_mobile': order.customerMobile,
        'customer_email': order.customerEmail,
        'customer_address': order.customerAddress,
        'district': order.district,
        'feed_category': order.feedCategory,
        'bags': order.bags,
        'weight_per_bag': order.weightPerBag,
        'weight_unit': order.weightUnit,
        'total_weight': order.totalWeight,
        'price_per_bag': order.pricePerBag,
        'total_price': order.totalPrice,
        'remarks': order.remarks,
        'status': newStatus,
        'tracking_id': order.trackingId,
        'tracking_token': order.trackingToken,
        'created_at': order.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (_autoSendWhatsApp && _onSendWhatsAppNotification != null && order.customerMobile.isNotEmpty) {
        try {
          await _onSendWhatsAppNotification!(orderData, newStatus, notes: notes);
          print('✅ WhatsApp notification sent successfully!');
        } catch (e) {
          print('❌ WhatsApp error: $e');
        }
      } else {
        print('⚠️ WhatsApp not sending: enabled=$_autoSendWhatsApp, callback=${_onSendWhatsAppNotification != null}, hasMobile=${order.customerMobile.isNotEmpty}');
      }
      
      if (_autoSendEmail && _onSendEmailNotification != null && order.customerEmail.isNotEmpty) {
        try {
          await _onSendEmailNotification!(orderData, newStatus, notes: notes);
          print('✅ Email notification sent successfully!');
        } catch (e) {
          print('❌ Email error: $e');
        }
      } else {
        print('⚠️ Email not sending: enabled=$_autoSendEmail, callback=${_onSendEmailNotification != null}, hasEmail=${order.customerEmail.isNotEmpty}');
      }
      
      print('🔔 ========== AUTO NOTIFICATION COMPLETE ==========');
    } catch (e) {
      print('❌ Error in auto-notification: $e');
    }
  }

  Future<void> updateOrderStatus(ProductionOrderItem order, String newStatus, {String? notes}) async {
    print('🔴🔴🔴 UPDATE ORDER STATUS CALLED! 🔴🔴🔴');
    print('   Order ID: ${order.id}');
    print('   New Status: $newStatus');
    
    if (order.status.toLowerCase() == newStatus.toLowerCase()) {
      print('⚠️ Status is already $newStatus, skipping update');
      return;
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String dbStatus = newStatus.toLowerCase().trim();
      final allowedStatuses = ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled'];
      if (!allowedStatuses.contains(dbStatus)) {
        throw Exception('Invalid status: $dbStatus');
      }
      
      _pendingUpdates.add(order.id);
      
      final response = await _supabase
          .from('emp_mar_orders')
          .update({
            'status': dbStatus,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', order.id)
          .select();

      print('✅ Order status update successful');
      
      if (response.isNotEmpty) {
        final verifiedOrder = ProductionOrderItem.fromMap(response.first);
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = verifiedOrder;
          notifyListeners();
          print('✅ Local order updated and verified');
        }
        
        print('📢 Triggering auto-notification for status change...');
        await _sendAutoStatusUpdateNotification(verifiedOrder, newStatus, notes: notes);
      }
      
    } catch (e) {
      _error = 'Failed to update order status: $e';
      print('❌ Error updating order status: $e');
      rethrow;
    } finally {
      _pendingUpdates.remove(order.id);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBulkOrderStatus(List<String> orderIds, String newStatus, {String? notes}) async {
    if (orderIds.isEmpty) return;
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 Bulk updating ${orderIds.length} orders to status: $newStatus');
      
      final validIds = orderIds.where((id) => id.isNotEmpty && id != 'null').toList();
      if (validIds.isEmpty) {
        throw Exception('No valid order IDs provided');
      }
      
      String dbStatus = newStatus.toLowerCase().trim();
      final allowedStatuses = ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled'];
      if (!allowedStatuses.contains(dbStatus)) {
        throw Exception('Invalid status: $dbStatus');
      }
      
      _pendingUpdates.addAll(validIds);
      
      int successCount = 0;
      List<String> failedIds = [];
      List<ProductionOrderItem> updatedOrders = [];
      
      for (final orderId in validIds) {
        try {
          final response = await _supabase
              .from('emp_mar_orders')
              .update({
                'status': dbStatus,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', orderId)
              .select();
          
          if (response.isNotEmpty) {
            updatedOrders.add(ProductionOrderItem.fromMap(response.first));
            successCount++;
            print('✅ Updated order: $orderId');
          } else {
            failedIds.add(orderId);
          }
        } catch (e) {
          failedIds.add(orderId);
          print('❌ Failed to update order $orderId: $e');
        }
      }

      print('✅ Bulk update complete: $successCount/${validIds.length} orders updated');
      
      for (final updatedOrder in updatedOrders) {
        final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }
      }
      
      notifyListeners();
      
      print('📢 Triggering auto-notifications for $successCount orders...');
      for (final updatedOrder in updatedOrders) {
        await _sendAutoStatusUpdateNotification(updatedOrder, newStatus, notes: notes);
      }
      
      if (failedIds.isNotEmpty) {
        throw Exception('Failed to update ${failedIds.length} orders: $failedIds');
      }
      
    } catch (e) {
      _error = 'Failed to update bulk order status: $e';
      print('❌ Error updating bulk order status: $e');
      rethrow;
    } finally {
      _pendingUpdates.clear();
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> getNextStatusOptions(ProductionOrderItem order) {
    final currentStatus = order.status.toLowerCase();
    final allStatuses = ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled'];
    return allStatuses.where((status) => status != currentStatus).toList();
  }

  void setFilter(String filter) {
    print('🔍 Setting filter to: $filter');
    _filter = filter;
    notifyListeners();
  }

  Map<String, int> getStatistics() {
    return {
      'total': _orders.length,
      'pending': _orders.where((order) => order.status.toLowerCase() == 'pending').length,
      'packing': _orders.where((order) => order.status.toLowerCase() == 'packing').length,
      'ready_for_dispatch': _orders.where((order) => order.status.toLowerCase() == 'ready_for_dispatch').length,
      'dispatched': _orders.where((order) => order.status.toLowerCase() == 'dispatched').length,
      'delivered': _orders.where((order) => order.status.toLowerCase() == 'delivered').length,
      'completed': _orders.where((order) => order.status.toLowerCase() == 'completed').length,
      'cancelled': _orders.where((order) => order.status.toLowerCase() == 'cancelled').length,
    };
  }

  double getMonthlyRevenue() {
    final today = DateTime.now();
    final monthStart = DateTime(today.year, today.month, 1);
    double revenue = 0.0;
    for (var order in completedOrders) {
      if (order.createdAt.isAfter(monthStart) && order.createdAt.isBefore(today.add(const Duration(days: 1)))) {
        revenue += order.totalPrice.toDouble();
      }
    }
    return revenue;
  }

  double getRevenueForDateRange(DateTime startDate, DateTime endDate) {
    double revenue = 0.0;
    for (var order in completedOrders) {
      if (order.createdAt.isAfter(startDate) && order.createdAt.isBefore(endDate.add(const Duration(days: 1)))) {
        revenue += order.totalPrice.toDouble();
      }
    }
    return revenue;
  }

  List<ProductionOrderItem> getCompletedOrdersForDashboard() => completedOrders;
  List<ProductionOrderItem> getRecentCompletedOrders({int limit = 5}) => completedOrders.take(limit).toList();
  
  Map<DateTime, double> getDailyRevenueSummary() {
    final Map<DateTime, double> dailyRevenue = {};
    for (var order in completedOrders) {
      final date = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
      dailyRevenue[date] = (dailyRevenue[date] ?? 0) + order.totalPrice.toDouble();
    }
    return dailyRevenue;
  }

  Map<String, double> getProductRevenueSummary() {
    final Map<String, double> productRevenue = {};
    for (var order in completedOrders) {
      productRevenue[order.productName] = (productRevenue[order.productName] ?? 0) + order.totalPrice.toDouble();
    }
    return productRevenue;
  }
}






















// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/order_item_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ProductionOrdersProvider extends ChangeNotifier {
//   final SupabaseClient _supabase = Supabase.instance.client;
  
//   List<ProductionOrderItem> _orders = [];
//   bool _isLoading = false;
//   bool _isQuickLoading = false;
//   String? _error;
//   String _filter = 'all';
  
//   // Pagination variables
//   bool _hasMoreData = true;
//   int _page = 0;
//   int _limit = 20;
//   bool _initialLoadComplete = false;
//   bool _isLoadingMore = false;
//   StreamSubscription? _realtimeSubscription;
  
//   // Track pending updates to prevent realtime conflicts
//   final Set<String> _pendingUpdates = {};

//   List<ProductionOrderItem> get orders => _orders;
//   bool get isLoading => _isLoading;
//   bool get isQuickLoading => _isQuickLoading;
//   String? get error => _error;
//   String get filter => _filter;
//   bool get hasMoreData => _hasMoreData;
//   bool get initialLoadComplete => _initialLoadComplete;

//   List<ProductionOrderItem> get filteredOrders {
//     if (_filter == 'all') {
//       return _orders;
//     }
//     return _orders.where((order) => 
//       order.status.toLowerCase() == _filter.toLowerCase()
//     ).toList();
//   }

//   List<ProductionOrderItem> get completedOrders {
//     return _orders.where((order) => order.status.toLowerCase() == 'completed').toList();
//   }

//   ProductionOrdersProvider() {
//     print('🔄 ProductionOrdersProvider initialized');
//     _initializeData();
//     _setupRealtimeSubscription();
//   }

//   @override
//   void dispose() {
//     _realtimeSubscription?.cancel();
//     super.dispose();
//   }

//   Future<void> _initializeData() async {
//     await _quickLoad();
//     await _loadOrders();
//   }

//   Future<void> _quickLoad() async {
//     if (_initialLoadComplete) return;
    
//     try {
//       _isQuickLoading = true;
//       _error = null;
//       notifyListeners();

//       print('⚡ Quick loading recent orders...');
      
//       final response = await _supabase
//           .from('emp_mar_orders')
//           .select('id, order_number, status, customer_name, total_price, created_at, bags, feed_category, district')
//           .order('created_at', ascending: false)
//           .limit(10);

//       print('✅ Quick load successful, found ${response.length} orders');
      
//       if (response.isNotEmpty) {
//         _orders = (response as List)
//             .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item))
//             .toList();
//         notifyListeners();
//       }
      
//     } catch (e, stackTrace) {
//       _error = 'Failed to load orders: $e';
//       print('❌ Quick load error: $e');
//       print('❌ Stack trace: $stackTrace');
//     } finally {
//       _isQuickLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _loadOrders() async {
//     if (_isLoading) return;
    
//     try {
//       _isLoading = true;
//       notifyListeners();

//       print('📡 Loading orders with pagination (page $_page)...');
      
//       final response = await _supabase
//           .from('emp_mar_orders')
//           .select()
//           .order('created_at', ascending: false)
//           .range(_page * _limit, (_page + 1) * _limit - 1);

//       print('✅ Query successful, found ${response.length} orders');
      
//       if (response.isNotEmpty) {
//         final ordersList = (response as List)
//             .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item))
//             .toList();
        
//         if (_page == 0) {
//           _orders = ordersList;
//         } else {
//           _orders.addAll(ordersList);
//         }
        
//         _hasMoreData = ordersList.length == _limit;
//         _initialLoadComplete = true;
//         notifyListeners();
//       } else {
//         _hasMoreData = false;
//       }
          
//     } catch (e, stackTrace) {
//       _error = 'Failed to load orders: $e';
//       print('❌ Error loading orders: $e');
//       print('❌ Stack trace: $stackTrace');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//       print('🏁 _loadOrders completed. Total orders: ${_orders.length}');
//     }
//   }

//   Future<void> loadMore() async {
//     if (!_hasMoreData || _isLoading || _isLoadingMore) return;
    
//     _isLoadingMore = true;
//     _page++;
//     await _loadOrders();
//     _isLoadingMore = false;
//   }

//   Future<void> refresh() async {
//     print('🔄 Manual refresh triggered');
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     _orders.clear();
//     _error = null;
//     notifyListeners();
    
//     await _quickLoad();
//     await _loadOrders();
//   }

//   void _setupRealtimeSubscription() {
//     print('🔔 Setting up realtime subscription...');
//     try {
//       _realtimeSubscription = _supabase
//           .from('emp_mar_orders')
//           .stream(primaryKey: ['id'])
//           .listen(
//             (List<Map<String, dynamic>> updates) {
//               print('🔄 Realtime update: ${updates.length} order(s) changed');
//               _handleOrderUpdates(updates);
//             },
//             onError: (error) {
//               print('❌ Realtime subscription error: $error');
//             },
//           );
//       print('✅ Realtime subscription established');
//     } catch (e) {
//       print('❌ Failed to set up realtime subscription: $e');
//     }
//   }

//   // FIXED: Improved realtime handler with pending update tracking
//   void _handleOrderUpdates(List<Map<String, dynamic>> updates) {
//     bool hasChanges = false;
    
//     for (final update in updates) {
//       try {
//         final updatedOrder = ProductionOrderItem.fromMap(update);
//         final index = _orders.indexWhere((order) => order.id == updatedOrder.id);

//         if (index != -1) {
//           // Check if this update is from our pending operation
//           if (_pendingUpdates.contains(updatedOrder.id)) {
//             print('📝 Ignoring self-update for order: ${updatedOrder.id}');
//             _pendingUpdates.remove(updatedOrder.id);
//             continue;
//           }
          
//           print('📝 Updating existing order: ${updatedOrder.id}');
//           _orders[index] = updatedOrder;
//           hasChanges = true;
//         } else {
//           print('➕ Adding new order: ${updatedOrder.id}');
//           _orders.insert(0, updatedOrder);
//           hasChanges = true;
//         }
//       } catch (e, stackTrace) {
//         print('❌ Error processing update: $e');
//         print('❌ Stack trace: $stackTrace');
//       }
//     }

//     if (hasChanges) {
//       notifyListeners();
//     }
//     print('✅ Orders updated. Total: ${_orders.length}');
//   }

//   // FIXED: Single status update with verification
//   Future<void> updateOrderStatus(ProductionOrderItem order, String newStatus) async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();

//       print('🔄 Updating order ${order.id} status from "${order.status}" to "$newStatus"');
      
//       String dbStatus = newStatus.toLowerCase().trim();
      
//       final allowedStatuses = ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled'];
//       if (!allowedStatuses.contains(dbStatus)) {
//         throw Exception('Invalid status: $dbStatus');
//       }
      
//       // Mark as pending update
//       _pendingUpdates.add(order.id);
      
//       // Update in database
//       final response = await _supabase
//           .from('emp_mar_orders')
//           .update({
//             'status': dbStatus,
//             'updated_at': DateTime.now().toUtc().toIso8601String(),
//           })
//           .eq('id', order.id)
//           .select(); // Add select to get the updated data

//       print('✅ Order status update successful');
//       print('📦 Response: $response');
      
//       // Verify the update by fetching the latest data
//       if (response.isNotEmpty) {
//         final verifiedOrder = ProductionOrderItem.fromMap(response.first);
        
//         // Update local state with verified data
//         final index = _orders.indexWhere((o) => o.id == order.id);
//         if (index != -1) {
//           _orders[index] = verifiedOrder;
//           notifyListeners();
//           print('✅ Local order updated and verified');
//         }
//       }
      
//     } catch (e, stackTrace) {
//       _error = 'Failed to update order status: $e';
//       print('❌ Error updating order status: $e');
//       print('❌ Stack trace: $stackTrace');
//       rethrow;
//     } finally {
//       _pendingUpdates.remove(order.id);
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // FIXED: Bulk update with verification
//   Future<void> updateBulkOrderStatus(List<String> orderIds, String newStatus) async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();

//       print('🔄 Bulk updating ${orderIds.length} orders to status: $newStatus');
      
//       final validIds = orderIds.where((id) => id.isNotEmpty && id != 'null').toList();
      
//       if (validIds.isEmpty) {
//         throw Exception('No valid order IDs provided');
//       }
      
//       String dbStatus = newStatus.toLowerCase().trim();
      
//       final allowedStatuses = ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled'];
//       if (!allowedStatuses.contains(dbStatus)) {
//         throw Exception('Invalid status: $dbStatus');
//       }
      
//       // Mark all as pending updates
//       _pendingUpdates.addAll(validIds);
      
//       int successCount = 0;
//       List<String> failedIds = [];
//       List<Map<String, dynamic>> successfulUpdates = [];
      
//       for (final orderId in validIds) {
//         try {
//           final response = await _supabase
//               .from('emp_mar_orders')
//               .update({
//                 'status': dbStatus,
//                 'updated_at': DateTime.now().toUtc().toIso8601String(),
//               })
//               .eq('id', orderId)
//               .select();
          
//           if (response.isNotEmpty) {
//             successfulUpdates.add(response.first);
//             successCount++;
//             print('✅ Updated order: $orderId');
//           } else {
//             failedIds.add(orderId);
//           }
          
//         } catch (e) {
//           failedIds.add(orderId);
//           print('❌ Failed to update order $orderId: $e');
//         }
//       }

//       print('✅ Bulk update complete: $successCount/${validIds.length} orders updated');
      
//       // Update local state with verified data
//       for (final update in successfulUpdates) {
//         final updatedOrder = ProductionOrderItem.fromMap(update);
//         final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
//         if (index != -1) {
//           _orders[index] = updatedOrder;
//         }
//       }
      
//       notifyListeners();
      
//       if (failedIds.isNotEmpty) {
//         throw Exception('Failed to update ${failedIds.length} orders: $failedIds');
//       }
      
//     } catch (e, stackTrace) {
//       _error = 'Failed to update bulk order status: $e';
//       print('❌ Error updating bulk order status: $e');
//       print('❌ Stack trace: $stackTrace');
//       rethrow;
//     } finally {
//       _pendingUpdates.clear();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   List<String> getNextStatusOptions(ProductionOrderItem order) {
//     final currentStatus = order.status.toLowerCase();
//     final allStatuses = ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled'];
//     return allStatuses.where((status) => status != currentStatus).toList();
//   }

//   void setFilter(String filter) {
//     print('🔍 Setting filter to: $filter');
//     _filter = filter;
//     notifyListeners();
//   }

//   Map<String, int> getStatistics() {
//     final stats = {
//       'total': _orders.length,
//       'pending': _orders.where((order) => order.status.toLowerCase() == 'pending').length,
//       'packing': _orders.where((order) => order.status.toLowerCase() == 'packing').length,
//       'ready_for_dispatch': _orders.where((order) => order.status.toLowerCase() == 'ready_for_dispatch').length,
//       'dispatched': _orders.where((order) => order.status.toLowerCase() == 'dispatched').length,
//       'delivered': _orders.where((order) => order.status.toLowerCase() == 'delivered').length,
//       'completed': _orders.where((order) => order.status.toLowerCase() == 'completed').length,
//       'cancelled': _orders.where((order) => order.status.toLowerCase() == 'cancelled').length,
//     };
    
//     print('📊 Statistics calculated: $stats');
//     return stats;
//   }

//   double getMonthlyRevenue() {
//     final today = DateTime.now();
//     final monthStart = DateTime(today.year, today.month, 1);
//     double revenue = 0.0;

//     for (var order in completedOrders) {
//       if (order.createdAt.isAfter(monthStart) && order.createdAt.isBefore(today.add(const Duration(days: 1)))) {
//         revenue += order.totalPrice.toDouble();
//       }
//     }

//     return revenue;
//   }

//   double getRevenueForDateRange(DateTime startDate, DateTime endDate) {
//     double revenue = 0.0;

//     for (var order in completedOrders) {
//       if (order.createdAt.isAfter(startDate) && order.createdAt.isBefore(endDate.add(const Duration(days: 1)))) {
//         revenue += order.totalPrice.toDouble();
//       }
//     }

//     return revenue;
//   }

//   List<ProductionOrderItem> getCompletedOrdersForDashboard() {
//     return completedOrders;
//   }

//   Map<DateTime, double> getDailyRevenueSummary() {
//     final Map<DateTime, double> dailyRevenue = {};
    
//     for (var order in completedOrders) {
//       final date = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
//       dailyRevenue[date] = (dailyRevenue[date] ?? 0) + order.totalPrice.toDouble();
//     }
    
//     return dailyRevenue;
//   }

//   Map<String, double> getProductRevenueSummary() {
//     final Map<String, double> productRevenue = {};
    
//     for (var order in completedOrders) {
//       productRevenue[order.productName] = (productRevenue[order.productName] ?? 0) + order.totalPrice.toDouble();
//     }
    
//     return productRevenue;
//   }

//   List<ProductionOrderItem> getRecentCompletedOrders({int limit = 5}) {
//     return completedOrders.take(limit).toList();
//   }
// }









// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/order_item_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ProductionOrdersProvider extends ChangeNotifier {
//   final SupabaseClient _supabase = Supabase.instance.client;
  
//   List<ProductionOrderItem> _orders = [];
//   bool _isLoading = false;
//   bool _isQuickLoading = false;
//   String? _error;
//   String _filter = 'all';
//   String? _productionManagerDistrict; // Added district field for filtering
  
//   // Pagination variables
//   bool _hasMoreData = true;
//   int _page = 0;
//   int _limit = 20;
//   bool _initialLoadComplete = false;

//   List<ProductionOrderItem> get orders => _orders;
//   bool get isLoading => _isLoading;
//   bool get isQuickLoading => _isQuickLoading;
//   String? get error => _error;
//   String get filter => _filter;
//   bool get hasMoreData => _hasMoreData;
//   bool get initialLoadComplete => _initialLoadComplete;
//   String? get productionManagerDistrict => _productionManagerDistrict; // Getter for district

//   List<ProductionOrderItem> get filteredOrders {
//     switch (_filter) {
//       case 'pending':
//         return _orders.where((order) => order.status.toLowerCase() == 'pending').toList();
//       case 'packing':
//         return _orders.where((order) => order.status.toLowerCase() == 'packing').toList();
//       case 'ready_for_dispatch':
//         return _orders.where((order) => order.status.toLowerCase() == 'ready_for_dispatch').toList();
//       case 'dispatched':
//         return _orders.where((order) => order.status.toLowerCase() == 'dispatched').toList();
//       case 'delivered':
//         return _orders.where((order) => order.status.toLowerCase() == 'delivered').toList();
//       case 'completed':
//         return _orders.where((order) => order.status.toLowerCase() == 'completed').toList();
//       case 'cancelled':
//         return _orders.where((order) => order.status.toLowerCase() == 'cancelled').toList();
//       default:
//         return _orders;
//     }
//   }

//   // Method to set production manager's district
//   void setProductionManagerDistrict(String district) {
//     _productionManagerDistrict = district;
//     print('📍 Production manager district set to: $district');
//     // Refresh orders with new district filter
//     refresh();
//   }

//   // GET COMPLETED ORDERS FOR PROFIT CALCULATION
//   List<ProductionOrderItem> get completedOrders {
//     return _orders.where((order) => order.status.toLowerCase() == 'completed').toList();
//   }

//   // GET MONTHLY REVENUE
//   double getMonthlyRevenue() {
//     final today = DateTime.now();
//     final monthStart = DateTime(today.year, today.month, 1);
//     double revenue = 0.0;

//     for (var order in completedOrders) {
//       if (order.createdAt.isAfter(monthStart) && order.createdAt.isBefore(today.add(const Duration(days: 1)))) {
//         revenue += order.totalPrice.toDouble();
//       }
//     }

//     return revenue;
//   }

//   // GET REVENUE FOR DATE RANGE
//   double getRevenueForDateRange(DateTime startDate, DateTime endDate) {
//     double revenue = 0.0;

//     for (var order in completedOrders) {
//       if (order.createdAt.isAfter(startDate) && order.createdAt.isBefore(endDate.add(const Duration(days: 1)))) {
//         revenue += order.totalPrice.toDouble();
//       }
//     }

//     return revenue;
//   }

//   ProductionOrdersProvider() {
//     print('🔄 ProductionOrdersProvider initialized');
//     _quickLoad();
//     _setupRealtimeSubscription();
//     // Start full load in background
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadOrders();
//     });
//   }

//   // ========================
//   // QUICK LOAD (Optimized)
//   // ========================
//   Future<void> _quickLoad() async {
//     if (_initialLoadComplete) return;
    
//     try {
//       _isQuickLoading = true;
//       _error = null;
//       notifyListeners();

//       print('⚡ Quick loading recent orders...');
//       print('📍 Current district filter: $_productionManagerDistrict');
      
//       // Create query with district filter if applicable
//       dynamic query;
      
//       if (_productionManagerDistrict != null && _productionManagerDistrict!.isNotEmpty) {
//         print('🔍 Applying district filter in quick load: $_productionManagerDistrict');
//         query = _supabase
//             .from('emp_mar_orders')
//             .select('id, order_number, status, customer_name, total_price, created_at, bags, feed_category, district')
//             .eq('district', _productionManagerDistrict!)
//             .order('created_at', ascending: false)
//             .limit(10);
//       } else {
//         print('⚠️ No district filter applied - showing all orders');
//         query = _supabase
//             .from('emp_mar_orders')
//             .select('id, order_number, status, customer_name, total_price, created_at, bags, feed_category, district')
//             .order('created_at', ascending: false)
//             .limit(10);
//       }

//       final response = await query;

//       print('✅ Quick load successful, found ${response.length} orders');
      
//       if (response.isNotEmpty) {
//         _orders = (response as List)
//             .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item))
//             .toList();
//       }
      
//     } catch (e) {
//       _error = 'Failed to load orders: $e';
//       print('❌ Quick load error: $e');
//     } finally {
//       _isQuickLoading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // LOAD ORDERS WITH PAGINATION
//   // ========================
//   Future<void> _loadOrders() async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       print('📡 Loading orders with pagination...');
//       print('📍 Current district filter: $_productionManagerDistrict');
      
//       // Create query with district filter if applicable
//       dynamic query;
      
//       if (_productionManagerDistrict != null && _productionManagerDistrict!.isNotEmpty) {
//         print('🔍 Applying district filter in full load: $_productionManagerDistrict');
//         query = _supabase
//             .from('emp_mar_orders')
//             .select('*')
//             .eq('district', _productionManagerDistrict!)
//             .order('created_at', ascending: false)
//             .range(_page * _limit, (_page + 1) * _limit - 1);
//       } else {
//         print('⚠️ No district filter applied - showing all orders');
//         query = _supabase
//             .from('emp_mar_orders')
//             .select('*')
//             .order('created_at', ascending: false)
//             .range(_page * _limit, (_page + 1) * _limit - 1);
//       }

//       final response = await query;

//       print('✅ Query successful, found ${response.length} orders');
      
//       if (response.isNotEmpty) {
//         final ordersList = (response as List)
//             .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item))
//             .toList();
        
//         if (ordersList.length < _limit) {
//           _hasMoreData = false;
//         }
        
//         _orders = ordersList;
//         _initialLoadComplete = true;
//       } else {
//         _hasMoreData = false;
//       }
          
//     } catch (e) {
//       _error = 'Failed to load orders: $e';
//       print('❌ Error loading orders: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//       print('🏁 _loadOrders completed. Total orders: ${_orders.length}');
//     }
//   }

//   // ========================
//   // LOAD MORE ORDERS
//   // ========================
//   Future<void> loadMore() async {
//     if (!_hasMoreData || _isLoading) return;
    
//     _page++;
//     await _loadOrders();
//   }

//   // ========================
//   // REFRESH
//   // ========================
//   Future<void> refresh() async {
//     print('🔄 Manual refresh triggered');
//     print('📍 Current district filter: $_productionManagerDistrict');
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     _orders.clear();
//     notifyListeners();
    
//     await _quickLoad();
//     await _loadOrders();
//   }

//   // ========================
//   // REALTIME SUBSCRIPTION
//   // ========================
//   void _setupRealtimeSubscription() {
//     print('🔔 Setting up realtime subscription...');
//     try {
//       _supabase
//           .from('emp_mar_orders')
//           .stream(primaryKey: ['id'])
//           .listen(
//             (List<Map<String, dynamic>> updates) {
//               print('🔄 Realtime update: ${updates.length} order(s) changed');
//               _handleOrderUpdates(updates);
//             },
//             onError: (error) {
//               print('❌ Realtime subscription error: $error');
//             },
//           );
//       print('✅ Realtime subscription established');
//     } catch (e) {
//       print('❌ Failed to set up realtime subscription: $e');
//     }
//   }

//   void _handleOrderUpdates(List<Map<String, dynamic>> updates) {
//     print('🔄 Processing ${updates.length} realtime updates');
//     for (final update in updates) {
//       final orderId = update['id'].toString();
//       final orderDistrict = update['district']?.toString() ?? '';
      
//       // Check if order matches the production manager's district
//       if (_productionManagerDistrict != null && 
//           _productionManagerDistrict!.isNotEmpty &&
//           orderDistrict != _productionManagerDistrict) {
//         print('🚫 Order $orderId district ($orderDistrict) does not match production manager district ($_productionManagerDistrict)');
//         continue; // Skip this order
//       }
      
//       final index = _orders.indexWhere((order) => order.id == orderId);
      
//       if (index != -1) {
//         print('📝 Updating existing order: $orderId');
//         _orders[index] = ProductionOrderItem.fromMap(update);
//       } else {
//         print('➕ Adding new order: $orderId');
//         _orders.insert(0, ProductionOrderItem.fromMap(update));
//       }
//     }
    
//     _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//     notifyListeners();
//     print('✅ Orders updated. Total: ${_orders.length}');
//   }

//   // ========================
//   // UPDATE ORDER STATUS
//   // ========================
//   Future<void> updateOrderStatus(ProductionOrderItem order, String newStatus) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       print('🔄 Updating order ${order.id} status from "${order.status}" to "$newStatus"');
      
//       await _supabase
//           .from('emp_mar_orders')
//           .update({
//             'status': newStatus,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', order.id);
      
//       print('✅ Order status update successful');
      
//     } catch (e) {
//       _error = 'Failed to update order status: $e';
//       print('❌ Error updating order status: $e');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> updateBulkOrderStatus(List<String> orderIds, String newStatus) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       print('🔄 Bulk updating ${orderIds.length} orders to status: $newStatus');
      
//       for (final orderId in orderIds) {
//         print('   📝 Updating order: $orderId');
//         await _supabase
//             .from('emp_mar_orders')
//             .update({
//               'status': newStatus,
//               'updated_at': DateTime.now().toIso8601String(),
//             })
//             .eq('id', orderId);
//       }

//       print('✅ Bulk update complete, refreshing orders...');
//       await refresh();
      
//     } catch (e) {
//       _error = 'Failed to update bulk order status: $e';
//       print('❌ Error updating bulk order status: $e');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   List<String> getNextStatusOptions(ProductionOrderItem order) {
//     return ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled'];
//   }

//   void setFilter(String filter) {
//     print('🔍 Setting filter to: $filter');
//     _filter = filter;
//     notifyListeners();
//   }

//   Map<String, int> getStatistics() {
//     final stats = {
//       'total': _orders.length,
//       'pending': _orders.where((order) => order.status.toLowerCase() == 'pending').length,
//       'packing': _orders.where((order) => order.status.toLowerCase() == 'packing').length,
//       'ready_for_dispatch': _orders.where((order) => order.status.toLowerCase() == 'ready_for_dispatch').length,
//       'dispatched': _orders.where((order) => order.status.toLowerCase() == 'dispatched').length,
//       'delivered': _orders.where((order) => order.status.toLowerCase() == 'delivered').length,
//       'completed': _orders.where((order) => order.status.toLowerCase() == 'completed').length,
//       'cancelled': _orders.where((order) => order.status.toLowerCase() == 'cancelled').length,
//     };
    
//     print('📊 Statistics calculated: $stats');
//     return stats;
//   }

//   // ========================
//   // PROFIT CALCULATION HELPERS
//   // ========================
  
//   // Get all completed orders for dashboard profit calculation
//   List<ProductionOrderItem> getCompletedOrdersForDashboard() {
//     return completedOrders;
//   }

//   // Get revenue summary by date
//   Map<DateTime, double> getDailyRevenueSummary() {
//     final Map<DateTime, double> dailyRevenue = {};
    
//     for (var order in completedOrders) {
//       final date = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
//       if (dailyRevenue.containsKey(date)) {
//         dailyRevenue[date] = dailyRevenue[date]! + order.totalPrice.toDouble();
//       } else {
//         dailyRevenue[date] = order.totalPrice.toDouble();
//       }
//     }
    
//     return dailyRevenue;
//   }

//   // Get top revenue generating products
//   Map<String, double> getProductRevenueSummary() {
//     final Map<String, double> productRevenue = {};
    
//     for (var order in completedOrders) {
//       if (productRevenue.containsKey(order.productName)) {
//         productRevenue[order.productName] = productRevenue[order.productName]! + order.totalPrice.toDouble();
//       } else {
//         productRevenue[order.productName] = order.totalPrice.toDouble();
//       }
//     }
    
//     return productRevenue;
//   }

//   // Get recent completed orders for dashboard display
//   List<ProductionOrderItem> getRecentCompletedOrders({int limit = 5}) {
//     return completedOrders
//         .take(limit)
//         .toList();
//   }
// }










// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ProductionOrderItem {
//   final String id;
//   final String customerName;
//   final String customerMobile;
//   final String customerAddress;
//   final String productName;
//   final int bags;
//   final int weightPerBag;
//   final String weightUnit;
//   final int totalWeight;
//   final int pricePerBag;
//   final int totalPrice;
//   final String status;
//   final DateTime createdAt;
//   final DateTime? updatedAt;
//   final String? employeeId;
//   final String? remarks;

//   ProductionOrderItem({
//     required this.id,
//     required this.customerName,
//     required this.customerMobile,
//     required this.customerAddress,
//     required this.productName,
//     required this.bags,
//     required this.weightPerBag,
//     required this.weightUnit,
//     required this.totalWeight,
//     required this.pricePerBag,
//     required this.totalPrice,
//     required this.status,
//     required this.createdAt,
//     this.updatedAt,
//     this.employeeId,
//     this.remarks,
//   });

//   factory ProductionOrderItem.fromMap(Map<String, dynamic> map) {
//     return ProductionOrderItem(
//       id: map['id'].toString(),
//       customerName: map['customer_name']?.toString() ?? 'N/A',
//       customerMobile: map['customer_mobile']?.toString() ?? '',
//       customerAddress: map['customer_address']?.toString() ?? '',
//       productName: map['feed_category']?.toString() ?? 'N/A',
//       bags: (map['bags'] ?? 0) as int,
//       weightPerBag: (map['weight_per_bag'] ?? 0) as int,
//       weightUnit: map['weight_unit']?.toString() ?? 'kg',
//       totalWeight: (map['total_weight'] ?? 0) as int,
//       pricePerBag: (map['price_per_bag'] ?? 0) as int,
//       totalPrice: (map['total_price'] ?? 0) as int,
//       status: (map['status'] ?? 'Pending')?.toString() ?? 'Pending',
//       createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
//       updatedAt: map['updated_at'] != null 
//           ? DateTime.parse(map['updated_at'].toString()) 
//           : null,
//       employeeId: map['employee_id']?.toString(),
//       remarks: map['remarks']?.toString(),
//     );
//   }

//   String get displayStatus {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return 'Pending';
//       case 'packing':
//         return 'Packing';
//       case 'ready_for_dispatch':
//         return 'Ready for Dispatch';
//       case 'dispatched':
//         return 'Dispatched';
//       case 'delivered':
//         return 'Delivered';
//       case 'completed':
//         return 'Completed';
//       case 'cancelled':
//         return 'Cancelled';
//       default:
//         return status;
//     }
//   }

//   String get displayQuantity {
//     return '$bags Bags';
//   }

//   Color get statusColor {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Colors.orange;
//       case 'packing':
//         return Colors.blue;
//       case 'ready_for_dispatch':
//         return Colors.purple;
//       case 'dispatched':
//         return Colors.indigo;
//       case 'delivered':
//         return Colors.green;
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

// class ProductionOrdersProvider extends ChangeNotifier {
//   final SupabaseClient _supabase = Supabase.instance.client;
  
//   List<ProductionOrderItem> _orders = [];
//   bool _isLoading = false;
//   bool _isQuickLoading = false;
//   String? _error;
//   String _filter = 'all';
  
//   // Pagination variables
//   bool _hasMoreData = true;
//   int _page = 0;
//   int _limit = 20;
//   bool _initialLoadComplete = false;

//   List<ProductionOrderItem> get orders => _orders;
//   bool get isLoading => _isLoading;
//   bool get isQuickLoading => _isQuickLoading;
//   String? get error => _error;
//   String get filter => _filter;
//   bool get hasMoreData => _hasMoreData;
//   bool get initialLoadComplete => _initialLoadComplete;

//   List<ProductionOrderItem> get filteredOrders {
//     switch (_filter) {
//       case 'pending':
//         return _orders.where((order) => order.status.toLowerCase() == 'pending').toList();
//       case 'packing':
//         return _orders.where((order) => order.status.toLowerCase() == 'packing').toList();
//       case 'ready_for_dispatch':
//         return _orders.where((order) => order.status.toLowerCase() == 'ready_for_dispatch').toList();
//       case 'dispatched':
//         return _orders.where((order) => order.status.toLowerCase() == 'dispatched').toList();
//       case 'delivered':
//         return _orders.where((order) => order.status.toLowerCase() == 'delivered').toList();
//       case 'completed':
//         return _orders.where((order) => order.status.toLowerCase() == 'completed').toList();
//       case 'cancelled':
//         return _orders.where((order) => order.status.toLowerCase() == 'cancelled').toList();
//       default:
//         return _orders;
//     }
//   }

//   // GET COMPLETED ORDERS FOR PROFIT CALCULATION
//   List<ProductionOrderItem> get completedOrders {
//     return _orders.where((order) => order.status.toLowerCase() == 'completed').toList();
//   }

//   // GET MONTHLY REVENUE
//   double getMonthlyRevenue() {
//     final today = DateTime.now();
//     final monthStart = DateTime(today.year, today.month, 1);
//     double revenue = 0.0;

//     for (var order in completedOrders) {
//       if (order.createdAt.isAfter(monthStart) && order.createdAt.isBefore(today.add(const Duration(days: 1)))) {
//         revenue += order.totalPrice;
//       }
//     }

//     return revenue;
//   }

//   // GET REVENUE FOR DATE RANGE
//   double getRevenueForDateRange(DateTime startDate, DateTime endDate) {
//     double revenue = 0.0;

//     for (var order in completedOrders) {
//       if (order.createdAt.isAfter(startDate) && order.createdAt.isBefore(endDate.add(const Duration(days: 1)))) {
//         revenue += order.totalPrice;
//       }
//     }

//     return revenue;
//   }

//   ProductionOrdersProvider() {
//     print('🔄 ProductionOrdersProvider initialized');
//     _quickLoad();
//     _setupRealtimeSubscription();
//     // Start full load in background
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadOrders();
//     });
//   }

//   // ========================
//   // QUICK LOAD (Optimized)
//   // ========================
//   Future<void> _quickLoad() async {
//     if (_initialLoadComplete) return;
    
//     try {
//       _isQuickLoading = true;
//       _error = null;
//       notifyListeners();

//       print('⚡ Quick loading recent orders...');
      
//       final response = await _supabase
//           .from('emp_mar_orders')
//           .select('id, order_number, status, customer_name, total_price, created_at, bags, feed_category')
//           .order('created_at', ascending: false)
//           .limit(10);

//       print('✅ Quick load successful, found ${response.length} orders');
      
//       if (response.isNotEmpty) {
//         _orders = response
//             .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item))
//             .toList();
//       }
      
//     } catch (e) {
//       _error = 'Failed to load orders: $e';
//       print('❌ Quick load error: $e');
//     } finally {
//       _isQuickLoading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // LOAD ORDERS WITH PAGINATION
//   // ========================
//   Future<void> _loadOrders() async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       print('📡 Loading orders with pagination...');
      
//       final response = await _supabase
//           .from('emp_mar_orders')
//           .select('*')
//           .order('created_at', ascending: false)
//           .range(_page * _limit, (_page + 1) * _limit - 1);

//       print('✅ Query successful, found ${response.length} orders');
      
//       if (response.isNotEmpty) {
//         final ordersList = response
//             .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item))
//             .toList();
        
//         if (ordersList.length < _limit) {
//           _hasMoreData = false;
//         }
        
//         _orders = ordersList;
//         _initialLoadComplete = true;
//       } else {
//         _hasMoreData = false;
//       }
          
//     } catch (e) {
//       _error = 'Failed to load orders: $e';
//       print('❌ Error loading orders: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//       print('🏁 _loadOrders completed. Total orders: ${_orders.length}');
//     }
//   }

//   // ========================
//   // LOAD MORE ORDERS
//   // ========================
//   Future<void> loadMore() async {
//     if (!_hasMoreData || _isLoading) return;
    
//     _page++;
//     await _loadOrders();
//   }

//   // ========================
//   // REFRESH
//   // ========================
//   Future<void> refresh() async {
//     print('🔄 Manual refresh triggered');
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     _orders.clear();
//     notifyListeners();
    
//     await _quickLoad();
//     await _loadOrders();
//   }

//   // ========================
//   // REALTIME SUBSCRIPTION
//   // ========================
//   void _setupRealtimeSubscription() {
//     print('🔔 Setting up realtime subscription...');
//     try {
//       _supabase
//           .from('emp_mar_orders')
//           .stream(primaryKey: ['id'])
//           .listen(
//             (List<Map<String, dynamic>> updates) {
//               print('🔄 Realtime update: ${updates.length} order(s) changed');
//               _handleOrderUpdates(updates);
//             },
//             onError: (error) {
//               print('❌ Realtime subscription error: $error');
//             },
//           );
//       print('✅ Realtime subscription established');
//     } catch (e) {
//       print('❌ Failed to set up realtime subscription: $e');
//     }
//   }

//   void _handleOrderUpdates(List<Map<String, dynamic>> updates) {
//     print('🔄 Processing ${updates.length} realtime updates');
//     for (final update in updates) {
//       final orderId = update['id'].toString();
//       final index = _orders.indexWhere((order) => order.id == orderId);
      
//       if (index != -1) {
//         print('📝 Updating existing order: $orderId');
//         _orders[index] = ProductionOrderItem.fromMap(update);
//       } else {
//         print('➕ Adding new order: $orderId');
//         _orders.insert(0, ProductionOrderItem.fromMap(update));
//       }
//     }
    
//     _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//     notifyListeners();
//     print('✅ Orders updated. Total: ${_orders.length}');
//   }

//   // ========================
//   // UPDATE ORDER STATUS
//   // ========================
//   Future<void> updateOrderStatus(ProductionOrderItem order, String newStatus) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       print('🔄 Updating order ${order.id} status from "${order.status}" to "$newStatus"');
      
//       await _supabase
//           .from('emp_mar_orders')
//           .update({
//             'status': newStatus,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', order.id);
      
//       print('✅ Order status update successful');
      
//     } catch (e) {
//       _error = 'Failed to update order status: $e';
//       print('❌ Error updating order status: $e');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> updateBulkOrderStatus(List<String> orderIds, String newStatus) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       print('🔄 Bulk updating ${orderIds.length} orders to status: $newStatus');
      
//       for (final orderId in orderIds) {
//         print('   📝 Updating order: $orderId');
//         await _supabase
//             .from('emp_mar_orders')
//             .update({
//               'status': newStatus,
//               'updated_at': DateTime.now().toIso8601String(),
//             })
//             .eq('id', orderId);
//       }

//       print('✅ Bulk update complete, refreshing orders...');
//       await refresh();
      
//     } catch (e) {
//       _error = 'Failed to update bulk order status: $e';
//       print('❌ Error updating bulk order status: $e');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   List<String> getNextStatusOptions(ProductionOrderItem order) {
//     return ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled'];
//   }

//   void setFilter(String filter) {
//     print('🔍 Setting filter to: $filter');
//     _filter = filter;
//     notifyListeners();
//   }

//   Map<String, int> getStatistics() {
//     final stats = {
//       'total': _orders.length,
//       'pending': _orders.where((order) => order.status.toLowerCase() == 'pending').length,
//       'packing': _orders.where((order) => order.status.toLowerCase() == 'packing').length,
//       'ready_for_dispatch': _orders.where((order) => order.status.toLowerCase() == 'ready_for_dispatch').length,
//       'dispatched': _orders.where((order) => order.status.toLowerCase() == 'dispatched').length,
//       'delivered': _orders.where((order) => order.status.toLowerCase() == 'delivered').length,
//       'completed': _orders.where((order) => order.status.toLowerCase() == 'completed').length,
//       'cancelled': _orders.where((order) => order.status.toLowerCase() == 'cancelled').length,
//     };
    
//     print('📊 Statistics calculated: $stats');
//     return stats;
//   }

//   // ========================
//   // PROFIT CALCULATION HELPERS
//   // ========================
  
//   // Get all completed orders for dashboard profit calculation
//   List<ProductionOrderItem> getCompletedOrdersForDashboard() {
//     return completedOrders;
//   }

//   // Get revenue summary by date
//   Map<DateTime, double> getDailyRevenueSummary() {
//     final Map<DateTime, double> dailyRevenue = {};
    
//     for (var order in completedOrders) {
//       final date = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
//       dailyRevenue[date] = (dailyRevenue[date] ?? 0) + order.totalPrice;
//     }
    
//     return dailyRevenue;
//   }

//   // Get top revenue generating products
//   Map<String, double> getProductRevenueSummary() {
//     final Map<String, double> productRevenue = {};
    
//     for (var order in completedOrders) {
//       productRevenue[order.productName] = (productRevenue[order.productName] ?? 0) + order.totalPrice;
//     }
    
//     return productRevenue;
//   }

//   // Get recent completed orders for dashboard display
//   List<ProductionOrderItem> getRecentCompletedOrders({int limit = 5}) {
//     return completedOrders
//         .take(limit)
//         .toList();
//   }
// }























// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ProductionOrderItem {
//   final String id;
//   final String customerName;
//   final String customerMobile;
//   final String customerAddress;
//   final String productName;
//   final int bags;
//   final int weightPerBag;
//   final String weightUnit;
//   final int totalWeight;
//   final int pricePerBag;
//   final int totalPrice;
//   final String status;
//   final DateTime createdAt;
//   final DateTime? updatedAt;
//   final String? employeeId;
//   final String? remarks;

//   ProductionOrderItem({
//     required this.id,
//     required this.customerName,
//     required this.customerMobile,
//     required this.customerAddress,
//     required this.productName,
//     required this.bags,
//     required this.weightPerBag,
//     required this.weightUnit,
//     required this.totalWeight,
//     required this.pricePerBag,
//     required this.totalPrice,
//     required this.status,
//     required this.createdAt,
//     this.updatedAt,
//     this.employeeId,
//     this.remarks,
//   });

//   factory ProductionOrderItem.fromMap(Map<String, dynamic> map) {
//     return ProductionOrderItem(
//       id: map['id'].toString(),
//       customerName: map['customer_name']?.toString() ?? 'N/A',
//       customerMobile: map['customer_mobile']?.toString() ?? '',
//       customerAddress: map['customer_address']?.toString() ?? '',
//       productName: map['feed_category']?.toString() ?? 'N/A',
//       bags: (map['bags'] ?? 0) as int,
//       weightPerBag: (map['weight_per_bag'] ?? 0) as int,
//       weightUnit: map['weight_unit']?.toString() ?? 'kg',
//       totalWeight: (map['total_weight'] ?? 0) as int,
//       pricePerBag: (map['price_per_bag'] ?? 0) as int,
//       totalPrice: (map['total_price'] ?? 0) as int,
//       status: (map['status'] ?? 'Pending')?.toString() ?? 'Pending',
//       createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
//       updatedAt: map['updated_at'] != null 
//           ? DateTime.parse(map['updated_at'].toString()) 
//           : null,
//       employeeId: map['employee_id']?.toString(),
//       remarks: map['remarks']?.toString(),
//     );
//   }

//   String get displayStatus {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return 'Pending';
//       case 'packing':
//         return 'Packing';
//       case 'ready_for_dispatch':
//         return 'Ready for Dispatch';
//       case 'dispatched':
//         return 'Dispatched';
//       case 'delivered':
//         return 'Delivered';
//       case 'completed':
//         return 'Completed';
//       case 'cancelled':
//         return 'Cancelled';
//       default:
//         return status;
//     }
//   }

//   String get displayQuantity {
//     return '$bags Bags';
//   }

//   Color get statusColor {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Colors.orange;
//       case 'packing':
//         return Colors.blue;
//       case 'ready_for_dispatch':
//         return Colors.purple;
//       case 'dispatched':
//         return Colors.indigo;
//       case 'delivered':
//         return Colors.green;
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

// class ProductionOrdersProvider extends ChangeNotifier {
//   final SupabaseClient _supabase = Supabase.instance.client;
  
//   List<ProductionOrderItem> _orders = [];
//   bool _isLoading = false;
//   bool _isQuickLoading = false;
//   String? _error;
//   String _filter = 'all';
  
//   // Pagination variables
//   bool _hasMoreData = true;
//   int _page = 0;
//   int _limit = 20;
//   bool _initialLoadComplete = false;

//   List<ProductionOrderItem> get orders => _orders;
//   bool get isLoading => _isLoading;
//   bool get isQuickLoading => _isQuickLoading;
//   String? get error => _error;
//   String get filter => _filter;
//   bool get hasMoreData => _hasMoreData;
//   bool get initialLoadComplete => _initialLoadComplete;

//   List<ProductionOrderItem> get filteredOrders {
//     switch (_filter) {
//       case 'pending':
//         return _orders.where((order) => order.status.toLowerCase() == 'pending').toList();
//       case 'packing':
//         return _orders.where((order) => order.status.toLowerCase() == 'packing').toList();
//       case 'ready_for_dispatch':
//         return _orders.where((order) => order.status.toLowerCase() == 'ready_for_dispatch').toList();
//       case 'dispatched':
//         return _orders.where((order) => order.status.toLowerCase() == 'dispatched').toList();
//       case 'delivered':
//         return _orders.where((order) => order.status.toLowerCase() == 'delivered').toList();
//       case 'completed':
//         return _orders.where((order) => order.status.toLowerCase() == 'completed').toList();
//       case 'cancelled':
//         return _orders.where((order) => order.status.toLowerCase() == 'cancelled').toList();
//       default:
//         return _orders;
//     }
//   }

//   ProductionOrdersProvider() {
//     print('🔄 ProductionOrdersProvider initialized');
//     _quickLoad();
//     _setupRealtimeSubscription();
//     // Start full load in background
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadOrders();
//     });
//   }

//   // ========================
//   // QUICK LOAD (Optimized)
//   // ========================
//   Future<void> _quickLoad() async {
//     if (_initialLoadComplete) return;
    
//     try {
//       _isQuickLoading = true;
//       _error = null;
//       notifyListeners();

//       print('⚡ Quick loading recent orders...');
      
//       final response = await _supabase
//           .from('emp_mar_orders')
//           .select('id, order_number, status, customer_name, total_price, created_at, bags, feed_category')
//           .order('created_at', ascending: false)
//           .limit(10);

//       print('✅ Quick load successful, found ${response.length} orders');
      
//       if (response.isNotEmpty) {
//         _orders = response
//             .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item))
//             .toList();
//       }
      
//     } catch (e) {
//       _error = 'Failed to load orders: $e';
//       print('❌ Quick load error: $e');
//     } finally {
//       _isQuickLoading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // LOAD ORDERS WITH PAGINATION
//   // ========================
//   Future<void> _loadOrders() async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       print('📡 Loading orders with pagination...');
      
//       final response = await _supabase
//           .from('emp_mar_orders')
//           .select('*')
//           .order('created_at', ascending: false)
//           .range(_page * _limit, (_page + 1) * _limit - 1);

//       print('✅ Query successful, found ${response.length} orders');
      
//       if (response.isNotEmpty) {
//         final ordersList = response
//             .map<ProductionOrderItem>((item) => ProductionOrderItem.fromMap(item))
//             .toList();
        
//         if (ordersList.length < _limit) {
//           _hasMoreData = false;
//         }
        
//         _orders = ordersList;
//         _initialLoadComplete = true;
//       } else {
//         _hasMoreData = false;
//       }
          
//     } catch (e) {
//       _error = 'Failed to load orders: $e';
//       print('❌ Error loading orders: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//       print('🏁 _loadOrders completed. Total orders: ${_orders.length}');
//     }
//   }

//   // ========================
//   // LOAD MORE ORDERS
//   // ========================
//   Future<void> loadMore() async {
//     if (!_hasMoreData || _isLoading) return;
    
//     _page++;
//     await _loadOrders();
//   }

//   // ========================
//   // REFRESH
//   // ========================
//   Future<void> refresh() async {
//     print('🔄 Manual refresh triggered');
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     _orders.clear();
//     notifyListeners();
    
//     await _quickLoad();
//     await _loadOrders();
//   }

//   // ========================
//   // REALTIME SUBSCRIPTION
//   // ========================
//   void _setupRealtimeSubscription() {
//     print('🔔 Setting up realtime subscription...');
//     try {
//       _supabase
//           .from('emp_mar_orders')
//           .stream(primaryKey: ['id'])
//           .listen(
//             (List<Map<String, dynamic>> updates) {
//               print('🔄 Realtime update: ${updates.length} order(s) changed');
//               _handleOrderUpdates(updates);
//             },
//             onError: (error) {
//               print('❌ Realtime subscription error: $error');
//             },
//           );
//       print('✅ Realtime subscription established');
//     } catch (e) {
//       print('❌ Failed to set up realtime subscription: $e');
//     }
//   }

//   void _handleOrderUpdates(List<Map<String, dynamic>> updates) {
//     print('🔄 Processing ${updates.length} realtime updates');
//     for (final update in updates) {
//       final orderId = update['id'].toString();
//       final index = _orders.indexWhere((order) => order.id == orderId);
      
//       if (index != -1) {
//         print('📝 Updating existing order: $orderId');
//         _orders[index] = ProductionOrderItem.fromMap(update);
//       } else {
//         print('➕ Adding new order: $orderId');
//         _orders.insert(0, ProductionOrderItem.fromMap(update));
//       }
//     }
    
//     _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//     notifyListeners();
//     print('✅ Orders updated. Total: ${_orders.length}');
//   }

//   // ========================
//   // UPDATE ORDER STATUS
//   // ========================
//   Future<void> updateOrderStatus(ProductionOrderItem order, String newStatus) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       print('🔄 Updating order ${order.id} status from "${order.status}" to "$newStatus"');
      
//       await _supabase
//           .from('emp_mar_orders')
//           .update({
//             'status': newStatus,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', order.id);
      
//       print('✅ Order status update successful');
      
//     } catch (e) {
//       _error = 'Failed to update order status: $e';
//       print('❌ Error updating order status: $e');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> updateBulkOrderStatus(List<String> orderIds, String newStatus) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       print('🔄 Bulk updating ${orderIds.length} orders to status: $newStatus');
      
//       for (final orderId in orderIds) {
//         print('   📝 Updating order: $orderId');
//         await _supabase
//             .from('emp_mar_orders')
//             .update({
//               'status': newStatus,
//               'updated_at': DateTime.now().toIso8601String(),
//             })
//             .eq('id', orderId);
//       }

//       print('✅ Bulk update complete, refreshing orders...');
//       await refresh();
      
//     } catch (e) {
//       _error = 'Failed to update bulk order status: $e';
//       print('❌ Error updating bulk order status: $e');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   List<String> getNextStatusOptions(ProductionOrderItem order) {
//     return ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled'];
//   }

//   void setFilter(String filter) {
//     print('🔍 Setting filter to: $filter');
//     _filter = filter;
//     notifyListeners();
//   }

//   Map<String, int> getStatistics() {
//     final stats = {
//       'total': _orders.length,
//       'pending': _orders.where((order) => order.status.toLowerCase() == 'pending').length,
//       'packing': _orders.where((order) => order.status.toLowerCase() == 'packing').length,
//       'ready_for_dispatch': _orders.where((order) => order.status.toLowerCase() == 'ready_for_dispatch').length,
//       'dispatched': _orders.where((order) => order.status.toLowerCase() == 'dispatched').length,
//       'delivered': _orders.where((order) => order.status.toLowerCase() == 'delivered').length,
//       'completed': _orders.where((order) => order.status.toLowerCase() == 'completed').length,
//       'cancelled': _orders.where((order) => order.status.toLowerCase() == 'cancelled').length,
//     };
    
//     print('📊 Statistics calculated: $stats');
//     return stats;
//   }
// }




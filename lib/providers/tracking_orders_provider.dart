// providers/real_time_order_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mega_pro/models/order_model.dart';

class RealTimeOrderProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all';
  
  // Realtime subscription
  RealtimeChannel? _channel;
  
  RealTimeOrderProvider(this._supabase);
  
  List<Order> get orders => _orders;
  List<Order> get filteredOrders => _getFilteredOrders();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;
  
  // Statistics
  Map<String, int> get statistics {
    return {
      'total': _orders.length,
      'pending': _orders.where((o) => o.status == 'pending').length,
      'packing': _orders.where((o) => o.status == 'packing').length,
      'ready_for_dispatch': _orders.where((o) => o.status == 'ready_for_dispatch').length,
      'dispatched': _orders.where((o) => o.status == 'dispatched').length,
      'delivered': _orders.where((o) => o.status == 'delivered').length,
      'completed': _orders.where((o) => o.status == 'completed').length,
      'cancelled': _orders.where((o) => o.status == 'cancelled').length,
    };
  }
  
  Future<void> initialize() async {
    await _fetchOrders();
    await _setupRealtimeSubscription();
  }
  
  Future<void> _fetchOrders() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final response = await _supabase
          .from('emp_mar_orders')
          .select('*')
          .order('created_at', ascending: false);
      
      _orders = response.map((json) => Order.fromJson(json)).toList();
      _error = null;
        } catch (e) {
      _error = 'Failed to fetch orders: $e';
      print('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _setupRealtimeSubscription() async {
    // Cancel existing subscription if any
    if (_channel != null) {
      await _channel!.unsubscribe();
    }
    
    // Subscribe to order changes
    _channel = _supabase.channel('orders_channel')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'emp_mar_orders',
        callback: (payload) {
          _handleRealtimeUpdate(payload);
        },
      );
    
    await _channel!.subscribe();
  }
  
  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    final orderData = payload.newRecord;
    final order = Order.fromJson(orderData);
    
    switch (payload.eventType) {
      // ignore: constant_pattern_never_matches_value_type
      case 'INSERT':
        _orders.insert(0, order);
        break;
      // ignore: constant_pattern_never_matches_value_type
      case 'UPDATE':
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = order;
        }
        break;
      // ignore: constant_pattern_never_matches_value_type
      case 'DELETE':
        _orders.removeWhere((o) => o.id == payload.oldRecord['id']);
        break;
      case PostgresChangeEvent.all:
        // TODO: Handle this case.
        throw UnimplementedError();
      case PostgresChangeEvent.insert:
        // TODO: Handle this case.
        throw UnimplementedError();
      case PostgresChangeEvent.update:
        throw UnimplementedError();
      case PostgresChangeEvent.delete:
        throw UnimplementedError();
    }
    
    notifyListeners();
  }
  
  Future<void> updateOrderStatus(Order order, String newStatus) async {
    try {
      // Update in database
      await _supabase
          .from('emp_mar_orders')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', order.id);
      
      // Local update will be handled by realtime subscription
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
  
  Future<void> updateBulkOrderStatus(List<String> orderIds, String newStatus) async {
    try {
      await _supabase
          .from('emp_mar_orders')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', orderIds);
    } catch (e) {
      throw Exception('Failed to bulk update: $e');
    }
  }
  
  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }
  
  List<Order> _getFilteredOrders() {
    if (_filter == 'all') return _orders;
    return _orders.where((order) => order.status == _filter).toList();
  }
  
  List<String> getNextStatusOptions(Order order) {
    final List<String> allStatuses = [
      'pending',
      'packing',
      'ready_for_dispatch',
      'dispatched',
      'delivered',
      'completed',
      'cancelled',
    ];
    
    final currentIndex = allStatuses.indexOf(order.status);
    if (currentIndex == -1) return [];
    
    // Allow moving to any status except backwards (for simplicity)
    // You can customize this logic based on your workflow
    return allStatuses.sublist(currentIndex + 1);
  }
  
  Future<void> refresh() async {
    await _fetchOrders();
  }
  
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
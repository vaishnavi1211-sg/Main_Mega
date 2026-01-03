import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;

  bool loading = false;

  int totalOrders = 0;
  int pendingOrders = 0;
  int completedOrders = 0;
  int packingOrders = 0;
  int readyForDispatchOrders = 0;
  int dispatchedOrders = 0;
  int deliveredOrders = 0;
  int cancelledOrders = 0;

  List<Map<String, dynamic>> orders = [];

  // ========================
  // CREATE ORDER (Updated for emp_mar_orders)
  // ========================
  Future<void> createOrder(Map<String, dynamic> data) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final int bags = data['bags'];
      final int weightPerBag = data['weight_per_bag'];
      final int pricePerBag = data['price_per_bag'];

      final int totalWeight = bags * weightPerBag;
      final int totalPrice = bags * pricePerBag;

      await supabase.from('emp_mar_orders').insert({
        'employee_id': user.id,

        'customer_name': data['customer_name'],
        'customer_mobile': data['customer_mobile'],
        'customer_address': data['customer_address'],

        'feed_category': data['feed_category'],

        'bags': bags,
        'weight_per_bag': weightPerBag,
        'weight_unit': data['weight_unit'],
        'total_weight': totalWeight,

        'price_per_bag': pricePerBag,
        'total_price': totalPrice,

        'remarks': data['remarks'],
        'status': 'pending', // Default status as per table schema
      });

      await fetchOrderCounts();
      await fetchOrders();
      
    } catch (e) {
      debugPrint("❌ Order insert failed: $e");
      rethrow;
    }
  }

  // ========================
  // FETCH COUNTS (Updated for emp_mar_orders)
  // ========================
  Future<void> fetchOrderCounts() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('emp_mar_orders')
          .select('status')
          .eq('employee_id', user.id);

      totalOrders = data.length;
      pendingOrders = data.where((e) => e['status'] == 'pending').length;
      packingOrders = data.where((e) => e['status'] == 'packing').length;
      readyForDispatchOrders = data.where((e) => e['status'] == 'ready_for_dispatch').length;
      dispatchedOrders = data.where((e) => e['status'] == 'dispatched').length;
      deliveredOrders = data.where((e) => e['status'] == 'delivered').length;
      completedOrders = data.where((e) => e['status'] == 'completed').length;
      cancelledOrders = data.where((e) => e['status'] == 'cancelled').length;

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Fetch counts failed: $e");
    }
  }

  // ========================
  // FETCH ORDERS (Updated for emp_mar_orders)
  // ========================
  Future<void> fetchOrders() async {
    try {
      loading = true;
      notifyListeners();

      final user = supabase.auth.currentUser;
      if (user == null) return;

      orders = List<Map<String, dynamic>>.from(
        await supabase
            .from('emp_mar_orders')
            .select()
            .eq('employee_id', user.id)
            .order('created_at', ascending: false),
      );

      // Update counts based on fetched orders
      _updateCountsFromOrders();

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Fetch orders failed: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Helper method to update counts from orders list
  void _updateCountsFromOrders() {
    totalOrders = orders.length;
    pendingOrders = orders.where((e) => e['status'] == 'pending').length;
    packingOrders = orders.where((e) => e['status'] == 'packing').length;
    readyForDispatchOrders = orders.where((e) => e['status'] == 'ready_for_dispatch').length;
    dispatchedOrders = orders.where((e) => e['status'] == 'dispatched').length;
    deliveredOrders = orders.where((e) => e['status'] == 'delivered').length;
    completedOrders = orders.where((e) => e['status'] == 'completed').length;
    cancelledOrders = orders.where((e) => e['status'] == 'cancelled').length;
  }

  // ========================
  // GET FILTERED ORDERS
  // ========================
  List<Map<String, dynamic>> get pending =>
      orders.where((e) => e['status'] == 'pending').toList();

  List<Map<String, dynamic>> get packing =>
      orders.where((e) => e['status'] == 'packing').toList();

  List<Map<String, dynamic>> get readyForDispatch =>
      orders.where((e) => e['status'] == 'ready_for_dispatch').toList();

  List<Map<String, dynamic>> get dispatched =>
      orders.where((e) => e['status'] == 'dispatched').toList();

  List<Map<String, dynamic>> get delivered =>
      orders.where((e) => e['status'] == 'delivered').toList();

  List<Map<String, dynamic>> get completed =>
      orders.where((e) => e['status'] == 'completed').toList();

  List<Map<String, dynamic>> get cancelled =>
      orders.where((e) => e['status'] == 'cancelled').toList();

  List<Map<String, dynamic>> get allOrders => orders;

  // ========================
  // GET ORDER BY ID
  // ========================
  Map<String, dynamic>? getOrderById(String id) {
    try {
      return orders.firstWhere((order) => order['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // ========================
  // UPDATE ORDER STATUS (For production manager)
  // ========================
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      loading = true;
      notifyListeners();

      await supabase
          .from('emp_mar_orders')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Refresh orders
      await fetchOrders();
      
    } catch (e) {
      debugPrint("❌ Update order status failed: $e");
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ========================
  // DELETE ORDER
  // ========================
  Future<void> deleteOrder(String orderId) async {
    try {
      loading = true;
      notifyListeners();

      await supabase
          .from('emp_mar_orders')
          .delete()
          .eq('id', orderId);

      // Remove from local list
      orders.removeWhere((order) => order['id'] == orderId);
      
      // Update counts
      _updateCountsFromOrders();
      
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Delete order failed: $e");
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ========================
  // REFRESH ALL DATA
  // ========================
  Future<void> refresh() async {
    await fetchOrders();
    await fetchOrderCounts();
  }

  // ========================
  // GET STATISTICS MAP
  // ========================
  Map<String, int> getStatistics() {
    return {
      'total': totalOrders,
      'pending': pendingOrders,
      'packing': packingOrders,
      'ready_for_dispatch': readyForDispatchOrders,
      'dispatched': dispatchedOrders,
      'delivered': deliveredOrders,
      'completed': completedOrders,
      'cancelled': cancelledOrders,
    };
  }

  // ========================
  // GET ORDER SUMMARY
  // ========================
  Map<String, dynamic> getOrderSummary() {
    double totalRevenue = 0;
    for (var order in orders) {
      if (order['total_price'] != null) {
        totalRevenue += (order['total_price'] as num).toDouble();
      }
    }

    return {
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'average_order_value': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      'completion_rate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0,
    };
  }

  // ========================
  // CHECK IF ORDER EXISTS
  // ========================
  bool orderExists(String orderId) {
    return orders.any((order) => order['id'] == orderId);
  }

  // ========================
  // GET ORDERS BY DATE RANGE
  // ========================
  List<Map<String, dynamic>> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return orders.where((order) {
      if (order['created_at'] == null) return false;
      
      final createdAt = DateTime.parse(order['created_at']);
      return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
             createdAt.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
}
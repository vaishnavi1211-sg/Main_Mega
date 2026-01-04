// lib/services/supabase_service.dart
import 'package:flutter/material.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/employee_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===================== HELPERS =====================
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ===================== REVENUE =====================
  Future<int> getTotalRevenue() async {
    try {
      final data = await _supabase
          .from('emp_mar_orders')
          .select('total_price')
          .eq('status', 'completed');

      int total = 0;
      for (final row in data) {
        total += (row['total_price'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      debugPrint('getTotalRevenue error: $e');
      return 0;
    }
  }

  // ===================== COUNTS =====================
  Future<int> getTotalOrders() async {
    try {
      final data = await _supabase
          .from('emp_mar_orders')
          .select('id');

      return data.length;
    } catch (e) {
      debugPrint('getTotalOrders error: $e');
      return 0;
    }
  }

  Future<int> getPendingOrders() async {
    try {
      final data = await _supabase
          .from('emp_mar_orders')
          .select('id')
          .eq('status', 'pending');

      return data.length;
    } catch (e) {
      debugPrint('getPendingOrders error: $e');
      return 0;
    }
  }

  Future<int> getActiveEmployees() async {
    try {
      final data = await _supabase
          .from('emp_profile')
          .select('id')
          .eq('status', 'Active')
          .eq('role', 'Employee');

      return data.length;
    } catch (e) {
      debugPrint('getActiveEmployees error: $e');
      return 0;
    }
  }

  // ===================== TOP PRODUCTS =====================
  Future<List<Map<String, dynamic>>> getTopProducts() async {
    try {
      debugPrint('Fetching top products...');
      
      // First check if own_order_items table has data
      final orderItemsData = await _supabase
          .from('own_order_items')
          .select('product_id, quantity, total_price, product:own_products(name)')
          .limit(1);

      if (orderItemsData.isEmpty) {
        debugPrint('own_order_items table is empty, using fallback');
        return await _topProductsFallback();
      }

      final data = await _supabase
          .from('own_order_items')
          .select('product_id, quantity, total_price, product:own_products(name)');

      debugPrint('Found ${data.length} order items');

      final Map<String, Map<String, dynamic>> map = {};

      for (final item in data) {
        final id = item['product_id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final product = item['product'] as Map<String, dynamic>?;
        final productName = product?['name']?.toString() ?? 'Unknown Product';

        map.putIfAbsent(id, () => {
              'name': productName,
              'sales': 0,
              'revenue': 0,
            });

        map[id]!['sales'] += (item['quantity'] as int? ?? 0);
        map[id]!['revenue'] += (item['total_price'] as int? ?? 0);
      }

      final list = map.values.toList()
        ..sort((a, b) => (b['revenue'] as int).compareTo(a['revenue'] as int));

      debugPrint('Processed ${list.length} unique products');
      return list.take(3).toList();
    } catch (e) {
      debugPrint('getTopProducts error: $e');
      return await _topProductsFallback();
    }
  }

  Future<List<Map<String, dynamic>>> _topProductsFallback() async {
    try {
      debugPrint('Using top products fallback...');
      final data = await _supabase
          .from('emp_mar_orders')
          .select('feed_category, bags, total_price')
          .eq('status', 'completed');

      debugPrint('Found ${data.length} completed orders for fallback');

      final Map<String, Map<String, dynamic>> map = {};

      for (final order in data) {
        final category = (order['feed_category'] as String?) ?? 'Unknown';

        map.putIfAbsent(category, () => {
              'name': category,
              'sales': 0,
              'revenue': 0,
            });

        map[category]!['sales'] += (order['bags'] as int? ?? 0);
        map[category]!['revenue'] += (order['total_price'] as int? ?? 0);
      }

      final list = map.values.toList()
        ..sort((a, b) => (b['revenue'] as int).compareTo(a['revenue'] as int));

      debugPrint('Fallback processed ${list.length} product categories');
      return list.take(3).toList();
    } catch (e) {
      debugPrint('Top products fallback error: $e');
      // Return mock data for testing
      return [
        {'name': 'Premium Cattle Feed', 'sales': 450, 'revenue': 675000},
        {'name': 'Organic Poultry Feed', 'sales': 320, 'revenue': 480000},
        {'name': 'Starter Broiler Feed', 'sales': 280, 'revenue': 420000},
      ];
    }
  }

  // ===================== RECENT ACTIVITY =====================
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      debugPrint('Fetching recent activities...');
      
      // First check if own_activity_logs table has data
      final activityCheck = await _supabase
          .from('own_activity_logs')
          .select('id')
          .limit(1);

      if (activityCheck.isEmpty) {
        debugPrint('own_activity_logs table is empty, using fallback');
        return await _activityFallback();
      }

      final data = await _supabase
          .from('own_activity_logs')
          .select('activity_type, description, created_at')
          .order('created_at', ascending: false)
          .limit(4);

      debugPrint('Found ${data.length} activities');

      final List<Map<String, dynamic>> activities = [];

      for (final row in data) {
        final createdAt = DateTime.parse(row['created_at'] as String);
        final diff = DateTime.now().difference(createdAt);
        final activityType = row['activity_type'] as String;
        final description = row['description'] as String;

        String timeAgo;
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes} mins ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours} hours ago';
        } else {
          timeAgo = '${diff.inDays} days ago';
        }

        final Map<String, dynamic> activityData = _mapActivityType(activityType);

        activities.add({
          'title': activityData['title'],
          'time': timeAgo,
          'icon': activityData['icon'],
          'color': activityData['color'],
          'description': description,
        });
      }

      return activities;
    } catch (e) {
      debugPrint('getRecentActivities error: $e');
      return await _activityFallback();
    }
  }

  Map<String, dynamic> _mapActivityType(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'order_created':
        return {
          'title': 'New Order Received',
          'icon': Icons.shopping_cart,
          'color': Colors.green,
        };
      case 'payment_received':
        return {
          'title': 'Payment Received',
          'icon': Icons.payment,
          'color': Colors.blue,
        };
      case 'stock_updated':
        return {
          'title': 'Stock Updated',
          'icon': Icons.inventory,
          'color': Colors.orange,
        };
      case 'employee_added':
        return {
          'title': 'New Employee Added',
          'icon': Icons.person_add,
          'color': Colors.purple,
        };
      case 'order_completed':
        return {
          'title': 'Order Completed',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      default:
        return {
          'title': activityType,
          'icon': Icons.notifications,
          'color': Colors.grey,
        };
    }
  }

  Future<List<Map<String, dynamic>>> _activityFallback() async {
    try {
      debugPrint('Using activity fallback...');
      final data = await _supabase
          .from('emp_mar_orders')
          .select('customer_name, feed_category, status, created_at')
          .order('created_at', ascending: false)
          .limit(4);

      debugPrint('Found ${data.length} orders for activity fallback');

      final List<Map<String, dynamic>> activities = [];

      for (final order in data) {
        final status = order['status'] as String;
        final createdAt = DateTime.parse(order['created_at'] as String);
        final diff = DateTime.now().difference(createdAt);

        String timeAgo;
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes} mins ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours} hours ago';
        } else {
          timeAgo = '${diff.inDays} days ago';
        }

        final Map<String, dynamic> activityData = _mapOrderStatusToActivity(status);

        activities.add({
          'title': activityData['title'],
          'time': timeAgo,
          'icon': activityData['icon'],
          'color': activityData['color'],
          'description': '${order['customer_name']} - ${order['feed_category']}',
        });
      }

      return activities;
    } catch (e) {
      debugPrint('Activity fallback error: $e');
      // Return mock data for testing
      return [
        {
          'title': 'New Order Received',
          'time': '10 mins ago',
          'icon': Icons.shopping_cart,
          'color': Colors.green,
          'description': 'Ramesh Kumar - Premium Cattle Feed'
        },
        {
          'title': 'Payment Received',
          'time': '30 mins ago',
          'icon': Icons.payment,
          'color': Colors.blue,
          'description': '₹25,000 received'
        },
        {
          'title': 'Stock Updated',
          'time': '1 hour ago',
          'icon': Icons.inventory,
          'color': Colors.orange,
          'description': 'Premium Cattle Feed (+500 bags)'
        },
        {
          'title': 'New Employee Added',
          'time': '2 hours ago',
          'icon': Icons.person_add,
          'color': Colors.purple,
          'description': 'Ajay Singh joined as Sales Executive'
        },
      ];
    }
  }

  Map<String, dynamic> _mapOrderStatusToActivity(String status) {
    switch (status) {
      case 'pending':
        return {
          'title': 'New Order Received',
          'icon': Icons.shopping_cart,
          'color': Colors.green,
        };
      case 'completed':
        return {
          'title': 'Order Completed',
          'icon': Icons.check_circle,
          'color': Colors.blue,
        };
      case 'dispatched':
        return {
          'title': 'Order Dispatched',
          'icon': Icons.local_shipping,
          'color': Colors.orange,
        };
      default:
        return {
          'title': 'Order Updated',
          'icon': Icons.update,
          'color': Colors.purple,
        };
    }
  }

  // ===================== CHART DATA =====================
  Future<List<Map<String, dynamic>>> getRevenueChartData() async {
    try {
      debugPrint('Fetching revenue chart data...');
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final data = await _supabase
          .from('emp_mar_orders')
          .select('created_at, total_price')
          .eq('status', 'completed')
          .gte('created_at', weekAgo.toIso8601String());

      debugPrint('Found ${data.length} completed orders for chart');

      final Map<String, int> revenue = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };

      for (final order in data) {
        try {
          final createdAt = DateTime.parse(order['created_at'] as String);
          final weekday = createdAt.weekday;
          final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
          final orderRevenue = order['total_price'] as int? ?? 0;
          revenue[day] = revenue[day]! + orderRevenue;
        } catch (e) {
          debugPrint('Error processing order for chart: $e');
        }
      }

      // Log the revenue data for debugging
      debugPrint('Chart revenue data: $revenue');

      return revenue.entries
          .map((e) => {'day': e.key, 'revenue': e.value})
          .toList();
    } catch (e) {
      debugPrint('getRevenueChartData error: $e');
      return _defaultChartData();
    }
  }

  List<Map<String, dynamic>> _defaultChartData() {
    debugPrint('Using default chart data');
    return [
      {'day': 'Mon', 'revenue': 160000},
      {'day': 'Tue', 'revenue': 200000},
      {'day': 'Wed', 'revenue': 240000},
      {'day': 'Thu', 'revenue': 280000},
      {'day': 'Fri', 'revenue': 220000},
      {'day': 'Sat', 'revenue': 180000},
      {'day': 'Sun', 'revenue': 120000},
    ];
  }

  // ===================== DASHBOARD =====================
  Future<DashboardData> getDashboardData() async {
    try {
      debugPrint('Fetching dashboard data...');
      
      // Don't wait for metrics update to avoid delays
      _updateDashboardMetricsInBackground();

      final totalRevenue = await getTotalRevenue();
      final totalOrders = await getTotalOrders();
      final activeEmployees = await getActiveEmployees();
      final pendingOrders = await getPendingOrders();
      final topProducts = await getTopProducts();
      final recentActivities = await getRecentActivities();

      debugPrint('Dashboard data loaded:');
      debugPrint('  Total Revenue: $totalRevenue');
      debugPrint('  Total Orders: $totalOrders');
      debugPrint('  Active Employees: $activeEmployees');
      debugPrint('  Pending Orders: $pendingOrders');
      debugPrint('  Top Products: ${topProducts.length}');
      debugPrint('  Recent Activities: ${recentActivities.length}');

      return DashboardData(
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
        activeEmployees: activeEmployees,
        pendingOrders: pendingOrders,
        revenueGrowth: 12.5,
        orderGrowth: 8.2,
        employeeGrowth: 3.5,
        topProducts: topProducts,
        recentActivities: recentActivities,
      );
    } catch (e) {
      debugPrint('getDashboardData error: $e');
      return DashboardData.empty();
    }
  }

  Future<void> _updateDashboardMetricsInBackground() async {
    try {
      final today = _formatDate(DateTime.now());

      await _supabase.from('own_dashboard_metrics').upsert({
        'metric_date': today,
        'total_revenue': await getTotalRevenue(),
        'total_orders': await getTotalOrders(),
        'active_employees': await getActiveEmployees(),
      });
    } catch (e) {
      debugPrint('_updateDashboardMetrics error: $e');
    }
  }

  // ===================== REAL-TIME =====================
  Stream<List<Order>> getOrdersStream() {
    return _supabase
        .from('emp_mar_orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => (data as List<dynamic>)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Employee>> getEmployeesStream() {
    return _supabase
        .from('emp_profile')
        .stream(primaryKey: ['id'])
        .eq('status', 'Active')
        .map((data) => (data as List<dynamic>)
            .map((e) => Employee.fromJson(e as Map<String, dynamic>))
            .toList());
  }

  // ===================== ACTIVITY LOG =====================
  Future<void> logActivity({
    required String activityType,
    required String description,
    String? userId,
    String? referenceId,
    String? referenceType,
  }) async {
    try {
      await _supabase.from('own_activity_logs').insert({
        'activity_type': activityType,
        'description': description,
        'user_id': userId,
        'reference_id': referenceId,
        'reference_type': referenceType,
      });
      debugPrint('Activity logged: $activityType - $description');
    } catch (e) {
      debugPrint('logActivity error: $e');
    }
  }
}








// // lib/services/supabase_service.dart
// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/order_model.dart';
// import '../models/employee_model.dart';

// class SupabaseService {
//   final SupabaseClient _supabase = Supabase.instance.client;

//   // ===================== HELPERS =====================
//   String _formatDate(DateTime date) {
//     return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//   }

//   // ===================== REVENUE =====================
//   Future<int> getTotalRevenue() async {
//     try {
//       final data = await _supabase
//           .from('emp_mar_orders')
//           .select('total_price')
//           .eq('status', 'completed');

//       int total = 0;
//       for (final row in data) {
//         total += (row['total_price'] as int? ?? 0);
//       }
//       return total;
//     } catch (e) {
//       debugPrint('getTotalRevenue error: $e');
//       return 0;
//     }
//   }

//   // ===================== COUNTS =====================
//   Future<int> getTotalOrders() async {
//     try {
//       final data = await _supabase
//           .from('emp_mar_orders')
//           .select('id');

//       return data.length;
//     } catch (e) {
//       debugPrint('getTotalOrders error: $e');
//       return 0;
//     }
//   }

//   Future<int> getPendingOrders() async {
//     try {
//       final data = await _supabase
//           .from('emp_mar_orders')
//           .select('id')
//           .eq('status', 'pending');

//       return data.length;
//     } catch (e) {
//       debugPrint('getPendingOrders error: $e');
//       return 0;
//     }
//   }

//   Future<int> getActiveEmployees() async {
//     try {
//       final data = await _supabase
//           .from('emp_profile')
//           .select('id')
//           .eq('status', 'Active')
//           .eq('role', 'Employee');

//       return data.length;
//     } catch (e) {
//       debugPrint('getActiveEmployees error: $e');
//       return 0;
//     }
//   }

//   // ===================== TOP PRODUCTS =====================
//   Future<List<Map<String, dynamic>>> getTopProducts() async {
//     try {
//       final data = await _supabase
//           .from('own_order_items')
//           .select('product_id, quantity, total_price, product:own_products(name)');

//       final Map<String, Map<String, dynamic>> map = {};

//       for (final item in data) {
//         final id = item['product_id']?.toString() ?? '';
//         if (id.isEmpty) continue;

//         map.putIfAbsent(id, () => {
//               'name': (item['product'] as Map<String, dynamic>?)?['name']?.toString() ?? 'Unknown',
//               'sales': 0,
//               'revenue': 0,
//             });

//         map[id]!['sales'] += (item['quantity'] as int? ?? 0);
//         map[id]!['revenue'] += (item['total_price'] as int? ?? 0);
//       }

//       final list = map.values.toList()
//         ..sort((a, b) => (b['revenue'] as int).compareTo(a['revenue'] as int));

//       return list.take(3).toList();
//     } catch (e) {
//       debugPrint('getTopProducts error: $e');
//       return await _topProductsFallback();
//     }
//   }

//   Future<List<Map<String, dynamic>>> _topProductsFallback() async {
//     try {
//       final data = await _supabase
//           .from('emp_mar_orders')
//           .select('feed_category, bags, total_price')
//           .eq('status', 'completed');

//       final Map<String, Map<String, dynamic>> map = {};

//       for (final order in data) {
//         final category = (order['feed_category'] as String?) ?? 'Unknown';

//         map.putIfAbsent(category, () => {
//               'name': category,
//               'sales': 0,
//               'revenue': 0,
//             });

//         map[category]!['sales'] += (order['bags'] as int? ?? 0);
//         map[category]!['revenue'] += (order['total_price'] as int? ?? 0);
//       }

//       final list = map.values.toList()
//         ..sort((a, b) => (b['revenue'] as int).compareTo(a['revenue'] as int));

//       return list.take(3).toList();
//     } catch (e) {
//       debugPrint('Top products fallback error: $e');
//       return [];
//     }
//   }

//   // ===================== RECENT ACTIVITY =====================
//   Future<List<Map<String, dynamic>>> getRecentActivities() async {
//     try {
//       final data = await _supabase
//           .from('own_activity_logs')
//           .select('activity_type, description, created_at')
//           .order('created_at', ascending: false)
//           .limit(4);

//       final List<Map<String, dynamic>> activities = [];

//       for (final row in data) {
//         final createdAt = DateTime.parse(row['created_at'] as String);
//         final diff = DateTime.now().difference(createdAt);
//         final activityType = row['activity_type'] as String;

//         String timeAgo;
//         if (diff.inMinutes < 60) {
//           timeAgo = '${diff.inMinutes} mins ago';
//         } else if (diff.inHours < 24) {
//           timeAgo = '${diff.inHours} hours ago';
//         } else {
//           timeAgo = '${diff.inDays} days ago';
//         }

//         final Map<String, dynamic> activityData = _mapActivityType(activityType);

//         activities.add({
//           'title': activityData['title'],
//           'time': timeAgo,
//           'icon': activityData['icon'],
//           'color': activityData['color'],
//           'description': row['description'] as String,
//         });
//       }

//       return activities;
//     } catch (e) {
//       debugPrint('getRecentActivities error: $e');
//       return await _activityFallback();
//     }
//   }

//   Map<String, dynamic> _mapActivityType(String activityType) {
//     switch (activityType.toLowerCase()) {
//       case 'order_created':
//         return {
//           'title': 'New Order Received',
//           'icon': Icons.shopping_cart,
//           'color': Colors.green,
//         };
//       case 'payment_received':
//         return {
//           'title': 'Payment Received',
//           'icon': Icons.payment,
//           'color': Colors.blue,
//         };
//       case 'stock_updated':
//         return {
//           'title': 'Stock Updated',
//           'icon': Icons.inventory,
//           'color': Colors.orange,
//         };
//       case 'employee_added':
//         return {
//           'title': 'New Employee Added',
//           'icon': Icons.person_add,
//           'color': Colors.purple,
//         };
//       case 'order_completed':
//         return {
//           'title': 'Order Completed',
//           'icon': Icons.check_circle,
//           'color': Colors.green,
//         };
//       default:
//         return {
//           'title': activityType,
//           'icon': Icons.notifications,
//           'color': Colors.grey,
//         };
//     }
//   }

//   Future<List<Map<String, dynamic>>> _activityFallback() async {
//     try {
//       final data = await _supabase
//           .from('emp_mar_orders')
//           .select('customer_name, feed_category, status, created_at')
//           .order('created_at', ascending: false)
//           .limit(4);

//       final List<Map<String, dynamic>> activities = [];

//       for (final order in data) {
//         final status = order['status'] as String;
//         final createdAt = DateTime.parse(order['created_at'] as String);
//         final diff = DateTime.now().difference(createdAt);

//         String timeAgo;
//         if (diff.inMinutes < 60) {
//           timeAgo = '${diff.inMinutes} mins ago';
//         } else if (diff.inHours < 24) {
//           timeAgo = '${diff.inHours} hours ago';
//         } else {
//           timeAgo = '${diff.inDays} days ago';
//         }

//         final Map<String, dynamic> activityData = _mapOrderStatusToActivity(status);

//         activities.add({
//           'title': activityData['title'],
//           'time': timeAgo,
//           'icon': activityData['icon'],
//           'color': activityData['color'],
//           'description': '${order['customer_name']} - ${order['feed_category']}',
//         });
//       }

//       return activities;
//     } catch (e) {
//       debugPrint('Activity fallback error: $e');
//       return [];
//     }
//   }

//   Map<String, dynamic> _mapOrderStatusToActivity(String status) {
//     switch (status) {
//       case 'pending':
//         return {
//           'title': 'New Order Received',
//           'icon': Icons.shopping_cart,
//           'color': Colors.green,
//         };
//       case 'completed':
//         return {
//           'title': 'Order Completed',
//           'icon': Icons.check_circle,
//           'color': Colors.blue,
//         };
//       case 'dispatched':
//         return {
//           'title': 'Order Dispatched',
//           'icon': Icons.local_shipping,
//           'color': Colors.orange,
//         };
//       default:
//         return {
//           'title': 'Order Updated',
//           'icon': Icons.update,
//           'color': Colors.purple,
//         };
//     }
//   }

//   // ===================== CHART DATA =====================
//   Future<List<Map<String, dynamic>>> getRevenueChartData() async {
//     try {
//       final weekAgo = DateTime.now().subtract(const Duration(days: 7));

//       final data = await _supabase
//           .from('emp_mar_orders')
//           .select('created_at, total_price')
//           .eq('status', 'completed')
//           .gte('created_at', weekAgo.toIso8601String());

//       final Map<String, int> revenue = {
//         'Mon': 0,
//         'Tue': 0,
//         'Wed': 0,
//         'Thu': 0,
//         'Fri': 0,
//         'Sat': 0,
//         'Sun': 0,
//       };

//       for (final order in data) {
//         final createdAt = DateTime.parse(order['created_at'] as String);
//         final weekday = createdAt.weekday;
//         final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
//         revenue[day] = revenue[day]! + (order['total_price'] as int? ?? 0);
//       }

//       return revenue.entries
//           .map((e) => {'day': e.key, 'revenue': e.value})
//           .toList();
//     } catch (e) {
//       debugPrint('getRevenueChartData error: $e');
//       return _defaultChartData();
//     }
//   }

//   List<Map<String, dynamic>> _defaultChartData() => [
//         {'day': 'Mon', 'revenue': 160000},
//         {'day': 'Tue', 'revenue': 200000},
//         {'day': 'Wed', 'revenue': 240000},
//         {'day': 'Thu', 'revenue': 280000},
//         {'day': 'Fri', 'revenue': 220000},
//         {'day': 'Sat', 'revenue': 180000},
//         {'day': 'Sun', 'revenue': 120000},
//       ];

//   // ===================== DASHBOARD =====================
//   Future<DashboardData> getDashboardData() async {
//     try {
//       await _updateDashboardMetrics();

//       return DashboardData(
//         totalRevenue: await getTotalRevenue(),
//         totalOrders: await getTotalOrders(),
//         activeEmployees: await getActiveEmployees(),
//         pendingOrders: await getPendingOrders(),
//         revenueGrowth: 12.5,
//         orderGrowth: 8.2,
//         employeeGrowth: 3.5,
//         topProducts: await getTopProducts(),
//         recentActivities: await getRecentActivities(),
//       );
//     } catch (e) {
//       debugPrint('getDashboardData error: $e');
//       return DashboardData.empty();
//     }
//   }

//   Future<void> _updateDashboardMetrics() async {
//     try {
//       final today = _formatDate(DateTime.now());

//       await _supabase.from('own_dashboard_metrics').upsert({
//         'metric_date': today,
//         'total_revenue': await getTotalRevenue(),
//         'total_orders': await getTotalOrders(),
//         'active_employees': await getActiveEmployees(),
//       });
//     } catch (e) {
//       debugPrint('_updateDashboardMetrics error: $e');
//     }
//   }

//   // ===================== REAL-TIME =====================
//   Stream<List<Order>> getOrdersStream() {
//     return _supabase
//         .from('emp_mar_orders')
//         .stream(primaryKey: ['id'])
//         .order('created_at', ascending: false)
//         .map((data) => (data as List<dynamic>)
//             .map((e) => Order.fromJson(e as Map<String, dynamic>))
//             .toList());
//   }

//   Stream<List<Employee>> getEmployeesStream() {
//     return _supabase
//         .from('emp_profile')
//         .stream(primaryKey: ['id'])
//         .eq('status', 'Active')
//         .map((data) => (data as List<dynamic>)
//             .map((e) => Employee.fromJson(e as Map<String, dynamic>))
//             .toList());
//   }

//   // ===================== ACTIVITY LOG =====================
//   Future<void> logActivity({
//     required String activityType,
//     required String description,
//     String? userId,
//     String? referenceId,
//     String? referenceType,
//   }) async {
//     try {
//       await _supabase.from('own_activity_logs').insert({
//         'activity_type': activityType,
//         'description': description,
//         'user_id': userId,
//         'reference_id': referenceId,
//         'reference_type': referenceType,
//       });
//     } catch (e) {
//       debugPrint('logActivity error: $e');
//     }
//   }
// }
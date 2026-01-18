// lib/services/supabase_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/employee_model.dart';
import 'package:intl/intl.dart';

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

  Future<double> getCurrentMonthRevenue() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      
      final data = await _supabase
          .from('emp_mar_orders')
          .select('total_price')
          .eq('status', 'completed')
          .gte('created_at', _formatDate(monthStart))
          .lte('created_at', _formatDate(monthEnd));

      double total = 0;
      for (final row in data) {
        total += (row['total_price'] as num? ?? 0).toDouble();
      }
      return total;
    } catch (e) {
      debugPrint('getCurrentMonthRevenue error: $e');
      return 0.0;
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

  Future<int> getCurrentMonthCompletedOrders() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      
      final data = await _supabase
          .from('emp_mar_orders')
          .select('id')
          .eq('status', 'completed')
          .gte('created_at', _formatDate(monthStart))
          .lte('created_at', _formatDate(monthEnd));

      return data.length;
    } catch (e) {
      debugPrint('getCurrentMonthCompletedOrders error: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    try {
      final response = await _supabase
          .from('emp_mar_orders')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getPendingOrders error: $e');
      return [];
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

  // ===================== EMPLOYEE METHODS =====================
  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      final response = await _supabase
          .from('emp_profile')
          .select('*')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getAllEmployees error: $e');
      return [];
    }
  }

  // ===================== ORDER METHODS =====================
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await _supabase
          .from('emp_mar_orders')
          .select('*')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getAllOrders error: $e');
      return [];
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('emp_mar_orders')
          .update({'status': newStatus})
          .eq('id', orderId);
    } catch (e) {
      debugPrint('updateOrderStatus error: $e');
      rethrow;
    }
  }

  // ===================== TOP PRODUCTS =====================
  Future<List<Map<String, dynamic>>> getTopProducts() async {
    try {
      final data = await _supabase
          .from('own_order_items')
          .select('product_id, quantity, total_price, product:own_products(name)');

      final Map<String, Map<String, dynamic>> map = {};

      for (final item in data) {
        final id = item['product_id']?.toString() ?? '';
        if (id.isEmpty) continue;

        map.putIfAbsent(id, () => {
              'name': (item['product'] as Map<String, dynamic>?)?['name']?.toString() ?? 'Unknown',
              'sales': 0,
              'revenue': 0,
            });

        map[id]!['sales'] += (item['quantity'] as int? ?? 0);
        map[id]!['revenue'] += (item['total_price'] as int? ?? 0);
      }

      final list = map.values.toList()
        ..sort((a, b) => (b['revenue'] as int).compareTo(a['revenue'] as int));

      return list.take(3).toList();
    } catch (e) {
      debugPrint('getTopProducts error: $e');
      return await _topProductsFallback();
    }
  }

  Future<List<Map<String, dynamic>>> _topProductsFallback() async {
    try {
      final data = await _supabase
          .from('emp_mar_orders')
          .select('feed_category, bags, total_price')
          .eq('status', 'completed');

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

      return list.take(3).toList();
    } catch (e) {
      debugPrint('Top products fallback error: $e');
      return [];
    }
  }

  // ===================== RECENT ACTIVITY =====================
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      final data = await _supabase
          .from('own_activity_logs')
          .select('activity_type, description, created_at')
          .order('created_at', ascending: false)
          .limit(4);

      final List<Map<String, dynamic>> activities = [];

      for (final row in data) {
        final createdAt = DateTime.parse(row['created_at'] as String);
        final diff = DateTime.now().difference(createdAt);
        final activityType = row['activity_type'] as String;

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
          'description': row['description'] as String,
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
      final data = await _supabase
          .from('emp_mar_orders')
          .select('customer_name, feed_category, status, created_at')
          .order('created_at', ascending: false)
          .limit(4);

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
      return [];
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
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final data = await _supabase
          .from('emp_mar_orders')
          .select('created_at, total_price')
          .eq('status', 'completed')
          .gte('created_at', weekAgo.toIso8601String());

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
        final createdAt = DateTime.parse(order['created_at'] as String);
        final weekday = createdAt.weekday;
        final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
        revenue[day] = revenue[day]! + (order['total_price'] as int? ?? 0);
      }

      return revenue.entries
          .map((e) => {'day': e.key, 'revenue': e.value})
          .toList();
    } catch (e) {
      debugPrint('getRevenueChartData error: $e');
      return _defaultChartData();
    }
  }

  List<Map<String, dynamic>> _defaultChartData() => [
        {'day': 'Mon', 'revenue': 160000},
        {'day': 'Tue', 'revenue': 200000},
        {'day': 'Wed', 'revenue': 240000},
        {'day': 'Thu', 'revenue': 280000},
        {'day': 'Fri', 'revenue': 220000},
        {'day': 'Sat', 'revenue': 180000},
        {'day': 'Sun', 'revenue': 120000},
      ];

  // ===================== PROFIT CALCULATION =====================
  Future<Map<String, dynamic>> getProfitMetrics() async {
    try {
      final today = DateTime.now();
      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 0);
      
      final monthStartStr = _formatDate(monthStart);
      final monthEndStr = _formatDate(monthEnd);

      // Get total revenue from completed orders this month
      final revenueResponse = await _supabase
          .from('emp_mar_orders')
          .select('total_price, created_at')
          .eq('status', 'completed')
          .gte('created_at', monthStartStr)
          .lte('created_at', monthEndStr);

      double totalRevenue = 0.0;
      for (var order in revenueResponse) {
        totalRevenue += (order['total_price'] as num).toDouble();
      }

      // Get raw material usage cost for this month
      final materialResponse = await _supabase
          .from('pro_raw_material_usage')
          .select('total_cost, raw_material_id, pro_inventory!inner(name)')
          .gte('usage_date', monthStartStr)
          .lte('usage_date', monthEndStr);

      double totalRawMaterialCost = 0.0;
      Map<String, double> materialCostBreakdown = {};

      for (var usage in materialResponse) {
        final cost = (usage['total_cost'] as num).toDouble();
        totalRawMaterialCost += cost;
        
        final inventoryData = usage['pro_inventory'] as Map<String, dynamic>?;
        final materialName = inventoryData?['name']?.toString() ?? 'Unknown Material';
        
        materialCostBreakdown[materialName] = (materialCostBreakdown[materialName] ?? 0) + cost;
      }

      // Calculate profit
      double totalProfit = totalRevenue - totalRawMaterialCost;
      double profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

      // Get production metrics for today
      final todayStr = _formatDate(today);
      final productionResponse = await _supabase
          .from('pro_production_logs')
          .select('SUM(quantity_produced) as total_quantity')
          .eq('production_date', todayStr)
          .single()
          .catchError((_) => {'total_quantity': 0});

      final targetResponse = await _supabase
          .from('pro_production_targets')
          .select('target_quantity')
          .eq('start_date', todayStr)
          .single()
          .catchError((_) => {'target_quantity': 100});

      final productionToday = (productionResponse['total_quantity'] ?? 0).toDouble();
      final productionTarget = (targetResponse['target_quantity'] ?? 100).toDouble();

      // Get completed orders count for this month
      final completedOrdersCount = revenueResponse.length;

      return {
        'totalRevenue': totalRevenue,
        'totalRawMaterialCost': totalRawMaterialCost,
        'totalProfit': totalProfit,
        'profitMargin': profitMargin,
        'materialCostBreakdown': materialCostBreakdown,
        'productionToday': productionToday,
        'productionTarget': productionTarget,
        'completedOrdersThisMonth': completedOrdersCount,
      };
    } catch (e) {
      debugPrint('Profit metrics error: $e');
      return {
        'totalRevenue': 0.0,
        'totalRawMaterialCost': 0.0,
        'totalProfit': 0.0,
        'profitMargin': 0.0,
        'materialCostBreakdown': {},
        'productionToday': 0.0,
        'productionTarget': 100.0,
        'completedOrdersThisMonth': 0,
      };
    }
  }

  // ===================== PROFIT CHART DATA =====================
  Future<List<Map<String, dynamic>>> getProfitChartData() async {
    try {
      final today = DateTime.now();
      final List<Map<String, dynamic>> profitData = [];

      // Get data for last 6 months
      for (int i = 5; i >= 0; i--) {
        final date = DateTime(today.year, today.month - i, 1);
        final monthStart = DateTime(date.year, date.month, 1);
        final monthEnd = DateTime(date.year, date.month + 1, 0);
        
        final monthStartStr = _formatDate(monthStart);
        final monthEndStr = _formatDate(monthEnd);

        // Get revenue for month
        final revenueResponse = await _supabase
            .from('emp_mar_orders')
            .select('total_price')
            .eq('status', 'completed')
            .gte('created_at', monthStartStr)
            .lte('created_at', monthEndStr);

        double monthRevenue = 0.0;
        for (var order in revenueResponse) {
          monthRevenue += (order['total_price'] as num).toDouble();
        }

        // Get material cost for month
        final materialResponse = await _supabase
            .from('pro_raw_material_usage')
            .select('total_cost')
            .gte('usage_date', monthStartStr)
            .lte('usage_date', monthEndStr);

        double monthMaterialCost = 0.0;
        for (var usage in materialResponse) {
          monthMaterialCost += (usage['total_cost'] as num).toDouble();
        }

        double monthProfit = monthRevenue - monthMaterialCost;
        double monthMargin = monthRevenue > 0 ? (monthProfit / monthRevenue) * 100 : 0;

        profitData.add({
          'month': DateFormat('MMM').format(date),
          'revenue': monthRevenue,
          'materialCost': monthMaterialCost,
          'profit': monthProfit,
          'margin': monthMargin,
          'monthNumber': date.month,
        });
      }

      return profitData;
    } catch (e) {
      debugPrint('Profit chart data error: $e');
      return [];
    }
  }

  // ===================== DISTRICT REVENUE DATA =====================
  Future<List<DistrictRevenueData>> getDistrictRevenueData() async {
    try {
      // This is a mock implementation. You should implement the actual logic
      // based on your database structure
      await Future.delayed(const Duration(milliseconds: 500));
      
      return [
        DistrictRevenueData(
          district: 'Kolhapur',
          branch: 'Main Branch',
          revenue: 450000,
          orders: 120,
          growth: 12.5,
          topProducts: ['Product A', 'Product B', 'Product C'],
        ),
        DistrictRevenueData(
          district: 'Pune',
          branch: 'City Branch',
          revenue: 620000,
          orders: 180,
          growth: 8.3,
          topProducts: ['Product X', 'Product Y'],
        ),
        DistrictRevenueData(
          district: 'Satara',
          branch: 'Satara Branch',
          revenue: 280000,
          orders: 85,
          growth: 15.2,
          topProducts: ['Product Z'],
        ),
        DistrictRevenueData(
          district: 'Sangli',
          branch: 'Sangli Branch',
          revenue: 320000,
          orders: 95,
          growth: 5.7,
          topProducts: ['Product A', 'Product D'],
        ),
      ];
    } catch (e) {
      debugPrint('getDistrictRevenueData error: $e');
      return [];
    }
  }

  // ===================== DASHBOARD DATA =====================
  Future<DashboardData> getDashboardData() async {
    try {
      // Update dashboard metrics first
      await _updateDashboardMetrics();

      // Get all data in parallel
      final pendingOrdersList = await getPendingOrders();
      final profitMetrics = await getProfitMetrics();
      final profitChartData = await getProfitChartData();

      // Calculate growth rates
      final revenueGrowth = await _calculateRevenueGrowth();
      final orderGrowth = await _calculateOrderGrowth();
      final employeeGrowth = await _calculateEmployeeGrowth();

      return DashboardData(
        totalRevenue: profitMetrics['totalRevenue'] as double,
        totalOrders: await getTotalOrders(),
        activeEmployees: await getActiveEmployees(),
        pendingOrders: pendingOrdersList.length,
        revenueGrowth: revenueGrowth,
        orderGrowth: orderGrowth,
        employeeGrowth: employeeGrowth,
        topProducts: await getTopProducts(),
        recentActivities: await getRecentActivities(),
        revenueChartData: await getRevenueChartData(),
        totalRawMaterialCost: profitMetrics['totalRawMaterialCost'] as double,
        totalProfit: profitMetrics['totalProfit'] as double,
        profitMargin: profitMetrics['profitMargin'] as double,
        materialCostBreakdown: profitMetrics['materialCostBreakdown'] as Map<String, double>,
        profitChartData: profitChartData,
        productionToday: profitMetrics['productionToday'] as double,
        productionTarget: profitMetrics['productionTarget'] as double,
        completedOrdersThisMonth: profitMetrics['completedOrdersThisMonth'] as int,
      );
    } catch (e) {
      debugPrint('getDashboardData error: $e');
      return DashboardData.empty();
    }
  }

  Future<double> _calculateRevenueGrowth() async {
    try {
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      
      // Current month revenue
      final currentMonthData = await _supabase
          .from('emp_mar_orders')
          .select('total_price')
          .eq('status', 'completed')
          .gte('created_at', _formatDate(currentMonthStart))
          .lte('created_at', _formatDate(now));

      double currentRevenue = 0;
      for (final row in currentMonthData) {
        currentRevenue += (row['total_price'] as num? ?? 0).toDouble();
      }

      // Last month revenue
      final lastMonthData = await _supabase
          .from('emp_mar_orders')
          .select('total_price')
          .eq('status', 'completed')
          .gte('created_at', _formatDate(lastMonthStart))
          .lte('created_at', _formatDate(lastMonthEnd));

      double lastMonthRevenue = 0;
      for (final row in lastMonthData) {
        lastMonthRevenue += (row['total_price'] as num? ?? 0).toDouble();
      }

      if (lastMonthRevenue == 0) return currentRevenue > 0 ? 100.0 : 0.0;
      return ((currentRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;
    } catch (e) {
      debugPrint('Revenue growth calculation error: $e');
      return 12.5; // Default growth
    }
  }

  Future<double> _calculateOrderGrowth() async {
    try {
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      
      // Current month orders
      final currentMonthData = await _supabase
          .from('emp_mar_orders')
          .select('id')
          .eq('status', 'completed')
          .gte('created_at', _formatDate(currentMonthStart))
          .lte('created_at', _formatDate(now));

      final currentOrders = currentMonthData.length;

      // Last month orders
      final lastMonthData = await _supabase
          .from('emp_mar_orders')
          .select('id')
          .eq('status', 'completed')
          .gte('created_at', _formatDate(lastMonthStart))
          .lte('created_at', _formatDate(lastMonthEnd));

      final lastMonthOrders = lastMonthData.length;

      if (lastMonthOrders == 0) return currentOrders > 0 ? 100.0 : 0.0;
      return ((currentOrders - lastMonthOrders) / lastMonthOrders) * 100;
    } catch (e) {
      debugPrint('Order growth calculation error: $e');
      return 8.2; // Default growth
    }
  }

  Future<double> _calculateEmployeeGrowth() async {
    // Simplified growth calculation
    return 3.5; // Default growth
  }

  Future<void> _updateDashboardMetrics() async {
    try {
      final today = _formatDate(DateTime.now());

      await _supabase.from('own_dashboard_metrics').upsert({
        'metric_date': today,
        'total_revenue': await getCurrentMonthRevenue(),
        'total_orders': await getTotalOrders(),
        'active_employees': await getActiveEmployees(),
      });
    } catch (e) {
      debugPrint('_updateDashboardMetrics error: $e');
    }
  }

  // ===================== REAL-TIME STREAMS =====================
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

  Stream<List<dynamic>> getRawMaterialUsageStream() {
    return _supabase
        .from('pro_raw_material_usage')
        .stream(primaryKey: ['id']);
  }

  Stream<Map<String, dynamic>> getProductionStream() {
    return _supabase
        .from('pro_production_logs')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final today = DateTime.now();
          final todayStr = _formatDate(today);
          
          try {
            final productionResponse = await _supabase
                .from('pro_production_logs')
                .select('SUM(quantity_produced) as total_quantity')
                .eq('production_date', todayStr)
                .single();

            return {
              'productionToday': (productionResponse['total_quantity'] ?? 0).toDouble(),
              'lastUpdated': DateTime.now(),
            };
          } catch (e) {
            debugPrint('Production stream fetch error: $e');
            return {
              'productionToday': 0.0,
              'lastUpdated': DateTime.now(),
            };
          }
        });
  }

  // ===================== PROFIT METRICS STREAM =====================
  Stream<Map<String, dynamic>> getProfitMetricsStream() {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      return await getProfitMetrics();
    });
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
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('logActivity error: $e');
    }
  }
}








// // lib/services/supabase_service.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/order_model.dart';
// import '../models/employee_model.dart';
// import 'package:intl/intl.dart';

// class SupabaseService {
//   final SupabaseClient _supabase = Supabase.instance.client;

//   // ===================== HELPERS =====================
//   String _formatDate(DateTime date) {
//     return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//   }
// // Add this method to SupabaseService class
// Future<List<Map<String, dynamic>>> getAllEmployees() async {
//   try {
//     final response = await _supabase
//         .from('emp_profile')
//         .select('*')
//         .order('created_at', ascending: false);
    
//     return List<Map<String, dynamic>>.from(response);
//   } catch (e) {
//     debugPrint('getAllEmployees error: $e');
//     return [];
//   }
// }

// Future<List<Map<String, dynamic>>> getAllOrders() async {
//   try {
//     final response = await _supabase
//         .from('emp_mar_orders')
//         .select('*')
//         .order('created_at', ascending: false);
    
//     return List<Map<String, dynamic>>.from(response);
//   } catch (e) {
//     debugPrint('getAllOrders error: $e');
//     return [];
//   }
// }

// // Add this method to update order status
// Future<void> updateOrderStatus(String orderId, String newStatus) async {
//   try {
//     await _supabase
//         .from('emp_mar_orders')
//         .update({'status': newStatus})
//         .eq('id', orderId);
//   } catch (e) {
//     debugPrint('updateOrderStatus error: $e');
//     rethrow;
//   }
// }

// // Update the getProductionStream method
// Stream<Map<String, dynamic>> getProductionStream() {
//   return _supabase
//       .from('pro_production_logs')
//       .stream(primaryKey: ['id'])
//       .asyncMap((data) async {
//         final today = DateTime.now();
//         final todayStr = _formatDate(today);
        
//         try {
//           final productionResponse = await _supabase
//               .from('pro_production_logs')
//               .select('SUM(quantity_produced) as total_quantity')
//               .eq('production_date', todayStr)
//               .single();

//           return {
//             'productionToday': (productionResponse['total_quantity'] ?? 0).toDouble(),
//             'lastUpdated': DateTime.now(),
//           };
//         } catch (e) {
//           debugPrint('Production stream fetch error: $e');
//           return {
//             'productionToday': 0.0,
//             'lastUpdated': DateTime.now(),
//           };
//         }
//       });
// }
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

//   Future<double> getCurrentMonthRevenue() async {
//     try {
//       final now = DateTime.now();
//       final monthStart = DateTime(now.year, now.month, 1);
//       final monthEnd = DateTime(now.year, now.month + 1, 0);
      
//       final data = await _supabase
//           .from('emp_mar_orders')
//           .select('total_price')
//           .eq('status', 'completed')
//           .gte('created_at', _formatDate(monthStart))
//           .lte('created_at', _formatDate(monthEnd));

//       double total = 0;
//       for (final row in data) {
//         total += (row['total_price'] as num? ?? 0).toDouble();
//       }
//       return total;
//     } catch (e) {
//       debugPrint('getCurrentMonthRevenue error: $e');
//       return 0.0;
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

//   Future<int> getCurrentMonthCompletedOrders() async {
//     try {
//       final now = DateTime.now();
//       final monthStart = DateTime(now.year, now.month, 1);
//       final monthEnd = DateTime(now.year, now.month + 1, 0);
      
//       final data = await _supabase
//           .from('emp_mar_orders')
//           .select('id')
//           .eq('status', 'completed')
//           .gte('created_at', _formatDate(monthStart))
//           .lte('created_at', _formatDate(monthEnd));

//       return data.length;
//     } catch (e) {
//       debugPrint('getCurrentMonthCompletedOrders error: $e');
//       return 0;
//     }
//   }

//   Future<List<Map<String, dynamic>>> getPendingOrders() async {
//     try {
//       final response = await _supabase
//           .from('emp_mar_orders')
//           .select('*')
//           .eq('status', 'pending')
//           .order('created_at', ascending: false);
      
//       return List<Map<String, dynamic>>.from(response);
//     } catch (e) {
//       debugPrint('getPendingOrders error: $e');
//       return [];
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

//   // ===================== PROFIT CALCULATION =====================
//   Future<Map<String, dynamic>> getProfitMetrics() async {
//     try {
//       final today = DateTime.now();
//       final monthStart = DateTime(today.year, today.month, 1);
//       final monthEnd = DateTime(today.year, today.month + 1, 0);
      
//       final monthStartStr = _formatDate(monthStart);
//       final monthEndStr = _formatDate(monthEnd);

//       // Get total revenue from completed orders this month
//       final revenueResponse = await _supabase
//           .from('emp_mar_orders')
//           .select('total_price, created_at')
//           .eq('status', 'completed')
//           .gte('created_at', monthStartStr)
//           .lte('created_at', monthEndStr);

//       double totalRevenue = 0.0;
//       for (var order in revenueResponse) {
//         totalRevenue += (order['total_price'] as num).toDouble();
//       }

//       // Get raw material usage cost for this month
//       final materialResponse = await _supabase
//           .from('pro_raw_material_usage')
//           .select('total_cost, raw_material_id, pro_inventory!inner(name)')
//           .gte('usage_date', monthStartStr)
//           .lte('usage_date', monthEndStr);

//       double totalRawMaterialCost = 0.0;
//       Map<String, double> materialCostBreakdown = {};

//       for (var usage in materialResponse) {
//         final cost = (usage['total_cost'] as num).toDouble();
//         totalRawMaterialCost += cost;
        
//         final inventoryData = usage['pro_inventory'] as Map<String, dynamic>?;
//         final materialName = inventoryData?['name']?.toString() ?? 'Unknown Material';
        
//         materialCostBreakdown[materialName] = (materialCostBreakdown[materialName] ?? 0) + cost;
//       }

//       // Calculate profit
//       double totalProfit = totalRevenue - totalRawMaterialCost;
//       double profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

//       // Get production metrics for today
//       final todayStr = _formatDate(today);
//       final productionResponse = await _supabase
//           .from('pro_production_logs')
//           .select('SUM(quantity_produced) as total_quantity')
//           .eq('production_date', todayStr)
//           .single()
//           .catchError((_) => {'total_quantity': 0});

//       final targetResponse = await _supabase
//           .from('pro_production_targets')
//           .select('target_quantity')
//           .eq('start_date', todayStr)
//           .single()
//           .catchError((_) => {'target_quantity': 100});

//       final productionToday = (productionResponse['total_quantity'] ?? 0).toDouble();
//       final productionTarget = (targetResponse['target_quantity'] ?? 100).toDouble();

//       // Get completed orders count for this month
//       final completedOrdersCount = revenueResponse.length;

//       return {
//         'totalRevenue': totalRevenue,
//         'totalRawMaterialCost': totalRawMaterialCost,
//         'totalProfit': totalProfit,
//         'profitMargin': profitMargin,
//         'materialCostBreakdown': materialCostBreakdown,
//         'productionToday': productionToday,
//         'productionTarget': productionTarget,
//         'completedOrdersThisMonth': completedOrdersCount,
//       };
//     } catch (e) {
//       debugPrint('Profit metrics error: $e');
//       return {
//         'totalRevenue': 0.0,
//         'totalRawMaterialCost': 0.0,
//         'totalProfit': 0.0,
//         'profitMargin': 0.0,
//         'materialCostBreakdown': {},
//         'productionToday': 0.0,
//         'productionTarget': 100.0,
//         'completedOrdersThisMonth': 0,
//       };
//     }
//   }

//   // ===================== PROFIT CHART DATA =====================
//   Future<List<Map<String, dynamic>>> getProfitChartData() async {
//     try {
//       final today = DateTime.now();
//       final List<Map<String, dynamic>> profitData = [];

//       // Get data for last 6 months
//       for (int i = 5; i >= 0; i--) {
//         final date = DateTime(today.year, today.month - i, 1);
//         final monthStart = DateTime(date.year, date.month, 1);
//         final monthEnd = DateTime(date.year, date.month + 1, 0);
        
//         final monthStartStr = _formatDate(monthStart);
//         final monthEndStr = _formatDate(monthEnd);

//         // Get revenue for month
//         final revenueResponse = await _supabase
//             .from('emp_mar_orders')
//             .select('total_price')
//             .eq('status', 'completed')
//             .gte('created_at', monthStartStr)
//             .lte('created_at', monthEndStr);

//         double monthRevenue = 0.0;
//         for (var order in revenueResponse) {
//           monthRevenue += (order['total_price'] as num).toDouble();
//         }

//         // Get material cost for month
//         final materialResponse = await _supabase
//             .from('pro_raw_material_usage')
//             .select('total_cost')
//             .gte('usage_date', monthStartStr)
//             .lte('usage_date', monthEndStr);

//         double monthMaterialCost = 0.0;
//         for (var usage in materialResponse) {
//           monthMaterialCost += (usage['total_cost'] as num).toDouble();
//         }

//         double monthProfit = monthRevenue - monthMaterialCost;
//         double monthMargin = monthRevenue > 0 ? (monthProfit / monthRevenue) * 100 : 0;

//         profitData.add({
//           'month': DateFormat('MMM').format(date),
//           'revenue': monthRevenue,
//           'materialCost': monthMaterialCost,
//           'profit': monthProfit,
//           'margin': monthMargin,
//           'monthNumber': date.month,
//         });
//       }

//       return profitData;
//     } catch (e) {
//       debugPrint('Profit chart data error: $e');
//       return [];
//     }
//   }

//   // ===================== DASHBOARD DATA =====================
//   Future<DashboardData> getDashboardData() async {
//     try {
//       // Update dashboard metrics first
//       await _updateDashboardMetrics();

//       // Get all data in parallel
//       final pendingOrdersList = await getPendingOrders();
//       final profitMetrics = await getProfitMetrics();
//       final profitChartData = await getProfitChartData();

//       // Calculate growth rates
//       final revenueGrowth = await _calculateRevenueGrowth();
//       final orderGrowth = await _calculateOrderGrowth();
//       final employeeGrowth = await _calculateEmployeeGrowth();

//       return DashboardData(
//         totalRevenue: profitMetrics['totalRevenue'] as double,
//         totalOrders: await getTotalOrders(),
//         activeEmployees: await getActiveEmployees(),
//         pendingOrders: pendingOrdersList.length,
//         revenueGrowth: revenueGrowth,
//         orderGrowth: orderGrowth,
//         employeeGrowth: employeeGrowth,
//         topProducts: await getTopProducts(),
//         recentActivities: await getRecentActivities(),
//         revenueChartData: await getRevenueChartData(),
//         totalRawMaterialCost: profitMetrics['totalRawMaterialCost'] as double,
//         totalProfit: profitMetrics['totalProfit'] as double,
//         profitMargin: profitMetrics['profitMargin'] as double,
//         materialCostBreakdown: profitMetrics['materialCostBreakdown'] as Map<String, double>,
//         profitChartData: profitChartData,
//         productionToday: profitMetrics['productionToday'] as double,
//         productionTarget: profitMetrics['productionTarget'] as double,
//         completedOrdersThisMonth: profitMetrics['completedOrdersThisMonth'] as int,
//       );
//     } catch (e) {
//       debugPrint('getDashboardData error: $e');
//       return DashboardData.empty();
//     }
//   }

//   Future<double> _calculateRevenueGrowth() async {
//     try {
//       final now = DateTime.now();
//       final currentMonthStart = DateTime(now.year, now.month, 1);
//       final lastMonthStart = DateTime(now.year, now.month - 1, 1);
//       final lastMonthEnd = DateTime(now.year, now.month, 0);
      
//       // Current month revenue
//       final currentMonthData = await _supabase
//           .from('emp_mar_orders')
//           .select('total_price')
//           .eq('status', 'completed')
//           .gte('created_at', _formatDate(currentMonthStart))
//           .lte('created_at', _formatDate(now));

//       double currentRevenue = 0;
//       for (final row in currentMonthData) {
//         currentRevenue += (row['total_price'] as num? ?? 0).toDouble();
//       }

//       // Last month revenue
//       final lastMonthData = await _supabase
//           .from('emp_mar_orders')
//           .select('total_price')
//           .eq('status', 'completed')
//           .gte('created_at', _formatDate(lastMonthStart))
//           .lte('created_at', _formatDate(lastMonthEnd));

//       double lastMonthRevenue = 0;
//       for (final row in lastMonthData) {
//         lastMonthRevenue += (row['total_price'] as num? ?? 0).toDouble();
//       }

//       if (lastMonthRevenue == 0) return currentRevenue > 0 ? 100.0 : 0.0;
//       return ((currentRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;
//     } catch (e) {
//       debugPrint('Revenue growth calculation error: $e');
//       return 12.5; // Default growth
//     }
//   }

//   Future<double> _calculateOrderGrowth() async {
//     try {
//       final now = DateTime.now();
//       final currentMonthStart = DateTime(now.year, now.month, 1);
//       final lastMonthStart = DateTime(now.year, now.month - 1, 1);
//       final lastMonthEnd = DateTime(now.year, now.month, 0);
      
//       // Current month orders
//       final currentMonthData = await _supabase
//           .from('emp_mar_orders')
//           .select('id')
//           .eq('status', 'completed')
//           .gte('created_at', _formatDate(currentMonthStart))
//           .lte('created_at', _formatDate(now));

//       final currentOrders = currentMonthData.length;

//       // Last month orders
//       final lastMonthData = await _supabase
//           .from('emp_mar_orders')
//           .select('id')
//           .eq('status', 'completed')
//           .gte('created_at', _formatDate(lastMonthStart))
//           .lte('created_at', _formatDate(lastMonthEnd));

//       final lastMonthOrders = lastMonthData.length;

//       if (lastMonthOrders == 0) return currentOrders > 0 ? 100.0 : 0.0;
//       return ((currentOrders - lastMonthOrders) / lastMonthOrders) * 100;
//     } catch (e) {
//       debugPrint('Order growth calculation error: $e');
//       return 8.2; // Default growth
//     }
//   }

//   Future<double> _calculateEmployeeGrowth() async {
//     // Simplified growth calculation
//     return 3.5; // Default growth
//   }

//   Future<void> _updateDashboardMetrics() async {
//     try {
//       final today = _formatDate(DateTime.now());

//       await _supabase.from('own_dashboard_metrics').upsert({
//         'metric_date': today,
//         'total_revenue': await getCurrentMonthRevenue(),
//         'total_orders': await getTotalOrders(),
//         'active_employees': await getActiveEmployees(),
//       });
//     } catch (e) {
//       debugPrint('_updateDashboardMetrics error: $e');
//     }
//   }

//   // ===================== REAL-TIME STREAMS =====================
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

//   Stream<List<dynamic>> getRawMaterialUsageStream() {
//     return _supabase
//         .from('pro_raw_material_usage')
//         .stream(primaryKey: ['id']);
//   }

//   Stream<List<dynamic>> getProductionLogsStream() {
//     return _supabase
//         .from('pro_production_logs')
//         .stream(primaryKey: ['id']);
//   }

//   // ===================== PROFIT METRICS STREAM =====================
//   Stream<Map<String, dynamic>> getProfitMetricsStream() {
//     return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
//       return await getProfitMetrics();
//     });
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
//         'created_at': DateTime.now().toIso8601String(),
//       });
//     } catch (e) {
//       debugPrint('logActivity error: $e');
//     }
//   }
// }






//works

// // lib/services/supabase_service.dart
// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:mega_pro/models/own_revenue_model.dart';
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

//   // // In lib/services/supabase_service.dart

// // Get pending orders with full details
// Future<List<Map<String, dynamic>>> getPendingOrders() async {
//   try {
//     final response = await _supabase
//         .from('emp_mar_orders')
//         .select('*')
//         .eq('status', 'pending')
//         .order('created_at', ascending: false);
    
//     return List<Map<String, dynamic>>.from(response);
//   } catch (e) {
//     debugPrint('getPendingOrders error: $e');
//     return [];
//   }
// }
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

//       final pendingOrdersList = await getPendingOrders();
//       return DashboardData(
//         totalRevenue: (await getTotalRevenue()).toDouble(),
//         totalOrders: await getTotalOrders(),
//         activeEmployees: await getActiveEmployees(),
//         pendingOrders: pendingOrdersList.length,
//         revenueGrowth: 12.5,
//         orderGrowth: 8.2,
//         employeeGrowth: 3.5,
//         topProducts: await getTopProducts(),
//         recentActivities: await getRecentActivities(), revenueChartData: [], totalRawMaterialCost: 0.0, totalProfit: 0.0, profitMargin: 0.0, materialCostBreakdown: {}, profitChartData: [], productionToday: 0.0, productionTarget: 0.0,
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










//   // Add these methods to your existing SupabaseService class

// // Get all orders
// Future<List<Map<String, dynamic>>> getAllOrders() async {
//   try {
//     final response = await _supabase
//         .from('emp_mar_orders')
//         .select('*')
//         .order('created_at', ascending: false);
    
//     return List<Map<String, dynamic>>.from(response);
//   } catch (e) {
//     debugPrint('getAllOrders error: $e');
//     return [];
//   }
// }

// // Get district-wise revenue data
// Future<List<DistrictRevenueData>> getDistrictRevenueData() async {
//   try {
//     // Get all orders grouped by district
//     final ordersResponse = await _supabase
//         .from('emp_mar_orders')
//         .select('district, total_price, status, created_at')
//         .eq('status', 'completed');

//     // Group orders by district
//     final Map<String, List<Map<String, dynamic>>> districtOrders = {};
    
//     for (final order in ordersResponse) {
//       final district = order['district']?.toString() ?? 'Unknown';
//       districtOrders.putIfAbsent(district, () => []);
//       districtOrders[district]!.add(order);
//     }

//     // Calculate revenue for each district
//     final List<DistrictRevenueData> districtData = [];
    
//     for (final entry in districtOrders.entries) {
//       final district = entry.key;
//       final orders = entry.value;
      
//       final totalRevenue = orders.fold(0.0, (sum, order) {
//         return sum + ((order['total_price'] as num?)?.toDouble() ?? 0.0);
//       });
      
//       final totalOrders = orders.length;
      
//       // Get branch info from employee profiles
//       final branchResponse = await _supabase
//           .from('emp_profile')
//           .select('district, branch')
//           .eq('district', district)
//           .limit(1);
      
//       final branch = branchResponse.isNotEmpty 
//           ? (branchResponse[0]['branch']?.toString() ?? 'Main Branch')
//           : 'Main Branch';
      
//       // Get top products for this district
//       final topProducts = await _getDistrictTopProducts(district);
      
//       districtData.add(DistrictRevenueData(
//         district: district,
//         branch: branch,
//         revenue: totalRevenue,
//         orders: totalOrders,
//         growth: _calculateDistrictGrowth(district, totalRevenue),
//         topProducts: topProducts,
//       ));
//     }
    
//     // Sort by revenue descending
//     districtData.sort((a, b) => b.revenue.compareTo(a.revenue));
    
//     return districtData;
//   } catch (e) {
//     debugPrint('getDistrictRevenueData error: $e');
//     return [];
//   }
// }

// // Get top products for a district
// Future<List<String>> _getDistrictTopProducts(String district) async {
//   try {
//     final response = await _supabase
//         .from('emp_mar_orders')
//         .select('feed_category')
//         .eq('district', district)
//         .eq('status', 'completed');
    
//     final Map<String, int> productCount = {};
    
//     for (final order in response) {
//       final product = order['feed_category']?.toString() ?? 'Unknown';
//       productCount[product] = (productCount[product] ?? 0) + 1;
//     }
    
//     // Get top 3 products
//     final sortedProducts = productCount.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));
    
//     return sortedProducts.take(3).map((e) => e.key).toList();
//   } catch (e) {
//     debugPrint('_getDistrictTopProducts error: $e');
//     return [];
//   }
// }

// // Calculate growth percentage (simplified - can be improved)
// double _calculateDistrictGrowth(String district, double currentRevenue) {
//   // For now, return a mock growth percentage
//   // You can implement actual growth calculation based on historical data
//   final mockGrowth = {
//     'Kolhapur': 12.5,
//     'Pune': 8.3,
//     'Satara': 15.2,
//     'Sangli': 5.7,
//   };
  
//   return mockGrowth[district] ?? 10.0;
// }

// // Get all employees
// Future<List<Map<String, dynamic>>> getAllEmployees() async {
//   try {
//     final response = await _supabase
//         .from('emp_profile')
//         .select('*')
//         .eq('role', 'Employee')
//         .order('created_at', ascending: false);
    
//     return List<Map<String, dynamic>>.from(response);
//   } catch (e) {
//     debugPrint('getAllEmployees error: $e');
//     return [];
//   }
// }

// // Update order status
// Future<void> updateOrderStatus(String orderId, String newStatus) async {
//   try {
//     await _supabase
//         .from('emp_mar_orders')
//         .update({'status': newStatus})
//         .eq('id', orderId);
//   } catch (e) {
//     debugPrint('updateOrderStatus error: $e');
//     rethrow;
//   }
// }
// }
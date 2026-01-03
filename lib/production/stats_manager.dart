// stats_manager.dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class StatsManager {
  static int pendingOrders = 0;
  static int lowStockItems = 0;
  
  static Future<void> loadStats() async {
    try {
      // Get pending orders count
      final empPending = await supabase
          .from('emp_orders')
          .select('count')
          .eq('status', 'Pending');
      
      final managerPending = await supabase
          .from('manager_orders')
          .select('count')
          .eq('order_status', 'Pending');

      // Get low stock items
      final lowStock = await supabase
          .from('inventory')
          .select('count')
          .lt('stock', 'reorder_level');

      pendingOrders = (empPending.first['count'] ?? 0) + 
                     (managerPending.first['count'] ?? 0);
      lowStockItems = lowStock.first['count'] ?? 0;
    } catch (e) {
      print('Error loading stats: $e');
    }
  }
  
  static void refreshStats() {
    loadStats();
  }
}
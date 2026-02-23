
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient supabase;
  
  OrderService(this.supabase);
  
  // Create order with notifications
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      // Add employee_id if user is logged in
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        orderData['employee_id'] = userId;
      }
      
      // Add timestamps
      final now = DateTime.now().toUtc().toIso8601String();
      orderData['created_at'] = now;
      orderData['updated_at'] = now;
      
      // Create order - CRITICAL: Use .select() to get all fields including generated ones
      final response = await supabase
        .from('emp_mar_orders')
        .insert(orderData)
        .select()  // This selects the inserted row with all fields
        .single();
      
      print('✅ Order created successfully: ${response['id']}');
      print('📊 Generated order_number: ${response['order_number']}');
      print('🔑 Tracking token: ${response['tracking_token']}');
      
      return response;
    } catch (e) {
      print('❌ Error creating order: $e');
      rethrow;
    }
  }
  
  // Get all orders
  Future<List<Map<String, dynamic>>> getOrders({
    int limit = 50,
    int offset = 0,
    String? status,
    String? employeeId,
  }) async {
    try {
      // Build query step by step
      dynamic query;
      
      // Start with base query
      if (employeeId != null && employeeId.isNotEmpty) {
        query = supabase
          .from('emp_mar_orders')
          .select()
          .eq('employee_id', employeeId);
      } else {
        query = supabase
          .from('emp_mar_orders')
          .select();
      }
      
      // Cast to the correct type and add filters
      if (query is PostgrestFilterBuilder) {
        if (status != null && status.isNotEmpty && status != 'all') {
          query = query.eq('status', status);
        }
        
        // Add ordering and pagination
        query = query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
        
        // Execute query
        final response = await query;
        
        // Handle response
        if (response is List) {
          return List<Map<String, dynamic>>.from(response);
        } else if (response is Map<String, dynamic>) {
          return [response];
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Error fetching orders: $e');
      return [];
    }
  }
  
  // Get single order
  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final response = await supabase
        .from('emp_mar_orders')
        .select()  // Select all columns
        .eq('id', orderId)
        .single();  // Use single() instead of maybeSingle()
      
      print('📋 Fetched order details:');
      print('   Order ID: ${response['id']}');
      print('   Order Number: ${response['order_number']}');
      print('   Status: ${response['status']}');
      return response;
    } catch (e) {
      print('❌ Error fetching order: $e');
      return null;
    }
  }
  
  // Get order by tracking token
  Future<Map<String, dynamic>?> getOrderByTrackingToken(String trackingToken) async {
    try {
      final response = await supabase
        .from('emp_mar_orders')
        .select()
        .eq('tracking_token', trackingToken)
        .maybeSingle();
      
      if (response != null) {
        return response;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching order by tracking token: $e');
      return null;
    }
  }
  
  // Update order status
  Future<bool> updateOrderStatus(
    String orderId, 
    String status, 
    {String? notes, bool sendNotification = true}
  ) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      
      if (notes != null && notes.isNotEmpty) {
        updateData['remarks'] = notes;
      }
      
      await supabase
        .from('emp_mar_orders')
        .update(updateData)
        .eq('id', orderId);
      
      print('✅ Order status updated to: $status');
      return true;
    } catch (e) {
      print('❌ Error updating order status: $e');
      return false;
    }
  }
  
  // Bulk update order status
  Future<bool> updateBulkOrderStatus(
    List<String> orderIds, 
    String status,
    {String? notes}
  ) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      
      if (notes != null && notes.isNotEmpty) {
        updateData['remarks'] = notes;
      }
      
      bool allSuccess = true;
      
      // Update each order individually
      for (final orderId in orderIds) {
        try {
          await supabase
            .from('emp_mar_orders')
            .update(updateData)
            .eq('id', orderId);
        } catch (e) {
          print('❌ Error updating order $orderId: $e');
          allSuccess = false;
        }
      }
      
      if (allSuccess) {
        print('✅ All ${orderIds.length} orders updated to: $status');
      }
      
      return allSuccess;
    } catch (e) {
      print('❌ Error bulk updating order status: $e');
      return false;
    }
  }
  
  // Delete order
  Future<bool> deleteOrder(String orderId) async {
    try {
      await supabase
        .from('emp_mar_orders')
        .delete()
        .eq('id', orderId);
      
      print('✅ Order deleted: $orderId');
      return true;
    } catch (e) {
      print('❌ Error deleting order: $e');
      return false;
    }
  }
  
  // Get orders by employee with pagination
  Future<List<Map<String, dynamic>>> getOrdersByEmployee({
    required String employeeId,
    int page = 0,
    int limit = 20,
    String? status,
  }) async {
    try {
      // Start with base query
      dynamic query = supabase
        .from('emp_mar_orders')
        .select()
        .eq('employee_id', employeeId);
      
      // Add status filter if provided
      if (status != null && status.isNotEmpty && status != 'all') {
        if (query is PostgrestFilterBuilder) {
          query = query.eq('status', status);
        }
      }
      
      // Add ordering and pagination
      if (query is PostgrestFilterBuilder) {
        query = query
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);
        
        // Execute query
        final response = await query;
        
        if (response is List) {
          return List<Map<String, dynamic>>.from(response);
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Error getting orders by employee: $e');
      return [];
    }
  }
  
  // Get order statistics
  Future<Map<String, int>> getOrderStatistics({String? employeeId}) async {
    try {
      List<Map<String, dynamic>> orders = [];
      
      if (employeeId != null && employeeId.isNotEmpty) {
        final response = await supabase
          .from('emp_mar_orders')
          .select('status')
          .eq('employee_id', employeeId);
        
        orders = List<Map<String, dynamic>>.from(response);
            } else {
        final response = await supabase
          .from('emp_mar_orders')
          .select('status');
        
        orders = List<Map<String, dynamic>>.from(response);
            }
      
      // Calculate statistics
      return {
        'total': orders.length,
        'pending': orders.where((o) => o['status'] == 'pending').length,
        'packing': orders.where((o) => o['status'] == 'packing').length,
        'ready_for_dispatch': orders.where((o) => o['status'] == 'ready_for_dispatch').length,
        'dispatched': orders.where((o) => o['status'] == 'dispatched').length,
        'delivered': orders.where((o) => o['status'] == 'delivered').length,
        'completed': orders.where((o) => o['status'] == 'completed').length,
        'cancelled': orders.where((o) => o['status'] == 'cancelled').length,
      };
    } catch (e) {
      print('❌ Error getting order statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'packing': 0,
        'ready_for_dispatch': 0,
        'dispatched': 0,
        'delivered': 0,
        'completed': 0,
        'cancelled': 0,
      };
    }
  }
  
  // Get tracking page URL
  String getTrackingUrl(String trackingToken) {
    // For web app
    return 'https://mega-pro.in/track/$trackingToken';
  }
  
  // Get shareable tracking message
  String getShareableTrackingMessage(Map<String, dynamic> order) {
    final trackingToken = order['tracking_token']?.toString() ?? '';
    final trackingUrl = getTrackingUrl(trackingToken);
    final orderNumber = order['order_number']?.toString() ?? 'N/A';
    final customerName = order['customer_name']?.toString() ?? 'Customer';
    final status = order['status']?.toString().toUpperCase() ?? 'PENDING';
    
    return '''
📦 Cattle Feed Order Tracking
Order: $orderNumber
Customer: $customerName
Status: $status
Track here: $trackingUrl
''';
  }
  
  // Search orders
  Future<List<Map<String, dynamic>>> searchOrders({
    required String searchTerm,
    String? employeeId,
    int limit = 20,
  }) async {
    try {
      // Build base query
      dynamic query;
      
      if (employeeId != null && employeeId.isNotEmpty) {
        query = supabase
          .from('emp_mar_orders')
          .select()
          .eq('employee_id', employeeId);
      } else {
        query = supabase
          .from('emp_mar_orders')
          .select();
      }
      
      // Add search filter
      if (query is PostgrestFilterBuilder) {
        query = query
          .or('customer_name.ilike.%$searchTerm%,customer_mobile.ilike.%$searchTerm%,order_number.ilike.%$searchTerm%')
          .order('created_at', ascending: false)
          .limit(limit);
        
        final response = await query;
        
        if (response is List) {
          return List<Map<String, dynamic>>.from(response);
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Error searching orders: $e');
      return [];
    }
  }
  
  // Get orders count
  Future<int> getOrdersCount({String? employeeId, String? status}) async {
    try {
      // Get all orders and count manually
      List<Map<String, dynamic>> orders = [];
      
      if (employeeId != null && employeeId.isNotEmpty) {
        final response = await supabase
          .from('emp_mar_orders')
          .select('id, status')
          .eq('employee_id', employeeId);
        
        orders = List<Map<String, dynamic>>.from(response);
            } else {
        final response = await supabase
          .from('emp_mar_orders')
          .select('id, status');
        
        orders = List<Map<String, dynamic>>.from(response);
            }
      
      // Apply status filter if needed
      if (status != null && status.isNotEmpty && status != 'all') {
        orders = orders.where((order) => order['status'] == status).toList();
      }
      
      return orders.length;
    } catch (e) {
      print('❌ Error getting orders count: $e');
      return 0;
    }
  }
  
  // Get recent orders
  Future<List<Map<String, dynamic>>> getRecentOrders({
    int days = 7,
    String? employeeId,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final cutoffDateStr = cutoffDate.toUtc().toIso8601String();
      
      // Build base query
      dynamic query;
      
      if (employeeId != null && employeeId.isNotEmpty) {
        query = supabase
          .from('emp_mar_orders')
          .select()
          .eq('employee_id', employeeId);
      } else {
        query = supabase
          .from('emp_mar_orders')
          .select();
      }
      
      // Add date filter and ordering
      if (query is PostgrestFilterBuilder) {
        query = query
          .gte('created_at', cutoffDateStr)
          .order('created_at', ascending: false);
        
        final response = await query;
        
        if (response is List) {
          return List<Map<String, dynamic>>.from(response);
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Error getting recent orders: $e');
      return [];
    }
  }
}











// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:supabase_flutter/supabase_flutter.dart';

// class OrderService {
//   final SupabaseClient supabase;
  
//   OrderService(this.supabase);
  
//   // Create order with notifications
//   // In order_service.dart, update the createOrder method:
// // In your order_service.dart, update the createOrder method:
// Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
//   try {
//     // Add employee_id if user is logged in
//     final userId = supabase.auth.currentUser?.id;
//     if (userId != null) {
//       orderData['employee_id'] = userId;
//     }
    
//     // Add timestamps
//     final now = DateTime.now().toUtc().toIso8601String();
//     orderData['created_at'] = now;
//     orderData['updated_at'] = now;
    
//     // Create order - CRITICAL: Use .select() to get all fields including generated ones
//     final response = await supabase
//       .from('emp_mar_orders')
//       .insert(orderData)
//       .select()  // This selects the inserted row with all fields
//       .single();
    
//     print('✅ Order created successfully: ${response['id']}');
//     print('📊 Generated order_number: ${response['order_number']}');
//     print('🔑 Tracking token: ${response['tracking_token']}');
    
//     return response;
//   } catch (e) {
//     print('❌ Error creating order: $e');
//     rethrow;
//   }
// }
//   // Get all orders - SIMPLIFIED AND FIXED
//   Future<List<Map<String, dynamic>>> getOrders({
//     int limit = 50,
//     int offset = 0,
//     String? status,
//     String? employeeId,
//   }) async {
//     try {
//       // Build query step by step
//       dynamic query;
      
//       // Start with base query
//       if (employeeId != null && employeeId.isNotEmpty) {
//         query = supabase
//           .from('emp_mar_orders')
//           .select()
//           .eq('employee_id', employeeId);
//       } else {
//         query = supabase
//           .from('emp_mar_orders')
//           .select();
//       }
      
//       // Cast to the correct type and add filters
//       if (query is PostgrestFilterBuilder) {
//         if (status != null && status.isNotEmpty && status != 'all') {
//           query = query.eq('status', status);
//         }
        
//         // Add ordering and pagination
//         query = query
//           .order('created_at', ascending: false)
//           .range(offset, offset + limit - 1);
        
//         // Execute query
//         final response = await query;
        
//         // Handle response
//         if (response is List) {
//           return List<Map<String, dynamic>>.from(response);
//         } else if (response is Map<String, dynamic>) {
//           return [response];
//         }
//       }
      
//       return [];
//     } catch (e) {
//       print('❌ Error fetching orders: $e');
//       return [];
//     }
//   }
  
//   // Get single order - SIMPLIFIED
//   // Get single order - ensure it fetches order_number
// Future<Map<String, dynamic>?> getOrder(String orderId) async {
//   try {
//     final response = await supabase
//       .from('emp_mar_orders')
//       .select()  // Select all columns
//       .eq('id', orderId)
//       .single();  // Use single() instead of maybeSingle()
    
//     if (response != null) {
//       print('📋 Fetched order details:');
//       print('   Order ID: ${response['id']}');
//       print('   Order Number: ${response['order_number']}');
//       print('   Status: ${response['status']}');
//       return response as Map<String, dynamic>;
//     }
//     return null;
//   } catch (e) {
//     print('❌ Error fetching order: $e');
//     return null;
//   }
// }
  
//   // Get order by tracking token - SIMPLIFIED
//   Future<Map<String, dynamic>?> getOrderByTrackingToken(String trackingToken) async {
//     try {
//       final response = await supabase
//         .from('emp_mar_orders')
//         .select()
//         .eq('tracking_token', trackingToken)
//         .maybeSingle();
      
//       if (response != null) {
//         return response as Map<String, dynamic>;
//       }
//       return null;
//     } catch (e) {
//       print('❌ Error fetching order by tracking token: $e');
//       return null;
//     }
//   }
  
//   // Update order status - SIMPLIFIED
//   Future<bool> updateOrderStatus(
//     String orderId, 
//     String status, 
//     {String? notes, bool sendNotification = true}
//   ) async {
//     try {
//       final updateData = <String, dynamic>{
//         'status': status,
//         'updated_at': DateTime.now().toUtc().toIso8601String(),
//       };
      
//       if (notes != null && notes.isNotEmpty) {
//         updateData['remarks'] = notes;
//       }
      
//       await supabase
//         .from('emp_mar_orders')
//         .update(updateData)
//         .eq('id', orderId);
      
//       print('✅ Order status updated to: $status');
//       return true;
//     } catch (e) {
//       print('❌ Error updating order status: $e');
//       return false;
//     }
//   }
  
//   // Bulk update order status - SIMPLIFIED
//   Future<bool> updateBulkOrderStatus(
//     List<String> orderIds, 
//     String status,
//     {String? notes}
//   ) async {
//     try {
//       final updateData = <String, dynamic>{
//         'status': status,
//         'updated_at': DateTime.now().toUtc().toIso8601String(),
//       };
      
//       if (notes != null && notes.isNotEmpty) {
//         updateData['remarks'] = notes;
//       }
      
//       bool allSuccess = true;
      
//       // Update each order individually
//       for (final orderId in orderIds) {
//         try {
//           await supabase
//             .from('emp_mar_orders')
//             .update(updateData)
//             .eq('id', orderId);
//         } catch (e) {
//           print('❌ Error updating order $orderId: $e');
//           allSuccess = false;
//         }
//       }
      
//       if (allSuccess) {
//         print('✅ All ${orderIds.length} orders updated to: $status');
//       }
      
//       return allSuccess;
//     } catch (e) {
//       print('❌ Error bulk updating order status: $e');
//       return false;
//     }
//   }
  
//   // Delete order - SIMPLIFIED
//   Future<bool> deleteOrder(String orderId) async {
//     try {
//       await supabase
//         .from('emp_mar_orders')
//         .delete()
//         .eq('id', orderId);
      
//       print('✅ Order deleted: $orderId');
//       return true;
//     } catch (e) {
//       print('❌ Error deleting order: $e');
//       return false;
//     }
//   }
  
//   // Get orders by employee with pagination - SIMPLIFIED
//   Future<List<Map<String, dynamic>>> getOrdersByEmployee({
//     required String employeeId,
//     int page = 0,
//     int limit = 20,
//     String? status,
//   }) async {
//     try {
//       // Start with base query
//       dynamic query = supabase
//         .from('emp_mar_orders')
//         .select()
//         .eq('employee_id', employeeId);
      
//       // Add status filter if provided
//       if (status != null && status.isNotEmpty && status != 'all') {
//         if (query is PostgrestFilterBuilder) {
//           query = query.eq('status', status);
//         }
//       }
      
//       // Add ordering and pagination
//       if (query is PostgrestFilterBuilder) {
//         query = query
//           .order('created_at', ascending: false)
//           .range(page * limit, (page + 1) * limit - 1);
        
//         // Execute query
//         final response = await query;
        
//         if (response is List) {
//           return List<Map<String, dynamic>>.from(response);
//         }
//       }
      
//       return [];
//     } catch (e) {
//       print('❌ Error getting orders by employee: $e');
//       return [];
//     }
//   }
  
//   // Get order statistics - SIMPLIFIED
//   Future<Map<String, int>> getOrderStatistics({String? employeeId}) async {
//     try {
//       List<Map<String, dynamic>> orders = [];
      
//       if (employeeId != null && employeeId.isNotEmpty) {
//         final response = await supabase
//           .from('emp_mar_orders')
//           .select('status')
//           .eq('employee_id', employeeId);
        
//         if (response is List) {
//           orders = List<Map<String, dynamic>>.from(response);
//         }
//       } else {
//         final response = await supabase
//           .from('emp_mar_orders')
//           .select('status');
        
//         if (response is List) {
//           orders = List<Map<String, dynamic>>.from(response);
//         }
//       }
      
//       // Calculate statistics
//       return {
//         'total': orders.length,
//         'pending': orders.where((o) => o['status'] == 'pending').length,
//         'packing': orders.where((o) => o['status'] == 'packing').length,
//         'ready_for_dispatch': orders.where((o) => o['status'] == 'ready_for_dispatch').length,
//         'dispatched': orders.where((o) => o['status'] == 'dispatched').length,
//         'delivered': orders.where((o) => o['status'] == 'delivered').length,
//         'completed': orders.where((o) => o['status'] == 'completed').length,
//         'cancelled': orders.where((o) => o['status'] == 'cancelled').length,
//       };
//     } catch (e) {
//       print('❌ Error getting order statistics: $e');
//       return {
//         'total': 0,
//         'pending': 0,
//         'packing': 0,
//         'ready_for_dispatch': 0,
//         'dispatched': 0,
//         'delivered': 0,
//         'completed': 0,
//         'cancelled': 0,
//       };
//     }
//   }
  
//   // Get tracking page URL
//   String getTrackingUrl(String trackingToken) {
//     // For web app
//     return 'https://yourapp.com/track/$trackingToken';
    
//     // For Flutter app with deep linking:
//     // return 'yourapp://track/$trackingToken';
//   }
  
//   // Get shareable tracking message
//   String getShareableTrackingMessage(Map<String, dynamic> order) {
//     final trackingToken = order['tracking_token']?.toString() ?? '';
//     final trackingUrl = getTrackingUrl(trackingToken);
//     final orderNumber = order['order_number']?.toString() ?? 'N/A';
//     final customerName = order['customer_name']?.toString() ?? 'Customer';
//     final status = order['status']?.toString().toUpperCase() ?? 'PENDING';
    
//     return '''
// 📦 Cattle Feed Order Tracking
// Order: $orderNumber
// Customer: $customerName
// Status: $status
// Track here: $trackingUrl
// ''';
//   }
  
//   // Search orders - SIMPLIFIED
//   Future<List<Map<String, dynamic>>> searchOrders({
//     required String searchTerm,
//     String? employeeId,
//     int limit = 20,
//   }) async {
//     try {
//       // Build base query
//       dynamic query;
      
//       if (employeeId != null && employeeId.isNotEmpty) {
//         query = supabase
//           .from('emp_mar_orders')
//           .select()
//           .eq('employee_id', employeeId);
//       } else {
//         query = supabase
//           .from('emp_mar_orders')
//           .select();
//       }
      
//       // Add search filter
//       if (query is PostgrestFilterBuilder) {
//         query = query
//           .or('customer_name.ilike.%$searchTerm%,customer_mobile.ilike.%$searchTerm%,order_number.ilike.%$searchTerm%')
//           .order('created_at', ascending: false)
//           .limit(limit);
        
//         final response = await query;
        
//         if (response is List) {
//           return List<Map<String, dynamic>>.from(response);
//         }
//       }
      
//       return [];
//     } catch (e) {
//       print('❌ Error searching orders: $e');
//       return [];
//     }
//   }
  
//   // Get orders count - SIMPLIFIED
//   Future<int> getOrdersCount({String? employeeId, String? status}) async {
//     try {
//       // Get all orders and count manually
//       List<Map<String, dynamic>> orders = [];
      
//       if (employeeId != null && employeeId.isNotEmpty) {
//         final response = await supabase
//           .from('emp_mar_orders')
//           .select('id, status')
//           .eq('employee_id', employeeId);
        
//         if (response is List) {
//           orders = List<Map<String, dynamic>>.from(response);
//         }
//       } else {
//         final response = await supabase
//           .from('emp_mar_orders')
//           .select('id, status');
        
//         if (response is List) {
//           orders = List<Map<String, dynamic>>.from(response);
//         }
//       }
      
//       // Apply status filter if needed
//       if (status != null && status.isNotEmpty && status != 'all') {
//         orders = orders.where((order) => order['status'] == status).toList();
//       }
      
//       return orders.length;
//     } catch (e) {
//       print('❌ Error getting orders count: $e');
//       return 0;
//     }
//   }
  
//   // Get recent orders - SIMPLIFIED
//   Future<List<Map<String, dynamic>>> getRecentOrders({
//     int days = 7,
//     String? employeeId,
//   }) async {
//     try {
//       final cutoffDate = DateTime.now().subtract(Duration(days: days));
//       final cutoffDateStr = cutoffDate.toUtc().toIso8601String();
      
//       // Build base query
//       dynamic query;
      
//       if (employeeId != null && employeeId.isNotEmpty) {
//         query = supabase
//           .from('emp_mar_orders')
//           .select()
//           .eq('employee_id', employeeId);
//       } else {
//         query = supabase
//           .from('emp_mar_orders')
//           .select();
//       }
      
//       // Add date filter and ordering
//       if (query is PostgrestFilterBuilder) {
//         query = query
//           .gte('created_at', cutoffDateStr)
//           .order('created_at', ascending: false);
        
//         final response = await query;
        
//         if (response is List) {
//           return List<Map<String, dynamic>>.from(response);
//         }
//       }
      
//       return [];
//     } catch (e) {
//       print('❌ Error getting recent orders: $e');
//       return [];
//     }
//   }
// }
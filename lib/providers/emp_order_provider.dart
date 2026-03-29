import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  late OrderService _orderService;
  
  bool loading = false;
  String? error;

  // Order counts
  int totalOrders = 0;
  int pendingOrders = 0;
  int completedOrders = 0;
  int packingOrders = 0;  
  int readyForDispatchOrders = 0;
  int dispatchedOrders = 0;
  int deliveredOrders = 0;
  int cancelledOrders = 0;

  List<Map<String, dynamic>> orders = [];

  // Pagination variables
  bool _hasMoreData = true;
  int _page = 0;
  int _limit = 200;
  bool _initialLoadComplete = false;

  // Current employee ID
  String? _currentEmployeeId;

  // Notification state
  bool _sendingNotification = false;
  String? _notificationError;

  // Auth state listener
  StreamSubscription<AuthState>? _authSubscription;

  OrderProvider() {
    _orderService = OrderService(supabase);
    _initAuthListener();
    _getCurrentEmployeeId();
  }

  void _initAuthListener() {
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _currentEmployeeId = session.user.id;
        print('👤 Auth: User logged in - ID: $_currentEmployeeId');
        _clearData();
        quickLoad();
      } else {
        print('👤 Auth: User logged out');
        _currentEmployeeId = null;
        _clearData();
      }
      notifyListeners();
    });
  }

  void _clearData() {
    totalOrders = 0;
    pendingOrders = 0;
    completedOrders = 0;
    packingOrders = 0;
    readyForDispatchOrders = 0;
    dispatchedOrders = 0;
    deliveredOrders = 0;
    cancelledOrders = 0;
    orders = [];
    _page = 0;
    _hasMoreData = true;
    _initialLoadComplete = false;
    error = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentEmployeeId() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      _currentEmployeeId = user.id;
      print('👤 Current employee ID: $_currentEmployeeId');
      await quickLoad();
    } else {
      _clearData();
    }
  }

  String? _ensureEmployeeId() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      if (_currentEmployeeId != user.id) {
        _currentEmployeeId = user.id;
        print('👤 Employee ID updated to: $_currentEmployeeId');
        _clearData();
      }
      return _currentEmployeeId;
    }
    
    if (_currentEmployeeId != null) {
      _currentEmployeeId = null;
      _clearData();
    }
    return null;
  }

  Future<void> fetchOrderCounts() async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) {
        print('⚠️ No employee logged in');
        return;
      }

      print('📊 Fetching accurate order counts for employee: $employeeId');

      final totalCount = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId);

      final pendingCount = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId)
          .eq('status', 'pending');

      final completedCount = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId)
          .eq('status', 'completed');

      final packingCount = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId)
          .eq('status', 'packing');

      final readyForDispatchCount = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId)
          .eq('status', 'ready_for_dispatch');

      final dispatchedCount = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId)
          .eq('status', 'dispatched');

      final deliveredCount = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId)
          .eq('status', 'delivered');

      final cancelledCount = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId)
          .eq('status', 'cancelled');

      totalOrders = totalCount;
      pendingOrders = pendingCount;
      completedOrders = completedCount;
      packingOrders = packingCount;
      readyForDispatchOrders = readyForDispatchCount;
      dispatchedOrders = dispatchedCount;
      deliveredOrders = deliveredCount;
      cancelledOrders = cancelledCount;

      print('✅ Accurate order counts fetched for employee $employeeId:');
      print('   Total: $totalOrders');
      print('   Pending: $pendingOrders');
      print('   Completed: $completedOrders');

      notifyListeners();

    } catch (e) {
      print('❌ Error fetching order counts: $e');
    }
  }

  Future<void> fetchOrdersWithCounts({bool loadMore = false, String? status}) async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) {
        orders = [];
        notifyListeners();
        return;
      }

      if (!loadMore) {
        _page = 0;
        _hasMoreData = true;
        orders.clear();
      }

      if (!_hasMoreData && loadMore) return;

      loading = true;
      notifyListeners();

      await fetchOrderCounts();

      final data = await _orderService.getOrders(
        limit: _limit,
        offset: _page * _limit,
        status: status,
        employeeId: employeeId,
      );

      final newOrders = data.map((order) {
        return {...order, 'display_id': _getDisplayOrderId(order)};
      }).toList();

      if (newOrders.length < _limit) {
        _hasMoreData = false;
      }

      if (loadMore) {
        orders.addAll(newOrders);
      } else {
        orders = newOrders;
      }

      _page++;
      _initialLoadComplete = true;
      error = null;
      
      print('📦 Fetched ${newOrders.length} orders for employee $employeeId (page $_page)');
      
    } catch (e) {
      error = 'Failed to fetch orders: $e';
      debugPrint("❌ Fetch orders failed: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getOrdersByDistrict(String district) async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) return {};

      final totalInDistrict = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId)
          .eq('district', district);

      final completedInDistrict = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId)
          .eq('district', district)
          .eq('status', 'completed');

      return {
        'total': totalInDistrict,
        'completed': completedInDistrict,
      };

    } catch (e) {
      print('❌ Error getting orders by district: $e');
      return {};
    }
  }

  Future<List<double>> getMonthlyCompletedOrders(int year) async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) return List.filled(12, 0.0);

      print('📊 Fetching monthly completed orders for employee $employeeId, year $year');

      final orders = await supabase
          .from('emp_mar_orders')
          .select('bags, created_at')
          .eq('employee_id', employeeId)
          .eq('status', 'completed')
          .gte('created_at', '$year-01-01')
          .lte('created_at', '$year-12-31');

      final monthlyTotals = List<double>.filled(12, 0.0);

      for (var order in orders) {
        final createdAt = order['created_at'] as String?;
        final bags = (order['bags'] as num?)?.toDouble() ?? 0.0;
        
        if (createdAt != null) {
          try {
            final date = DateTime.parse(createdAt);
            final monthIndex = date.month - 1;
            if (monthIndex >= 0 && monthIndex < 12) {
              monthlyTotals[monthIndex] += bags;
            }
          } catch (e) {
            print('⚠️ Error parsing date: $e');
          }
        }
      }

      print('✅ Monthly completed orders: $monthlyTotals');
      return monthlyTotals;

    } catch (e) {
      print('❌ Error fetching monthly completed orders: $e');
      return List.filled(12, 0.0);
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) return [];

      final response = await supabase
          .from('emp_mar_orders')
          .select()
          .eq('employee_id', employeeId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return response.map((order) {
        return {...order, 'display_id': _getDisplayOrderId(order)};
      }).toList();

    } catch (e) {
      print('❌ Error fetching orders by date range: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getEmployeeStatistics() async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) return {};

      final revenueResponse = await supabase
          .from('emp_mar_orders')
          .select('total_price')
          .eq('employee_id', employeeId);

      double totalRevenue = 0;
      for (var order in revenueResponse) {
        totalRevenue += (order['total_price'] as num?)?.toDouble() ?? 0;
      }

      final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
      final completionRate = totalOrders > 0 
          ? (completedOrders / totalOrders) * 100 
          : 0;

      return {
        'total_orders': totalOrders,
        'total_revenue': totalRevenue,
        'average_order_value': avgOrderValue,
        'completion_rate': completionRate,
        'pending_orders': pendingOrders,
        'completed_orders': completedOrders,
      };

    } catch (e) {
      print('❌ Error getting employee statistics: $e');
      return {};
    }
  }

  String generateTrackingLink(Map<String, dynamic> order) {
    // This method is kept for reference but NOT used in messages
    final trackingId = order['tracking_id']?.toString() ?? '';
    final trackingToken = order['tracking_token']?.toString() ?? '';
    
    if (trackingId.isEmpty) return '';
    
    return 'https://phkkiyxfcepqauxncqpm.supabase.co/storage/v1/object/public/tracking/tracker.html?id=$trackingId&token=$trackingToken';
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data, BuildContext context) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      _currentEmployeeId = user.id;

      final int bags = data['bags'] as int;
      final int weightPerBag = data['weight_per_bag'] as int;
      final int pricePerBag = data['price_per_bag'] as int;

      final int totalWeight = bags * weightPerBag;
      final int totalPrice = bags * pricePerBag;

      print('📝 Creating new order for employee: ${user.id}');
      print('   👤 Customer Name: ${data['customer_name']}');
      print('   📱 Customer Mobile: ${data['customer_mobile']}');
      print('   📧 Customer Email: ${data['customer_email'] ?? "Not provided"}');
      print('   📍 District: ${data['district']}');
      print('   📦 Bags: $bags');
      print('   💰 Total Price: $totalPrice');

      final orderResponse = await _orderService.createOrder({
        'employee_id': user.id,
        'customer_name': data['customer_name'] as String,
        'customer_mobile': data['customer_mobile'] as String,
        'customer_address': data['customer_address'] as String,
        'customer_email': data['customer_email'] as String?,
        'district': data['district'] as String?,
        'feed_category': data['feed_category'] as String,
        'bags': bags,
        'weight_per_bag': weightPerBag,
        'weight_unit': data['weight_unit'] as String? ?? 'kg',
        'total_weight': totalWeight,
        'price_per_bag': pricePerBag,
        'total_price': totalPrice,
        'remarks': data['remarks'] as String?,
        'status': 'pending',
        'notification_sent': false,
        'whatsapp_sent': false,
        'email_sent': false,
      });

      print('✅ Order saved successfully with ID: ${orderResponse['id']}');
      
      await fetchOrderCounts();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order placed successfully! Order ID: ${orderResponse['order_number'] ?? 'N/A'}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await quickLoad();
      
      return orderResponse;

    } catch (e) {
      debugPrint("❌ Order insert failed: $e");
      if (context.mounted) {
        _showErrorSnackbar(context, "Failed to create order: ${e.toString()}");
      }
      rethrow;
    }
  }

  Future<void> sendOrderWhatsAppNotification({
    required BuildContext context,
    required String orderId,
    Map<String, dynamic>? order,
    bool showDialog = true,
  }) async {
    try {
      print('🚀 Starting WhatsApp notification for order: $orderId');
      
      Map<String, dynamic> orderData;
      if (order != null) {
        orderData = order;
        print('📊 Using provided order data');
      } else {
        print('📥 Fetching order data from database');
        orderData = await fetchSingleOrder(orderId) ?? {};
      }
      
      if (orderData.isEmpty) {
        throw Exception('Order not found');
      }

      final employeeId = _ensureEmployeeId();
      if (orderData['employee_id'] != employeeId) {
        throw Exception('You do not have permission to access this order');
      }

      final phoneNumber = orderData['customer_mobile']?.toString() ?? '';
      print('📱 Customer mobile: $phoneNumber');
      
      if (phoneNumber.isEmpty) {
        throw Exception('No mobile number available');
      }

      final message = _generateWhatsAppMessage(orderData, 'confirmation');

      print('📤 Launching WhatsApp...');
      final launched = await _launchWhatsAppMobile(phoneNumber, message);
      
      if (!launched) {
        throw Exception('Could not launch WhatsApp');
      }

      print('💾 Updating database...');
      await supabase
        .from('emp_mar_orders')
        .update({
          'whatsapp_sent': true,
          'notification_sent': true,
          'last_notification_sent_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', orderId)
        .eq('employee_id', employeeId as Object);

      if (showDialog && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp opened successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      print('✅ WhatsApp notification completed successfully');

    } catch (e) {
      print('❌ WhatsApp error: $e');
      
      if (showDialog && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open WhatsApp: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<bool> _launchWhatsAppMobile(String phoneNumber, String message) async {
    if (phoneNumber.isEmpty) {
      throw Exception('Phone number is empty');
    }
    
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanPhone.length < 10) {
      throw Exception('Invalid phone number: $phoneNumber (too short)');
    }
    
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    } else if (cleanPhone.length == 11 && cleanPhone.startsWith('0')) {
      cleanPhone = '91${cleanPhone.substring(1)}';
    }
    
    final encodedMessage = Uri.encodeComponent(message.trim());
    
    final intentUri = 'intent://send?phone=$cleanPhone&text=$encodedMessage#Intent;package=com.whatsapp;scheme=whatsapp;end;';
    
    try {
      final intentAndroid = Uri.parse(intentUri);
      if (await canLaunchUrl(intentAndroid)) {
        await launchUrl(intentAndroid);
        print('✅ Launched WhatsApp via intent');
        return true;
      }
    } catch (e) {
      print('❌ Intent method failed: $e');
    }
    
    List<String> whatsappUrls = [
      'https://wa.me/$cleanPhone?text=$encodedMessage',
      'whatsapp://send?phone=$cleanPhone&text=$encodedMessage',
      'https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMessage',
    ];
    
    for (String url in whatsappUrls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('✅ Launched WhatsApp with URL: $url');
          return true;
        }
      } catch (e) {
        print('❌ Failed with URL $url: $e');
        continue;
      }
    }
    
    try {
      final whatsappUri = Uri.parse('whatsapp://send?phone=$cleanPhone');
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
        
        if (message.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: message));
          _showMessageCopiedDialog(message);
        }
        
        print('✅ Launched WhatsApp without pre-filled message');
        return true;
      }
    } catch (e) {
      print('❌ Direct WhatsApp open failed: $e');
    }
    
    await Clipboard.setData(ClipboardData(text: message));
    throw Exception('Could not launch WhatsApp. Message copied to clipboard.');
  }

  void _showMessageCopiedDialog(String message) {
    print('📋 Message copied to clipboard: $message');
  }

  Future<void> sendStatusUpdateWhatsApp({
    required BuildContext context,
    required String orderId,
    required String newStatus,
    String? notes,
  }) async {
    try {
      final order = await fetchSingleOrder(orderId);
      if (order == null) throw Exception('Order not found');

      final employeeId = _ensureEmployeeId();
      if (order['employee_id'] != employeeId) {
        throw Exception('You do not have permission to update this order');
      }

      final phoneNumber = order['customer_mobile']?.toString() ?? '';
      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No mobile number available for notification'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final message = _generateWhatsAppMessage(order, 'status_update', 
        newStatus: newStatus, notes: notes);

      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (context) => _WhatsAppPreviewDialog(
          phoneNumber: phoneNumber,
          message: message,
          orderNumber: order['order_number']?.toString() ?? 'N/A',
          isStatusUpdate: true,
          newStatus: newStatus,
        ),
      );

      if (shouldSend == true) {
        final launched = await _launchWhatsAppMobile(phoneNumber, message);
        
        if (launched) {
          await updateOrderStatus(orderId, newStatus, notes: notes);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Status updated and WhatsApp opened'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========================
// GENERATE VISUAL TRACKING TIMELINE (OLD UI)
// ========================
String _generateVisualTimeline(String currentStatus) {
  final steps = [
    {'status': 'pending', 'label': 'Ordered', 'icon': '📋'},
    {'status': 'packing', 'label': 'Packing', 'icon': '📦'},
    {'status': 'ready_for_dispatch', 'label': 'Ready', 'icon': '✓'},
    {'status': 'dispatched', 'label': 'Shipped', 'icon': '🚚'},
    {'status': 'delivered', 'label': 'Delivered', 'icon': '✅'},
  ];
  
  final statusOrder = ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed'];
  
  int currentIndex = statusOrder.indexOf(currentStatus);
  if (currentIndex == -1) currentIndex = 0;
  
  if (currentStatus == 'completed') {
    return '''
✅ *COMPLETED* 🎉
Your order has been successfully delivered!
    ''';
  }
  
  if (currentStatus == 'cancelled') {
    return '''
❌ *CANCELLED*
This order has been cancelled. Contact support if needed.
    ''';
  }
  
  List<String> statusLines = [];
  
  for (int i = 0; i < steps.length; i++) {
    final step = steps[i];
    final stepStatusIndex = statusOrder.indexOf(step['status']!);
    final isCompleted = currentIndex > stepStatusIndex;
    final isCurrent = currentIndex == stepStatusIndex;
    
    String line;
    if (isCompleted) {
      line = '✅ ${step['icon']} ${step['label']}';
    } else if (isCurrent) {
      line = '🔄 ${step['icon']} ${step['label']} (In Progress)';
    } else {
      line = '⏳ ${step['icon']} ${step['label']}';
    }
    statusLines.add(line);
  }
  
  final statusMessages = {
    'pending': '✅ Your order has been confirmed and is being processed.',
    'packing': '📦 Your order is being carefully packed.',
    'ready_for_dispatch': '✓ Your order is packed and ready for dispatch.',
    'dispatched': '🚚 Your order is on the way!',
    'delivered': '✅ Your order has been delivered!',
  };
  
  final statusMessage = statusMessages[currentStatus] ?? 'Your order is being processed.';
  
  return '''
${statusLines.join('\n')}

$statusMessage
''';
}

// ========================
// GENERATE WHATSAPP MESSAGE (OLD UI)
// ========================
String _generateWhatsAppMessage(
  Map<String, dynamic> order, 
  String messageType, {
  String? newStatus,
  String? notes,
}) {
  // Get order number
  String orderNumber;
  final orderNumValue = order['order_number'];
  
  if (orderNumValue == null) {
    if (order['id'] != null) {
      final idStr = order['id'].toString();
      orderNumber = idStr.length >= 8 
          ? 'ORD${idStr.substring(0, 8).toUpperCase()}'
          : 'ORD${idStr.toUpperCase()}';
    } else {
      orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}';
    }
  } else {
    final orderNumStr = orderNumValue.toString();
    orderNumber = orderNumStr.isEmpty ? 'N/A' : orderNumStr;
  }
  
  // Get other fields
  final customerName = order['customer_name']?.toString() ?? 'Customer';
  final product = order['feed_category']?.toString() ?? 'Cattle Feed';
  final bags = order['bags']?.toString() ?? '1';
  final amount = order['total_price']?.toString() ?? '0';
  final weight = order['total_weight']?.toString() ?? '0';
  final unit = order['weight_unit']?.toString() ?? 'kg';
  final address = order['customer_address']?.toString() ?? '';
  final district = order['district']?.toString() ?? '';
  
  // Determine current status
  final currentStatus = (newStatus ?? order['status']?.toString() ?? 'pending').toLowerCase();
  
  // Generate visual timeline
  final timeline = _generateVisualTimeline(currentStatus);
  
  if (messageType == 'confirmation') {
    return '''
🛒 *MEGA PRO CATTLE FEED*
━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 *ORDER CONFIRMED*

*Order:* $orderNumber
*Customer:* $customerName
*Product:* $product
*Qty:* $bags bags ($weight $unit)
*Amount:* ₹$amount

━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 *ORDER STATUS*
$timeline
━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 *Delivery:* $address, $district
📞 *Support:* +91 98765 43210

*Thank you for choosing Mega Pro!* 🙏
    ''';
  } else if (messageType == 'status_update' && newStatus != null) {
    return '''
🔄 *ORDER STATUS UPDATE*
━━━━━━━━━━━━━━━━━━━━━━━━━━
*Order:* $orderNumber
*Customer:* $customerName

📦 *STATUS*
$timeline

${notes != null && notes.isNotEmpty ? '📝 *Note:* $notes\n' : ''}
📞 *Support:* +91 98765 43210
━━━━━━━━━━━━━━━━━━━━━━━━━━
    ''';
  }
  
  return 'Order update for $orderNumber';
}

  Future<void> sendOrderEmailNotification({
    required BuildContext context,
    required String orderId,
    Map<String, dynamic>? order,
  }) async {
    try {
      _sendingNotification = true;
      _notificationError = null;
      notifyListeners();

      Map<String, dynamic> orderData = order ?? await fetchSingleOrder(orderId) ?? {};
      if (orderData.isEmpty) {
        throw Exception('Order not found');
      }

      final employeeId = _ensureEmployeeId();
      if (orderData['employee_id'] != employeeId) {
        throw Exception('You do not have permission to access this order');
      }

      final email = orderData['customer_email']?.toString() ?? '';
      if (email.isEmpty) {
        throw Exception('No email address available');
      }

      String orderNumber;
      if (orderData['order_number'] != null && orderData['order_number'].toString().isNotEmpty) {
        orderNumber = orderData['order_number'].toString();
      } else if (orderData['id'] != null) {
        orderNumber = 'ORD${orderData['id'].toString().substring(0, 8).toUpperCase()}';
      } else {
        orderNumber = 'N/A';
      }
      
      final customerName = orderData['customer_name']?.toString() ?? 'Customer';
      final product = orderData['feed_category']?.toString() ?? 'Cattle Feed';
      final bags = orderData['bags']?.toString() ?? '1';
      final amount = orderData['total_price']?.toString() ?? '0';
      final weight = orderData['total_weight']?.toString() ?? '0';
      final unit = orderData['weight_unit']?.toString() ?? 'kg';
      
      final currentStatus = orderData['status']?.toString() ?? 'pending';
      final timeline = _generateVisualTimeline(currentStatus);
      
      final emailContent = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                     MEGA PRO CATTLE FEED
                     ORDER CONFIRMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dear $customerName,

Your order has been confirmed!

ORDER DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Order Number:  $orderNumber
Product:       $product
Quantity:      $bags bags ($weight $unit)
Total Amount:  ₹$amount
Delivery:      ${orderData['customer_address'] ?? ''}, ${orderData['district'] ?? 'N/A'}

ORDER STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$timeline

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Need help? Call +91 98765 43210

Best regards,
Mega Pro Cattle Feed Team
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ''';
      
      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Send Email'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Send to: $email'),
                  const SizedBox(height: 10),
                  const Text('Email content:'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        emailContent,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context, true);
                },
                child: const Text('Open Email App'),
              ),
            ],
          );
        },
      );

      if (shouldSend == true) {
        final subject = 'Order Confirmed: $orderNumber';
        final mailtoUrl = 'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(emailContent)}';
        final emailUri = Uri.parse(mailtoUrl);

        if (await canLaunchUrl(emailUri)) {
          await launchUrl(
            emailUri,
            mode: LaunchMode.externalApplication,
          );
          
          await supabase
            .from('emp_mar_orders')
            .update({
              'email_sent': true,
              'notification_sent': true,
              'last_notification_sent_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', orderId)
            .eq('employee_id', employeeId as Object);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email app opened successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          await Clipboard.setData(ClipboardData(text: emailContent));
          throw Exception('Could not open email app. Email content copied to clipboard.');
        }
      }

    } catch (e) {
      _notificationError = e.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      _sendingNotification = false;
      notifyListeners();
    }
  }

  Future<void> resendAllNotifications({
    required BuildContext context,
    required String orderId,
  }) async {
    try {
      final order = await fetchSingleOrder(orderId);
      if (order == null) return;

      final employeeId = _ensureEmployeeId();
      if (order['employee_id'] != employeeId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to access this order'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final hasEmail = order['customer_email']?.toString().isNotEmpty ?? false;
      final hasWhatsApp = order['customer_mobile']?.toString().isNotEmpty ?? false;

      if (!hasEmail && !hasWhatsApp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No contact information available'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resend Notifications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasWhatsApp)
                ListTile(
                  leading: const Icon(Icons.message, color: Colors.green),
                  title: const Text('Send WhatsApp'),
                  subtitle: Text('To: ${order['customer_mobile']}'),
                  onTap: () {
                    Navigator.pop(context);
                    sendOrderWhatsAppNotification(
                      context: context,
                      orderId: orderId,
                      order: order,
                    );
                  },
                ),
              if (hasEmail)
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
                  title: const Text('Send Email'),
                  subtitle: Text('To: ${order['customer_email']}'),
                  onTap: () {
                    Navigator.pop(context);
                    sendOrderEmailNotification(
                      context: context,
                      orderId: orderId,
                      order: order,
                    );
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> sendStatusUpdateNotification({
    required String orderId,
    required String newStatus,
    required BuildContext context,
    String? notes,
  }) async {
    await sendStatusUpdateWhatsApp(
      context: context,
      orderId: orderId,
      newStatus: newStatus,
      notes: notes,
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> quickLoad() async {
    final employeeId = _ensureEmployeeId();
    if (employeeId == null) {
      orders = [];
      notifyListeners();
      return;
    }

    if (_initialLoadComplete && orders.isNotEmpty) return;

    try {
      loading = true;
      notifyListeners();

      await fetchOrderCounts();

      final data = await _orderService.getOrders(
        limit: 10,
        employeeId: employeeId,
      );

      orders = data.map((order) {
        return {...order, 'display_id': _getDisplayOrderId(order)};
      }).toList();

      _initialLoadComplete = true;
      error = null;
    } catch (e) {
      error = 'Failed to load orders: $e';
      debugPrint("❌ Quick load failed: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrders({bool loadMore = false, String? status}) async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) {
        orders = [];
        notifyListeners();
        return;
      }

      if (!loadMore) {
        _page = 0;
        _hasMoreData = true;
        orders.clear();
      }

      if (!_hasMoreData && loadMore) return;

      loading = true;
      notifyListeners();

      final data = await _orderService.getOrders(
        limit: _limit,
        offset: _page * _limit,
        status: status,
        employeeId: employeeId,
      );

      final newOrders = data.map((order) {
        return {...order, 'display_id': _getDisplayOrderId(order)};
      }).toList();

      if (newOrders.length < _limit) {
        _hasMoreData = false;
      }

      if (loadMore) {
        orders.addAll(newOrders);
      } else {
        orders = newOrders;
      }

      _page++;
      _initialLoadComplete = true;
      error = null;
    } catch (e) {
      error = 'Failed to fetch orders: $e';
      debugPrint("❌ Fetch orders failed: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMoreData || loading) return;
    await fetchOrders(loadMore: true);
  }

  Future<Map<String, dynamic>?> fetchSingleOrder(String orderId) async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) return null;

      final response = await _orderService.getOrder(orderId);
      
      if (response != null && response['employee_id'] == employeeId) {
        return {...response, 'display_id': _getDisplayOrderId(response)};
      }
      
      return null;
    } catch (e) {
      debugPrint("❌ Fetch single order failed: $e");
      return null;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus, {String? notes}) async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) throw Exception('No employee logged in');

      loading = true;
      notifyListeners();

      final order = await fetchSingleOrder(orderId);
      if (order == null) {
        throw Exception('Order not found or you do not have permission');
      }

      await _orderService.updateOrderStatus(
        orderId, 
        newStatus, 
        notes: notes,
        sendNotification: false,
      );

      await fetchOrderCounts();
      await quickLoad();
    } catch (e) {
      debugPrint("❌ Update order status failed: $e");
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) throw Exception('No employee logged in');

      loading = true;
      notifyListeners();

      final order = await fetchSingleOrder(orderId);
      if (order == null) {
        throw Exception('Order not found or you do not have permission');
      }

      await _orderService.deleteOrder(orderId);

      orders.removeWhere((order) => order['id'] == orderId);
      
      await fetchOrderCounts();

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Delete order failed: $e");
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String _getDisplayOrderId(Map<String, dynamic> order) {
    if (order['order_number'] != null &&
        order['order_number'].toString().isNotEmpty) {
      return order['order_number'].toString();
    }

    if (order['id'] != null) {
      final uuid = order['id'].toString();
      return '#${uuid.substring(0, 8).toUpperCase()}';
    }

    return '#N/A';
  }

  Future<void> refresh() async {
    _page = 0;
    _hasMoreData = true;
    _initialLoadComplete = false;
    
    await fetchOrderCounts();
    await quickLoad();
  }

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

  Map<String, dynamic>? getOrderById(String id) {
    try {
      final order = orders.firstWhere((order) => order['id'] == id);
      final employeeId = _ensureEmployeeId();
      if (order['employee_id'] == employeeId) {
        return order;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool get hasMoreData => _hasMoreData;
  bool get sendingNotification => _sendingNotification;
  String? get notificationError => _notificationError;

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
      'completion_rate': totalOrders > 0
          ? (completedOrders / totalOrders) * 100
          : 0,
    };
  }

  bool orderExists(String orderId) {
    final employeeId = _ensureEmployeeId();
    return orders.any((order) => 
      order['id'] == orderId && order['employee_id'] == employeeId
    );
  }
}

class _WhatsAppPreviewDialog extends StatelessWidget {
  final String phoneNumber;
  final String message;
  final String orderNumber;
  final bool isStatusUpdate;
  final String? newStatus;

  const _WhatsAppPreviewDialog({
    required this.phoneNumber,
    required this.message,
    required this.orderNumber,
    this.isStatusUpdate = false,
    this.newStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.message,
                  color: Colors.green,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Text(
                  isStatusUpdate ? 'Status Update' : 'Order Confirmation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              'Send to: $phoneNumber',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Order: $orderNumber',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            if (isStatusUpdate && newStatus != null) ...[
              const SizedBox(height: 5),
              Text(
                'New Status: ${newStatus!.toUpperCase()}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message Preview:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, size: 18),
                      SizedBox(width: 8),
                      Text('Send via WhatsApp'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


























//trcking issue only


// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../services/order_service.dart';

// class OrderProvider with ChangeNotifier {
//   final SupabaseClient supabase = Supabase.instance.client;
//   late OrderService _orderService;
  
//   bool loading = false;
//   String? error;

//   // Order counts - these will be accurate and employee-specific
//   int totalOrders = 0;
//   int pendingOrders = 0;
//   int completedOrders = 0;
//   int packingOrders = 0;  
//   int readyForDispatchOrders = 0;
//   int dispatchedOrders = 0;
//   int deliveredOrders = 0;
//   int cancelledOrders = 0;

//   List<Map<String, dynamic>> orders = [];

//   // Pagination variables
//   bool _hasMoreData = true;
//   int _page = 0;
//   int _limit = 200;
//   bool _initialLoadComplete = false;

//   // Current employee ID
//   String? _currentEmployeeId;

//   // Notification state
//   bool _sendingNotification = false;
//   String? _notificationError;

//   // Auth state listener
//   StreamSubscription<AuthState>? _authSubscription;

//   // Tracking base URL  
//   OrderProvider() {
//     _orderService = OrderService(supabase);
//     _initAuthListener();
//     _getCurrentEmployeeId();
//   }

//   // ========================
//   // INIT AUTH LISTENER
//   // ========================
//   void _initAuthListener() {
//     _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
//       final session = data.session;
//       if (session != null) {
//         // User logged in
//         _currentEmployeeId = session.user.id;
//         print('👤 Auth: User logged in - ID: $_currentEmployeeId');
//         // Clear old data and reload for new user
//         _clearData();
//         quickLoad();
//       } else {
//         // User logged out
//         print('👤 Auth: User logged out');
//         _currentEmployeeId = null;
//         _clearData();
//       }
//       notifyListeners();
//     });
//   }

//   // ========================
//   // CLEAR DATA ON LOGOUT
//   // ========================
//   void _clearData() {
//     totalOrders = 0;
//     pendingOrders = 0;
//     completedOrders = 0;
//     packingOrders = 0;
//     readyForDispatchOrders = 0;
//     dispatchedOrders = 0;
//     deliveredOrders = 0;
//     cancelledOrders = 0;
//     orders = [];
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     error = null;
//   }

//   // ========================
//   // DISPOSE
//   // ========================
//   void dispose() {
//     _authSubscription?.cancel();
//     super.dispose();
//   }

//   // ========================
//   // GET CURRENT EMPLOYEE ID
//   // ========================
//   Future<void> _getCurrentEmployeeId() async {
//     final user = supabase.auth.currentUser;
//     if (user != null) {
//       _currentEmployeeId = user.id;
//       print('👤 Current employee ID: $_currentEmployeeId');
//       // Load data for this user
//       await quickLoad();
//     } else {
//       _clearData();
//     }
//   }

//   // Helper method to ensure employee ID is available
//   String? _ensureEmployeeId() {
//     // Always get fresh user from auth
//     final user = supabase.auth.currentUser;
//     if (user != null) {
//       // Update if changed
//       if (_currentEmployeeId != user.id) {
//         _currentEmployeeId = user.id;
//         print('👤 Employee ID updated to: $_currentEmployeeId');
//         // Clear old data when user changes
//         _clearData();
//       }
//       return _currentEmployeeId;
//     }
    
//     // No user logged in
//     if (_currentEmployeeId != null) {
//       _currentEmployeeId = null;
//       _clearData();
//     }
//     return null;
//   }

//   // ========================
//   // FETCH ACCURATE ORDER COUNTS (Employee-specific)
//   // ========================
//   Future<void> fetchOrderCounts() async {
//     try {
//       final employeeId = _ensureEmployeeId();
//       if (employeeId == null) {
//         print('⚠️ No employee logged in');
//         return;
//       }

//       print('📊 Fetching accurate order counts for employee: $employeeId');

//       // Get total orders count - filtered by employee_id
//       final totalCount = await supabase
//           .from('emp_mar_orders')
//           .count(CountOption.exact)
//           .eq('employee_id', employeeId);

//       // Get counts by status - all filtered by employee_id
//       final pendingCount = await supabase
//           .from('emp_mar_orders')
//           .count(CountOption.exact)
//           .eq('employee_id', employeeId)
//           .eq('status', 'pending');

//       final completedCount = await supabase
//           .from('emp_mar_orders')
//           .count(CountOption.exact)
//           .eq('employee_id', employeeId)
//           .eq('status', 'completed');

//       final packingCount = await supabase
//           .from('emp_mar_orders')
//           .count(CountOption.exact)
//           .eq('employee_id', employeeId)
//           .eq('status', 'packing');

//       final readyForDispatchCount = await supabase
//           .from('emp_mar_orders')
//           .count(CountOption.exact)
//           .eq('employee_id', employeeId)
//           .eq('status', 'ready_for_dispatch');

//       final dispatchedCount = await supabase
//           .from('emp_mar_orders')
//           .count(CountOption.exact)
//           .eq('employee_id', employeeId)
//           .eq('status', 'dispatched');

//       final deliveredCount = await supabase
//           .from('emp_mar_orders')
//           .count(CountOption.exact)
//           .eq('employee_id', employeeId)
//           .eq('status', 'delivered');

//       final cancelledCount = await supabase
//           .from('emp_mar_orders')
//           .count(CountOption.exact)
//           .eq('employee_id', employeeId)
//           .eq('status', 'cancelled');

//       // Update the counts
//       totalOrders = totalCount;
//       pendingOrders = pendingCount;
//       completedOrders = completedCount;
//       packingOrders = packingCount;
//       readyForDispatchOrders = readyForDispatchCount;
//       dispatchedOrders = dispatchedCount;
//       deliveredOrders = deliveredCount;
//       cancelledOrders = cancelledCount;

//       print('✅ Accurate order counts fetched for employee $employeeId:');
//       print('   Total: $totalOrders');
//       print('   Pending: $pendingOrders');
//       print('   Completed: $completedOrders');
//       print('   Packing: $packingOrders');
//       print('   Ready for Dispatch: $readyForDispatchOrders');
//       print('   Dispatched: $dispatchedOrders');
//       print('   Delivered: $deliveredOrders');
//       print('   Cancelled: $cancelledOrders');

//       notifyListeners();

//     } catch (e) {
//       print('❌ Error fetching order counts: $e');
//     }
//   }

//   // ========================
//   // FETCH ORDERS WITH COUNTS (Employee-specific)
//   // ========================
//   Future<void> fetchOrdersWithCounts({bool loadMore = false, String? status}) async {
//     try {
//       final employeeId = _ensureEmployeeId();
//       if (employeeId == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       if (!loadMore) {
//         _page = 0;
//         _hasMoreData = true;
//         orders.clear();
//       }

//       if (!_hasMoreData && loadMore) return;

//       loading = true;
//       notifyListeners();

//       // First fetch the counts (employee-specific)
//       await fetchOrderCounts();

//       // Then fetch the paginated orders (employee-specific)
//       final data = await _orderService.getOrders(
//         limit: _limit,
//         offset: _page * _limit,
//         status: status,
//         employeeId: employeeId, // This ensures only employee's orders
//       );

//       final newOrders = data.map((order) {
//         return {...order, 'display_id': _getDisplayOrderId(order)};
//       }).toList();

//       if (newOrders.length < _limit) {
//         _hasMoreData = false;
//       }

//       if (loadMore) {
//         orders.addAll(newOrders);
//       } else {
//         orders = newOrders;
//       }

//       _page++;
//       _initialLoadComplete = true;
//       error = null;
      
//       print('📦 Fetched ${newOrders.length} orders for employee $employeeId (page $_page)');
      
//     } catch (e) {
//       error = 'Failed to fetch orders: $e';
//       debugPrint("❌ Fetch orders failed: $e");
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // GET ORDERS BY DISTRICT (Employee-specific)
//   // ========================
//   Future<Map<String, dynamic>> getOrdersByDistrict(String district) async {
//     try {
//       final employeeId = _ensureEmployeeId();
//       if (employeeId == null) return {};

//       // Get counts for specific district - filtered by employee_id
//       final totalInDistrict = await supabase
//           .from('emp_mar_orders')
//           .count(CountOption.exact)
//           .eq('employee_id', employeeId)
//           .eq('district', district);

//       final completedInDistrict = await supabase
//           .from('emp_mar_orders')
//           .count(CountOption.exact)
//           .eq('employee_id', employeeId)
//           .eq('district', district)
//           .eq('status', 'completed');

//       return {
//         'total': totalInDistrict,
//         'completed': completedInDistrict,
//       };

//     } catch (e) {
//       print('❌ Error getting orders by district: $e');
//       return {};
//     }
//   }

//   // ========================
//   // GET MONTHLY COMPLETED ORDERS (for dashboard charts)
//   // ========================
//   Future<List<double>> getMonthlyCompletedOrders(int year) async {
//     try {
//       final employeeId = _ensureEmployeeId();
//       if (employeeId == null) return List.filled(12, 0.0);

//       print('📊 Fetching monthly completed orders for employee $employeeId, year $year');

//       // Fetch all completed orders for this employee in the given year
//       final orders = await supabase
//           .from('emp_mar_orders')
//           .select('bags, created_at')
//           .eq('employee_id', employeeId)
//           .eq('status', 'completed')
//           .gte('created_at', '$year-01-01')
//           .lte('created_at', '$year-12-31');

//       // Initialize monthly totals
//       final monthlyTotals = List<double>.filled(12, 0.0);

//       // Sum bags by month
//       for (var order in orders) {
//         final createdAt = order['created_at'] as String?;
//         final bags = (order['bags'] as num?)?.toDouble() ?? 0.0;
        
//         if (createdAt != null) {
//           try {
//             final date = DateTime.parse(createdAt);
//             final monthIndex = date.month - 1;
//             if (monthIndex >= 0 && monthIndex < 12) {
//               monthlyTotals[monthIndex] += bags;
//             }
//           } catch (e) {
//             print('⚠️ Error parsing date: $e');
//           }
//         }
//       }

//       print('✅ Monthly completed orders: $monthlyTotals');
//       return monthlyTotals;

//     } catch (e) {
//       print('❌ Error fetching monthly completed orders: $e');
//       return List.filled(12, 0.0);
//     }
//   }

//   // ========================
//   // GET ORDERS BY DATE RANGE   
//   // ========================
//   Future<List<Map<String, dynamic>>> getOrdersByDateRange(
//     DateTime startDate,
//     DateTime endDate,
//   ) async {
//     try {
//       final employeeId = _ensureEmployeeId();
//       if (employeeId == null) return [];

//       final response = await supabase
//           .from('emp_mar_orders')
//           .select()
//           .eq('employee_id', employeeId)
//           .gte('created_at', startDate.toIso8601String())
//           .lte('created_at', endDate.toIso8601String())
//           .order('created_at', ascending: false);

//       return response.map((order) {
//         return {...order, 'display_id': _getDisplayOrderId(order)};
//       }).toList();

//     } catch (e) {
//       print('❌ Error fetching orders by date range: $e');
//       return [];
//     }
//   }

//   // ========================
//   // GET ORDER STATISTICS (Employee-specific)
//   // ========================
//   Future<Map<String, dynamic>> getEmployeeStatistics() async {
//     try {
//       final employeeId = _ensureEmployeeId();
//       if (employeeId == null) return {};

//       // Get total revenue
//       final revenueResponse = await supabase
//           .from('emp_mar_orders')
//           .select('total_price')
//           .eq('employee_id', employeeId);

//       double totalRevenue = 0;
//       for (var order in revenueResponse) {
//         totalRevenue += (order['total_price'] as num?)?.toDouble() ?? 0;
//       }

//       // Get average order value
//       final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

//       // Get completion rate
//       final completionRate = totalOrders > 0 
//           ? (completedOrders / totalOrders) * 100 
//           : 0;

//       return {
//         'total_orders': totalOrders,
//         'total_revenue': totalRevenue,
//         'average_order_value': avgOrderValue,
//         'completion_rate': completionRate,
//         'pending_orders': pendingOrders,
//         'completed_orders': completedOrders,
//       };

//     } catch (e) {
//       print('❌ Error getting employee statistics: $e');
//       return {};
//     }
//   }

//   // ========================
//   // GENERATE TRACKING LINK
//   // ========================
//   String generateTrackingLink(Map<String, dynamic> order) {
//     final trackingId = order['tracking_id']?.toString() ?? '';
//     final trackingToken = order['tracking_token']?.toString() ?? '';
    
//     if (trackingId.isEmpty) return '';
    
//     // Direct link to HTML file in storage
//     return 'https://phkkiyxfcepqauxncqpm.supabase.co/storage/v1/object/public/tracking/tracker.html?id=$trackingId&token=$trackingToken';
//   }

//   // ========================
//   // CREATE ORDER WITH NOTIFICATIONS
//   // ========================
//   Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data, BuildContext context) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       // Update current employee ID
//       _currentEmployeeId = user.id;

//       final int bags = data['bags'] as int;
//       final int weightPerBag = data['weight_per_bag'] as int;
//       final int pricePerBag = data['price_per_bag'] as int;

//       final int totalWeight = bags * weightPerBag;
//       final int totalPrice = bags * pricePerBag;

//       print('📝 Creating new order for employee: ${user.id}');
//       print('   👤 Customer Name: ${data['customer_name']}');
//       print('   📱 Customer Mobile: ${data['customer_mobile']}');
//       print('   📧 Customer Email: ${data['customer_email'] ?? "Not provided"}');
//       print('   📍 District: ${data['district']}');
//       print('   📦 Bags: $bags');
//       print('   💰 Total Price: $totalPrice');

//       // Use OrderService to create order
//       final orderResponse = await _orderService.createOrder({
//         'employee_id': user.id,
//         'customer_name': data['customer_name'] as String,
//         'customer_mobile': data['customer_mobile'] as String,
//         'customer_address': data['customer_address'] as String,
//         'customer_email': data['customer_email'] as String?,
//         'district': data['district'] as String?,
//         'feed_category': data['feed_category'] as String,
//         'bags': bags,
//         'weight_per_bag': weightPerBag,
//         'weight_unit': data['weight_unit'] as String? ?? 'kg',
//         'total_weight': totalWeight,
//         'price_per_bag': pricePerBag,
//         'total_price': totalPrice,
//         'remarks': data['remarks'] as String?,
//         'status': 'pending',
//         'notification_sent': false,
//         'whatsapp_sent': false,
//         'email_sent': false,
//       });

//       print('✅ Order saved successfully with ID: ${orderResponse['id']}');
      
//       // Refresh counts after creating new order
//       await fetchOrderCounts();

//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Order placed successfully! Order ID: ${orderResponse['order_number'] ?? 'N/A'}',
//             ),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }

//       await quickLoad();
      
//       return orderResponse;

//     } catch (e) {
//       debugPrint("❌ Order insert failed: $e");
//       if (context.mounted) {
//         _showErrorSnackbar(context, "Failed to create order: ${e.toString()}");
//       }
//       rethrow;
//     }
//   }

//   // ========================
//   // WHATSAPP NOTIFICATION METHODS
//   // ========================
//   Future<void> sendOrderWhatsAppNotification({
//     required BuildContext context,
//     required String orderId,
//     Map<String, dynamic>? order,
//     bool showDialog = true,
//   }) async {
//     try {
//       print('🚀 Starting WhatsApp notification for order: $orderId');
      
//       // Fetch order details if not provided
//       Map<String, dynamic> orderData;
//       if (order != null) {
//         orderData = order;
//         print('📊 Using provided order data');
//       } else {
//         print('📥 Fetching order data from database');
//         orderData = await fetchSingleOrder(orderId) ?? {};
//       }
      
//       if (orderData.isEmpty) {
//         throw Exception('Order not found');
//       }

//       // Verify this order belongs to the current employee
//       final employeeId = _ensureEmployeeId();
//       if (orderData['employee_id'] != employeeId) {
//         throw Exception('You do not have permission to access this order');
//       }

//       final phoneNumber = orderData['customer_mobile']?.toString() ?? '';
//       print('📱 Customer mobile: $phoneNumber');
      
//       if (phoneNumber.isEmpty) {
//         throw Exception('No mobile number available');
//       }

//       // Generate message
//       final message = _generateWhatsAppMessage(orderData, 'confirmation');

//       // Send via WhatsApp
//       print('📤 Launching WhatsApp...');
//       final launched = await _launchWhatsAppMobile(phoneNumber, message);
      
//       if (!launched) {
//         throw Exception('Could not launch WhatsApp');
//       }

//       // Update database
//       print('💾 Updating database...');
//       await supabase
//         .from('emp_mar_orders')
//         .update({
//           'whatsapp_sent': true,
//           'notification_sent': true,
//           'last_notification_sent_at': DateTime.now().toUtc().toIso8601String(),
//           'updated_at': DateTime.now().toUtc().toIso8601String(),
//         })
//         .eq('id', orderId)
//         .eq('employee_id', employeeId as Object); // Extra safety: ensure employee owns this order

//       if (showDialog && context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('WhatsApp opened successfully'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
      
//       print('✅ WhatsApp notification completed successfully');

//     } catch (e) {
//       print('❌ WhatsApp error: $e');
      
//       if (showDialog && context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to open WhatsApp: ${e.toString()}'),
//             backgroundColor: Colors.orange,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }

//   // MOBILE-OPTIMIZED WHATSAPP LAUNCH METHOD
//   Future<bool> _launchWhatsAppMobile(String phoneNumber, String message) async {
//     // Check if phone number is valid
//     if (phoneNumber.isEmpty) {
//       throw Exception('Phone number is empty');
//     }
    
//     // Clean and format phone number
//     String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
//     // Ensure it's valid length
//     if (cleanPhone.length < 10) {
//       throw Exception('Invalid phone number: $phoneNumber (too short)');
//     }
    
//     // Handle different formats
//     if (cleanPhone.length == 10) {
//       cleanPhone = '91$cleanPhone'; // Add India country code
//     } else if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
//       // Already has country code
//     } else if (cleanPhone.length == 11 && cleanPhone.startsWith('0')) {
//       cleanPhone = '91${cleanPhone.substring(1)}'; // Remove leading 0, add 91
//     }
    
//     // For mobile devices, we need to use a different approach
//     // First, try the intent method for Android
//     final encodedMessage = Uri.encodeComponent(message.trim());
    
//     // Method 1: WhatsApp intent for Android
//     final intentUri = 'intent://send?phone=$cleanPhone&text=$encodedMessage#Intent;package=com.whatsapp;scheme=whatsapp;end;';
    
//     try {
//       final intentAndroid = Uri.parse(intentUri);
//       if (await canLaunchUrl(intentAndroid)) {
//         await launchUrl(intentAndroid);
//         print('✅ Launched WhatsApp via intent with pre-filled message');
//         return true;
//       }
//     } catch (e) {
//       print('❌ Intent method failed: $e');
//     }
    
//     // Method 2: Traditional URL schemes
//     List<String> whatsappUrls = [
//       'https://wa.me/$cleanPhone?text=$encodedMessage',
//       'whatsapp://send?phone=$cleanPhone&text=$encodedMessage',
//       'https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMessage',
//     ];
    
//     for (String url in whatsappUrls) {
//       try {
//         final uri = Uri.parse(url);
//         if (await canLaunchUrl(uri)) {
//           await launchUrl(uri, mode: LaunchMode.externalApplication);
//           print('✅ Launched WhatsApp with URL: $url');
//           return true;
//         }
//       } catch (e) {
//         print('❌ Failed with URL $url: $e');
//         continue;
//       }
//     }
    
//     // Method 3: Try to open WhatsApp directly (without pre-filled message)
//     try {
//       final whatsappUri = Uri.parse('whatsapp://send?phone=$cleanPhone');
//       if (await canLaunchUrl(whatsappUri)) {
//         await launchUrl(whatsappUri);
        
//         // Show dialog with message to copy
//         if (message.isNotEmpty) {
//           await Clipboard.setData(ClipboardData(text: message));
//           _showMessageCopiedDialog(message);
//         }
        
//         print('✅ Launched WhatsApp without pre-filled message, message copied');
//         return true;
//       }
//     } catch (e) {
//       print('❌ Direct WhatsApp open failed: $e');
//     }
    
//     // Check if WhatsApp is installed
//     bool isWhatsAppInstalled = false;
//     try {
//       final checkUri = Uri.parse('whatsapp://send');
//       isWhatsAppInstalled = await canLaunchUrl(checkUri);
//     } catch (e) {
//       print('Error checking WhatsApp installation: $e');
//     }
    
//     if (!isWhatsAppInstalled) {
//       // WhatsApp not installed, offer to open Play Store
//       final playStoreUri = Uri.parse('market://details?id=com.whatsapp');
//       if (await canLaunchUrl(playStoreUri)) {
//         await launchUrl(playStoreUri);
//         throw Exception('WhatsApp is not installed. Opening Play Store to install WhatsApp.');
//       } else {
//         final webUri = Uri.parse('https://play.google.com/store/apps/details?id=com.whatsapp');
//         await launchUrl(webUri);
//         throw Exception('WhatsApp is not installed. Opening web page to install WhatsApp.');
//       }
//     }
    
//     // Final fallback: Copy to clipboard
//     await Clipboard.setData(ClipboardData(text: message));
//     throw Exception('Could not launch WhatsApp. Message copied to clipboard. Please open WhatsApp manually and paste the message.');
//   }

//   void _showMessageCopiedDialog(String message) {
//     print('📋 Message copied to clipboard: $message');
//   }

//   Future<void> sendStatusUpdateWhatsApp({
//     required BuildContext context,
//     required String orderId,
//     required String newStatus,
//     String? notes,
//   }) async {
//     try {
//       final order = await fetchSingleOrder(orderId);
//       if (order == null) throw Exception('Order not found');

//       final employeeId = _ensureEmployeeId();
//       if (order['employee_id'] != employeeId) {
//         throw Exception('You do not have permission to update this order');
//       }

//       final phoneNumber = order['customer_mobile']?.toString() ?? '';
//       if (phoneNumber.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('No mobile number available for notification'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//         return;
//       }

//       // Generate status message
//       final message = _generateWhatsAppMessage(order, 'status_update', 
//         newStatus: newStatus, notes: notes);

//       // Show preview
//       final shouldSend = await showDialog<bool>(
//         context: context,
//         builder: (context) => _WhatsAppPreviewDialog(
//           phoneNumber: phoneNumber,
//           message: message,
//           orderNumber: order['order_number']?.toString() ?? 'N/A',
//           isStatusUpdate: true,
//           newStatus: newStatus,
//         ),
//       );

//       if (shouldSend == true) {
//         final launched = await _launchWhatsAppMobile(phoneNumber, message);
        
//         if (launched) {
//           // Update status in database
//           await updateOrderStatus(orderId, newStatus, notes: notes);
          
//           if (context.mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Status updated and WhatsApp opened'),
//                 backgroundColor: Colors.green,
//               ),
//             );
//           }
//         }
//       }

//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   String _generateWhatsAppMessage(
//     Map<String, dynamic> order, 
//     String messageType, {
//     String? newStatus,
//     String? notes,
//   }) {
//     // Get order number
//     String orderNumber;
//     final orderNumValue = order['order_number'];
    
//     if (orderNumValue == null) {
//       if (order['id'] != null) {
//         final idStr = order['id'].toString();
//         orderNumber = idStr.length >= 8 
//             ? 'ORD${idStr.substring(0, 8).toUpperCase()}'
//             : 'ORD${idStr.toUpperCase()}';
//       } else {
//         orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}';
//       }
//     } else {
//       final orderNumStr = orderNumValue.toString();
//       orderNumber = orderNumStr.isEmpty ? 'N/A' : orderNumStr;
//     }
    
//     // Get other fields
//     final customerName = order['customer_name']?.toString() ?? 'Customer';
//     final product = order['feed_category']?.toString() ?? 'Cattle Feed';
//     final bags = order['bags']?.toString() ?? '1';
//     final amount = order['total_price']?.toString() ?? '0';
//     final weight = order['total_weight']?.toString() ?? '0';
//     final unit = order['weight_unit']?.toString() ?? 'kg';
//     final address = order['customer_address']?.toString() ?? '';
//     final district = order['district']?.toString() ?? '';
    
//     // Generate tracking link
//     final trackingLink = generateTrackingLink(order);

//     if (messageType == 'confirmation') {
//       return '''
// 🛒 *MEGA PRO CATTLE FEED - ORDER CONFIRMED*

// 👤 *Customer:* $customerName
// 📦 *Product:* $product
// 🔢 *Quantity:* $bags bags ($weight $unit)
// 💰 *Amount:* ₹$amount
// 📍 *Status:* ✅ Processing

// 📋 *Delivery Details:*
// $address
// $district

// ${trackingLink.isNotEmpty ? '🔗 *Track Your Order (Click Link):*\n$trackingLink\n' : ''}
// 📞 *Need Help?* Call: +91 98765 43210

// _Thank you for choosing Mega Pro Cattle Feed!_
//     ''';
//     } else if (messageType == 'status_update' && newStatus != null) {
//       final statusMessages = {
//         'pending': '📋 Order received and being processed',
//         'packing': '📦 Your order is being packed',
//         'ready_for_dispatch': '🚚 Order packed and ready for dispatch',
//         'dispatched': '📤 Order dispatched! On the way',
//         'delivered': '✅ Order delivered successfully',
//         'completed': '🎉 Order completed! Thank you',
//         'cancelled': '❌ Order has been cancelled',
//       };
      
//       final statusText = statusMessages[newStatus.toLowerCase()] ?? 'Status updated';
//       final statusEmoji = {
//         'pending': '📋',
//         'packing': '📦',
//         'ready_for_dispatch': '🚚',
//         'dispatched': '📤',
//         'delivered': '✅',
//         'completed': '🎉',
//         'cancelled': '❌',
//       }[newStatus.toLowerCase()] ?? '📋';
      
//       String message = '''
// $statusEmoji *ORDER STATUS UPDATE*

// _Status: ${newStatus.toUpperCase()}_

// $statusText

// ${notes != null && notes.isNotEmpty ? '📝 _Notes:_ $notes\n' : ''}
// ${trackingLink.isNotEmpty ? '🔗 *Track Your Order (Click Link):*\n$trackingLink\n' : ''}
// _We appreciate your patience!_
//     ''';
      
//       return message;
//     }
    
//     return 'Order update for $orderNumber';
//   }

//   void debugOrderData(Map<String, dynamic> order) {
//     print('🔍 DEBUG ORDER DATA:');
//     print('Order keys: ${order.keys.toList()}');
//     print('Employee ID: ${order['employee_id']}');
//   }

//   // ========================
//   // EMAIL NOTIFICATION METHODS
//   // ========================
//   Future<void> sendOrderEmailNotification({
//     required BuildContext context,
//     required String orderId,
//     Map<String, dynamic>? order,
//   }) async {
//     try {
//       _sendingNotification = true;
//       _notificationError = null;
//       notifyListeners();

//       // Fetch order details if not provided
//       Map<String, dynamic> orderData = order ?? await fetchSingleOrder(orderId) ?? {};
//       if (orderData.isEmpty) {
//         throw Exception('Order not found');
//       }

//       final employeeId = _ensureEmployeeId();
//       if (orderData['employee_id'] != employeeId) {
//         throw Exception('You do not have permission to access this order');
//       }

//       final email = orderData['customer_email']?.toString() ?? '';
//       if (email.isEmpty) {
//         throw Exception('No email address available');
//       }

//       // Safely get order number
//       String orderNumber;
//       if (orderData['order_number'] != null && orderData['order_number'].toString().isNotEmpty) {
//         orderNumber = orderData['order_number'].toString();
//       } else if (orderData['id'] != null) {
//         orderNumber = 'ORD${orderData['id'].toString().substring(0, 8).toUpperCase()}';
//       } else {
//         orderNumber = 'N/A';
//       }
      
//       final customerName = orderData['customer_name']?.toString() ?? 'Customer';
//       final product = orderData['feed_category']?.toString() ?? 'Cattle Feed';
//       final bags = orderData['bags']?.toString() ?? '1';
//       final amount = orderData['total_price']?.toString() ?? '0';
//       final weight = orderData['total_weight']?.toString() ?? '0';
//       final unit = orderData['weight_unit']?.toString() ?? 'kg';
      
//       // Generate tracking link
//       final trackingLink = generateTrackingLink(orderData);

//       // Create email content
//       final emailContent = '''
// Dear $customerName,

// Your cattle feed order has been confirmed!

// 📋 ORDER DETAILS:
// - Order Number: $orderNumber
// - Product: $product
// - Quantity: $bags bags
// - Total Weight: $weight $unit
// - Total Amount: ₹$amount
// - Delivery Address: ${orderData['customer_address'] ?? ''}
// - District: ${orderData['district'] ?? 'N/A'}
// - Status: Processing
// - Expected Delivery: 3-5 business days

// ${trackingLink.isNotEmpty ? '🔗 TRACK YOUR ORDER:\n$trackingLink\n' : ''}

// Click the link above to see real-time updates on your order status.

// Thank you for choosing Mega Pro Cattle Feed!

// Best regards,
// Mega Pro Cattle Feed Team
// 📞 +91 98765 43210
//       ''';

//       // Show email template
//       final shouldSend = await showDialog<bool>(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text('Send Email'),
//             content: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text('Send to: $email'),
//                   const SizedBox(height: 10),
//                   const Text('Email content:'),
//                   const SizedBox(height: 10),
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey.shade300),
//                     ),
//                     child: SingleChildScrollView(
//                       child: SelectableText(
//                         emailContent,
//                         style: const TextStyle(fontSize: 12),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   Navigator.pop(context, true);
//                 },
//                 child: const Text('Open Email App'),
//               ),
//             ],
//           );
//         },
//       );

//       if (shouldSend == true) {
//         // Create a proper mailto URL with encoded components
//         final subject = 'Order Confirmed: $orderNumber';
//         final mailtoUrl = 'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(emailContent)}';
//         final emailUri = Uri.parse(mailtoUrl);

//         // Try to launch email app
//         if (await canLaunchUrl(emailUri)) {
//           await launchUrl(
//             emailUri,
//             mode: LaunchMode.externalApplication,
//           );
          
//           // Update database with employee_id check
//           await supabase
//             .from('emp_mar_orders')
//             .update({
//               'email_sent': true,
//               'notification_sent': true,
//               'last_notification_sent_at': DateTime.now().toUtc().toIso8601String(),
//               'updated_at': DateTime.now().toUtc().toIso8601String(),
//             })
//             .eq('id', orderId)
//             .eq('employee_id', employeeId as Object);

//           if (context.mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Email app opened successfully'),
//                 backgroundColor: Colors.green,
//                 duration: Duration(seconds: 2),
//               ),
//             );
//           }
//         } else {
//           // Fallback: Copy to clipboard
//           await Clipboard.setData(ClipboardData(text: emailContent));
//           throw Exception('Could not open email app. Email content copied to clipboard.');
//         }
//       }

//     } catch (e) {
//       _notificationError = e.toString();
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(e.toString()),
//             backgroundColor: Colors.orange,
//             duration: const Duration(seconds: 5),
//           ),
//         );
//       }
//     } finally {
//       _sendingNotification = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // RESEND NOTIFICATIONS
//   // ========================
//   Future<void> resendAllNotifications({
//     required BuildContext context,
//     required String orderId,
//   }) async {
//     try {
//       final order = await fetchSingleOrder(orderId);
//       if (order == null) return;

//       final employeeId = _ensureEmployeeId();
//       if (order['employee_id'] != employeeId) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('You do not have permission to access this order'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }

//       final hasEmail = order['customer_email']?.toString().isNotEmpty ?? false;
//       final hasWhatsApp = order['customer_mobile']?.toString().isNotEmpty ?? false;

//       if (!hasEmail && !hasWhatsApp) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('No contact information available'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//         return;
//       }

//       // Show options dialog
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Resend Notifications'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (hasWhatsApp)
//                 ListTile(
//                   leading: const Icon(Icons.message, color: Colors.green),
//                   title: const Text('Send WhatsApp'),
//                   subtitle: Text('To: ${order['customer_mobile']}'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     sendOrderWhatsAppNotification(
//                       context: context,
//                       orderId: orderId,
//                       order: order,
//                     );
//                   },
//                 ),
//               if (hasEmail)
//                 ListTile(
//                   leading: const Icon(Icons.email, color: Colors.blue),
//                   title: const Text('Send Email'),
//                   subtitle: Text('To: ${order['customer_email']}'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     sendOrderEmailNotification(
//                       context: context,
//                       orderId: orderId,
//                       order: order,
//                     );
//                   },
//                 ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//           ],
//         ),
//       );

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // ========================
//   // SEND STATUS UPDATE NOTIFICATION
//   // ========================
//   Future<void> sendStatusUpdateNotification({
//     required String orderId,
//     required String newStatus,
//     required BuildContext context,
//     String? notes,
//   }) async {
//     await sendStatusUpdateWhatsApp(
//       context: context,
//       orderId: orderId,
//       newStatus: newStatus,
//       notes: notes,
//     );
//   }

//   // ========================
//   // HELPER METHODS
//   // ========================
//   void _showErrorSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // ========================
//   // QUICK LOAD (for initial load) - Employee-specific
//   // ========================
//   Future<void> quickLoad() async {
//     // Don't use cached flag if no user
//     final employeeId = _ensureEmployeeId();
//     if (employeeId == null) {
//       orders = [];
//       notifyListeners();
//       return;
//     }

//     if (_initialLoadComplete && orders.isNotEmpty) return;

//     try {
//       loading = true;
//       notifyListeners();

//       // First fetch accurate counts
//       await fetchOrderCounts();

//       // Then fetch first page of orders
//       final data = await _orderService.getOrders(
//         limit: 10,
//         employeeId: employeeId,
//       );

//       orders = data.map((order) {
//         return {...order, 'display_id': _getDisplayOrderId(order)};
//       }).toList();

//       _initialLoadComplete = true;
//       error = null;
//     } catch (e) {
//       error = 'Failed to load orders: $e';
//       debugPrint("❌ Quick load failed: $e");
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // FETCH ORDERS (original method) - Employee-specific
//   // ========================
//   Future<void> fetchOrders({bool loadMore = false, String? status}) async {
//     try {
//       final employeeId = _ensureEmployeeId();
//       if (employeeId == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       if (!loadMore) {
//         _page = 0;
//         _hasMoreData = true;
//         orders.clear();
//       }

//       if (!_hasMoreData && loadMore) return;

//       loading = true;
//       notifyListeners();

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: _limit,
//         offset: _page * _limit,
//         status: status,
//         employeeId: employeeId,
//       );

//       final newOrders = data.map((order) {
//         return {...order, 'display_id': _getDisplayOrderId(order)};
//       }).toList();

//       if (newOrders.length < _limit) {
//         _hasMoreData = false;
//       }

//       if (loadMore) {
//         orders.addAll(newOrders);
//       } else {
//         orders = newOrders;
//       }

//       _page++;
//       _initialLoadComplete = true;
//       error = null;
//     } catch (e) {
//       error = 'Failed to fetch orders: $e';
//       debugPrint("❌ Fetch orders failed: $e");
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> loadMore() async {
//     if (!_hasMoreData || loading) return;
//     await fetchOrders(loadMore: true);
//   }

//   Future<Map<String, dynamic>?> fetchSingleOrder(String orderId) async {
//     try {
//       final employeeId = _ensureEmployeeId();
//       if (employeeId == null) return null;

//       // Use OrderService to fetch single order with employee_id check
//       final response = await _orderService.getOrder(orderId);
      
//       // Verify this order belongs to the current employee
//       if (response != null && response['employee_id'] == employeeId) {
//         return {...response, 'display_id': _getDisplayOrderId(response)};
//       }
      
//       return null;
//     } catch (e) {
//       debugPrint("❌ Fetch single order failed: $e");
//       return null;
//     }
//   }

//   Future<void> updateOrderStatus(String orderId, String newStatus, {String? notes}) async {
//     try {
//       final employeeId = _ensureEmployeeId();
//       if (employeeId == null) throw Exception('No employee logged in');

//       loading = true;
//       notifyListeners();

//       // First verify this order belongs to the employee
//       final order = await fetchSingleOrder(orderId);
//       if (order == null) {
//         throw Exception('Order not found or you do not have permission');
//       }

//       // Use OrderService to update status
//       await _orderService.updateOrderStatus(
//         orderId, 
//         newStatus, 
//         notes: notes,
//         sendNotification: false,
//       );

//       // Refresh counts after status update
//       await fetchOrderCounts();
//       await quickLoad();
//     } catch (e) {
//       debugPrint("❌ Update order status failed: $e");
//       rethrow;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> deleteOrder(String orderId) async {
//     try {
//       final employeeId = _ensureEmployeeId();
//       if (employeeId == null) throw Exception('No employee logged in');

//       loading = true;
//       notifyListeners();

//       // First verify this order belongs to the employee
//       final order = await fetchSingleOrder(orderId);
//       if (order == null) {
//         throw Exception('Order not found or you do not have permission');
//       }

//       await _orderService.deleteOrder(orderId);

//       orders.removeWhere((order) => order['id'] == orderId);
      
//       // Refresh counts after deletion
//       await fetchOrderCounts();

//       notifyListeners();
//     } catch (e) {
//       debugPrint("❌ Delete order failed: $e");
//       rethrow;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   String _getDisplayOrderId(Map<String, dynamic> order) {
//     if (order['order_number'] != null &&
//         order['order_number'].toString().isNotEmpty) {
//       return order['order_number'].toString();
//     }

//     if (order['id'] != null) {
//       final uuid = order['id'].toString();
//       return '#${uuid.substring(0, 8).toUpperCase()}';
//     }

//     return '#N/A';
//   }

//   // ========================
//   // REFRESH METHOD
//   // ========================
//   Future<void> refresh() async {
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
    
//     // Fetch counts first
//     await fetchOrderCounts();
//     await quickLoad();
//   }

//   // ========================
//   // GETTERS (all filtered to current employee)
//   // ========================
//   List<Map<String, dynamic>> get pending =>
//       orders.where((e) => e['status'] == 'pending').toList();

//   List<Map<String, dynamic>> get packing =>
//       orders.where((e) => e['status'] == 'packing').toList();

//   List<Map<String, dynamic>> get readyForDispatch =>
//       orders.where((e) => e['status'] == 'ready_for_dispatch').toList();

//   List<Map<String, dynamic>> get dispatched =>
//       orders.where((e) => e['status'] == 'dispatched').toList();

//   List<Map<String, dynamic>> get delivered =>
//       orders.where((e) => e['status'] == 'delivered').toList();

//   List<Map<String, dynamic>> get completed =>
//       orders.where((e) => e['status'] == 'completed').toList();

//   List<Map<String, dynamic>> get cancelled =>
//       orders.where((e) => e['status'] == 'cancelled').toList();

//   List<Map<String, dynamic>> get allOrders => orders;

//   Map<String, dynamic>? getOrderById(String id) {
//     try {
//       final order = orders.firstWhere((order) => order['id'] == id);
//       // Verify this order belongs to current employee
//       final employeeId = _ensureEmployeeId();
//       if (order['employee_id'] == employeeId) {
//         return order;
//       }
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }

//   bool get hasMoreData => _hasMoreData;
//   bool get sendingNotification => _sendingNotification;
//   String? get notificationError => _notificationError;

//   Map<String, int> getStatistics() {
//     return {
//       'total': totalOrders,
//       'pending': pendingOrders,
//       'packing': packingOrders,
//       'ready_for_dispatch': readyForDispatchOrders,
//       'dispatched': dispatchedOrders,
//       'delivered': deliveredOrders,
//       'completed': completedOrders,
//       'cancelled': cancelledOrders,
//     };
//   }

//   Map<String, dynamic> getOrderSummary() {
//     double totalRevenue = 0;
//     for (var order in orders) {
//       if (order['total_price'] != null) {
//         totalRevenue += (order['total_price'] as num).toDouble();
//       }
//     }

//     return {
//       'total_orders': totalOrders,
//       'total_revenue': totalRevenue,
//       'average_order_value': totalOrders > 0 ? totalRevenue / totalOrders : 0,
//       'completion_rate': totalOrders > 0
//           ? (completedOrders / totalOrders) * 100
//           : 0,
//     };
//   }

//   bool orderExists(String orderId) {
//     final employeeId = _ensureEmployeeId();
//     return orders.any((order) => 
//       order['id'] == orderId && order['employee_id'] == employeeId
//     );
//   }
// }

// // WhatsApp Preview Dialog Widget
// class _WhatsAppPreviewDialog extends StatelessWidget {
//   final String phoneNumber;
//   final String message;
//   final String orderNumber;
//   final bool isStatusUpdate;
//   final String? newStatus;

//   const _WhatsAppPreviewDialog({
//     required this.phoneNumber,
//     required this.message,
//     required this.orderNumber,
//     this.isStatusUpdate = false,
//     this.newStatus,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.message,
//                   color: Colors.green,
//                   size: 30,
//                 ),
//                 const SizedBox(width: 10),
//                 Text(
//                   isStatusUpdate ? 'Status Update' : 'Order Confirmation',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 15),
//             Text(
//               'Send to: $phoneNumber',
//               style: TextStyle(
//                 color: Colors.grey[700],
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 5),
//             Text(
//               'Order: $orderNumber',
//               style: TextStyle(
//                 color: Colors.grey[700],
//                 fontSize: 14,
//               ),
//             ),
//             if (isStatusUpdate && newStatus != null) ...[
//               const SizedBox(height: 5),
//               Text(
//                 'New Status: ${newStatus!.toUpperCase()}',
//                 style: TextStyle(
//                   color: Colors.blue[700],
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.green[50],
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.green[100]!),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Message Preview:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 14,
//                       color: Colors.green,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey[300]!),
//                     ),
//                     child: SingleChildScrollView(
//                       child: Text(
//                         message,
//                         style: const TextStyle(
//                           fontSize: 12,
//                           height: 1.4,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 25),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text(
//                     'Cancel',
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: () => Navigator.pop(context, true),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.send, size: 18),
//                       SizedBox(width: 8),
//                       Text('Send via WhatsApp'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




















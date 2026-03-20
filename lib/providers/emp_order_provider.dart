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

  // Order counts - these will be accurate and employee-specific
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

  // Tracking base URL  
  OrderProvider() {
    _orderService = OrderService(supabase);
    _initAuthListener();
    _getCurrentEmployeeId();
  }

  // ========================
  // INIT AUTH LISTENER
  // ========================
  void _initAuthListener() {
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // User logged in
        _currentEmployeeId = session.user.id;
        print('👤 Auth: User logged in - ID: $_currentEmployeeId');
        // Clear old data and reload for new user
        _clearData();
        quickLoad();
      } else {
        // User logged out
        print('👤 Auth: User logged out');
        _currentEmployeeId = null;
        _clearData();
      }
      notifyListeners();
    });
  }

  // ========================
  // CLEAR DATA ON LOGOUT
  // ========================
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

  // ========================
  // DISPOSE
  // ========================
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ========================
  // GET CURRENT EMPLOYEE ID
  // ========================
  Future<void> _getCurrentEmployeeId() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      _currentEmployeeId = user.id;
      print('👤 Current employee ID: $_currentEmployeeId');
      // Load data for this user
      await quickLoad();
    } else {
      _clearData();
    }
  }

  // Helper method to ensure employee ID is available
  String? _ensureEmployeeId() {
    // Always get fresh user from auth
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Update if changed
      if (_currentEmployeeId != user.id) {
        _currentEmployeeId = user.id;
        print('👤 Employee ID updated to: $_currentEmployeeId');
        // Clear old data when user changes
        _clearData();
      }
      return _currentEmployeeId;
    }
    
    // No user logged in
    if (_currentEmployeeId != null) {
      _currentEmployeeId = null;
      _clearData();
    }
    return null;
  }

  // ========================
  // FETCH ACCURATE ORDER COUNTS (Employee-specific)
  // ========================
  Future<void> fetchOrderCounts() async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) {
        print('⚠️ No employee logged in');
        return;
      }

      print('📊 Fetching accurate order counts for employee: $employeeId');

      // Get total orders count - filtered by employee_id
      final totalCount = await supabase
          .from('emp_mar_orders')
          .count(CountOption.exact)
          .eq('employee_id', employeeId);

      // Get counts by status - all filtered by employee_id
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

      // Update the counts
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
      print('   Packing: $packingOrders');
      print('   Ready for Dispatch: $readyForDispatchOrders');
      print('   Dispatched: $dispatchedOrders');
      print('   Delivered: $deliveredOrders');
      print('   Cancelled: $cancelledOrders');

      notifyListeners();

    } catch (e) {
      print('❌ Error fetching order counts: $e');
    }
  }

  // ========================
  // FETCH ORDERS WITH COUNTS (Employee-specific)
  // ========================
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

      // First fetch the counts (employee-specific)
      await fetchOrderCounts();

      // Then fetch the paginated orders (employee-specific)
      final data = await _orderService.getOrders(
        limit: _limit,
        offset: _page * _limit,
        status: status,
        employeeId: employeeId, // This ensures only employee's orders
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

  // ========================
  // GET ORDERS BY DISTRICT (Employee-specific)
  // ========================
  Future<Map<String, dynamic>> getOrdersByDistrict(String district) async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) return {};

      // Get counts for specific district - filtered by employee_id
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

  // ========================
  // GET MONTHLY COMPLETED ORDERS (for dashboard charts)
  // ========================
  Future<List<double>> getMonthlyCompletedOrders(int year) async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) return List.filled(12, 0.0);

      print('📊 Fetching monthly completed orders for employee $employeeId, year $year');

      // Fetch all completed orders for this employee in the given year
      final orders = await supabase
          .from('emp_mar_orders')
          .select('bags, created_at')
          .eq('employee_id', employeeId)
          .eq('status', 'completed')
          .gte('created_at', '$year-01-01')
          .lte('created_at', '$year-12-31');

      // Initialize monthly totals
      final monthlyTotals = List<double>.filled(12, 0.0);

      // Sum bags by month
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

  // ========================
  // GET ORDERS BY DATE RANGE   
  // ========================
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

  // ========================
  // GET ORDER STATISTICS (Employee-specific)
  // ========================
  Future<Map<String, dynamic>> getEmployeeStatistics() async {
    try {
      final employeeId = _ensureEmployeeId();
      if (employeeId == null) return {};

      // Get total revenue
      final revenueResponse = await supabase
          .from('emp_mar_orders')
          .select('total_price')
          .eq('employee_id', employeeId);

      double totalRevenue = 0;
      for (var order in revenueResponse) {
        totalRevenue += (order['total_price'] as num?)?.toDouble() ?? 0;
      }

      // Get average order value
      final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

      // Get completion rate
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

  // ========================
  // GENERATE TRACKING LINK
  // ========================
  String generateTrackingLink(Map<String, dynamic> order) {
    final trackingId = order['tracking_id']?.toString() ?? '';
    final trackingToken = order['tracking_token']?.toString() ?? '';
    
    if (trackingId.isEmpty) return '';
    
    // Direct link to HTML file in storage
    return 'https://phkkiyxfcepqauxncqpm.supabase.co/storage/v1/object/public/tracking/tracker.html?id=$trackingId&token=$trackingToken';
  }

  // ========================
  // CREATE ORDER WITH NOTIFICATIONS
  // ========================
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data, BuildContext context) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Update current employee ID
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

      // Use OrderService to create order
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
      
      // Refresh counts after creating new order
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

  // ========================
  // WHATSAPP NOTIFICATION METHODS
  // ========================
  Future<void> sendOrderWhatsAppNotification({
    required BuildContext context,
    required String orderId,
    Map<String, dynamic>? order,
    bool showDialog = true,
  }) async {
    try {
      print('🚀 Starting WhatsApp notification for order: $orderId');
      
      // Fetch order details if not provided
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

      // Verify this order belongs to the current employee
      final employeeId = _ensureEmployeeId();
      if (orderData['employee_id'] != employeeId) {
        throw Exception('You do not have permission to access this order');
      }

      final phoneNumber = orderData['customer_mobile']?.toString() ?? '';
      print('📱 Customer mobile: $phoneNumber');
      
      if (phoneNumber.isEmpty) {
        throw Exception('No mobile number available');
      }

      // Generate message
      final message = _generateWhatsAppMessage(orderData, 'confirmation');

      // Send via WhatsApp
      print('📤 Launching WhatsApp...');
      final launched = await _launchWhatsAppMobile(phoneNumber, message);
      
      if (!launched) {
        throw Exception('Could not launch WhatsApp');
      }

      // Update database
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
        .eq('employee_id', employeeId as Object); // Extra safety: ensure employee owns this order

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

  // MOBILE-OPTIMIZED WHATSAPP LAUNCH METHOD
  Future<bool> _launchWhatsAppMobile(String phoneNumber, String message) async {
    // Check if phone number is valid
    if (phoneNumber.isEmpty) {
      throw Exception('Phone number is empty');
    }
    
    // Clean and format phone number
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Ensure it's valid length
    if (cleanPhone.length < 10) {
      throw Exception('Invalid phone number: $phoneNumber (too short)');
    }
    
    // Handle different formats
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone'; // Add India country code
    } else if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
      // Already has country code
    } else if (cleanPhone.length == 11 && cleanPhone.startsWith('0')) {
      cleanPhone = '91${cleanPhone.substring(1)}'; // Remove leading 0, add 91
    }
    
    // For mobile devices, we need to use a different approach
    // First, try the intent method for Android
    final encodedMessage = Uri.encodeComponent(message.trim());
    
    // Method 1: WhatsApp intent for Android
    final intentUri = 'intent://send?phone=$cleanPhone&text=$encodedMessage#Intent;package=com.whatsapp;scheme=whatsapp;end;';
    
    try {
      final intentAndroid = Uri.parse(intentUri);
      if (await canLaunchUrl(intentAndroid)) {
        await launchUrl(intentAndroid);
        print('✅ Launched WhatsApp via intent with pre-filled message');
        return true;
      }
    } catch (e) {
      print('❌ Intent method failed: $e');
    }
    
    // Method 2: Traditional URL schemes
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
    
    // Method 3: Try to open WhatsApp directly (without pre-filled message)
    try {
      final whatsappUri = Uri.parse('whatsapp://send?phone=$cleanPhone');
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
        
        // Show dialog with message to copy
        if (message.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: message));
          _showMessageCopiedDialog(message);
        }
        
        print('✅ Launched WhatsApp without pre-filled message, message copied');
        return true;
      }
    } catch (e) {
      print('❌ Direct WhatsApp open failed: $e');
    }
    
    // Check if WhatsApp is installed
    bool isWhatsAppInstalled = false;
    try {
      final checkUri = Uri.parse('whatsapp://send');
      isWhatsAppInstalled = await canLaunchUrl(checkUri);
    } catch (e) {
      print('Error checking WhatsApp installation: $e');
    }
    
    if (!isWhatsAppInstalled) {
      // WhatsApp not installed, offer to open Play Store
      final playStoreUri = Uri.parse('market://details?id=com.whatsapp');
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri);
        throw Exception('WhatsApp is not installed. Opening Play Store to install WhatsApp.');
      } else {
        final webUri = Uri.parse('https://play.google.com/store/apps/details?id=com.whatsapp');
        await launchUrl(webUri);
        throw Exception('WhatsApp is not installed. Opening web page to install WhatsApp.');
      }
    }
    
    // Final fallback: Copy to clipboard
    await Clipboard.setData(ClipboardData(text: message));
    throw Exception('Could not launch WhatsApp. Message copied to clipboard. Please open WhatsApp manually and paste the message.');
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

      // Generate status message
      final message = _generateWhatsAppMessage(order, 'status_update', 
        newStatus: newStatus, notes: notes);

      // Show preview
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
          // Update status in database
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
    
    // Generate tracking link
    final trackingLink = generateTrackingLink(order);

    if (messageType == 'confirmation') {
      return '''
🛒 *MEGA PRO CATTLE FEED - ORDER CONFIRMED*

👤 *Customer:* $customerName
📦 *Product:* $product
🔢 *Quantity:* $bags bags ($weight $unit)
💰 *Amount:* ₹$amount
📍 *Status:* ✅ Processing

📋 *Delivery Details:*
$address
$district

${trackingLink.isNotEmpty ? '🔗 *Track Your Order (Click Link):*\n$trackingLink\n' : ''}
📞 *Need Help?* Call: +91 98765 43210

_Thank you for choosing Mega Pro Cattle Feed!_
    ''';
    } else if (messageType == 'status_update' && newStatus != null) {
      final statusMessages = {
        'pending': '📋 Order received and being processed',
        'packing': '📦 Your order is being packed',
        'ready_for_dispatch': '🚚 Order packed and ready for dispatch',
        'dispatched': '📤 Order dispatched! On the way',
        'delivered': '✅ Order delivered successfully',
        'completed': '🎉 Order completed! Thank you',
        'cancelled': '❌ Order has been cancelled',
      };
      
      final statusText = statusMessages[newStatus.toLowerCase()] ?? 'Status updated';
      final statusEmoji = {
        'pending': '📋',
        'packing': '📦',
        'ready_for_dispatch': '🚚',
        'dispatched': '📤',
        'delivered': '✅',
        'completed': '🎉',
        'cancelled': '❌',
      }[newStatus.toLowerCase()] ?? '📋';
      
      String message = '''
$statusEmoji *ORDER STATUS UPDATE*

_Status: ${newStatus.toUpperCase()}_

$statusText

${notes != null && notes.isNotEmpty ? '📝 _Notes:_ $notes\n' : ''}
${trackingLink.isNotEmpty ? '🔗 *Track Your Order (Click Link):*\n$trackingLink\n' : ''}
_We appreciate your patience!_
    ''';
      
      return message;
    }
    
    return 'Order update for $orderNumber';
  }

  void debugOrderData(Map<String, dynamic> order) {
    print('🔍 DEBUG ORDER DATA:');
    print('Order keys: ${order.keys.toList()}');
    print('Employee ID: ${order['employee_id']}');
  }

  // ========================
  // EMAIL NOTIFICATION METHODS
  // ========================
  Future<void> sendOrderEmailNotification({
    required BuildContext context,
    required String orderId,
    Map<String, dynamic>? order,
  }) async {
    try {
      _sendingNotification = true;
      _notificationError = null;
      notifyListeners();

      // Fetch order details if not provided
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

      // Safely get order number
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
      
      // Generate tracking link
      final trackingLink = generateTrackingLink(orderData);

      // Create email content
      final emailContent = '''
Dear $customerName,

Your cattle feed order has been confirmed!

📋 ORDER DETAILS:
- Order Number: $orderNumber
- Product: $product
- Quantity: $bags bags
- Total Weight: $weight $unit
- Total Amount: ₹$amount
- Delivery Address: ${orderData['customer_address'] ?? ''}
- District: ${orderData['district'] ?? 'N/A'}
- Status: Processing
- Expected Delivery: 3-5 business days

${trackingLink.isNotEmpty ? '🔗 TRACK YOUR ORDER:\n$trackingLink\n' : ''}

Click the link above to see real-time updates on your order status.

Thank you for choosing Mega Pro Cattle Feed!

Best regards,
Mega Pro Cattle Feed Team
📞 +91 98765 43210
      ''';

      // Show email template
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
                        style: const TextStyle(fontSize: 12),
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
        // Create a proper mailto URL with encoded components
        final subject = 'Order Confirmed: $orderNumber';
        final mailtoUrl = 'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(emailContent)}';
        final emailUri = Uri.parse(mailtoUrl);

        // Try to launch email app
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(
            emailUri,
            mode: LaunchMode.externalApplication,
          );
          
          // Update database with employee_id check
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
          // Fallback: Copy to clipboard
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

  // ========================
  // RESEND NOTIFICATIONS
  // ========================
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

      // Show options dialog
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

  // ========================
  // SEND STATUS UPDATE NOTIFICATION
  // ========================
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

  // ========================
  // HELPER METHODS
  // ========================
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ========================
  // QUICK LOAD (for initial load) - Employee-specific
  // ========================
  Future<void> quickLoad() async {
    // Don't use cached flag if no user
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

      // First fetch accurate counts
      await fetchOrderCounts();

      // Then fetch first page of orders
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

  // ========================
  // FETCH ORDERS (original method) - Employee-specific
  // ========================
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

      // Use OrderService to fetch orders
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

      // Use OrderService to fetch single order with employee_id check
      final response = await _orderService.getOrder(orderId);
      
      // Verify this order belongs to the current employee
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

      // First verify this order belongs to the employee
      final order = await fetchSingleOrder(orderId);
      if (order == null) {
        throw Exception('Order not found or you do not have permission');
      }

      // Use OrderService to update status
      await _orderService.updateOrderStatus(
        orderId, 
        newStatus, 
        notes: notes,
        sendNotification: false,
      );

      // Refresh counts after status update
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

      // First verify this order belongs to the employee
      final order = await fetchSingleOrder(orderId);
      if (order == null) {
        throw Exception('Order not found or you do not have permission');
      }

      await _orderService.deleteOrder(orderId);

      orders.removeWhere((order) => order['id'] == orderId);
      
      // Refresh counts after deletion
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

  // ========================
  // REFRESH METHOD
  // ========================
  Future<void> refresh() async {
    _page = 0;
    _hasMoreData = true;
    _initialLoadComplete = false;
    
    // Fetch counts first
    await fetchOrderCounts();
    await quickLoad();
  }

  // ========================
  // GETTERS (all filtered to current employee)
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

  Map<String, dynamic>? getOrderById(String id) {
    try {
      final order = orders.firstWhere((order) => order['id'] == id);
      // Verify this order belongs to current employee
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

// WhatsApp Preview Dialog Widget
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























// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:mega_pro/employee/emp_attendance.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import '../services/order_service.dart';

// class OrderProvider with ChangeNotifier {
//   final SupabaseClient supabase = Supabase.instance.client;
//   late OrderService _orderService;
  
//   bool loading = false;
//   String? error;
//   String filter = 'all'; // Add filter property

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
//   int _limit = 20;
//   bool _initialLoadComplete = false;

//   // Notification state
//   bool _sendingNotification = false;
//   String? _notificationError;

//   OrderProvider() {
//     _orderService = OrderService(supabase);
//   }

//   // ========================
//   // CREATE ORDER WITH NOTIFICATIONS
//   // ========================
//   Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data, BuildContext context) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       final int bags = data['bags'] as int;
//       final int weightPerBag = data['weight_per_bag'] as int;
//       final int pricePerBag = data['price_per_bag'] as int;

//       final int totalWeight = bags * weightPerBag;
//       final int totalPrice = bags * pricePerBag;

//       print('📝 Creating new order with data:');
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
//       print('📊 Order details: ${orderResponse['order_number']} - ${orderResponse['tracking_token']}');

//       // Show notification options dialog if customer has contact info
//       final hasMobile = (data['customer_mobile'] as String).isNotEmpty;
//       final hasEmail = data['customer_email'] != null && (data['customer_email'] as String).isNotEmpty;
      
//       if (hasMobile || hasEmail) {
//         await _showNotificationOptionsDialog(
//           context: context,
//           orderResponse: orderResponse,
//           customerMobile: data['customer_mobile'] as String,
//           customerEmail: data['customer_email'] as String?,
//         );
//       }

//       await quickLoad();
      
//       return orderResponse;

//     } catch (e) {
//       debugPrint("❌ Order insert failed: $e");
//       _showErrorSnackbar(context, "Failed to create order: ${e.toString()}");
//       rethrow;
//     }
//   }

//   // ========================
//   // SHOW NOTIFICATION OPTIONS DIALOG
//   // ========================
//   Future<void> _showNotificationOptionsDialog({
//     required BuildContext context,
//     required Map<String, dynamic> orderResponse,
//     required String customerMobile,
//     required String? customerEmail,
//   }) async {
//     final orderNumber = orderResponse['order_number']?.toString() ?? 
//         'ORD${DateTime.now().millisecondsSinceEpoch}';
//     final trackingToken = orderResponse['tracking_token']?.toString() ?? '';
//     final trackingLink = _orderService.getTrackingUrl(trackingToken);

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Send Notifications'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Order #$orderNumber created successfully!'),
//                 const SizedBox(height: 8),
//                 const Text('Would you like to send notifications to the customer?'),
//                 const SizedBox(height: 20),
                
//                 if (customerMobile.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.message_outlined,
//                     color: Colors.green,
//                     title: 'Send WhatsApp',
//                     subtitle: 'To: $customerMobile',
//                     onTap: () {
//                       Navigator.pop(context);
//                       sendOrderWhatsAppNotification(
//                         context: context,
//                         orderId: orderResponse['id'].toString(),
//                         order: orderResponse,
//                       );
//                     },
//                   ),
                
//                 if (customerEmail != null && customerEmail.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.email,
//                     color: Colors.blue,
//                     title: 'Send Email',
//                     subtitle: 'To: $customerEmail',
//                     onTap: () {
//                       Navigator.pop(context);
//                       sendOrderEmailNotification(
//                         context: context,
//                         orderId: orderResponse['id'].toString(),
//                         order: orderResponse,
//                       );
//                     },
//                   ),
                
//                 const SizedBox(height: 16),
//                 Text(
//                   '💡 Tip: You can send notifications later from the order details screen.',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Skip'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ========================
//   // BUILD NOTIFICATION OPTION WIDGET
//   // ========================
//   Widget _buildNotificationOption({
//     required IconData icon,
//     required Color color,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         child: ListTile(
//           leading: Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: color),
//           ),
//           title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//           subtitle: Text(subtitle),
//           trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//           onTap: onTap,
//         ),
//       ),
//     );
//   }

//   // ========================
//   // WHATSAPP NOTIFICATION METHODS - FIXED FOR MOBILE
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
//         final fetchedOrder = await fetchSingleOrder(orderId);
//         if (fetchedOrder == null) {
//           throw Exception('Order not found');
//         }
//         orderData = fetchedOrder;
//       }
      
//       if (orderData.isEmpty) {
//         throw Exception('Order data is empty');
//       }

//       // DEBUG: Check what's in the order data
//       debugOrderData(orderData);
      
//       final phoneNumber = orderData['customer_mobile']?.toString() ?? '';
//       print('📱 Customer mobile: $phoneNumber');
      
//       if (phoneNumber.isEmpty) {
//         throw Exception('No mobile number available');
//       }

//       // Generate message
//       final message = _generateWhatsAppMessage(orderData, 'confirmation');
//       print('💬 Generated message length: ${message.length}');
//       print('📄 Generated message preview: ${message.substring(0, message.length > 100 ? 100 : message.length)}...');

//       // Send via WhatsApp with mobile-optimized method
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
//         .eq('id', orderId);

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
    
//     // Method 1: WhatsApp intent for Android (most reliable for pre-filled messages)
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
    
//     // Method 2: Traditional URL schemes (try multiple)
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
//     // DEBUG: Print what's in the order
//     print('🛠️ DEBUG: Generating WhatsApp message from order data');
//     print('Order keys: ${order.keys.toList()}');
//     print('order_number field: ${order['order_number']}');
//     print('order_number type: ${order['order_number']?.runtimeType}');
    
//     // Get order number - handle database NULL value
//     String orderNumber;
//     final orderNumValue = order['order_number'];
    
//     if (orderNumValue == null) {
//       print('⚠️ order_number is NULL in database');
      
//       // Try to use id as fallback
//       if (order['id'] != null) {
//         final idStr = order['id'].toString();
//         if (idStr.length >= 8) {
//           orderNumber = 'ORD${idStr.substring(0, 8).toUpperCase()}';
//         } else {
//           orderNumber = 'ORD${idStr.toUpperCase()}';
//         }
//         print('🔄 Using ID as fallback: $orderNumber');
//       } else {
//         orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}';
//         print('🔄 Using timestamp as fallback: $orderNumber');
//       }
//     } else {
//       // Convert to string and check if empty
//       final orderNumStr = orderNumValue.toString();
//       if (orderNumStr.isEmpty) {
//         orderNumber = 'N/A';
//         print('⚠️ order_number is empty string');
//       } else {
//         orderNumber = orderNumStr;
//         print('✅ Using database order_number: $orderNumber');
//       }
//     }
    
//     // Get other fields with null safety
//     final customerName = order['customer_name']?.toString() ?? 'Customer';
//     final product = order['feed_category']?.toString() ?? 'Cattle Feed';
//     final bags = order['bags']?.toString() ?? '1';
//     final amount = order['total_price']?.toString() ?? '0';
//     final weight = order['total_weight']?.toString() ?? '0';
//     final unit = order['weight_unit']?.toString() ?? 'kg';
//     final address = order['customer_address']?.toString() ?? '';
//     final district = order['district']?.toString() ?? '';
//     final trackingToken = order['tracking_token']?.toString() ?? '';
//     final trackingLink = trackingToken.isNotEmpty 
//         ? 'https://mega-pro.in/track/$trackingToken'
//         : '';

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

// ${trackingLink.isNotEmpty ? '🔗 *Track Order:*\n$trackingLink\n' : ''}
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
// ${trackingLink.isNotEmpty ? '🔗 *Track Order:*\n$trackingLink\n' : ''}
// _We appreciate your patience!_
//     ''';
      
//       return message;
//     }
    
//     return 'Order update for $orderNumber';
//   }

//   void debugOrderData(Map<String, dynamic> order) {
//     print('🔍 DEBUG ORDER DATA:');
//     print('Order keys: ${order.keys.toList()}');
    
//     if (order.containsKey('order_number')) {
//       final value = order['order_number'];
//       print('order_number exists: true');
//       print('order_number value: $value');
//       print('order_number type: ${value.runtimeType}');
//       print('order_number is null: ${value == null}');
//       print('order_number toString: ${value.toString()}');
//       print('order_number isEmpty: ${value.toString().isEmpty}');
//     } else {
//       print('order_number exists: false');
//     }
    
//     if (order.containsKey('id')) {
//       print('id: ${order['id']}');
//     }
//   }

//   Future<void> testDatabaseOrderNumber(String orderId) async {
//     try {
//       print('🔍 TEST: Checking database for order: $orderId');
      
//       // Direct database query to see what's really there
//       final response = await supabase
//         .from('emp_mar_orders')
//         .select('id, order_number, customer_name, created_at')
//         .eq('id', orderId)
//         .single();
      
//       print('📊 Database response:');
//       print('   ID: ${response['id']}');
//       print('   Order Number: ${response['order_number']}');
//       print('   Order Number Type: ${response['order_number']?.runtimeType}');
//       print('   Customer Name: ${response['customer_name']}');
//       print('   Created At: ${response['created_at']}');
      
//     } catch (e) {
//       print('❌ Test failed: $e');
//     }
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
//       Map<String, dynamic> orderData;
//       if (order != null) {
//         orderData = order;
//       } else {
//         final fetchedOrder = await fetchSingleOrder(orderId);
//         if (fetchedOrder == null) {
//           throw Exception('Order not found');
//         }
//         orderData = fetchedOrder;
//       }
      
//       if (orderData.isEmpty) {
//         throw Exception('Order data is empty');
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
//         final idStr = orderData['id'].toString();
//         orderNumber = 'ORD${idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : idStr.toUpperCase()}';
//       } else {
//         orderNumber = 'N/A';
//       }
      
//       final customerName = orderData['customer_name']?.toString() ?? 'Customer';
//       final product = orderData['feed_category']?.toString() ?? 'Cattle Feed';
//       final bags = orderData['bags']?.toString() ?? '1';
//       final amount = orderData['total_price']?.toString() ?? '0';
//       final weight = orderData['total_weight']?.toString() ?? '0';
//       final unit = orderData['weight_unit']?.toString() ?? 'kg';
      
//       final trackingToken = orderData['tracking_token']?.toString() ?? '';
//       final trackingLink = trackingToken.isNotEmpty 
//           ? 'https://mega-pro.in/track/$trackingToken'
//           : '';

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

// ${trackingLink.isNotEmpty ? '🔗 Track Your Order:\n$trackingLink\n' : ''}

// Thank you for choosing Mega Pro Cattle Feed!

// Best regards,
// Mega Pro Cattle Feed Team
// 📞 +91 98765 43210
//     ''';

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
          
//           // Update database
//           await supabase
//             .from('emp_mar_orders')
//             .update({
//               'email_sent': true,
//               'notification_sent': true,
//               'last_notification_sent_at': DateTime.now().toUtc().toIso8601String(),
//               'updated_at': DateTime.now().toUtc().toIso8601String(),
//             })
//             .eq('id', orderId);

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

//   // Add this method to OrderProvider
//   String generateTrackingLink(String trackingId, String? trackingToken) {
//     final baseUrl = 'https://phkkiyxfcepqauxncqpm.supabase.co/storage/v1/object/public/tracking/index.html';
    
//     if (trackingToken != null && trackingToken.isNotEmpty) {
//       return '$baseUrl?id=$trackingId&token=$trackingToken';
//     } else {
//       return '$baseUrl?id=$trackingId';
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

//   void _showSuccessSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showInfoSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.blue,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // ========================
//   // EXISTING METHODS
//   // ========================
//   Future<void> quickLoad() async {
//     if (_initialLoadComplete && orders.isNotEmpty) return;

//     try {
//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: 10,
//         employeeId: user.id,
//       );

//       orders = data.map((order) {
//         return {...order, 'display_id': _getDisplayOrderId(order)};
//       }).toList();

//       _updateCountsFromOrders();
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

//   Future<void> fetchOrders({bool loadMore = false, String? status}) async {
//     try {
//       if (!loadMore) {
//         _page = 0;
//         _hasMoreData = true;
//         orders.clear();
//       }

//       if (!_hasMoreData && loadMore) return;

//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: _limit,
//         offset: _page * _limit,
//         status: status,
//         employeeId: user.id,
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
//       _updateCountsFromOrders();
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

//   // ========================
//   // FETCH ORDER COUNTS
//   // ========================
//   Future<void> fetchOrderCounts() async {
//     try {
//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         totalOrders = 0;
//         pendingOrders = 0;
//         packingOrders = 0;
//         readyForDispatchOrders = 0;
//         dispatchedOrders = 0;
//         deliveredOrders = 0;
//         completedOrders = 0;
//         cancelledOrders = 0;
//         notifyListeners();
//         return;
//       }

//       // Fetch all orders for this employee
//       final response = await supabase
//           .from('emp_mar_orders')
//           .select('status')
//           .eq('employee_id', user.id);

//       // Reset counts
//       totalOrders = response.length;
//       pendingOrders = response.where((e) => e['status'] == 'pending').length;
//       packingOrders = response.where((e) => e['status'] == 'packing').length;
//       readyForDispatchOrders = response.where((e) => e['status'] == 'ready_for_dispatch').length;
//       dispatchedOrders = response.where((e) => e['status'] == 'dispatched').length;
//       deliveredOrders = response.where((e) => e['status'] == 'delivered').length;
//       completedOrders = response.where((e) => e['status'] == 'completed').length;
//       cancelledOrders = response.where((e) => e['status'] == 'cancelled').length;

//       error = null;
//       print('📊 Order counts fetched - Total: $totalOrders, Completed: $completedOrders');
      
//     } catch (e) {
//       error = 'Failed to fetch order counts: $e';
//       debugPrint("❌ Fetch order counts failed: $e");
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
//       // Use OrderService to fetch single order
//       final response = await _orderService.getOrder(orderId);
//       return response != null
//           ? {...response, 'display_id': _getDisplayOrderId(response)}
//           : null;
//     } catch (e) {
//       debugPrint("❌ Fetch single order failed: $e");
//       return null;
//     }
//   }

//   Future<void> updateOrderStatus(String orderId, String newStatus, {String? notes}) async {
//     try {
//       loading = true;
//       notifyListeners();

//       // Use OrderService to update status
//       await _orderService.updateOrderStatus(
//         orderId, 
//         newStatus, 
//         notes: notes,
//         sendNotification: false,
//       );

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
//       loading = true;
//       notifyListeners();

//       await _orderService.deleteOrder(orderId);

//       orders.removeWhere((order) => order['id'] == orderId);
//       _updateCountsFromOrders();

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

//   void _updateCountsFromOrders() {
//     totalOrders = orders.length;
//     pendingOrders = orders.where((e) => e['status'] == 'pending').length;
//     packingOrders = orders.where((e) => e['status'] == 'packing').length;
//     readyForDispatchOrders = orders
//         .where((e) => e['status'] == 'ready_for_dispatch')
//         .length;
//     dispatchedOrders = orders.where((e) => e['status'] == 'dispatched').length;
//     deliveredOrders = orders.where((e) => e['status'] == 'delivered').length;
//     completedOrders = orders.where((e) => e['status'] == 'completed').length;
//     cancelledOrders = orders.where((e) => e['status'] == 'cancelled').length;
//   }

//   // ========================
//   // GETTERS
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
//       return orders.firstWhere((order) => order['id'] == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   bool get hasMoreData => _hasMoreData;
//   bool get sendingNotification => _sendingNotification;
//   String? get notificationError => _notificationError;

//   Future<void> refresh() async {
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     await quickLoad();
//   }

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
//     return orders.any((order) => order['id'] == orderId);
//   }

//   List<Map<String, dynamic>> getOrdersByDateRange(
//     DateTime startDate,
//     DateTime endDate,
//   ) {
//     return orders.where((order) {
//       if (order['created_at'] == null) return false;

//       final createdAt = DateTime.parse(order['created_at']);
//       return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
//           createdAt.isBefore(endDate.add(const Duration(days: 1)));
//     }).toList();
//   }

//   // ========================
//   // GET MONTHLY ORDERS BY STATUS
//   // ========================
//   Future<List<int>> getMonthlyOrdersByStatus(int year, String status, {String? employeeId}) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) return List.filled(12, 0);

//       // Use provided employeeId or get from current user
//       final empId = employeeId ?? user.id;

//       // Fetch orders with specified status for the year
//       final response = await supabase
//           .from('emp_mar_orders')
//           .select('created_at')
//           .eq('employee_id', empId)
//           .eq('status', status)
//           .gte('created_at', DateTime(year, 1, 1).toIso8601String())
//           .lt('created_at', DateTime(year + 1, 1, 1).toIso8601String());

//       // Initialize list with 12 zeros
//       List<int> monthlyCounts = List.filled(12, 0);

//       // Count orders per month
//       for (var order in response) {
//         if (order['created_at'] != null) {
//           final createdAt = DateTime.parse(order['created_at']);
//           final month = createdAt.month - 1;
//           monthlyCounts[month]++;
//         }
//       }

//       print('📊 Monthly $status orders for $year: $monthlyCounts');
//       return monthlyCounts;

//     } catch (e) {
//       debugPrint('❌ Error getting monthly $status orders: $e');
//       return List.filled(12, 0);
//     }
//   }

//   // ========================
//   // GET MONTHLY COMPLETED ORDERS
//   // ========================
//   // Version with optional employeeId parameter
//   Future<List<int>> getMonthlyCompletedOrders(int year, {String? employeeId}) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) return List.filled(12, 0);

//       // Use provided employeeId or get from current user
//       final empId = employeeId ?? user.id;

//       // Fetch completed orders for the specified year
//       final response = await supabase
//           .from('emp_mar_orders')
//           .select('created_at')
//           .eq('employee_id', empId)
//           .eq('status', 'completed')
//           .gte('created_at', DateTime(year, 1, 1).toIso8601String())
//           .lt('created_at', DateTime(year + 1, 1, 1).toIso8601String());

//       // Initialize list with 12 zeros
//       List<int> monthlyCompleted = List.filled(12, 0);

//       // Count completed orders per month
//       for (var order in response) {
//         if (order['created_at'] != null) {
//           final createdAt = DateTime.parse(order['created_at']);
//           final month = createdAt.month - 1;
//           monthlyCompleted[month]++;
//         }
//       }

//       print('📊 Monthly completed orders for $year (employee $empId): $monthlyCompleted');
//       return monthlyCompleted;

//     } catch (e) {
//       debugPrint('❌ Error getting monthly completed orders: $e');
//       return List.filled(12, 0);
//     }
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














// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:mega_pro/employee/emp_attendance.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import '../services/order_service.dart';

// class OrderProvider with ChangeNotifier {
//   final SupabaseClient supabase = Supabase.instance.client;
//   late OrderService _orderService;
  
//   bool loading = false;
//   String? error;
//   String filter = 'all'; // Add filter property

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
//   int _limit = 20;
//   bool _initialLoadComplete = false;

//   // Notification state
//   bool _sendingNotification = false;
//   String? _notificationError;

//   OrderProvider() {
//     _orderService = OrderService(supabase);
//   }

//   // ========================
//   // CREATE ORDER WITH NOTIFICATIONS
//   // ========================
//   Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data, BuildContext context) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       final int bags = data['bags'] as int;
//       final int weightPerBag = data['weight_per_bag'] as int;
//       final int pricePerBag = data['price_per_bag'] as int;

//       final int totalWeight = bags * weightPerBag;
//       final int totalPrice = bags * pricePerBag;

//       print('📝 Creating new order with data:');
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
//       print('📊 Order details: ${orderResponse['order_number']} - ${orderResponse['tracking_token']}');

//       // Show notification options dialog if customer has contact info
//       final hasMobile = (data['customer_mobile'] as String).isNotEmpty;
//       final hasEmail = data['customer_email'] != null && (data['customer_email'] as String).isNotEmpty;
      
//       if (hasMobile || hasEmail) {
//         await _showNotificationOptionsDialog(
//           context: context,
//           orderResponse: orderResponse,
//           customerMobile: data['customer_mobile'] as String,
//           customerEmail: data['customer_email'] as String?,
//         );
//       }

//       await quickLoad();
      
//       return orderResponse;

//     } catch (e) {
//       debugPrint("❌ Order insert failed: $e");
//       _showErrorSnackbar(context, "Failed to create order: ${e.toString()}");
//       rethrow;
//     }
//   }

//   // ========================
//   // SHOW NOTIFICATION OPTIONS DIALOG
//   // ========================
//   Future<void> _showNotificationOptionsDialog({
//     required BuildContext context,
//     required Map<String, dynamic> orderResponse,
//     required String customerMobile,
//     required String? customerEmail,
//   }) async {
//     final orderNumber = orderResponse['order_number']?.toString() ?? 
//         'ORD${DateTime.now().millisecondsSinceEpoch}';
//     final trackingToken = orderResponse['tracking_token']?.toString() ?? '';
//     final trackingLink = _orderService.getTrackingUrl(trackingToken);

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Send Notifications'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Order #$orderNumber created successfully!'),
//                 const SizedBox(height: 8),
//                 const Text('Would you like to send notifications to the customer?'),
//                 const SizedBox(height: 20),
                
//                 if (customerMobile.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.message_outlined,
//                     color: Colors.green,
//                     title: 'Send WhatsApp',
//                     subtitle: 'To: $customerMobile',
//                     onTap: () {
//                       Navigator.pop(context);
//                       sendOrderWhatsAppNotification(
//                         context: context,
//                         orderId: orderResponse['id'].toString(),
//                         order: orderResponse,
//                       );
//                     },
//                   ),
                
//                 if (customerEmail != null && customerEmail.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.email,
//                     color: Colors.blue,
//                     title: 'Send Email',
//                     subtitle: 'To: $customerEmail',
//                     onTap: () {
//                       Navigator.pop(context);
//                       sendOrderEmailNotification(
//                         context: context,
//                         orderId: orderResponse['id'].toString(),
//                         order: orderResponse,
//                       );
//                     },
//                   ),
                
//                 const SizedBox(height: 16),
//                 Text(
//                   '💡 Tip: You can send notifications later from the order details screen.',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Skip'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ========================
//   // BUILD NOTIFICATION OPTION WIDGET
//   // ========================
//   Widget _buildNotificationOption({
//     required IconData icon,
//     required Color color,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         child: ListTile(
//           leading: Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: color),
//           ),
//           title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//           subtitle: Text(subtitle),
//           trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//           onTap: onTap,
//         ),
//       ),
//     );
//   }

//   // ========================
//   // WHATSAPP NOTIFICATION METHODS - FIXED FOR MOBILE
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
//         final fetchedOrder = await fetchSingleOrder(orderId);
//         if (fetchedOrder == null) {
//           throw Exception('Order not found');
//         }
//         orderData = fetchedOrder;
//       }
      
//       if (orderData.isEmpty) {
//         throw Exception('Order data is empty');
//       }

//       // DEBUG: Check what's in the order data
//       debugOrderData(orderData);
      
//       final phoneNumber = orderData['customer_mobile']?.toString() ?? '';
//       print('📱 Customer mobile: $phoneNumber');
      
//       if (phoneNumber.isEmpty) {
//         throw Exception('No mobile number available');
//       }

//       // Generate message
//       final message = _generateWhatsAppMessage(orderData, 'confirmation');
//       print('💬 Generated message length: ${message.length}');
//       print('📄 Generated message preview: ${message.substring(0, message.length > 100 ? 100 : message.length)}...');

//       // Send via WhatsApp with mobile-optimized method
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
//         .eq('id', orderId);

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
    
//     // Method 1: WhatsApp intent for Android (most reliable for pre-filled messages)
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
    
//     // Method 2: Traditional URL schemes (try multiple)
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
//     // DEBUG: Print what's in the order
//     print('🛠️ DEBUG: Generating WhatsApp message from order data');
//     print('Order keys: ${order.keys.toList()}');
//     print('order_number field: ${order['order_number']}');
//     print('order_number type: ${order['order_number']?.runtimeType}');
    
//     // Get order number - handle database NULL value
//     String orderNumber;
//     final orderNumValue = order['order_number'];
    
//     if (orderNumValue == null) {
//       print('⚠️ order_number is NULL in database');
      
//       // Try to use id as fallback
//       if (order['id'] != null) {
//         final idStr = order['id'].toString();
//         if (idStr.length >= 8) {
//           orderNumber = 'ORD${idStr.substring(0, 8).toUpperCase()}';
//         } else {
//           orderNumber = 'ORD${idStr.toUpperCase()}';
//         }
//         print('🔄 Using ID as fallback: $orderNumber');
//       } else {
//         orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}';
//         print('🔄 Using timestamp as fallback: $orderNumber');
//       }
//     } else {
//       // Convert to string and check if empty
//       final orderNumStr = orderNumValue.toString();
//       if (orderNumStr.isEmpty) {
//         orderNumber = 'N/A';
//         print('⚠️ order_number is empty string');
//       } else {
//         orderNumber = orderNumStr;
//         print('✅ Using database order_number: $orderNumber');
//       }
//     }
    
//     // Get other fields with null safety
//     final customerName = order['customer_name']?.toString() ?? 'Customer';
//     final product = order['feed_category']?.toString() ?? 'Cattle Feed';
//     final bags = order['bags']?.toString() ?? '1';
//     final amount = order['total_price']?.toString() ?? '0';
//     final weight = order['total_weight']?.toString() ?? '0';
//     final unit = order['weight_unit']?.toString() ?? 'kg';
//     final address = order['customer_address']?.toString() ?? '';
//     final district = order['district']?.toString() ?? '';
//     final trackingToken = order['tracking_token']?.toString() ?? '';
//     final trackingLink = trackingToken.isNotEmpty 
//         ? 'https://mega-pro.in/track/$trackingToken'
//         : '';

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

// ${trackingLink.isNotEmpty ? '🔗 *Track Order:*\n$trackingLink\n' : ''}
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
// ${trackingLink.isNotEmpty ? '🔗 *Track Order:*\n$trackingLink\n' : ''}
// _We appreciate your patience!_
//     ''';
      
//       return message;
//     }
    
//     return 'Order update for $orderNumber';
//   }

//   void debugOrderData(Map<String, dynamic> order) {
//     print('🔍 DEBUG ORDER DATA:');
//     print('Order keys: ${order.keys.toList()}');
    
//     if (order.containsKey('order_number')) {
//       final value = order['order_number'];
//       print('order_number exists: true');
//       print('order_number value: $value');
//       print('order_number type: ${value.runtimeType}');
//       print('order_number is null: ${value == null}');
//       print('order_number toString: ${value.toString()}');
//       print('order_number isEmpty: ${value.toString().isEmpty}');
//     } else {
//       print('order_number exists: false');
//     }
    
//     if (order.containsKey('id')) {
//       print('id: ${order['id']}');
//     }
//   }

//   Future<void> testDatabaseOrderNumber(String orderId) async {
//     try {
//       print('🔍 TEST: Checking database for order: $orderId');
      
//       // Direct database query to see what's really there
//       final response = await supabase
//         .from('emp_mar_orders')
//         .select('id, order_number, customer_name, created_at')
//         .eq('id', orderId)
//         .single();
      
//       print('📊 Database response:');
//       print('   ID: ${response['id']}');
//       print('   Order Number: ${response['order_number']}');
//       print('   Order Number Type: ${response['order_number']?.runtimeType}');
//       print('   Customer Name: ${response['customer_name']}');
//       print('   Created At: ${response['created_at']}');
      
//     } catch (e) {
//       print('❌ Test failed: $e');
//     }
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
//       Map<String, dynamic> orderData;
//       if (order != null) {
//         orderData = order;
//       } else {
//         final fetchedOrder = await fetchSingleOrder(orderId);
//         if (fetchedOrder == null) {
//           throw Exception('Order not found');
//         }
//         orderData = fetchedOrder;
//       }
      
//       if (orderData.isEmpty) {
//         throw Exception('Order data is empty');
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
//         final idStr = orderData['id'].toString();
//         orderNumber = 'ORD${idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : idStr.toUpperCase()}';
//       } else {
//         orderNumber = 'N/A';
//       }
      
//       final customerName = orderData['customer_name']?.toString() ?? 'Customer';
//       final product = orderData['feed_category']?.toString() ?? 'Cattle Feed';
//       final bags = orderData['bags']?.toString() ?? '1';
//       final amount = orderData['total_price']?.toString() ?? '0';
//       final weight = orderData['total_weight']?.toString() ?? '0';
//       final unit = orderData['weight_unit']?.toString() ?? 'kg';
      
//       final trackingToken = orderData['tracking_token']?.toString() ?? '';
//       final trackingLink = trackingToken.isNotEmpty 
//           ? 'https://mega-pro.in/track/$trackingToken'
//           : '';

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

// ${trackingLink.isNotEmpty ? '🔗 Track Your Order:\n$trackingLink\n' : ''}

// Thank you for choosing Mega Pro Cattle Feed!

// Best regards,
// Mega Pro Cattle Feed Team
// 📞 +91 98765 43210
//     ''';

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
          
//           // Update database
//           await supabase
//             .from('emp_mar_orders')
//             .update({
//               'email_sent': true,
//               'notification_sent': true,
//               'last_notification_sent_at': DateTime.now().toUtc().toIso8601String(),
//               'updated_at': DateTime.now().toUtc().toIso8601String(),
//             })
//             .eq('id', orderId);

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

//   // Add this method to OrderProvider
//   String generateTrackingLink(String trackingId, String? trackingToken) {
//     final baseUrl = 'https://phkkiyxfcepqauxncqpm.supabase.co/storage/v1/object/public/tracking/index.html';
    
//     if (trackingToken != null && trackingToken.isNotEmpty) {
//       return '$baseUrl?id=$trackingId&token=$trackingToken';
//     } else {
//       return '$baseUrl?id=$trackingId';
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

//   void _showSuccessSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showInfoSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.blue,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // ========================
//   // EXISTING METHODS
//   // ========================
//   Future<void> quickLoad() async {
//     if (_initialLoadComplete && orders.isNotEmpty) return;

//     try {
//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: 10,
//         employeeId: user.id,
//       );

//       orders = data.map((order) {
//         return {...order, 'display_id': _getDisplayOrderId(order)};
//       }).toList();

//       _updateCountsFromOrders();
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

//   Future<void> fetchOrders({bool loadMore = false, String? status}) async {
//     try {
//       if (!loadMore) {
//         _page = 0;
//         _hasMoreData = true;
//         orders.clear();
//       }

//       if (!_hasMoreData && loadMore) return;

//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: _limit,
//         offset: _page * _limit,
//         status: status,
//         employeeId: user.id,
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
//       _updateCountsFromOrders();
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

//   // ========================
//   // FETCH ORDER COUNTS
//   // ========================
//   Future<void> fetchOrderCounts() async {
//     try {
//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         totalOrders = 0;
//         pendingOrders = 0;
//         packingOrders = 0;
//         readyForDispatchOrders = 0;
//         dispatchedOrders = 0;
//         deliveredOrders = 0;
//         completedOrders = 0;
//         cancelledOrders = 0;
//         notifyListeners();
//         return;
//       }

//       // Fetch all orders for this employee
//       final response = await supabase
//           .from('emp_mar_orders')
//           .select('status')
//           .eq('employee_id', user.id);

//       // Reset counts
//       totalOrders = response.length;
//       pendingOrders = response.where((e) => e['status'] == 'pending').length;
//       packingOrders = response.where((e) => e['status'] == 'packing').length;
//       readyForDispatchOrders = response.where((e) => e['status'] == 'ready_for_dispatch').length;
//       dispatchedOrders = response.where((e) => e['status'] == 'dispatched').length;
//       deliveredOrders = response.where((e) => e['status'] == 'delivered').length;
//       completedOrders = response.where((e) => e['status'] == 'completed').length;
//       cancelledOrders = response.where((e) => e['status'] == 'cancelled').length;

//       error = null;
//       print('📊 Order counts fetched - Total: $totalOrders, Completed: $completedOrders');
      
//     } catch (e) {
//       error = 'Failed to fetch order counts: $e';
//       debugPrint("❌ Fetch order counts failed: $e");
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
//       // Use OrderService to fetch single order
//       final response = await _orderService.getOrder(orderId);
//       return response != null
//           ? {...response, 'display_id': _getDisplayOrderId(response)}
//           : null;
//     } catch (e) {
//       debugPrint("❌ Fetch single order failed: $e");
//       return null;
//     }
//   }

//   Future<void> updateOrderStatus(String orderId, String newStatus, {String? notes}) async {
//     try {
//       loading = true;
//       notifyListeners();

//       // Use OrderService to update status
//       await _orderService.updateOrderStatus(
//         orderId, 
//         newStatus, 
//         notes: notes,
//         sendNotification: false,
//       );

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
//       loading = true;
//       notifyListeners();

//       await _orderService.deleteOrder(orderId);

//       orders.removeWhere((order) => order['id'] == orderId);
//       _updateCountsFromOrders();

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

//   void _updateCountsFromOrders() {
//     totalOrders = orders.length;
//     pendingOrders = orders.where((e) => e['status'] == 'pending').length;
//     packingOrders = orders.where((e) => e['status'] == 'packing').length;
//     readyForDispatchOrders = orders
//         .where((e) => e['status'] == 'ready_for_dispatch')
//         .length;
//     dispatchedOrders = orders.where((e) => e['status'] == 'dispatched').length;
//     deliveredOrders = orders.where((e) => e['status'] == 'delivered').length;
//     completedOrders = orders.where((e) => e['status'] == 'completed').length;
//     cancelledOrders = orders.where((e) => e['status'] == 'cancelled').length;
//   }

//   // ========================
//   // GETTERS
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
//       return orders.firstWhere((order) => order['id'] == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   bool get hasMoreData => _hasMoreData;
//   bool get sendingNotification => _sendingNotification;
//   String? get notificationError => _notificationError;

//   Future<void> refresh() async {
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     await quickLoad();
//   }

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
//     return orders.any((order) => order['id'] == orderId);
//   }

//   List<Map<String, dynamic>> getOrdersByDateRange(
//     DateTime startDate,
//     DateTime endDate,
//   ) {
//     return orders.where((order) {
//       if (order['created_at'] == null) return false;

//       final createdAt = DateTime.parse(order['created_at']);
//       return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
//           createdAt.isBefore(endDate.add(const Duration(days: 1)));
//     }).toList();
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
//   // ========================
// // GET MONTHLY ORDERS BY STATUS
// // ========================
// Future<List<int>> getMonthlyOrdersByStatus(int year, String status, {String? employeeId}) async {
//   try {
//     final user = supabase.auth.currentUser;
//     if (user == null) return List.filled(12, 0);

//     // Use provided employeeId or get from current user
//     final empId = employeeId ?? user.id;

//     // Fetch orders with specified status for the year
//     final response = await supabase
//         .from('emp_mar_orders')
//         .select('created_at')
//         .eq('employee_id', empId)
//         .eq('status', status)
//         .gte('created_at', DateTime(year, 1, 1).toIso8601String())
//         .lt('created_at', DateTime(year + 1, 1, 1).toIso8601String());

//     // Initialize list with 12 zeros
//     List<int> monthlyCounts = List.filled(12, 0);

//     // Count orders per month
//     for (var order in response) {
//       if (order['created_at'] != null) {
//         final createdAt = DateTime.parse(order['created_at']);
//         final month = createdAt.month - 1;
//         monthlyCounts[month]++;
//       }
//     }

//     print('📊 Monthly $status orders for $year: $monthlyCounts');
//     return monthlyCounts;

//   } catch (e) {
//     debugPrint('❌ Error getting monthly $status orders: $e');
//     return List.filled(12, 0);
//   }
// }

// // ========================
// // GET MONTHLY COMPLETED ORDERS
// // ========================
// // Simplified version - always uses current user
// Future<List<int>> getMonthlyCompletedOrders(int year) async {
//   try {
//     final user = supabase.auth.currentUser;
//     if (user == null) return List.filled(12, 0);

//     // Always use current user's ID
//     final empId = user.id;

//     // Fetch completed orders for the specified year
//     final response = await supabase
//         .from('emp_mar_orders')
//         .select('created_at')
//         .eq('employee_id', empId)
//         .eq('status', 'completed')
//         .gte('created_at', DateTime(year, 1, 1).toIso8601String())
//         .lt('created_at', DateTime(year + 1, 1, 1).toIso8601String());

//     // Initialize list with 12 zeros
//     List<int> monthlyCompleted = List.filled(12, 0);

//     // Count completed orders per month
//     for (var order in response) {
//       if (order['created_at'] != null) {
//         final createdAt = DateTime.parse(order['created_at']);
//         final month = createdAt.month - 1;
//         monthlyCompleted[month]++;
//       }
//     }

//     return monthlyCompleted;
//   } catch (e) {
//     debugPrint('❌ Error getting monthly completed orders: $e');
//     return List.filled(12, 0);
//   }
// }
// }











// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import '../services/order_service.dart';

// class OrderProvider with ChangeNotifier {
//   final SupabaseClient supabase = Supabase.instance.client;
//   late OrderService _orderService;
  
//   bool loading = false;
//   String? error;
//   String filter = 'all'; // Add filter property

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
//   int _limit = 20;
//   bool _initialLoadComplete = false;

//   // Notification state
//   bool _sendingNotification = false;
//   String? _notificationError;

//   OrderProvider() {
//     _orderService = OrderService(supabase);
//   }

//   // ========================
//   // CREATE ORDER WITH NOTIFICATIONS
//   // ========================
//   Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data, BuildContext context) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       final int bags = data['bags'] as int;
//       final int weightPerBag = data['weight_per_bag'] as int;
//       final int pricePerBag = data['price_per_bag'] as int;

//       final int totalWeight = bags * weightPerBag;
//       final int totalPrice = bags * pricePerBag;

//       print('📝 Creating new order with data:');
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
//       print('📊 Order details: ${orderResponse['order_number']} - ${orderResponse['tracking_token']}');

//       // Show notification options dialog if customer has contact info
//       final hasMobile = (data['customer_mobile'] as String).isNotEmpty;
//       final hasEmail = data['customer_email'] != null && (data['customer_email'] as String).isNotEmpty;
      
//       if (hasMobile || hasEmail) {
//         await _showNotificationOptionsDialog(
//           context: context,
//           orderResponse: orderResponse,
//           customerMobile: data['customer_mobile'] as String,
//           customerEmail: data['customer_email'] as String?,
//         );
//       }

//       await quickLoad();
      
//       return orderResponse;

//     } catch (e) {
//       debugPrint("❌ Order insert failed: $e");
//       _showErrorSnackbar(context, "Failed to create order: ${e.toString()}");
//       rethrow;
//     }
//   }

//   // ========================
//   // SHOW NOTIFICATION OPTIONS DIALOG
//   // ========================
//   Future<void> _showNotificationOptionsDialog({
//     required BuildContext context,
//     required Map<String, dynamic> orderResponse,
//     required String customerMobile,
//     required String? customerEmail,
//   }) async {
//     final orderNumber = orderResponse['order_number']?.toString() ?? 
//         'ORD${DateTime.now().millisecondsSinceEpoch}';
//     final trackingToken = orderResponse['tracking_token']?.toString() ?? '';
//     final trackingLink = _orderService.getTrackingUrl(trackingToken);

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Send Notifications'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Order #$orderNumber created successfully!'),
//                 const SizedBox(height: 8),
//                 const Text('Would you like to send notifications to the customer?'),
//                 const SizedBox(height: 20),
                
//                 if (customerMobile.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.message_outlined,
//                     color: Colors.green,
//                     title: 'Send WhatsApp',
//                     subtitle: 'To: $customerMobile',
//                     onTap: () {
//                       Navigator.pop(context);
//                       sendOrderWhatsAppNotification(
//                         context: context,
//                         orderId: orderResponse['id'].toString(),
//                         order: orderResponse,
//                       );
//                     },
//                   ),
                
//                 if (customerEmail != null && customerEmail.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.email,
//                     color: Colors.blue,
//                     title: 'Send Email',
//                     subtitle: 'To: $customerEmail',
//                     onTap: () {
//                       Navigator.pop(context);
//                       sendOrderEmailNotification(
//                         context: context,
//                         orderId: orderResponse['id'].toString(),
//                         order: orderResponse,
//                       );
//                     },
//                   ),
                
//                 const SizedBox(height: 16),
//                 Text(
//                   '💡 Tip: You can send notifications later from the order details screen.',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Skip'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ========================
//   // BUILD NOTIFICATION OPTION WIDGET
//   // ========================
//   Widget _buildNotificationOption({
//     required IconData icon,
//     required Color color,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         child: ListTile(
//           leading: Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: color),
//           ),
//           title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//           subtitle: Text(subtitle),
//           trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//           onTap: onTap,
//         ),
//       ),
//     );
//   }

//   // ========================
//   // WHATSAPP NOTIFICATION METHODS - FIXED FOR MOBILE
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
//         final fetchedOrder = await fetchSingleOrder(orderId);
//         if (fetchedOrder == null) {
//           throw Exception('Order not found');
//         }
//         orderData = fetchedOrder;
//       }
      
//       if (orderData.isEmpty) {
//         throw Exception('Order data is empty');
//       }

//       // DEBUG: Check what's in the order data
//       debugOrderData(orderData);
      
//       final phoneNumber = orderData['customer_mobile']?.toString() ?? '';
//       print('📱 Customer mobile: $phoneNumber');
      
//       if (phoneNumber.isEmpty) {
//         throw Exception('No mobile number available');
//       }

//       // Generate message
//       final message = _generateWhatsAppMessage(orderData, 'confirmation');
//       print('💬 Generated message length: ${message.length}');
//       print('📄 Generated message preview: ${message.substring(0, message.length > 100 ? 100 : message.length)}...');

//       // Send via WhatsApp with mobile-optimized method
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
//         .eq('id', orderId);

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
    
//     // Method 1: WhatsApp intent for Android (most reliable for pre-filled messages)
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
    
//     // Method 2: Traditional URL schemes (try multiple)
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
//     // DEBUG: Print what's in the order
//     print('🛠️ DEBUG: Generating WhatsApp message from order data');
//     print('Order keys: ${order.keys.toList()}');
//     print('order_number field: ${order['order_number']}');
//     print('order_number type: ${order['order_number']?.runtimeType}');
    
//     // Get order number - handle database NULL value
//     String orderNumber;
//     final orderNumValue = order['order_number'];
    
//     if (orderNumValue == null) {
//       print('⚠️ order_number is NULL in database');
      
//       // Try to use id as fallback
//       if (order['id'] != null) {
//         final idStr = order['id'].toString();
//         if (idStr.length >= 8) {
//           orderNumber = 'ORD${idStr.substring(0, 8).toUpperCase()}';
//         } else {
//           orderNumber = 'ORD${idStr.toUpperCase()}';
//         }
//         print('🔄 Using ID as fallback: $orderNumber');
//       } else {
//         orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}';
//         print('🔄 Using timestamp as fallback: $orderNumber');
//       }
//     } else {
//       // Convert to string and check if empty
//       final orderNumStr = orderNumValue.toString();
//       if (orderNumStr.isEmpty) {
//         orderNumber = 'N/A';
//         print('⚠️ order_number is empty string');
//       } else {
//         orderNumber = orderNumStr;
//         print('✅ Using database order_number: $orderNumber');
//       }
//     }
    
//     // Get other fields with null safety
//     final customerName = order['customer_name']?.toString() ?? 'Customer';
//     final product = order['feed_category']?.toString() ?? 'Cattle Feed';
//     final bags = order['bags']?.toString() ?? '1';
//     final amount = order['total_price']?.toString() ?? '0';
//     final weight = order['total_weight']?.toString() ?? '0';
//     final unit = order['weight_unit']?.toString() ?? 'kg';
//     final address = order['customer_address']?.toString() ?? '';
//     final district = order['district']?.toString() ?? '';
//     final trackingToken = order['tracking_token']?.toString() ?? '';
//     final trackingLink = trackingToken.isNotEmpty 
//         ? 'https://mega-pro.in/track/$trackingToken'
//         : '';

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

// ${trackingLink.isNotEmpty ? '🔗 *Track Order:*\n$trackingLink\n' : ''}
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
// ${trackingLink.isNotEmpty ? '🔗 *Track Order:*\n$trackingLink\n' : ''}
// _We appreciate your patience!_
//     ''';
      
//       return message;
//     }
    
//     return 'Order update for $orderNumber';
//   }

//   void debugOrderData(Map<String, dynamic> order) {
//     print('🔍 DEBUG ORDER DATA:');
//     print('Order keys: ${order.keys.toList()}');
    
//     if (order.containsKey('order_number')) {
//       final value = order['order_number'];
//       print('order_number exists: true');
//       print('order_number value: $value');
//       print('order_number type: ${value.runtimeType}');
//       print('order_number is null: ${value == null}');
//       print('order_number toString: ${value.toString()}');
//       print('order_number isEmpty: ${value.toString().isEmpty}');
//     } else {
//       print('order_number exists: false');
//     }
    
//     if (order.containsKey('id')) {
//       print('id: ${order['id']}');
//     }
//   }

//   Future<void> testDatabaseOrderNumber(String orderId) async {
//     try {
//       print('🔍 TEST: Checking database for order: $orderId');
      
//       // Direct database query to see what's really there
//       final response = await supabase
//         .from('emp_mar_orders')
//         .select('id, order_number, customer_name, created_at')
//         .eq('id', orderId)
//         .single();
      
//       print('📊 Database response:');
//       print('   ID: ${response['id']}');
//       print('   Order Number: ${response['order_number']}');
//       print('   Order Number Type: ${response['order_number']?.runtimeType}');
//       print('   Customer Name: ${response['customer_name']}');
//       print('   Created At: ${response['created_at']}');
      
//     } catch (e) {
//       print('❌ Test failed: $e');
//     }
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
//       Map<String, dynamic> orderData;
//       if (order != null) {
//         orderData = order;
//       } else {
//         final fetchedOrder = await fetchSingleOrder(orderId);
//         if (fetchedOrder == null) {
//           throw Exception('Order not found');
//         }
//         orderData = fetchedOrder;
//       }
      
//       if (orderData.isEmpty) {
//         throw Exception('Order data is empty');
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
//         final idStr = orderData['id'].toString();
//         orderNumber = 'ORD${idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : idStr.toUpperCase()}';
//       } else {
//         orderNumber = 'N/A';
//       }
      
//       final customerName = orderData['customer_name']?.toString() ?? 'Customer';
//       final product = orderData['feed_category']?.toString() ?? 'Cattle Feed';
//       final bags = orderData['bags']?.toString() ?? '1';
//       final amount = orderData['total_price']?.toString() ?? '0';
//       final weight = orderData['total_weight']?.toString() ?? '0';
//       final unit = orderData['weight_unit']?.toString() ?? 'kg';
      
//       final trackingToken = orderData['tracking_token']?.toString() ?? '';
//       final trackingLink = trackingToken.isNotEmpty 
//           ? 'https://mega-pro.in/track/$trackingToken'
//           : '';

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

// ${trackingLink.isNotEmpty ? '🔗 Track Your Order:\n$trackingLink\n' : ''}

// Thank you for choosing Mega Pro Cattle Feed!

// Best regards,
// Mega Pro Cattle Feed Team
// 📞 +91 98765 43210
//     ''';

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
          
//           // Update database
//           await supabase
//             .from('emp_mar_orders')
//             .update({
//               'email_sent': true,
//               'notification_sent': true,
//               'last_notification_sent_at': DateTime.now().toUtc().toIso8601String(),
//               'updated_at': DateTime.now().toUtc().toIso8601String(),
//             })
//             .eq('id', orderId);

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

//   // Add this method to OrderProvider
//   String generateTrackingLink(String trackingId, String? trackingToken) {
//     final baseUrl = 'https://phkkiyxfcepqauxncqpm.supabase.co/storage/v1/object/public/tracking/index.html';
    
//     if (trackingToken != null && trackingToken.isNotEmpty) {
//       return '$baseUrl?id=$trackingId&token=$trackingToken';
//     } else {
//       return '$baseUrl?id=$trackingId';
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

//   void _showSuccessSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showInfoSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.blue,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // ========================
//   // EXISTING METHODS
//   // ========================
//   Future<void> quickLoad() async {
//     if (_initialLoadComplete && orders.isNotEmpty) return;

//     try {
//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: 10,
//         employeeId: user.id,
//       );

//       orders = data.map((order) {
//         return {...order, 'display_id': _getDisplayOrderId(order)};
//       }).toList();

//       _updateCountsFromOrders();
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

//   Future<void> fetchOrders({bool loadMore = false, String? status}) async {
//     try {
//       if (!loadMore) {
//         _page = 0;
//         _hasMoreData = true;
//         orders.clear();
//       }

//       if (!_hasMoreData && loadMore) return;

//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: _limit,
//         offset: _page * _limit,
//         status: status,
//         employeeId: user.id,
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
//       _updateCountsFromOrders();
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
//       // Use OrderService to fetch single order
//       final response = await _orderService.getOrder(orderId);
//       return response != null
//           ? {...response, 'display_id': _getDisplayOrderId(response)}
//           : null;
//     } catch (e) {
//       debugPrint("❌ Fetch single order failed: $e");
//       return null;
//     }
//   }

//   Future<void> updateOrderStatus(String orderId, String newStatus, {String? notes}) async {
//     try {
//       loading = true;
//       notifyListeners();

//       // Use OrderService to update status
//       await _orderService.updateOrderStatus(
//         orderId, 
//         newStatus, 
//         notes: notes,
//         sendNotification: false,
//       );

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
//       loading = true;
//       notifyListeners();

//       await _orderService.deleteOrder(orderId);

//       orders.removeWhere((order) => order['id'] == orderId);
//       _updateCountsFromOrders();

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

//   void _updateCountsFromOrders() {
//     totalOrders = orders.length;
//     pendingOrders = orders.where((e) => e['status'] == 'pending').length;
//     packingOrders = orders.where((e) => e['status'] == 'packing').length;
//     readyForDispatchOrders = orders
//         .where((e) => e['status'] == 'ready_for_dispatch')
//         .length;
//     dispatchedOrders = orders.where((e) => e['status'] == 'dispatched').length;
//     deliveredOrders = orders.where((e) => e['status'] == 'delivered').length;
//     completedOrders = orders.where((e) => e['status'] == 'completed').length;
//     cancelledOrders = orders.where((e) => e['status'] == 'cancelled').length;
//   }

//   // ========================
//   // GETTERS
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
//       return orders.firstWhere((order) => order['id'] == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   bool get hasMoreData => _hasMoreData;
//   bool get sendingNotification => _sendingNotification;
//   String? get notificationError => _notificationError;

//   Future<void> refresh() async {
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     await quickLoad();
//   }

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
//     return orders.any((order) => order['id'] == orderId);
//   }

//   List<Map<String, dynamic>> getOrdersByDateRange(
//     DateTime startDate,
//     DateTime endDate,
//   ) {
//     return orders.where((order) {
//       if (order['created_at'] == null) return false;

//       final createdAt = DateTime.parse(order['created_at']);
//       return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
//           createdAt.isBefore(endDate.add(const Duration(days: 1)));
//     }).toList();
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










//tracking link does not work

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import '../services/order_service.dart';

// class OrderProvider with ChangeNotifier {
//   final SupabaseClient supabase = Supabase.instance.client;
//   late OrderService _orderService;
  
//   bool loading = false;
//   String? error;

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
//   int _limit = 20;
//   bool _initialLoadComplete = false;

//   // Notification state
//   bool _sendingNotification = false;
//   String? _notificationError;

//   OrderProvider() {
//     _orderService = OrderService(supabase);
//   }

//   // ========================
//   // CREATE ORDER WITH NOTIFICATIONS
//   // ========================
//   Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data, BuildContext context) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       final int bags = data['bags'] as int;
//       final int weightPerBag = data['weight_per_bag'] as int;
//       final int pricePerBag = data['price_per_bag'] as int;

//       final int totalWeight = bags * weightPerBag;
//       final int totalPrice = bags * pricePerBag;

//       print('📝 Creating new order with data:');
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
//       print('📊 Order details: ${orderResponse['order_number']} - ${orderResponse['tracking_token']}');

//       // Show notification options dialog if customer has contact info
//       final hasMobile = (data['customer_mobile'] as String).isNotEmpty;
//       final hasEmail = data['customer_email'] != null && (data['customer_email'] as String).isNotEmpty;
      
//       if (hasMobile || hasEmail) {
//         await _showNotificationOptionsDialog(
//           context: context,
//           orderResponse: orderResponse,
//           customerMobile: data['customer_mobile'] as String,
//           customerEmail: data['customer_email'] as String?,
//         );
//       }

//       await quickLoad();
      
//       return orderResponse;

//     } catch (e) {
//       debugPrint("❌ Order insert failed: $e");
//       _showErrorSnackbar(context, "Failed to create order: ${e.toString()}");
//       rethrow;
//     }
//   }

//   // ========================
//   // SHOW NOTIFICATION OPTIONS DIALOG
//   // ========================
//   Future<void> _showNotificationOptionsDialog({
//     required BuildContext context,
//     required Map<String, dynamic> orderResponse,
//     required String customerMobile,
//     required String? customerEmail,
//   }) async {
//     final orderNumber = orderResponse['order_number']?.toString() ?? 
//         'ORD${DateTime.now().millisecondsSinceEpoch}';
//     final trackingToken = orderResponse['tracking_token']?.toString() ?? '';
//     final trackingLink = _orderService.getTrackingUrl(trackingToken);

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Send Notifications'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Order #$orderNumber created successfully!'),
//                 const SizedBox(height: 8),
//                 const Text('Would you like to send notifications to the customer?'),
//                 const SizedBox(height: 20),
                
//                 if (customerMobile.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.message_outlined,
//                     color: Colors.green,
//                     title: 'Send WhatsApp',
//                     subtitle: 'To: $customerMobile',
//                     onTap: () {
//                       Navigator.pop(context);
//                       sendOrderWhatsAppNotification(
//                         context: context,
//                         orderId: orderResponse['id'].toString(),
//                         order: orderResponse,
//                       );
//                     },
//                   ),
                
//                 if (customerEmail != null && customerEmail.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.email,
//                     color: Colors.blue,
//                     title: 'Send Email',
//                     subtitle: 'To: $customerEmail',
//                     onTap: () {
//                       Navigator.pop(context);
//                       sendOrderEmailNotification(
//                         context: context,
//                         orderId: orderResponse['id'].toString(),
//                         order: orderResponse,
//                       );
//                     },
//                   ),
                
//                 const SizedBox(height: 16),
//                 Text(
//                   '💡 Tip: You can send notifications later from the order details screen.',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Skip'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ========================
//   // BUILD NOTIFICATION OPTION WIDGET
//   // ========================
//   Widget _buildNotificationOption({
//     required IconData icon,
//     required Color color,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         child: ListTile(
//           leading: Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: color),
//           ),
//           title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//           subtitle: Text(subtitle),
//           trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//           onTap: onTap,
//         ),
//       ),
//     );
//   }

//   // ========================
//   // WHATSAPP NOTIFICATION METHODS - FIXED FOR MOBILE
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

//       // DEBUG: Check what's in the order data
//       debugOrderData(orderData);
      
//       final phoneNumber = orderData['customer_mobile']?.toString() ?? '';
//       print('📱 Customer mobile: $phoneNumber');
      
//       if (phoneNumber.isEmpty) {
//         throw Exception('No mobile number available');
//       }

//       // Generate message
//       final message = _generateWhatsAppMessage(orderData, 'confirmation');
//       print('💬 Generated message length: ${message.length}');
//       print('📄 Generated message preview: ${message.substring(0, 100)}...');

//       // Send via WhatsApp with mobile-optimized method
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
//         .eq('id', orderId);

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
//       print('Stack trace: ${e.toString()}');
      
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
    
//     // Method 1: WhatsApp intent for Android (most reliable for pre-filled messages)
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
    
//     // Method 2: Traditional URL schemes (try multiple)
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
//     // This is a helper method that would need context
//     // You can implement this as a snackbar or dialog in the UI layer
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
//     // DEBUG: Print what's in the order
//     print('🛠️ DEBUG: Generating WhatsApp message from order data');
//     print('Order keys: ${order.keys.toList()}');
//     print('order_number field: ${order['order_number']}');
//     print('order_number type: ${order['order_number']?.runtimeType}');
    
//     // Get order number - handle database NULL value
//     String orderNumber;
//     final orderNumValue = order['order_number'];
    
//     if (orderNumValue == null) {
//       print('⚠️ order_number is NULL in database');
      
//       // Try to use id as fallback
//       if (order['id'] != null) {
//         final idStr = order['id'].toString();
//         if (idStr.length >= 8) {
//           orderNumber = 'ORD${idStr.substring(0, 8).toUpperCase()}';
//         } else {
//           orderNumber = 'ORD${idStr.toUpperCase()}';
//         }
//         print('🔄 Using ID as fallback: $orderNumber');
//       } else {
//         orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}';
//         print('🔄 Using timestamp as fallback: $orderNumber');
//       }
//     } else {
//       // Convert to string and check if empty
//       final orderNumStr = orderNumValue.toString();
//       if (orderNumStr.isEmpty) {
//         orderNumber = 'N/A';
//         print('⚠️ order_number is empty string');
//       } else {
//         orderNumber = orderNumStr;
//         print('✅ Using database order_number: $orderNumber');
//       }
//     }
    
//     // Get other fields with null safety
//     final customerName = order['customer_name']?.toString() ?? 'Customer';
//     final product = order['feed_category']?.toString() ?? 'Cattle Feed';
//     final bags = order['bags']?.toString() ?? '1';
//     final amount = order['total_price']?.toString() ?? '0';
//     final weight = order['total_weight']?.toString() ?? '0';
//     final unit = order['weight_unit']?.toString() ?? 'kg';
//     final address = order['customer_address']?.toString() ?? '';
//     final district = order['district']?.toString() ?? '';
//     final trackingToken = order['tracking_token']?.toString() ?? '';
//     final trackingLink = trackingToken.isNotEmpty 
//         ? 'https://mega-pro.in/track/$trackingToken'
//         : '';

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

// ${trackingLink.isNotEmpty ? '🔗 *Track Order:*\n$trackingLink\n' : ''}
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
// ${trackingLink.isNotEmpty ? '🔗 *Track Order:*\n$trackingLink\n' : ''}
// _We appreciate your patience!_
//     ''';
      
//       return message;
//     }
    
//     return 'Order update for $orderNumber';
//   }

//   void debugOrderData(Map<String, dynamic> order) {
//     print('🔍 DEBUG ORDER DATA:');
//     print('Order keys: ${order.keys.toList()}');
    
//     if (order.containsKey('order_number')) {
//       final value = order['order_number'];
//       print('order_number exists: true');
//       print('order_number value: $value');
//       print('order_number type: ${value.runtimeType}');
//       print('order_number is null: ${value == null}');
//       print('order_number toString: ${value.toString()}');
//       print('order_number isEmpty: ${value.toString().isEmpty}');
//     } else {
//       print('order_number exists: false');
//     }
    
//     if (order.containsKey('id')) {
//       print('id: ${order['id']}');
//     }
//   }

//   Future<void> testDatabaseOrderNumber(String orderId) async {
//     try {
//       print('🔍 TEST: Checking database for order: $orderId');
      
//       // Direct database query to see what's really there
//       final response = await supabase
//         .from('emp_mar_orders')
//         .select('id, order_number, customer_name, created_at')
//         .eq('id', orderId)
//         .single();
      
//       print('📊 Database response:');
//       print('   ID: ${response['id']}');
//       print('   Order Number: ${response['order_number']}');
//       print('   Order Number Type: ${response['order_number']?.runtimeType}');
//       print('   Customer Name: ${response['customer_name']}');
//       print('   Created At: ${response['created_at']}');
      
//     } catch (e) {
//       print('❌ Test failed: $e');
//     }
//   }

//   // ========================
//   // EMAIL NOTIFICATION METHODS
//   // ========================
// Future<void> sendOrderEmailNotification({
//   required BuildContext context,
//   required String orderId,
//   Map<String, dynamic>? order,
// }) async {
//   try {
//     _sendingNotification = true;
//     _notificationError = null;
//     notifyListeners();

//     // Fetch order details if not provided
//     Map<String, dynamic> orderData = order ?? await fetchSingleOrder(orderId) ?? {};
//     if (orderData.isEmpty) {
//       throw Exception('Order not found');
//     }

//     final email = orderData['customer_email']?.toString() ?? '';
//     if (email.isEmpty) {
//       throw Exception('No email address available');
//     }

//     // Safely get order number
//     String orderNumber;
//     if (orderData['order_number'] != null && orderData['order_number'].toString().isNotEmpty) {
//       orderNumber = orderData['order_number'].toString();
//     } else if (orderData['id'] != null) {
//       orderNumber = 'ORD${orderData['id'].toString().substring(0, 8).toUpperCase()}';
//     } else {
//       orderNumber = 'N/A';
//     }
    
//     final customerName = orderData['customer_name']?.toString() ?? 'Customer';
//     final product = orderData['feed_category']?.toString() ?? 'Cattle Feed';
//     final bags = orderData['bags']?.toString() ?? '1';
//     final amount = orderData['total_price']?.toString() ?? '0';
//     final weight = orderData['total_weight']?.toString() ?? '0';
//     final unit = orderData['weight_unit']?.toString() ?? 'kg';
    
//     final trackingToken = orderData['tracking_token']?.toString() ?? '';
//     final trackingLink = trackingToken.isNotEmpty 
//         ? 'https://mega-pro.in/track/$trackingToken'
//         : '';

//     // Create email content
//     final emailContent = '''
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

// ${trackingLink.isNotEmpty ? '🔗 Track Your Order:\n$trackingLink\n' : ''}

// Thank you for choosing Mega Pro Cattle Feed!

// Best regards,
// Mega Pro Cattle Feed Team
// 📞 +91 98765 43210
//     ''';

//     // Show email template
//     final shouldSend = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Send Email'),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text('Send to: $email'),
//                 const SizedBox(height: 10),
//                 const Text('Email content:'),
//                 const SizedBox(height: 10),
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey.shade300),
//                   ),
//                   child: SingleChildScrollView(
//                     child: SelectableText(
//                       emailContent,
//                       style: const TextStyle(fontSize: 12),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.pop(context, true);
//               },
//               child: const Text('Open Email App'),
//             ),
//           ],
//         );
//       },
//     );

//     if (shouldSend == true) {
//       // FIX: Build the email URI differently - encode the body properly
//       final subject = 'Order Confirmed: $orderNumber';
      
//       // Create a proper mailto URL with encoded components
//       final mailtoUrl = 'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(emailContent)}';
      
//       final emailUri = Uri.parse(mailtoUrl);

//       // Try to launch email app
//       if (await canLaunchUrl(emailUri)) {
//         await launchUrl(
//           emailUri,
//           mode: LaunchMode.externalApplication,
//         );
        
//         // Update database
//         await supabase
//           .from('emp_mar_orders')
//           .update({
//             'email_sent': true,
//             'notification_sent': true,
//             'last_notification_sent_at': DateTime.now().toUtc().toIso8601String(),
//             'updated_at': DateTime.now().toUtc().toIso8601String(),
//           })
//           .eq('id', orderId);

//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Email app opened successfully'),
//               backgroundColor: Colors.green,
//               duration: Duration(seconds: 2),
//             ),
//           );
//         }
//       } else {
//         // Fallback: Copy to clipboard
//         await Clipboard.setData(ClipboardData(text: emailContent));
//         throw Exception('Could not open email app. Email content copied to clipboard.');
//       }
//     }

//   } catch (e) {
//     _notificationError = e.toString();
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//           backgroundColor: Colors.orange,
//           duration: const Duration(seconds: 5),
//         ),
//       );
//     }
//   } finally {
//     _sendingNotification = false;
//     notifyListeners();
//   }
// }
// // Add this method to OrderProvider
// String generateTrackingLink(String trackingId, String? trackingToken) {
//   final baseUrl = 'https://phkkiyxfcepqauxncqpm.supabase.co/storage/v1/object/public/tracking/index.html';
  
//   if (trackingToken != null && trackingToken.isNotEmpty) {
//     return '$baseUrl?id=$trackingId&token=$trackingToken';
//   } else {
//     return '$baseUrl?id=$trackingId';
//   }
// }
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

//   void _showSuccessSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showInfoSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.blue,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // ========================
//   // EXISTING METHODS
//   // ========================
//   Future<void> quickLoad() async {
//     if (_initialLoadComplete && orders.isNotEmpty) return;

//     try {
//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: 10,
//         employeeId: user.id,
//       );

//       orders = data.map((order) {
//         return {...order, 'display_id': _getDisplayOrderId(order)};
//       }).toList();

//       _updateCountsFromOrders();
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

//   Future<void> fetchOrders({bool loadMore = false, String? status}) async {
//     try {
//       if (!loadMore) {
//         _page = 0;
//         _hasMoreData = true;
//         orders.clear();
//       }

//       if (!_hasMoreData && loadMore) return;

//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: _limit,
//         offset: _page * _limit,
//         status: status,
//         employeeId: user.id,
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
//       _updateCountsFromOrders();
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
//       // Use OrderService to fetch single order
//       final response = await _orderService.getOrder(orderId);
//       return response != null
//           ? {...response, 'display_id': _getDisplayOrderId(response)}
//           : null;
//     } catch (e) {
//       debugPrint("❌ Fetch single order failed: $e");
//       return null;
//     }
//   }

//   Future<void> updateOrderStatus(String orderId, String newStatus, {String? notes}) async {
//     try {
//       loading = true;
//       notifyListeners();

//       // Use OrderService to update status
//       await _orderService.updateOrderStatus(
//         orderId, 
//         newStatus, 
//         notes: notes,
//         sendNotification: false,
//       );

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
//       loading = true;
//       notifyListeners();

//       await _orderService.deleteOrder(orderId);

//       orders.removeWhere((order) => order['id'] == orderId);
//       _updateCountsFromOrders();

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

//   void _updateCountsFromOrders() {
//     totalOrders = orders.length;
//     pendingOrders = orders.where((e) => e['status'] == 'pending').length;
//     packingOrders = orders.where((e) => e['status'] == 'packing').length;
//     readyForDispatchOrders = orders
//         .where((e) => e['status'] == 'ready_for_dispatch')
//         .length;
//     dispatchedOrders = orders.where((e) => e['status'] == 'dispatched').length;
//     deliveredOrders = orders.where((e) => e['status'] == 'delivered').length;
//     completedOrders = orders.where((e) => e['status'] == 'completed').length;
//     cancelledOrders = orders.where((e) => e['status'] == 'cancelled').length;
//   }

//   // ========================
//   // GETTERS
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
//       return orders.firstWhere((order) => order['id'] == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   bool get hasMoreData => _hasMoreData;
//   bool get sendingNotification => _sendingNotification;
//   String? get notificationError => _notificationError;

//   Future<void> refresh() async {
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     await quickLoad();
//   }

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
//     return orders.any((order) => order['id'] == orderId);
//   }

//   List<Map<String, dynamic>> getOrdersByDateRange(
//     DateTime startDate,
//     DateTime endDate,
//   ) {
//     return orders.where((order) {
//       if (order['created_at'] == null) return false;

//       final createdAt = DateTime.parse(order['created_at']);
//       return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
//           createdAt.isBefore(endDate.add(const Duration(days: 1)));
//     }).toList();
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



























// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import '../services/order_service.dart';

// class OrderProvider with ChangeNotifier {
//   final SupabaseClient supabase = Supabase.instance.client;
//   late OrderService _orderService;
  
//   bool loading = false;
//   String? error;

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
//   int _limit = 20;
//   bool _initialLoadComplete = false;

//   // Notification state
//   bool _sendingNotification = false;
//   String? _notificationError;

//   OrderProvider() {
//     _orderService = OrderService(supabase);
//   }

//   // ========================
//   // CREATE ORDER WITH NOTIFICATIONS (FIXED)
//   // ========================
//   Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data, BuildContext context) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       final int bags = data['bags'] as int;
//       final int weightPerBag = data['weight_per_bag'] as int;
//       final int pricePerBag = data['price_per_bag'] as int;

//       final int totalWeight = bags * weightPerBag;
//       final int totalPrice = bags * pricePerBag;

//       print('📝 Creating new order with data:');
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
//       print('📊 Order details: ${orderResponse['order_number']} - ${orderResponse['tracking_token']}');

//       // Send notifications (simplified - show dialog instead of auto-send)
//       if (data['customer_mobile'].isNotEmpty || 
//           (data['customer_email'] != null && (data['customer_email'] as String).isNotEmpty)) {
//         // Show notification options dialog
//         await _showNotificationOptionsDialog(
//           context: context,
//           orderResponse: orderResponse,
//           customerMobile: data['customer_mobile'] as String,
//           customerEmail: data['customer_email'] as String?,
//           orderData: data,
//         );
//       }

//       await quickLoad();
      
//       return orderResponse;

//     } catch (e) {
//       debugPrint("❌ Order insert failed: $e");
//       _showErrorSnackbar(context, "Failed to create order: ${e.toString()}");
//       rethrow;
//     }
//   }

//   // ========================
//   // SHOW NOTIFICATION OPTIONS DIALOG (FIXED)
//   // ========================
//   Future<void> _showNotificationOptionsDialog({
//     required BuildContext context,
//     required Map<String, dynamic> orderResponse,
//     required String customerMobile,
//     required String? customerEmail,
//     required Map<String, dynamic> orderData,
//   }) async {
//     final orderNumber = orderResponse['order_number']?.toString() ?? 
//         'ORD${DateTime.now().millisecondsSinceEpoch}';
//     final trackingToken = orderResponse['tracking_token']?.toString() ?? '';
//     final trackingLink = _orderService.getTrackingUrl(trackingToken);

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Send Notifications'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Order #$orderNumber created successfully!'),
//                 const SizedBox(height: 8),
//                 const Text('Would you like to send notifications to the customer?'),
//                 const SizedBox(height: 20),
                
//                 if (customerMobile.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.message_outlined,
//                     color: Colors.green,
//                     title: 'Send WhatsApp',
//                     subtitle: 'To: $customerMobile',
//                     onTap: () {
//                       Navigator.pop(context);
//                       sendWhatsAppNotification(
//                         mobile: customerMobile,
//                         order: orderResponse,
//                         trackingLink: trackingLink,
//                         context: context,
//                         orderId: orderResponse['id']?.toString() ?? '', phoneNumber: '',
//                       );
//                     },
//                   ),
                
//                 if (customerEmail != null && customerEmail.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.email,
//                     color: Colors.blue,
//                     title: 'Send Email',
//                     subtitle: 'To: $customerEmail',
//                     onTap: () {
//                       Navigator.pop(context);
//                       _sendEmailManually(
//                         email: customerEmail,
//                         order: orderResponse,
//                         trackingLink: trackingLink,
//                         context: context,
//                         orderId: orderResponse['id']?.toString() ?? '',
//                       );
//                     },
//                   ),
                
//                 const SizedBox(height: 16),
//                 Text(
//                   '💡 Tip: You can send notifications later from the order details screen.',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Skip'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ========================
//   // BUILD NOTIFICATION OPTION WIDGET (FIXED)
//   // ========================
//   Widget _buildNotificationOption({
//     required IconData icon,
//     required Color color,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         child: ListTile(
//           leading: Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: color),
//           ),
//           title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//           subtitle: Text(subtitle),
//           trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//           onTap: onTap,
//         ),
//       ),
//     );
//   }

//   // ========================
//   // MANUAL WHATSAPP SENDING (FIXED)
//   // ========================
//  Future<void> sendWhatsAppNotification({
//   required BuildContext context,
//   required String orderId,
//   required String phoneNumber,
//   required Map<String, dynamic> order,
//   String messageType = 'confirmation', required String mobile, required String trackingLink,
// }) async {
//   try {
//     // Clean phone number
//     String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
//     // Remove country code if present and add +91
//     if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
//       cleanPhone = cleanPhone.substring(2);
//     } else if (cleanPhone.startsWith('+91')) {
//       cleanPhone = cleanPhone.substring(3);
//     }
    
//     // Ensure it's 10 digits
//     if (cleanPhone.length != 10) {
//       throw Exception('Invalid Indian mobile number: $phoneNumber');
//     }

//     final orderNumber = order['order_number']?.toString() ?? 
//         'ORD${order['id']?.toString().substring(0, 8).toUpperCase() ?? DateTime.now().millisecondsSinceEpoch}';
    
//     final customerName = order['customer_name']?.toString() ?? 'Customer';
//     final product = order['feed_category']?.toString() ?? 'Cattle Feed';
//     final bags = order['bags']?.toString() ?? '1';
//     final amount = order['total_price']?.toString() ?? '0';
//     final weight = order['total_weight']?.toString() ?? '0';
//     final unit = order['weight_unit']?.toString() ?? 'kg';
    
//     final trackingToken = order['tracking_token']?.toString() ?? '';
//     String trackingLink = '';
    
//     if (trackingToken.isNotEmpty) {
//       // For web app:
//       trackingLink = 'https://mega-pro.in/track/$trackingToken';
//       // OR for Flutter app with deep linking:
//       // trackingLink = 'megapro://track/$trackingToken';
//     }

//     // Generate different messages based on type
//     String message = '';
    
//     if (messageType == 'confirmation') {
//       message = '''
// 🛒 *ORDER CONFIRMED!*

// Order #: $orderNumber
// Customer: $customerName
// Product: $product
// Quantity: $bags bags
// Total Weight: $weight $unit
// Amount: ₹$amount
// Status: ✅ Processing

// Your order is being processed. We'll notify you at each stage.

// ${trackingLink.isNotEmpty ? '🔗 Track Order: $trackingLink\n' : ''}
// 📞 Need help? Call: +91 98765 43210

// Thank you for choosing Mega Pro Cattle Feed!
//       ''';
//     } else if (messageType == 'status_update') {
//       final status = order['status']?.toString().toUpperCase() ?? 'PROCESSING';
      
//       final statusMessages = {
//         'PENDING': '📋 Order received and being processed',
//         'PACKING': '📦 Your order is being packed',
//         'READY_FOR_DISPATCH': '🚚 Order packed, ready for dispatch',
//         'DISPATCHED': '📤 Order dispatched! On the way',
//         'DELIVERED': '✅ Order delivered successfully',
//         'COMPLETED': '🎉 Order completed! Thank you',
//         'CANCELLED': '❌ Order has been cancelled',
//       };
      
//       final statusMessage = statusMessages[status] ?? 'Order status updated';
      
//       message = '''
// 📦 *ORDER UPDATE*

// Order #: $orderNumber
// Status: $status
// $statusMessage

// ${trackingLink.isNotEmpty ? '🔗 Track here: $trackingLink\n' : ''}
// We appreciate your patience!
//       ''';
//     }

//     // Encode the message for URL
//     final encodedMessage = Uri.encodeComponent(message);
    
//     // Create WhatsApp URL (without country code in URL)
//     final whatsappUrl = 'https://wa.me/91$cleanPhone?text=$encodedMessage';
    
//     // Show confirmation dialog
//     final shouldSend = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Send WhatsApp Message'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Send to: $phoneNumber'),
//             const SizedBox(height: 10),
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 message,
//                 style: const TextStyle(fontSize: 12),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Open WhatsApp'),
//           ),
//         ],
//       ),
//     );

//     if (shouldSend == true) {
//       if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
//         await launchUrl(Uri.parse(whatsappUrl));
        
//         // Update database
//         await supabase
//           .from('emp_mar_orders')
//           .update({
//             'whatsapp_sent': true,
//             'notification_sent': true,
//             'updated_at': DateTime.now().toUtc().toIso8601String(),
//           })
//           .eq('id', orderId);
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('WhatsApp opened with message'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         // Fallback: Copy message to clipboard
//         await Clipboard.setData(ClipboardData(text: message));
        
//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Message Copied'),
//             content: const Text('WhatsApp could not be opened. Message copied to clipboard. You can manually send it.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//         );
//       }
//     }
    
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Error: ${e.toString()}'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }

//   // ========================
//   // MANUAL EMAIL SENDING (FIXED)
//   // ========================
//   Future<void> _sendEmailManually({
//     required String email,
//     required Map<String, dynamic> order,
//     required String trackingLink,
//     required BuildContext context,
//     required String orderId,
//   }) async {
//     try {
//       final orderNumber = order['order_number']?.toString() ?? 'N/A';
//       final customerName = order['customer_name']?.toString() ?? 'Customer';
//       final product = order['feed_category']?.toString() ?? 'N/A';
//       final bags = order['bags']?.toString() ?? '0';
//       final amount = order['total_price']?.toString() ?? '0';
//       final weight = order['total_weight']?.toString() ?? '0';
//       final unit = order['weight_unit']?.toString() ?? 'kg';

//       // Create email content
//       final emailContent = '''
// To: $email
// Subject: Order Confirmed: $orderNumber

// Dear $customerName,

// Your cattle feed order has been confirmed!

// Order Details:
// - Order Number: $orderNumber
// - Product: $product
// - Quantity: $bags bags
// - Total Weight: $weight $unit
// - Total Amount: ₹$amount
// - Delivery Address: ${order['customer_address']}
// - District: ${order['district']}

// Track Your Order: $trackingLink

// Status: Processing
// Expected Delivery: 3-5 business days

// Thank you for your order!

// Best regards,
// Cattle Feed Management Team
//       ''';

//       // Show email template
//       await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text('Email Template'),
//             content: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Copy the content below and send to: $email'),
//                   const SizedBox(height: 16),
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: SelectableText(
//                       emailContent,
//                       style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final emailUri = Uri(
//                         scheme: 'mailto',
//                         path: email,
//                         queryParameters: {
//                           'subject': 'Order Confirmed: $orderNumber',
//                           'body': emailContent,
//                         },
//                       );
                      
//                       if (await canLaunchUrl(emailUri)) {
//                         await launchUrl(emailUri);
//                       }
//                       Navigator.pop(context);
//                     },
//                     child: const Text('Open Email App'),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Close'),
//               ),
//             ],
//           );
//         },
//       );

//       // Update database
//       await supabase
//         .from('emp_mar_orders')
//         .update({
//           'email_sent': true,
//           'notification_sent': true,
//           'updated_at': DateTime.now().toUtc().toIso8601String(),
//         })
//         .eq('id', orderId);

//     } catch (e) {
//       _showErrorSnackbar(context, "Failed to prepare email: ${e.toString()}");
//     }
//   }

//   // ========================
//   // SEND STATUS UPDATE NOTIFICATION (FIXED)
//   // ========================
//   Future<void> sendStatusUpdateNotification({
//     required String orderId,
//     required String newStatus,
//     required BuildContext context,
//     String? notes,
//   }) async {
//     try {
//       // Fetch order details
//       final order = await fetchSingleOrder(orderId);
//       if (order == null) {
//         throw Exception('Order not found');
//       }

//       final customerMobile = order['customer_mobile']?.toString() ?? '';
//       final customerEmail = order['customer_email']?.toString() ?? '';
//       final orderNumber = order['order_number']?.toString() ?? 'N/A';
//       final trackingToken = order['tracking_token']?.toString() ?? '';
//       final trackingLink = _orderService.getTrackingUrl(trackingToken);

//       if (customerMobile.isEmpty && customerEmail.isEmpty) {
//         _showInfoSnackbar(context, 'No contact information available for notifications');
//         return;
//       }

//       // Show notification options
//       await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text('Send Status Update'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Status updated to: ${newStatus.toUpperCase()}'),
//                 const SizedBox(height: 12),
//                 const Text('Send notification to customer:'),
//                 const SizedBox(height: 16),
                
//                 if (customerMobile.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.medical_services_sharp,
//                     color: Colors.green,
//                     title: 'Send WhatsApp Update',
//                     subtitle: 'To: $customerMobile',
//                     onTap: () {
//                       Navigator.pop(context);
//                       _sendStatusWhatsApp(
//                         mobile: customerMobile,
//                         order: order,
//                         newStatus: newStatus,
//                         trackingLink: trackingLink,
//                         notes: notes,
//                         context: context,
//                       );
//                     },
//                   ),
                
//                 if (customerEmail.isNotEmpty)
//                   _buildNotificationOption(
//                     icon: Icons.email,
//                     color: Colors.blue,
//                     title: 'Send Email Update',
//                     subtitle: 'To: $customerEmail',
//                     onTap: () {
//                       Navigator.pop(context);
//                       _sendStatusEmail(
//                         email: customerEmail,
//                         order: order,
//                         newStatus: newStatus,
//                         trackingLink: trackingLink,
//                         notes: notes,
//                         context: context,
//                       );
//                     },
//                   ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Skip'),
//               ),
//             ],
//           );
//         },
//       );

//     } catch (e) {
//       print('❌ Error sending status notification: $e');
//       _showErrorSnackbar(context, "Failed to send notification");
//     }
//   }

//   // ========================
//   // SEND STATUS WHATSAPP
//   // ========================
//   Future<void> _sendStatusWhatsApp({
//     required String mobile,
//     required Map<String, dynamic> order,
//     required String newStatus,
//     required String trackingLink,
//     required BuildContext context,
//     String? notes,
//   }) async {
//     try {
//       String cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
//       if (cleanMobile.length != 10) {
//         throw Exception('Invalid mobile number');
//       }

//       final orderNumber = order['order_number']?.toString() ?? 'N/A';
//       final customerName = order['customer_name']?.toString() ?? 'Customer';
//       final product = order['feed_category']?.toString() ?? 'N/A';
//       final bags = order['bags']?.toString() ?? '0';
//       final amount = order['total_price']?.toString() ?? '0';

//       // Status messages
//       final statusMessages = {
//         'pending': 'Your order has been received and is being processed.',
//         'packing': 'Great news! Your order is now being packed.',
//         'ready_for_dispatch': 'Your order is packed and ready for dispatch.',
//         'dispatched': '🚚 Your order has been dispatched! On its way to you.',
//         'delivered': '✅ Your order has been delivered successfully.',
//         'completed': '🎉 Order completed! Thank you for your business.',
//         'cancelled': 'Your order has been cancelled as requested.',
//       };

//       final statusMessage = statusMessages[newStatus] ?? 'Your order status has been updated.';

//       // Create message
//       String message = '''
// 📦 *Order Update*

// Order #$orderNumber
// Customer: $customerName
// Product: $product
// Quantity: $bags bags
// Amount: ₹$amount

// Status: ${newStatus.toUpperCase()}
// $statusMessage
// ''';

//       if (notes != null && notes.isNotEmpty) {
//         message += '\n📝 Notes: $notes\n';
//       }

//       message += '\n🔗 Track Order: $trackingLink\n';
//       message += '\nThank you for choosing us!';

//       final whatsappUrl = 'https://wa.me/91$cleanMobile?text=${Uri.encodeComponent(message)}';
      
//       if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
//         await launchUrl(Uri.parse(whatsappUrl));
//         _showSuccessSnackbar(context, 'WhatsApp opened with status update');
//       }
//     } catch (e) {
//       _showErrorSnackbar(context, "Failed to open WhatsApp");
//     }
//   }

//   // ========================
//   // SEND STATUS EMAIL
//   // ========================
//   Future<void> _sendStatusEmail({
//     required String email,
//     required Map<String, dynamic> order,
//     required String newStatus,
//     required String trackingLink,
//     required BuildContext context,
//     String? notes,
//   }) async {
//     try {
//       final orderNumber = order['order_number']?.toString() ?? 'N/A';
//       final customerName = order['customer_name']?.toString() ?? 'Customer';

//       // Status messages
//       final statusMessages = {
//         'pending': 'Your order has been received and is being processed.',
//         'packing': 'Great news! Your order is now being packed.',
//         'ready_for_dispatch': 'Your order is packed and ready for dispatch.',
//         'dispatched': 'Your order has been dispatched and is on its way to you.',
//         'delivered': 'Your order has been delivered successfully.',
//         'completed': 'Order completed! Thank you for your business.',
//         'cancelled': 'Your order has been cancelled as requested.',
//       };

//       final statusMessage = statusMessages[newStatus] ?? 'Your order status has been updated.';

//       // Create email content
//       String emailContent = '''
// To: $email
// Subject: Order Status Update: $orderNumber

// Dear $customerName,

// Your order status has been updated.

// Order Number: $orderNumber
// New Status: ${newStatus.toUpperCase()}
// $statusMessage
// ''';

//       if (notes != null && notes.isNotEmpty) {
//         emailContent += '\nNotes: $notes\n';
//       }

//       emailContent += '\nTrack Your Order: $trackingLink\n';
//       emailContent += '\nBest regards,\nCattle Feed Management Team';

//       // Show email template
//       await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text('Email Template'),
//             content: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Copy the content below and send to: $email'),
//                   const SizedBox(height: 16),
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: SelectableText(
//                       emailContent,
//                       style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final emailUri = Uri(
//                         scheme: 'mailto',
//                         path: email,
//                         queryParameters: {
//                           'subject': 'Order Status Update: $orderNumber',
//                           'body': emailContent,
//                         },
//                       );
                      
//                       if (await canLaunchUrl(emailUri)) {
//                         await launchUrl(emailUri);
//                       }
//                       Navigator.pop(context);
//                     },
//                     child: const Text('Open Email App'),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Close'),
//               ),
//             ],
//           );
//         },
//       );

//     } catch (e) {
//       _showErrorSnackbar(context, "Failed to prepare email");
//     }
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

//   void _showSuccessSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showInfoSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.blue,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // ========================
//   // EXISTING METHODS (FIXED)
//   // ========================
//   Future<void> quickLoad() async {
//     if (_initialLoadComplete && orders.isNotEmpty) return;

//     try {
//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: 10,
//         employeeId: user.id,
//       );

//       orders = data.map((order) {
//         return {...order, 'display_id': _getDisplayOrderId(order)};
//       }).toList();

//       _updateCountsFromOrders();
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

//   Future<void> fetchOrders({bool loadMore = false, String? status}) async {
//     try {
//       if (!loadMore) {
//         _page = 0;
//         _hasMoreData = true;
//         orders.clear();
//       }

//       if (!_hasMoreData && loadMore) return;

//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Use OrderService to fetch orders
//       final data = await _orderService.getOrders(
//         limit: _limit,
//         offset: _page * _limit,
//         status: status,
//         employeeId: user.id,
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
//       _updateCountsFromOrders();
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
//       // Use OrderService to fetch single order
//       final response = await _orderService.getOrder(orderId);
//       return response != null
//           ? {...response, 'display_id': _getDisplayOrderId(response)}
//           : null;
//     } catch (e) {
//       debugPrint("❌ Fetch single order failed: $e");
//       return null;
//     }
//   }

//   Future<void> updateOrderStatus(String orderId, String newStatus, {String? notes}) async {
//     try {
//       loading = true;
//       notifyListeners();

//       // Use OrderService to update status
//       await _orderService.updateOrderStatus(
//         orderId, 
//         newStatus, 
//         notes: notes,
//         sendNotification: false, // We'll handle notification manually
//       );

//       // Send notification
//       await sendStatusUpdateNotification(
//         orderId: orderId,
//         newStatus: newStatus,
//         context: navigatorKey.currentContext!, // You'll need to set up a navigatorKey
//         notes: notes,
//       );

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
//       loading = true;
//       notifyListeners();

//       await _orderService.deleteOrder(orderId);

//       orders.removeWhere((order) => order['id'] == orderId);
//       _updateCountsFromOrders();

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

//   void _updateCountsFromOrders() {
//     totalOrders = orders.length;
//     pendingOrders = orders.where((e) => e['status'] == 'pending').length;
//     packingOrders = orders.where((e) => e['status'] == 'packing').length;
//     readyForDispatchOrders = orders
//         .where((e) => e['status'] == 'ready_for_dispatch')
//         .length;
//     dispatchedOrders = orders.where((e) => e['status'] == 'dispatched').length;
//     deliveredOrders = orders.where((e) => e['status'] == 'delivered').length;
//     completedOrders = orders.where((e) => e['status'] == 'completed').length;
//     cancelledOrders = orders.where((e) => e['status'] == 'cancelled').length;
//   }

//   // ========================
//   // GETTERS
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
//       return orders.firstWhere((order) => order['id'] == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   bool get hasMoreData => _hasMoreData;
//   bool get sendingNotification => _sendingNotification;
//   String? get notificationError => _notificationError;

//   Future<void> refresh() async {
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     await quickLoad();
//   }

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
//     return orders.any((order) => order['id'] == orderId);
//   }

//   List<Map<String, dynamic>> getOrdersByDateRange(
//     DateTime startDate,
//     DateTime endDate,
//   ) {
//     return orders.where((order) {
//       if (order['created_at'] == null) return false;

//       final createdAt = DateTime.parse(order['created_at']);
//       return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
//           createdAt.isBefore(endDate.add(const Duration(days: 1)));
//     }).toList();
//   }

//   // ========================
//   // RE-SEND NOTIFICATIONS (FIXED)
//   // ========================
//   Future<void> resendNotifications(
//     String orderId,
//     BuildContext context,
//   ) async {
//     try {
//       final order = await fetchSingleOrder(orderId);
//       if (order == null) {
//         throw Exception('Order not found');
//       }

//       final customerMobile = order['customer_mobile']?.toString() ?? '';
//       final customerEmail = order['customer_email']?.toString() ?? '';
//       final orderNumber = order['order_number']?.toString() ?? 'N/A';
//       final trackingToken = order['tracking_token']?.toString() ?? '';
//       final trackingLink = _orderService.getTrackingUrl(trackingToken);

//       if (customerMobile.isEmpty && customerEmail.isEmpty) {
//         throw Exception('No contact information available');
//       }

//       // Show notification options
//       await _showNotificationOptionsDialog(
//         context: context,
//         orderResponse: order,
//         customerMobile: customerMobile,
//         customerEmail: customerEmail,
//         orderData: order,
//       );

//     } catch (e) {
//       _showErrorSnackbar(context, "Failed to resend notifications: ${e.toString()}");
//     }
//   }
// }

// // Add this to your main.dart for navigation
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();







































// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class OrderProvider with ChangeNotifier {
//   final supabase = Supabase.instance.client;

//   bool loading = false;
//   String? error;

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
//   int _limit = 20;
//   bool _initialLoadComplete = false;

//   // ========================
//   // CREATE ORDER
//   // ========================
//   Future<void> createOrder(Map<String, dynamic> data) async {
//   try {
//     final user = supabase.auth.currentUser;
//     if (user == null) throw Exception("User not logged in");

//     final int bags = data['bags'];
//     final int weightPerBag = data['weight_per_bag'];
//     final int pricePerBag = data['price_per_bag'];

//     final int totalWeight = bags * weightPerBag;
//     final int totalPrice = bags * pricePerBag;

//     // Log order data before saving
//     print('📝 DEBUG: Creating new order with data:');
//     print('   👤 Employee ID: ${user.id}');
//     print('   👤 Customer Name: ${data['customer_name']}');
//     print('   📍 District: ${data['district']}');
//     print('   📦 Bags: $bags');
//     print('   💰 Total Price: $totalPrice');
//     print('   📍 Feed Category: ${data['feed_category']}');

//     await supabase.from('emp_mar_orders').insert({
//       'employee_id': user.id,
//       'customer_name': data['customer_name'],
//       'customer_mobile': data['customer_mobile'],
//       'customer_address': data['customer_address'],
//       'district': data['district'], // This should not be null
//       'feed_category': data['feed_category'],
//       'bags': bags,
//       'weight_per_bag': weightPerBag,
//       'weight_unit': data['weight_unit'],
//       'total_weight': totalWeight,
//       'price_per_bag': pricePerBag,
//       'total_price': totalPrice,
//       'remarks': data['remarks'],
//       'status': 'pending',
//     });

//     print('✅ DEBUG: Order saved successfully with district: ${data['district']}');
    
//     await quickLoad();
    
//   } catch (e) {
//     debugPrint("❌ Order insert failed: $e");
//     rethrow;
//   }
// }

//   // ========================
//   // QUICK LOAD (Optimized for initial display)
//   // ========================
//   Future<void> quickLoad() async {
//     if (_initialLoadComplete && orders.isNotEmpty) return;

//     try {
//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Load only essential fields for initial display
//       final data = await supabase
//           .from('emp_mar_orders')
//           .select(
//             'id, order_number, status, customer_name, total_price, created_at, bags, feed_category, district',
//           )
//           .eq('employee_id', user.id)
//           .order('created_at', ascending: false)
//           .limit(10);

//       orders = data.map((order) {
//         return {...order, 'display_id': _getDisplayOrderId(order)};
//       }).toList();

//       _updateCountsFromOrders();
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
//   // FETCH ORDERS WITH PAGINATION
//   // ========================
//   Future<void> fetchOrders({bool loadMore = false}) async {
//     try {
//       if (!loadMore) {
//         _page = 0;
//         _hasMoreData = true;
//         orders.clear();
//       }

//       if (!_hasMoreData && loadMore) return;

//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       final data = await supabase
//           .from('emp_mar_orders')
//           .select('*')
//           .eq('employee_id', user.id)
//           .order('created_at', ascending: false)
//           .range(_page * _limit, (_page + 1) * _limit - 1);

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
//       _updateCountsFromOrders();
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

//   // ========================
//   // LOAD MORE ORDERS
//   // ========================
//   Future<void> loadMore() async {
//     if (!_hasMoreData || loading) return;
//     await fetchOrders(loadMore: true);
//   }

//   // ========================
//   // FETCH SINGLE ORDER
//   // ========================
//   Future<Map<String, dynamic>?> fetchSingleOrder(String orderId) async {
//     try {
//       final response = await supabase
//           .from('emp_mar_orders')
//           .select('*')
//           .eq('id', orderId)
//           .single();

//       // ignore: unnecessary_null_comparison
//       return response != null
//           ? {...response, 'display_id': _getDisplayOrderId(response)}
//           : null;
//     } catch (e) {
//       debugPrint("❌ Fetch single order failed: $e");
//       return null;
//     }
//   }

//   // ========================
//   // UPDATE ORDER STATUS
//   // ========================
//   Future<void> updateOrderStatus(String orderId, String newStatus) async {
//     try {
//       loading = true;
//       notifyListeners();

//       await supabase
//           .from('emp_mar_orders')
//           .update({
//             'status': newStatus,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', orderId);

//       // Refresh orders
//       await quickLoad();
//     } catch (e) {
//       debugPrint("❌ Update order status failed: $e");
//       rethrow;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // DELETE ORDER
//   // ========================
//   Future<void> deleteOrder(String orderId) async {
//     try {
//       loading = true;
//       notifyListeners();

//       await supabase.from('emp_mar_orders').delete().eq('id', orderId);

//       // Remove from local list
//       orders.removeWhere((order) => order['id'] == orderId);

//       // Update counts
//       _updateCountsFromOrders();

//       notifyListeners();
//     } catch (e) {
//       debugPrint("❌ Delete order failed: $e");
//       rethrow;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // HELPER METHODS
//   // ========================
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

//   void _updateCountsFromOrders() {
//     totalOrders = orders.length;
//     pendingOrders = orders.where((e) => e['status'] == 'pending').length;
//     packingOrders = orders.where((e) => e['status'] == 'packing').length;
//     readyForDispatchOrders = orders
//         .where((e) => e['status'] == 'ready_for_dispatch')
//         .length;
//     dispatchedOrders = orders.where((e) => e['status'] == 'dispatched').length;
//     deliveredOrders = orders.where((e) => e['status'] == 'delivered').length;
//     completedOrders = orders.where((e) => e['status'] == 'completed').length;
//     cancelledOrders = orders.where((e) => e['status'] == 'cancelled').length;
//   }

//   // ========================
//   // GETTERS
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
//       return orders.firstWhere((order) => order['id'] == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   bool get hasMoreData => _hasMoreData;

//   // ========================
//   // REFRESH
//   // ========================
//   Future<void> refresh() async {
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     await quickLoad();
//   }

//   // ========================
//   // STATISTICS
//   // ========================
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
//     return orders.any((order) => order['id'] == orderId);
//   }

//   List<Map<String, dynamic>> getOrdersByDateRange(
//     DateTime startDate,
//     DateTime endDate,
//   ) {
//     return orders.where((order) {
//       if (order['created_at'] == null) return false;

//       final createdAt = DateTime.parse(order['created_at']);
//       return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
//           createdAt.isBefore(endDate.add(const Duration(days: 1)));
//     }).toList();
//   }
//   Future<void> sendOrderNotification(String orderId, String customerMobile, String customerEmail, BuildContext context) async {
//     try {
//       // Get order details
//       final orderResponse = await supabase
//           .from('emp_mar_orders')
//           .select()
//           .eq('id', orderId)
//           .single();
      
//       final orderNumber = orderResponse['order_number'] ?? 'N/A';
//       final trackingId = orderResponse['tracking_id'];
//       final trackingToken = orderResponse['tracking_token'];
      
//       // Create tracking link
//       final trackingLink = 'https://yourapp.com/track/$trackingId/$trackingToken';
      
//       // 1. Send WhatsApp notification
//       await _sendWhatsAppNotification(
//         mobile: customerMobile,
//         orderNumber: orderNumber,
//         trackingLink: trackingLink,
//       );
      
//       // 2. Send Email notification
//       if (customerEmail != null && customerEmail.isNotEmpty) {
//         await _sendEmailNotification(
//           email: customerEmail,
//           orderNumber: orderNumber,
//           trackingLink: trackingLink,
//           orderDetails: orderResponse,
//         );
//       }
      
//       // Update notification status
//       await supabase
//           .from('emp_mar_orders')
//           .update({
//             'notification_sent': true,
//             'whatsapp_sent': true,
//             'email_sent': customerEmail != null && customerEmail.isNotEmpty,
//           })
//           .eq('id', orderId);
      
//     } catch (e) {
//       print('Error sending notification: $e');
//     }
//   }
  
//   Future<void> _sendWhatsAppNotification({
//     required String mobile,
//     required String orderNumber,
//     required String trackingLink,
//   }) async {
//     try {
//       // Format mobile number (remove +91 if present)
//       String formattedMobile = mobile.replaceAll('+91', '');
      
//       // WhatsApp message template
//       final message = '''
// 🛒 *Order Confirmed!* 🛒

// Your cattle feed order has been placed successfully!

// 📋 *Order Details:*
// Order Number: $orderNumber
// Status: ✅ Confirmed
// Tracking: $trackingLink

// You can track your order anytime using the link above.

// Thank you for choosing us!
//       ''';
      
//       // URL encode the message
//       final encodedMessage = Uri.encodeComponent(message);
      
//       // Create WhatsApp deep link
//       final whatsappUrl = 'https://wa.me/91$formattedMobile?text=$encodedMessage';
      
//       // You can either:
//       // 1. Open WhatsApp directly
//       // launch(whatsappUrl);
      
//       // 2. OR Use a WhatsApp API service (like WhatsApp Business API)
//       await _sendViaWhatsAppAPI(
//         mobile: formattedMobile,
//         message: message,
//       );
      
//     } catch (e) {
//       print('WhatsApp notification error: $e');
//     }
//   }
  
//   Future<void> _sendViaWhatsAppAPI({required String mobile, required String message}) async {
//     // Using a WhatsApp API service (like Twilio, MessageBird, etc.)
//     // Example with a service:
//     final response = await http.post(
//       Uri.parse('https://api.twilio.com/2010-04-01/Accounts/YOUR_ACCOUNT/Messages.json'),
//       headers: {
//         'Authorization': 'Basic ' + base64Encode(utf8.encode('YOUR_ACCOUNT_SID:YOUR_AUTH_TOKEN')),
//         'Content-Type': 'application/x-www-form-urlencoded',
//       },
//       body: {
//         'From': 'whatsapp:+14155238886',
//         'To': 'whatsapp:+91$mobile',
//         'Body': message,
//       },
//     );
    
//     if (response.statusCode != 201) {
//       throw Exception('Failed to send WhatsApp message');
//     }
//   }
  
//   Future<void> _sendEmailNotification({
//     required String email,
//     required String orderNumber,
//     required String trackingLink,
//     required Map<String, dynamic> orderDetails,
//   }) async {
//     try {
//       // Call Supabase Edge Function for email
//       final response = await supabase.functions.invoke('send-order-email', body: {
//         'email': email,
//         'orderNumber': orderNumber,
//         'trackingLink': trackingLink,
//         'orderDetails': orderDetails,
//       });
      
//       if (response.status != 200) {
//         throw Exception('Email sending failed');
//       }
//     } catch (e) {
//       print('Email notification error: $e');
//       // Fallback: Send via SMTP
//       await _sendEmailViaSMTP(
//         email: email,
//         orderNumber: orderNumber,
//         trackingLink: trackingLink,
//         orderDetails: orderDetails,
//       );
//     }
//   }
  
//   Future<void> _sendEmailViaSMTP({
//     required String email,
//     required String orderNumber,
//     required String trackingLink,
//     required Map<String, dynamic> orderDetails,
//   }) async {
//     // Implementation using SMTP (like mailer package)
//     // This is a fallback if Edge Function fails
//   }

// }











// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class OrderProvider with ChangeNotifier {
//   final supabase = Supabase.instance.client;

//   bool loading = false;
//   String? error;

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
//   int _limit = 20;
//   bool _initialLoadComplete = false;

//   // ========================
//   // CREATE ORDER
//   // ========================
//   Future<void> createOrder(Map<String, dynamic> data) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       final int bags = data['bags'];
//       final int weightPerBag = data['weight_per_bag'];
//       final int pricePerBag = data['price_per_bag'];

//       final int totalWeight = bags * weightPerBag;
//       final int totalPrice = bags * pricePerBag;

//       await supabase.from('emp_mar_orders').insert({
//         'employee_id': user.id,
//         'customer_name': data['customer_name'],
//         'customer_mobile': data['customer_mobile'],
//         'customer_address': data['customer_address'],
//         'feed_category': data['feed_category'],
//         'bags': bags,
//         'weight_per_bag': weightPerBag,
//         'weight_unit': data['weight_unit'],
//         'total_weight': totalWeight,
//         'price_per_bag': pricePerBag,
//         'total_price': totalPrice,
//         'remarks': data['remarks'],
//         'status': 'pending',
//       });

//       await quickLoad();
      
//     } catch (e) {
//       debugPrint("❌ Order insert failed: $e");
//       rethrow;
//     }
//   }

//   // ========================
//   // QUICK LOAD (Optimized for initial display)
//   // ========================
//   Future<void> quickLoad() async {
//     if (_initialLoadComplete && orders.isNotEmpty) return;
    
//     try {
//       loading = true;
//       notifyListeners();
      
//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // Load only essential fields for initial display
//       final data = await supabase
//           .from('emp_mar_orders')
//           .select('id, order_number, status, customer_name, total_price, created_at, bags, feed_category')
//           .eq('employee_id', user.id)
//           .order('created_at', ascending: false)
//           .limit(10);
      
//       orders = data.map((order) {
//         return {
//           ...order,
//           'display_id': _getDisplayOrderId(order),
//         };
//       }).toList();
      
//       _updateCountsFromOrders();
//       _initialLoadComplete = true;
//       error = null;
//         } catch (e) {
//       error = 'Failed to load orders: $e';
//       debugPrint("❌ Quick load failed: $e");
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // FETCH ORDERS WITH PAGINATION
//   // ========================
//   Future<void> fetchOrders({bool loadMore = false}) async {
//     try {
//       if (!loadMore) {
//         _page = 0;
//         _hasMoreData = true;
//         orders.clear();
//       }
      
//       if (!_hasMoreData && loadMore) return;
      
//       loading = true;
//       notifyListeners();
      
//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       final data = await supabase
//           .from('emp_mar_orders')
//           .select('*')
//           .eq('employee_id', user.id)
//           .order('created_at', ascending: false)
//           .range(_page * _limit, (_page + 1) * _limit - 1);
      
//       final newOrders = data.map((order) {
//         return {
//           ...order,
//           'display_id': _getDisplayOrderId(order),
//         };
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
//       _updateCountsFromOrders();
//       _initialLoadComplete = true;
//       error = null;
//         } catch (e) {
//       error = 'Failed to fetch orders: $e';
//       debugPrint("❌ Fetch orders failed: $e");
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // LOAD MORE ORDERS
//   // ========================
//   Future<void> loadMore() async {
//     if (!_hasMoreData || loading) return;
//     await fetchOrders(loadMore: true);
//   }

//   // ========================
//   // FETCH SINGLE ORDER
//   // ========================
//   Future<Map<String, dynamic>?> fetchSingleOrder(String orderId) async {
//     try {
//       final response = await supabase
//           .from('emp_mar_orders')
//           .select('*')
//           .eq('id', orderId)
//           .single();
      
//       // ignore: unnecessary_null_comparison
//       return response != null ? {
//         ...response,
//         'display_id': _getDisplayOrderId(response),
//       } : null;
//     } catch (e) {
//       debugPrint("❌ Fetch single order failed: $e");
//       return null;
//     }
//   }

//   // ========================
//   // UPDATE ORDER STATUS
//   // ========================
//   Future<void> updateOrderStatus(String orderId, String newStatus) async {
//     try {
//       loading = true;
//       notifyListeners();

//       await supabase
//           .from('emp_mar_orders')
//           .update({
//             'status': newStatus,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', orderId);

//       // Refresh orders
//       await quickLoad();
      
//     } catch (e) {
//       debugPrint("❌ Update order status failed: $e");
//       rethrow;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // DELETE ORDER
//   // ========================
//   Future<void> deleteOrder(String orderId) async {
//     try {
//       loading = true;
//       notifyListeners();

//       await supabase
//           .from('emp_mar_orders')
//           .delete()
//           .eq('id', orderId);

//       // Remove from local list
//       orders.removeWhere((order) => order['id'] == orderId);
      
//       // Update counts
//       _updateCountsFromOrders();
      
//       notifyListeners();
//     } catch (e) {
//       debugPrint("❌ Delete order failed: $e");
//       rethrow;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // HELPER METHODS
//   // ========================
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
  
//   void _updateCountsFromOrders() {
//     totalOrders = orders.length;
//     pendingOrders = orders.where((e) => e['status'] == 'pending').length;
//     packingOrders = orders.where((e) => e['status'] == 'packing').length;
//     readyForDispatchOrders = orders.where((e) => e['status'] == 'ready_for_dispatch').length;
//     dispatchedOrders = orders.where((e) => e['status'] == 'dispatched').length;
//     deliveredOrders = orders.where((e) => e['status'] == 'delivered').length;
//     completedOrders = orders.where((e) => e['status'] == 'completed').length;
//     cancelledOrders = orders.where((e) => e['status'] == 'cancelled').length;
//   }

//   // ========================
//   // GETTERS
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
//       return orders.firstWhere((order) => order['id'] == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   bool get hasMoreData => _hasMoreData;

//   // ========================
//   // REFRESH
//   // ========================
//   Future<void> refresh() async {
//     _page = 0;
//     _hasMoreData = true;
//     _initialLoadComplete = false;
//     await quickLoad();
//   }

//   // ========================
//   // STATISTICS
//   // ========================
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
//       'completion_rate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0,
//     };
//   }

//   bool orderExists(String orderId) {
//     return orders.any((order) => order['id'] == orderId);
//   }

//   List<Map<String, dynamic>> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
//     return orders.where((order) {
//       if (order['created_at'] == null) return false;
      
//       final createdAt = DateTime.parse(order['created_at']);
//       return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
//              createdAt.isBefore(endDate.add(const Duration(days: 1)));
//     }).toList();
//   }
// }






























// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class OrderProvider with ChangeNotifier {
//   final supabase = Supabase.instance.client;

//   bool loading = false;

//   int totalOrders = 0;
//   int pendingOrders = 0;
//   int completedOrders = 0;
//   int packingOrders = 0;
//   int readyForDispatchOrders = 0;
//   int dispatchedOrders = 0;
//   int deliveredOrders = 0;
//   int cancelledOrders = 0;

//   List<Map<String, dynamic>> orders = [];

//   // ========================
//   // CREATE ORDER (Updated for emp_mar_orders)
//   // ========================
//   Future<void> createOrder(Map<String, dynamic> data) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       final int bags = data['bags'];
//       final int weightPerBag = data['weight_per_bag'];
//       final int pricePerBag = data['price_per_bag'];

//       final int totalWeight = bags * weightPerBag;
//       final int totalPrice = bags * pricePerBag;

//       await supabase.from('emp_mar_orders').insert({
//         'employee_id': user.id,

//         'customer_name': data['customer_name'],
//         'customer_mobile': data['customer_mobile'],
//         'customer_address': data['customer_address'],

//         'feed_category': data['feed_category'],

//         'bags': bags,
//         'weight_per_bag': weightPerBag,
//         'weight_unit': data['weight_unit'],
//         'total_weight': totalWeight,

//         'price_per_bag': pricePerBag,
//         'total_price': totalPrice,

//         'remarks': data['remarks'],
//         'status': 'pending', // Default status as per table schema
//       });

//       await fetchOrderCounts();
//       await fetchOrders();
      
//     } catch (e) {
//       debugPrint("❌ Order insert failed: $e");
//       rethrow;
//     }
//   }

//   // ========================
//   // FETCH COUNTS (Updated for emp_mar_orders)
//   // ========================
//   Future<void> fetchOrderCounts() async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) return;

//       final data = await supabase
//           .from('emp_mar_orders')
//           .select('status')
//           .eq('employee_id', user.id); // Filter by current employee

//       totalOrders = data.length;
//       pendingOrders = data.where((e) => e['status'] == 'pending').length;
//       packingOrders = data.where((e) => e['status'] == 'packing').length;
//       readyForDispatchOrders = data.where((e) => e['status'] == 'ready_for_dispatch').length;
//       dispatchedOrders = data.where((e) => e['status'] == 'dispatched').length;
//       deliveredOrders = data.where((e) => e['status'] == 'delivered').length;
//       completedOrders = data.where((e) => e['status'] == 'completed').length;
//       cancelledOrders = data.where((e) => e['status'] == 'cancelled').length;

//       notifyListeners();
//     } catch (e) {
//       debugPrint("❌ Fetch counts failed: $e");
//     }
//   }

//   // ========================
//   // FETCH ORDERS (FIXED - Added employee filter)
//   // ========================
//   Future<void> fetchOrders() async {
//     try {
//       loading = true;
//       notifyListeners();
      
//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         orders = [];
//         notifyListeners();
//         return;
//       }

//       // ADD THIS FILTER: .eq('employee_id', user.id)
//       final data = await supabase
//           .from('emp_mar_orders')
//           .select('*')
//           .eq('employee_id', user.id) // <-- CRITICAL: Filter by current employee
//           .order('created_at', ascending: false);
      
//       // Process orders to ensure they have display IDs
//       orders = data.map((order) {
//         return {
//           ...order,
//           'display_id': _getDisplayOrderId(order), // Add a display ID field
//         };
//       }).toList();
      
//       // Update counts from fetched orders
//       _updateCountsFromOrders();
      
//     } catch (e) {
//       print('Error fetching orders: $e');
//       orders = [];
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   String _getDisplayOrderId(Map<String, dynamic> order) {
//     // Priority 1: Use the auto-generated order_number
//     if (order['order_number'] != null && 
//         order['order_number'].toString().isNotEmpty) {
//       return order['order_number'].toString();
//     }
    
//     // Priority 2: Use short UUID (for existing orders before trigger)
//     if (order['id'] != null) {
//       final uuid = order['id'].toString();
//       return '#${uuid.substring(0, 8).toUpperCase()}';
//     }
    
//     // Fallback
//     return '#N/A';
//   }
  
//   // Helper method to update counts from orders list
//   void _updateCountsFromOrders() {
//     totalOrders = orders.length;
//     pendingOrders = orders.where((e) => e['status'] == 'pending').length;
//     packingOrders = orders.where((e) => e['status'] == 'packing').length;
//     readyForDispatchOrders = orders.where((e) => e['status'] == 'ready_for_dispatch').length;
//     dispatchedOrders = orders.where((e) => e['status'] == 'dispatched').length;
//     deliveredOrders = orders.where((e) => e['status'] == 'delivered').length;
//     completedOrders = orders.where((e) => e['status'] == 'completed').length;
//     cancelledOrders = orders.where((e) => e['status'] == 'cancelled').length;
//   }

//   // ========================
//   // GET FILTERED ORDERS
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

//   // ========================
//   // GET ORDER BY ID
//   // ========================
//   Map<String, dynamic>? getOrderById(String id) {
//     try {
//       return orders.firstWhere((order) => order['id'] == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   // ========================
//   // UPDATE ORDER STATUS (For production manager)
//   // ========================
//   Future<void> updateOrderStatus(String orderId, String newStatus) async {
//     try {
//       loading = true;
//       notifyListeners();

//       await supabase
//           .from('emp_mar_orders')
//           .update({
//             'status': newStatus,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', orderId);

//       // Refresh orders
//       await fetchOrders();
      
//     } catch (e) {
//       debugPrint("❌ Update order status failed: $e");
//       rethrow;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // DELETE ORDER
//   // ========================
//   Future<void> deleteOrder(String orderId) async {
//     try {
//       loading = true;
//       notifyListeners();

//       await supabase
//           .from('emp_mar_orders')
//           .delete()
//           .eq('id', orderId);

//       // Remove from local list
//       orders.removeWhere((order) => order['id'] == orderId);
      
//       // Update counts
//       _updateCountsFromOrders();
      
//       notifyListeners();
//     } catch (e) {
//       debugPrint("❌ Delete order failed: $e");
//       rethrow;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // REFRESH ALL DATA
//   // ========================
//   Future<void> refresh() async {
//     await fetchOrders();
//     await fetchOrderCounts();
//   }

//   // ========================
//   // GET STATISTICS MAP
//   // ========================
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

//   // ========================
//   // GET ORDER SUMMARY
//   // ========================
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
//       'completion_rate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0,
//     };
//   }

//   // ========================
//   // CHECK IF ORDER EXISTS
//   // ========================
//   bool orderExists(String orderId) {
//     return orders.any((order) => order['id'] == orderId);
//   }

//   // ========================
//   // GET ORDERS BY DATE RANGE
//   // ========================
//   List<Map<String, dynamic>> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
//     return orders.where((order) {
//       if (order['created_at'] == null) return false;
      
//       final createdAt = DateTime.parse(order['created_at']);
//       return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
//              createdAt.isBefore(endDate.add(const Duration(days: 1)));
//     }).toList();
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class OrderProvider with ChangeNotifier {
//   final supabase = Supabase.instance.client;

//   bool loading = false;

//   int totalOrders = 0;
//   int pendingOrders = 0;
//   int completedOrders = 0;
//   int packingOrders = 0;
//   int readyForDispatchOrders = 0;
//   int dispatchedOrders = 0;
//   int deliveredOrders = 0;
//   int cancelledOrders = 0;

//   List<Map<String, dynamic>> orders = [];

//   // ========================
//   // CREATE ORDER (Updated for emp_mar_orders)
//   // ========================
//   Future<void> createOrder(Map<String, dynamic> data) async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       final int bags = data['bags'];
//       final int weightPerBag = data['weight_per_bag'];
//       final int pricePerBag = data['price_per_bag'];

//       final int totalWeight = bags * weightPerBag;
//       final int totalPrice = bags * pricePerBag;

//       await supabase.from('emp_mar_orders').insert({
//         'employee_id': user.id,

//         'customer_name': data['customer_name'],
//         'customer_mobile': data['customer_mobile'],
//         'customer_address': data['customer_address'],

//         'feed_category': data['feed_category'],

//         'bags': bags,
//         'weight_per_bag': weightPerBag,
//         'weight_unit': data['weight_unit'],
//         'total_weight': totalWeight,

//         'price_per_bag': pricePerBag,
//         'total_price': totalPrice,

//         'remarks': data['remarks'],
//         'status': 'pending', // Default status as per table schema
//       });

//       await fetchOrderCounts();
//       await fetchOrders();
      
//     } catch (e) {
//       debugPrint("❌ Order insert failed: $e");
//       rethrow;
//     }
//   }

//   // ========================
//   // FETCH COUNTS (Updated for emp_mar_orders)
//   // ========================
//   Future<void> fetchOrderCounts() async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) return;

//       final data = await supabase
//           .from('emp_mar_orders')
//           .select('status')
//           .eq('employee_id', user.id);

//       totalOrders = data.length;
//       pendingOrders = data.where((e) => e['status'] == 'pending').length;
//       packingOrders = data.where((e) => e['status'] == 'packing').length;
//       readyForDispatchOrders = data.where((e) => e['status'] == 'ready_for_dispatch').length;
//       dispatchedOrders = data.where((e) => e['status'] == 'dispatched').length;
//       deliveredOrders = data.where((e) => e['status'] == 'delivered').length;
//       completedOrders = data.where((e) => e['status'] == 'completed').length;
//       cancelledOrders = data.where((e) => e['status'] == 'cancelled').length;

//       notifyListeners();
//     } catch (e) {
//       debugPrint("❌ Fetch counts failed: $e");
//     }
//   }

//   // ========================
//   // FETCH ORDERS (Updated for emp_mar_orders)
//   // ========================
//   Future<void> fetchOrders() async {
//   try {
//     final data = await supabase
//         .from('emp_mar_orders')
//         .select('*')
//         .order('created_at', ascending: false);
    
//     // Process orders to ensure they have display IDs
//     orders = data.map((order) {
//       return {
//         ...order,
//         'display_id': _getDisplayOrderId(order), // Add a display ID field
//       };
//     }).toList();
    
//     notifyListeners();
//   } catch (e) {
//     print('Error fetching orders: $e');
//   }
// }

// String _getDisplayOrderId(Map<String, dynamic> order) {
//   // Priority 1: Use the auto-generated order_number
//   if (order['order_number'] != null && 
//       order['order_number'].toString().isNotEmpty) {
//     return order['order_number'].toString();
//   }
  
//   // Priority 2: Use short UUID (for existing orders before trigger)
//   if (order['id'] != null) {
//     final uuid = order['id'].toString();
//     return '#${uuid.substring(0, 8).toUpperCase()}';
//   }
  
//   // Fallback
//   return '#N/A';
// }
//   // Helper method to update counts from orders list
//   void _updateCountsFromOrders() {
//     totalOrders = orders.length;
//     pendingOrders = orders.where((e) => e['status'] == 'pending').length;
//     packingOrders = orders.where((e) => e['status'] == 'packing').length;
//     readyForDispatchOrders = orders.where((e) => e['status'] == 'ready_for_dispatch').length;
//     dispatchedOrders = orders.where((e) => e['status'] == 'dispatched').length;
//     deliveredOrders = orders.where((e) => e['status'] == 'delivered').length;
//     completedOrders = orders.where((e) => e['status'] == 'completed').length;
//     cancelledOrders = orders.where((e) => e['status'] == 'cancelled').length;
//   }

//   // ========================
//   // GET FILTERED ORDERS
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

//   // ========================
//   // GET ORDER BY ID
//   // ========================
//   Map<String, dynamic>? getOrderById(String id) {
//     try {
//       return orders.firstWhere((order) => order['id'] == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   // ========================
//   // UPDATE ORDER STATUS (For production manager)
//   // ========================
//   Future<void> updateOrderStatus(String orderId, String newStatus) async {
//     try {
//       loading = true;
//       notifyListeners();

//       await supabase
//           .from('emp_mar_orders')
//           .update({
//             'status': newStatus,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', orderId);

//       // Refresh orders
//       await fetchOrders();
      
//     } catch (e) {
//       debugPrint("❌ Update order status failed: $e");
//       rethrow;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // DELETE ORDER
//   // ========================
//   Future<void> deleteOrder(String orderId) async {
//     try {
//       loading = true;
//       notifyListeners();

//       await supabase
//           .from('emp_mar_orders')
//           .delete()
//           .eq('id', orderId);

//       // Remove from local list
//       orders.removeWhere((order) => order['id'] == orderId);
      
//       // Update counts
//       _updateCountsFromOrders();
      
//       notifyListeners();
//     } catch (e) {
//       debugPrint("❌ Delete order failed: $e");
//       rethrow;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   // ========================
//   // REFRESH ALL DATA
//   // ========================
//   Future<void> refresh() async {
//     await fetchOrders();
//     await fetchOrderCounts();
//   }

//   // ========================
//   // GET STATISTICS MAP
//   // ========================
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

//   // ========================
//   // GET ORDER SUMMARY
//   // ========================
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
//       'completion_rate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0,
//     };
//   }

//   // ========================
//   // CHECK IF ORDER EXISTS
//   // ========================
//   bool orderExists(String orderId) {
//     return orders.any((order) => order['id'] == orderId);
//   }

//   // ========================
//   // GET ORDERS BY DATE RANGE
//   // ========================
//   List<Map<String, dynamic>> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
//     return orders.where((order) {
//       if (order['created_at'] == null) return false;
      
//       final createdAt = DateTime.parse(order['created_at']);
//       return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
//              createdAt.isBefore(endDate.add(const Duration(days: 1)));
//     }).toList();
//   }
// }
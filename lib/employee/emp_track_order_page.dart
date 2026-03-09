import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_order_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;
  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _hasError = false;

  // Track which notifications were already sent
  bool _whatsappSent = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    // Load order immediately without waiting for frame
    Future.microtask(() => _fetchOrderDetails());
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final orderProvider = context.read<OrderProvider>();
      
      // FIRST: Check local cache
      final foundOrder = orderProvider.orders.firstWhere(
        (order) => order['id'].toString() == widget.orderId,
        orElse: () => {},
      );
      
      if (foundOrder.isNotEmpty) {
        if (mounted) {
          setState(() {
            _order = foundOrder;
            _whatsappSent = foundOrder['whatsapp_sent'] == true;
            _emailSent = foundOrder['email_sent'] == true;
            _isLoading = false;
          });
        }
        return;
      }
      
      // SECOND: Try to fetch single order
      final singleOrder = await orderProvider.fetchSingleOrder(widget.orderId);
      
      if (singleOrder != null && mounted) {
        setState(() {
          _order = singleOrder;
          _whatsappSent = singleOrder['whatsapp_sent'] == true;
          _emailSent = singleOrder['email_sent'] == true;
          _isLoading = false;
        });
      } else {
        // LAST: Show error
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  // Method to handle WhatsApp button press
  Future<void> _handleWhatsAppPress() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    if (_whatsappSent) {
      // Show confirmation dialog for resend
      final shouldResend = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resend WhatsApp?'),
          content: const Text('A WhatsApp notification was already sent for this order. Do you want to send another one?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Send Again'),
            ),
          ],
        ),
      );
      
      if (shouldResend != true) return;
    }
    
    // Send WhatsApp
    await orderProvider.sendOrderWhatsAppNotification(
      context: context,
      orderId: widget.orderId,
      order: _order,
      showDialog: true,
    );
    
    // Refresh order to get updated sent status
    await _fetchOrderDetails();
  }

  // Method to handle Email button press
  Future<void> _handleEmailPress() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    if (_emailSent) {
      // Show confirmation dialog for resend
      final shouldResend = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resend Email?'),
          content: const Text('An email notification was already sent for this order. Do you want to send another one?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Send Again'),
            ),
          ],
        ),
      );
      
      if (shouldResend != true) return;
    }
    
    // Send Email
    await orderProvider.sendOrderEmailNotification(
      context: context,
      orderId: widget.orderId,
      order: _order,
    );
    
    // Refresh order to get updated sent status
    await _fetchOrderDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        title: const Text(
          "Track Order",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: GlobalColors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlobalColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: GlobalColors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _fetchOrderDetails();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading 
          ? _buildLoadingState()
          : _hasError || _order == null
              ? _buildErrorState()
              : _buildOrderContent(_order!),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: GlobalColors.primaryBlue,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order ID",
                style: TextStyle(
                  color: GlobalColors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                widget.orderId.length > 8 
                  ? '#${widget.orderId.substring(0, 8).toUpperCase()}' 
                  : widget.orderId,
                style: const TextStyle(
                  color: GlobalColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: GlobalColors.primaryBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading order details...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderContent(Map<String, dynamic> order) {
    final displayId = order['order_number'] ??
                     order['display_id'] ??
                     '#${order['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}';
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final customerName = order['customer_name'] ?? 'Customer';
    final category = order['feed_category'] ?? 'N/A';
    final bags = order['bags'] ?? 0;
    final weight = order['total_weight'] ?? 0;
    final totalPrice = order['total_price'] ?? 0;
    final address = order['customer_address'] ?? 'Address not provided';
    final mobile = order['customer_mobile'] ?? 'N/A';
    final email = order['customer_email'] ?? '';
    final createdAt = order['created_at'] ?? '';

    // Determine timeline steps based on status (without times)
    final timelineSteps = _getTimelineSteps(status);
    final currentStatusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);

    return Column(
      children: [
        // Blue Curved Header with Order ID
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: GlobalColors.primaryBlue,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order ID",
                style: TextStyle(
                  color: GlobalColors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                displayId,
                style: const TextStyle(
                  color: GlobalColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$bags Bags • $category",
                style: TextStyle(
                  color: GlobalColors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Order Tracking
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Status Card with Order Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GlobalColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowGrey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Current Status",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentStatusText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                currentStatusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Divider
                        Container(
                          height: 1,
                          color: AppColors.borderGrey,
                        ),
                        const SizedBox(height: 16),

                        // Order Information
                        Column(
                          children: [
                            _buildInfoRow("Order Date", _formatDate(createdAt)),
                            const SizedBox(height: 12),
                            _buildInfoRow("Customer", customerName),
                            const SizedBox(height: 12),
                            _buildInfoRow("Mobile", mobile),
                            const SizedBox(height: 12),
                            if (email.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildInfoRow("Email", email),
                              ),
                            const SizedBox(height: 12),
                            _buildInfoRow("Delivery Address", address),
                            const SizedBox(height: 12),
                            _buildInfoRow("Weight", "$weight kg"),
                            const SizedBox(height: 12),
                            _buildInfoRow("Total Amount", "₹$totalPrice"),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Notification Buttons Section
                        if (mobile.isNotEmpty || email.isNotEmpty) ...[
                          Container(
                            height: 1,
                            color: AppColors.borderGrey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Send Notifications",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // WhatsApp Button
                              if (mobile.isNotEmpty)
                                Expanded(
                                  child: _buildNotificationButton(
                                    icon: Icons.message,
                                    label: "WhatsApp",
                                    color: Colors.green,
                                    isSent: _whatsappSent,
                                    onPressed: _handleWhatsAppPress,
                                  ),
                                ),
                              if (mobile.isNotEmpty && email.isNotEmpty)
                                const SizedBox(width: 12),
                              // Email Button
                              if (email.isNotEmpty)
                                Expanded(
                                  child: _buildNotificationButton(
                                    icon: Icons.email,
                                    label: "Email",
                                    color: Colors.blue,
                                    isSent: _emailSent,
                                    onPressed: _handleEmailPress,
                                  ),
                                ),
                            ],
                          ),
                          // Show tracking link if available
                          if (order['tracking_id'] != null && order['tracking_token'] != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: GlobalColors.primaryBlue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: GlobalColors.primaryBlue.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 16,
                                    color: GlobalColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Tracking link available",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: GlobalColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      "Order Timeline",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Timeline (without times)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GlobalColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowGrey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: timelineSteps.map((step) {
                        return _buildTimelineStep(
                          step['title'],
                          step['description'],
                          isCompleted: step['isCompleted'],
                          isActive: step['isActive'],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSent,
    required VoidCallback onPressed,
  }) {
    return Opacity(
      opacity: isSent ? 0.5 : 1.0,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(isSent ? "$label" : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
            maxLines: label == "Delivery Address" ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    String title,
    String description, {
    bool isCompleted = false,
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Dot
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? GlobalColors.primaryBlue
                      : isCompleted
                          ? GlobalColors.success
                          : AppColors.borderGrey,
                  border: Border.all(
                    color: isActive
                        ? GlobalColors.primaryBlue
                        : isCompleted
                            ? GlobalColors.success
                            : AppColors.borderGrey,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 12,
                        color: GlobalColors.white,
                      )
                    : null,
              ),
              if (title != "Delivered")
                Container(
                  width: 2,
                  height: 40,
                  color: isCompleted
                      ? GlobalColors.success
                      : AppColors.borderGrey,
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content (without time)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? GlobalColors.primaryBlue
                        : isCompleted
                            ? GlobalColors.success
                            : AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: GlobalColors.primaryBlue,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Order ID",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.orderId.length > 8 
                  ? '#${widget.orderId.substring(0, 8).toUpperCase()}'
                  : widget.orderId,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Order Not Found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "This order might not exist or was deleted",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                    _fetchOrderDetails();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalColors.primaryBlue,
                  ),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Order Confirmed';
      case 'processing':
        return 'Processing';
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
        return 'Order Placed';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return GlobalColors.warning;
      case 'packing':
      case 'ready_for_dispatch':
        return Colors.orange;
      case 'dispatched':
        return GlobalColors.primaryBlue;
      case 'delivered':
      case 'completed':
        return GlobalColors.success;
      case 'cancelled':
        return GlobalColors.danger;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getTimelineSteps(String currentStatus) {
    final steps = [
      {
        'title': 'Order Confirmed',
        'description': 'Order placed successfully',
        'status': 'pending',
      },
      {
        'title': 'Packing',
        'description': 'Feed bags are being packed',
        'status': 'packing',
      },
      {
        'title': 'Ready for Dispatch',
        'description': 'Order packed and ready for dispatch',
        'status': 'ready_for_dispatch',
      },
      {
        'title': 'Dispatched',
        'description': 'Order has been dispatched',
        'status': 'dispatched',
      },
      {
        'title': 'In Transit',
        'description': 'On the way to destination',
        'status': 'in_transit',
      },
      {
        'title': 'Delivered',
        'description': 'Order delivered to customer',
        'status': 'delivered',
      },
    ];

    // Find the current step index based on actual status
    int currentIndex = 0;
    switch (currentStatus) {
      case 'pending':
        currentIndex = 0;
        break;
      case 'packing':
        currentIndex = 1;
        break;
      case 'ready_for_dispatch':
        currentIndex = 2;
        break;
      case 'dispatched':
        currentIndex = 3;
        break;
      case 'delivered':
      case 'completed':
        currentIndex = 5;
        break;
      case 'cancelled':
        currentIndex = 0;
        break;
      default:
        currentIndex = 0;
    }

    return steps.map((step) {
      final stepIndex = steps.indexOf(step);
      final isCancelled = currentStatus == 'cancelled';
      return {
        'title': step['title'],
        'description': step['description'],
        'isCompleted': !isCancelled && stepIndex <= currentIndex,
        'isActive': !isCancelled && stepIndex == currentIndex,
      };
    }).toList();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "Unknown Date";
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}



















//no send buttons and timeline yes

// import 'package:flutter/material.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/providers/emp_order_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';

// class TrackOrderScreen extends StatefulWidget {
//   final String orderId;
//   const TrackOrderScreen({super.key, required this.orderId});

//   @override
//   State<TrackOrderScreen> createState() => _TrackOrderScreenState();
// }

// class _TrackOrderScreenState extends State<TrackOrderScreen> {
//   Map<String, dynamic>? _order;
//   bool _isLoading = true;
//   bool _hasError = false;

//   @override
//   void initState() {
//     super.initState();
//     // Load order immediately without waiting for frame
//     Future.microtask(() => _fetchOrderDetails());
//   }

//   Future<void> _fetchOrderDetails() async {
//     try {
//       final orderProvider = context.read<OrderProvider>();
      
//       // FIRST: Check local cache
//       final foundOrder = orderProvider.orders.firstWhere(
//         (order) => order['id'].toString() == widget.orderId,
//         orElse: () => {},
//       );
      
//       if (foundOrder.isNotEmpty) {
//         if (mounted) {
//           setState(() {
//             _order = foundOrder;
//             _isLoading = false;
//           });
//         }
//         return;
//       }
      
//       // SECOND: Try to fetch single order
//       final singleOrder = await orderProvider.fetchSingleOrder(widget.orderId);
      
//       if (singleOrder != null && mounted) {
//         setState(() {
//           _order = singleOrder;
//           _isLoading = false;
//         });
//       } else {
//         // LAST: Show error
//         if (mounted) {
//           setState(() {
//             _hasError = true;
//             _isLoading = false;
//           });
//         }
//       }
      
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _hasError = true;
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         title: const Text(
//           "Track Order",
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             color: GlobalColors.white,
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: GlobalColors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: GlobalColors.white),
//             onPressed: () {
//               setState(() {
//                 _isLoading = true;
//                 _hasError = false;
//               });
//               _fetchOrderDetails();
//             },
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading 
//           ? _buildLoadingState()
//           : _hasError || _order == null
//               ? _buildErrorState()
//               : _buildOrderContent(_order!),
//     );
//   }

//   Widget _buildLoadingState() {
//     return Column(
//       children: [
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
//           decoration: BoxDecoration(
//             color: GlobalColors.primaryBlue,
//             borderRadius: const BorderRadius.only(
//               bottomLeft: Radius.circular(20),
//               bottomRight: Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Order ID",
//                 style: TextStyle(
//                   color: GlobalColors.white.withOpacity(0.9),
//                   fontSize: 14,
//                 ),
//               ),
//               Text(
//                 widget.orderId.length > 8 
//                   ? '#${widget.orderId.substring(0, 8).toUpperCase()}' 
//                   : widget.orderId,
//                 style: const TextStyle(
//                   color: GlobalColors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const LinearProgressIndicator(
//                 backgroundColor: Colors.white24,
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(
//                   color: GlobalColors.primaryBlue,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Loading order details...',
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildOrderContent(Map<String, dynamic> order) {
//     final displayId = order['order_number'] ??
//                      order['display_id'] ??
//                      '#${order['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}';
//     final status = (order['status'] ?? 'pending').toString().toLowerCase();
//     final customerName = order['customer_name'] ?? 'Customer';
//     final category = order['feed_category'] ?? 'N/A';
//     final bags = order['bags'] ?? 0;
//     final weight = order['total_weight'] ?? 0;
//     final totalPrice = order['total_price'] ?? 0;
//     final address = order['customer_address'] ?? 'Address not provided';
//     final mobile = order['customer_mobile'] ?? 'N/A';
//     final createdAt = order['created_at'] ?? '';

//     // Determine timeline steps based on status
//     final timelineSteps = _getTimelineSteps(status);
//     final currentStatusText = _getStatusText(status);
//     final statusColor = _getStatusColor(status);

//     return Column(
//       children: [
//         // Blue Curved Header with Order ID
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
//           decoration: BoxDecoration(
//             color: GlobalColors.primaryBlue,
//             borderRadius: const BorderRadius.only(
//               bottomLeft: Radius.circular(20),
//               bottomRight: Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Order ID",
//                 style: TextStyle(
//                   color: GlobalColors.white.withOpacity(0.9),
//                   fontSize: 14,
//                 ),
//               ),
//               Text(
//                 displayId,
//                 style: const TextStyle(
//                   color: GlobalColors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "$bags Bags • $category",
//                 style: TextStyle(
//                   color: GlobalColors.white.withOpacity(0.9),
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // Order Tracking
//         Expanded(
//           child: SingleChildScrollView(
//             physics: const BouncingScrollPhysics(),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Current Status Card with Order Info
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: GlobalColors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.shadowGrey.withOpacity(0.1),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Status Header
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "Current Status",
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: AppColors.secondaryText,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   currentStatusText,
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                     color: statusColor,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 12, vertical: 6),
//                               decoration: BoxDecoration(
//                                 color: statusColor.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Text(
//                                 currentStatusText,
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                   color: statusColor,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),

//                         // Divider
//                         Container(
//                           height: 1,
//                           color: AppColors.borderGrey,
//                         ),
//                         const SizedBox(height: 16),

//                         // Order Information
//                         Column(
//                           children: [
//                             _buildInfoRow("Order Date", _formatDate(createdAt)),
//                             const SizedBox(height: 12),
//                             _buildInfoRow("Customer", customerName),
//                             const SizedBox(height: 12),
//                             _buildInfoRow("Mobile", mobile),
//                             const SizedBox(height: 12),
//                             _buildInfoRow("Delivery Address", address),
//                             const SizedBox(height: 12),
//                             _buildInfoRow("Weight", "$weight kg"),
//                             const SizedBox(height: 12),
//                             _buildInfoRow("Total Amount", "₹$totalPrice"),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // Title
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4),
//                     child: Text(
//                       "Order Timeline",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.primaryText,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),

//                   // Timeline
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: GlobalColors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.shadowGrey.withOpacity(0.1),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: timelineSteps.map((step) {
//                         return _buildTimelineStep(
//                           step['title'],
//                           step['description'],
//                           step['time'],
//                           isCompleted: step['isCompleted'],
//                           isActive: step['isActive'],
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 13,
//             color: AppColors.secondaryText,
//           ),
//         ),
//         Expanded(
//           child: Text(
//             value,
//             textAlign: TextAlign.right,
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//               color: AppColors.primaryText,
//             ),
//             maxLines: label == "Delivery Address" ? 2 : 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTimelineStep(
//     String title,
//     String description,
//     String time, {
//     bool isCompleted = false,
//     bool isActive = false,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Timeline Dot
//           Column(
//             children: [
//               Container(
//                 width: 20,
//                 height: 20,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: isActive
//                       ? GlobalColors.primaryBlue
//                       : isCompleted
//                           ? GlobalColors.success
//                           : AppColors.borderGrey,
//                   border: Border.all(
//                     color: isActive
//                         ? GlobalColors.primaryBlue
//                         : isCompleted
//                             ? GlobalColors.success
//                             : AppColors.borderGrey,
//                     width: 2,
//                   ),
//                 ),
//                 child: isCompleted
//                     ? const Icon(
//                         Icons.check,
//                         size: 12,
//                         color: GlobalColors.white,
//                       )
//                     : null,
//               ),
//               if (title != "Delivered")
//                 Container(
//                   width: 2,
//                   height: 40,
//                   color: isCompleted
//                       ? GlobalColors.success
//                       : AppColors.borderGrey,
//                 ),
//             ],
//           ),
//           const SizedBox(width: 16),

//           // Content
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                         color: isActive
//                             ? GlobalColors.primaryBlue
//                             : isCompleted
//                                 ? GlobalColors.success
//                                 : AppColors.primaryText,
//                       ),
//                     ),
//                     Text(
//                       time,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: AppColors.secondaryText,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   description,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: AppColors.secondaryText,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState() {
//     return Column(
//       children: [
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
//           decoration: BoxDecoration(
//             color: GlobalColors.primaryBlue,
//             borderRadius: const BorderRadius.only(
//               bottomLeft: Radius.circular(20),
//               bottomRight: Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Order ID",
//                 style: TextStyle(
//                   color: Colors.white70,
//                   fontSize: 14,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 widget.orderId.length > 8 
//                   ? '#${widget.orderId.substring(0, 8).toUpperCase()}'
//                   : widget.orderId,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.error_outline,
//                   size: 80,
//                   color: Colors.grey[300],
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   "Order Not Found",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   "This order might not exist or was deleted",
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _isLoading = true;
//                       _hasError = false;
//                     });
//                     _fetchOrderDetails();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: GlobalColors.primaryBlue,
//                   ),
//                   child: const Text("Retry"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   String _getStatusText(String status) {
//     switch (status) {
//       case 'pending':
//         return 'Order Confirmed';
//       case 'processing':
//         return 'Processing';
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
//         return 'Order Placed';
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'pending':
//         return GlobalColors.warning;
//       case 'packing':
//       case 'ready_for_dispatch':
//         return Colors.orange;
//       case 'dispatched':
//         return GlobalColors.primaryBlue;
//       case 'delivered':
//       case 'completed':
//         return GlobalColors.success;
//       case 'cancelled':
//         return GlobalColors.danger;
//       default:
//         return Colors.grey;
//     }
//   }

//   List<Map<String, dynamic>> _getTimelineSteps(String currentStatus) {
//     final steps = [
//       {
//         'title': 'Order Confirmed',
//         'description': 'Order placed successfully',
//         'time': _getTimeForStep(0),
//         'status': 'pending',
//       },
//       {
//         'title': 'Packing',
//         'description': 'Feed bags are being packed',
//         'time': _getTimeForStep(1),
//         'status': 'packing',
//       },
//       {
//         'title': 'Ready for Dispatch',
//         'description': 'Order packed and ready for dispatch',
//         'time': _getTimeForStep(2),
//         'status': 'ready_for_dispatch',
//       },
//       {
//         'title': 'Dispatched',
//         'description': 'Order has been dispatched',
//         'time': _getTimeForStep(3),
//         'status': 'dispatched',
//       },
//       {
//         'title': 'In Transit',
//         'description': 'On the way to destination',
//         'time': _getTimeForStep(4),
//         'status': 'in_transit',
//       },
//       {
//         'title': 'Delivered',
//         'description': 'Order delivered to customer',
//         'time': _getTimeForStep(5),
//         'status': 'delivered',
//       },
//     ];

//     // Find the current step index based on actual status
//     int currentIndex = 0;
//     switch (currentStatus) {
//       case 'pending':
//         currentIndex = 0;
//         break;
//       case 'packing':
//         currentIndex = 1;
//         break;
//       case 'ready_for_dispatch':
//         currentIndex = 2;
//         break;
//       case 'dispatched':
//         currentIndex = 3;
//         break;
//       case 'delivered':
//       case 'completed':
//         currentIndex = 5;
//         break;
//       case 'cancelled':
//         currentIndex = 0;
//         break;
//       default:
//         currentIndex = 0;
//     }

//     return steps.map((step) {
//       final stepIndex = steps.indexOf(step);
//       final isCancelled = currentStatus == 'cancelled';
//       return {
//         'title': step['title'],
//         'description': step['description'],
//         'time': step['time'],
//         'isCompleted': !isCancelled && stepIndex <= currentIndex,
//         'isActive': !isCancelled && stepIndex == currentIndex,
//       };
//     }).toList();
//   }

//   String _getTimeForStep(int step) {
//     final now = DateTime.now();
//     final times = [
//       DateFormat('hh:mm a').format(now.subtract(const Duration(minutes: 30))),
//       DateFormat('hh:mm a').format(now),
//       DateFormat('hh:mm a').format(now.add(const Duration(minutes: 15))),
//       DateFormat('hh:mm a').format(now.add(const Duration(minutes: 30))),
//       'Now',
//       DateFormat('hh:mm a').format(now.add(const Duration(hours: 2))),
//     ];
//     return step < times.length ? times[step] : '';
//   }

//   String _formatDate(String? dateString) {
//     if (dateString == null) return "Unknown Date";
    
//     try {
//       final date = DateTime.parse(dateString);
//       return DateFormat('dd MMM yyyy, hh:mm a').format(date);
//     } catch (e) {
//       return dateString;
//     }
//   }
// }









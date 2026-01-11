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
    final createdAt = order['created_at'] ?? '';

    // Determine timeline steps based on status
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
                            _buildInfoRow("Delivery Address", address),
                            const SizedBox(height: 12),
                            _buildInfoRow("Weight", "$weight kg"),
                            const SizedBox(height: 12),
                            _buildInfoRow("Total Amount", "₹$totalPrice"),
                          ],
                        ),
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

                  // Timeline
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
                          step['time'],
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
    String description,
    String time, {
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

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
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
        'time': _getTimeForStep(0),
        'status': 'pending',
      },
      {
        'title': 'Packing',
        'description': 'Feed bags are being packed',
        'time': _getTimeForStep(1),
        'status': 'packing',
      },
      {
        'title': 'Ready for Dispatch',
        'description': 'Order packed and ready for dispatch',
        'time': _getTimeForStep(2),
        'status': 'ready_for_dispatch',
      },
      {
        'title': 'Dispatched',
        'description': 'Order has been dispatched',
        'time': _getTimeForStep(3),
        'status': 'dispatched',
      },
      {
        'title': 'In Transit',
        'description': 'On the way to destination',
        'time': _getTimeForStep(4),
        'status': 'in_transit',
      },
      {
        'title': 'Delivered',
        'description': 'Order delivered to customer',
        'time': _getTimeForStep(5),
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
        'time': step['time'],
        'isCompleted': !isCancelled && stepIndex <= currentIndex,
        'isActive': !isCancelled && stepIndex == currentIndex,
      };
    }).toList();
  }

  String _getTimeForStep(int step) {
    final now = DateTime.now();
    final times = [
      DateFormat('hh:mm a').format(now.subtract(const Duration(minutes: 30))),
      DateFormat('hh:mm a').format(now),
      DateFormat('hh:mm a').format(now.add(const Duration(minutes: 15))),
      DateFormat('hh:mm a').format(now.add(const Duration(minutes: 30))),
      'Now',
      DateFormat('hh:mm a').format(now.add(const Duration(hours: 2))),
    ];
    return step < times.length ? times[step] : '';
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








// // Updated TrackOrderScreen with real-time updates
// import 'package:flutter/material.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/models/order_model.dart';
// import 'package:mega_pro/providers/tracking_orders_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class RealTimeTrackOrderScreen extends StatefulWidget {
//   final String orderId;
//   const RealTimeTrackOrderScreen({super.key, required this.orderId});

//   @override
//   State<RealTimeTrackOrderScreen> createState() => _RealTimeTrackOrderScreenState();
// }

// class _RealTimeTrackOrderScreenState extends State<RealTimeTrackOrderScreen> {
//   late Order? _order;
//   late RealTimeOrderProvider _orderProvider;
//   RealtimeChannel? _orderChannel;

//   @override
//   void initState() {
//     super.initState();
//     _fetchOrderDetails();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _orderProvider = context.read<RealTimeOrderProvider>();
//   }

//   void _fetchOrderDetails() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       try {
//         final order = _orderProvider.orders.firstWhere(
//           (order) => order.id == widget.orderId,
//         );
        
//         setState(() {
//           _order = order;
//         });
//       } catch (e) {
//         setState(() {
//           _order = null;
//         });
//       }
//       _setupOrderRealtimeSubscription();
//         });
//   }

//   void _setupOrderRealtimeSubscription() {
//     if (_orderChannel != null) {
//       _orderChannel!.unsubscribe();
//     }

//     // Subscribe to specific order changes
//     final supabase = Provider.of<SupabaseClient>(context, listen: false);
    
//     _orderChannel = supabase.channel('order_${widget.orderId}')
//       .onPostgresChanges(
//         event: PostgresChangeEvent.update,
//         schema: 'public',
//         table: 'emp_mar_orders',
//         filter: PostgresChangeFilter(
//           type: PostgresChangeFilterType.eq,
//           column: 'id',
//           value: widget.orderId,
//         ),
//         callback: (payload) {
//           if (payload.newRecord != null) {
//             final updatedOrder = Order.fromJson(payload.newRecord);
//             setState(() {
//               _order = updatedOrder;
//             });
            
//             // Show status update notification
//             if (payload.oldRecord['status'] != payload.newRecord['status']) {
//               _showStatusUpdateNotification(
//                 payload.oldRecord['status'],
//                 payload.newRecord['status'],
//               );
//             }
//           }
//         },
//       )
//       .subscribe();
//   }

//   void _showStatusUpdateNotification(String oldStatus, String newStatus) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           '✅ Order status updated from ${_getStatusText(oldStatus)} to ${_getStatusText(newStatus)}',
//         ),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         title: const Text(
//           "Track Order (Live)",
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
//           if (_order != null)
//             IconButton(
//               icon: const Icon(Icons.refresh, color: GlobalColors.white),
//               onPressed: _fetchOrderDetails,
//               tooltip: 'Refresh Order',
//             ),
//         ],
//       ),
//       body: Consumer<RealTimeOrderProvider>(
//         builder: (context, orderProvider, _) {
//           if (_order == null && orderProvider.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (_order == null) {
//             return _buildErrorState();
//           }

//           return _buildOrderDetails(_order!);
//         },
//       ),
//     );
//   }

//   Widget _buildOrderDetails(Order order) {
//     final timelineSteps = _getTimelineSteps(order.status);
//     final currentStatusText = _getStatusText(order.status);
//     final statusColor = order.statusColor;

//     return Column(
//       children: [
//         // Header with real-time indicator
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
//               Row(
//                 children: [
//                   Text(
//                     "Order ID",
//                     style: TextStyle(
//                       color: GlobalColors.white.withOpacity(0.9),
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: Colors.green,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: const Text(
//                       'LIVE',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               Text(
//                 order.orderNumber ?? '#${order.id.substring(0, 8).toUpperCase()}',
//                 style: const TextStyle(
//                   color: GlobalColors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "${order.bags} Bags • ${order.feedCategory}",
//                 style: TextStyle(
//                   color: GlobalColors.white.withOpacity(0.9),
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // Real-time status card
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.1),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Current Status",
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           currentStatusText,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: statusColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           "Updated",
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           order.updatedAt != null
//                               ? DateFormat('hh:mm a').format(order.updatedAt!)
//                               : 'Never',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 LinearProgressIndicator(
//                   value: _getProgressValue(order.status),
//                   backgroundColor: Colors.grey[200],
//                   valueColor: AlwaysStoppedAnimation<Color>(statusColor),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "${(_getProgressValue(order.status) * 100).toInt()}% Complete",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),

//         // Timeline
//         Expanded(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.1),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Order Timeline",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ...timelineSteps.map((step) {
//                       return _buildTimelineStep(
//                         step['title'],
//                         step['description'],
//                         step['time'],
//                         isCompleted: step['isCompleted'],
//                         isActive: step['isActive'],
//                         actualTime: step['actualTime'],
//                       );
//                     }).toList(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),

//         // Action buttons
//         if (order.status != 'completed' && order.status != 'cancelled')
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.white,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () {
//                       _showStatusUpdateDialog(context, order);
//                     },
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text('Update Status'),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       _showOrderDetails(context, order);
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: GlobalColors.primaryBlue,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text('View Details'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildTimelineStep(
//     String title,
//     String description,
//     String time, {
//     bool isCompleted = false,
//     bool isActive = false,
//     String? actualTime,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Timeline indicator
//           Column(
//             children: [
//               Container(
//                 width: 24,
//                 height: 24,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: isActive
//                       ? GlobalColors.primaryBlue
//                       : isCompleted
//                           ? Colors.green
//                           : Colors.grey[300],
//                   border: Border.all(
//                     color: isActive
//                         ? GlobalColors.primaryBlue
//                         : isCompleted
//                             ? Colors.green
//                             : Colors.grey,
//                     width: 2,
//                   ),
//                 ),
//                 child: isCompleted
//                     ? const Icon(
//                         Icons.check,
//                         size: 14,
//                         color: Colors.white,
//                       )
//                     : isActive
//                         ? const Icon(
//                             Icons.circle,
//                             size: 10,
//                             color: Colors.white,
//                           )
//                         : null,
//               ),
//               if (title != "Delivered")
//                 Container(
//                   width: 2,
//                   height: 40,
//                   color: isCompleted
//                       ? Colors.green
//                       : Colors.grey[300],
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
//                                 ? Colors.green
//                                 : Colors.grey[700],
//                       ),
//                     ),
//                     Text(
//                       actualTime ?? time,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   description,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   double _getProgressValue(String status) {
//     switch (status) {
//       case 'pending':
//         return 0.0;
//       case 'packing':
//         return 0.2;
//       case 'ready_for_dispatch':
//         return 0.4;
//       case 'dispatched':
//         return 0.6;
//       case 'delivered':
//         return 0.8;
//       case 'completed':
//         return 1.0;
//       default:
//         return 0.0;
//     }
//   }

//   Future<void> _showStatusUpdateDialog(BuildContext context, Order order) async {
//     final nextStatusOptions = _orderProvider.getNextStatusOptions(order);
    
//     if (nextStatusOptions.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No further status updates available'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     await showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Update Order Status',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[800],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ...nextStatusOptions.map((status) {
//                 return ListTile(
//                   leading: Icon(
//                     _getStatusIcon(status),
//                     color: _getStatusColor(status),
//                   ),
//                   title: Text(_getStatusText(status)),
//                   onTap: () async {
//                     Navigator.pop(context);
//                     await _updateOrderStatus(order, status);
//                   },
//                 );
//               }).toList(),
//               const SizedBox(height: 16),
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _updateOrderStatus(Order order, String newStatus) async {
//     try {
//       await _orderProvider.updateOrderStatus(order, newStatus);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to update status: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _showOrderDetails(BuildContext context, Order order) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Order Details'),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _detailItem('Order ID', order.orderNumber ?? order.id),
//                 _detailItem('Customer', order.customerName),
//                 _detailItem('Mobile', order.customerMobile),
//                 _detailItem('Address', order.customerAddress),
//                 _detailItem('Product', order.feedCategory),
//                 _detailItem('Bags', '${order.bags}'),
//                 _detailItem('Total Weight', '${order.totalWeight} ${order.weightUnit}'),
//                 _detailItem('Total Price', '₹${order.totalPrice}'),
//                 _detailItem('Status', order.displayStatus),
//                 _detailItem('Created', order.formattedCreatedAt),
//                 _detailItem('Last Updated', order.formattedUpdatedAt),
//                 if (order.remarks != null)
//                   _detailItem('Remarks', order.remarks!),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _detailItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               '$label:',
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper methods
//   List<Map<String, dynamic>> _getTimelineSteps(String currentStatus) {
//     final steps = [
//       {
//         'title': 'Order Confirmed',
//         'description': 'Order placed and confirmed',
//         'status': 'pending',
//         'actualTime': _order?.createdAt != null 
//             ? DateFormat('hh:mm a').format(_order!.createdAt)
//             : '',
//       },
//       {
//         'title': 'Packing',
//         'description': 'Products are being packed',
//         'status': 'packing',
//       },
//       {
//         'title': 'Ready for Dispatch',
//         'description': 'Order packed and ready for dispatch',
//         'status': 'ready_for_dispatch',
//       },
//       {
//         'title': 'Dispatched',
//         'description': 'Order dispatched to delivery',
//         'status': 'dispatched',
//       },
//       {
//         'title': 'Delivered',
//         'description': 'Order delivered to customer',
//         'status': 'delivered',
//       },
//       {
//         'title': 'Completed',
//         'description': 'Order completed successfully',
//         'status': 'completed',
//       },
//     ];

//     int currentIndex = steps.indexWhere((step) => step['status'] == currentStatus);
//     if (currentIndex == -1) currentIndex = 0;

//     return steps.map((step) {
//       final stepIndex = steps.indexOf(step);
//       final isCancelled = currentStatus == 'cancelled';
      
//       return {
//         ...step,
//         'time': step['actualTime'] ?? _getEstimatedTime(stepIndex),
//         'isCompleted': !isCancelled && stepIndex <= currentIndex,
//         'isActive': !isCancelled && stepIndex == currentIndex,
//       };
//     }).toList();
//   }

//   String _getEstimatedTime(int step) {
//     final now = DateTime.now();
//     final times = [
//       DateFormat('hh:mm a').format(now),
//       DateFormat('hh:mm a').format(now.add(const Duration(minutes: 15))),
//       DateFormat('hh:mm a').format(now.add(const Duration(minutes: 30))),
//       DateFormat('hh:mm a').format(now.add(const Duration(hours: 1))),
//       DateFormat('hh:mm a').format(now.add(const Duration(hours: 2))),
//       DateFormat('hh:mm a').format(now.add(const Duration(hours: 3))),
//     ];
//     return step < times.length ? 'Est: ${times[step]}' : '';
//   }

//   String _getStatusText(String status) {
//     switch (status) {
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

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'pending':
//         return Colors.orange;
//       case 'packing':
//         return Colors.blue;
//       case 'ready_for_dispatch':
//         return Colors.purple;
//       case 'dispatched':
//         return Colors.indigo;
//       case 'delivered':
//       case 'completed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getStatusIcon(String status) {
//     switch (status) {
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
//                 widget.orderId.substring(0, 8),
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
//                   onPressed: _fetchOrderDetails,
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

//   @override
//   void dispose() {
//     _orderChannel?.unsubscribe();
//     super.dispose();
//   }
// }







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
//   late Map<String, dynamic>? _order;

//   @override
//   void initState() {
//     super.initState();
//     _fetchOrderDetails();
//   }

//   void _fetchOrderDetails() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final orderProvider = context.read<OrderProvider>();
//       // Find the order by ID
//       final foundOrder = orderProvider.orders.firstWhere(
//         (order) => order['id'].toString() == widget.orderId,
//         orElse: () => {},
//       );
      
//       if (foundOrder.isNotEmpty) {
//         setState(() {
//           _order = foundOrder;
//         });
//       } else {
//         // If not found in local cache, fetch from provider
//         orderProvider.fetchOrders().then((_) {
//           final updatedOrder = orderProvider.orders.firstWhere(
//             (order) => order['id'].toString() == widget.orderId,
//             orElse: () => {},
//           );
//           setState(() {
//             _order = updatedOrder;
//           });
//         });
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         title: const Text(
//           "Track the Order",
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             color: GlobalColors.white,
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: GlobalColors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Consumer<OrderProvider>(
//         builder: (context, orderProvider, _) {
//           if (_order == null && orderProvider.loading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (_order == null || _order!.isEmpty) {
//             return _buildErrorState();
//           }

//           final order = _order!;
//           final displayId = order['order_number'] ??
//                          order['display_id'] ??
//                          '#${order['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}';
//           final status = (order['status'] ?? 'pending').toString().toLowerCase();
//           final customerName = order['customer_name'] ?? 'Customer';
//           final category = order['category'] ?? order['feed_category'] ?? 'N/A';
//           final bags = order['bags'] ?? 0;
//           final weight = order['weight'] ?? 0;
//           final totalPrice = order['total_price'] ?? 0;
//           final address = order['customer_address'] ?? 'Address not provided';
//           final mobile = order['customer_mobile'] ?? 'N/A';
//           final createdAt = order['created_at'] ?? '';

//           // Determine timeline steps based on status
//           final timelineSteps = _getTimelineSteps(status);
//           final currentStatusText = _getStatusText(status);
//           final statusColor = _getStatusColor(status);
//           final isOnTime = _isDeliveryOnTime(status);

//           return Column(
//             children: [
//               // Blue Curved Header with Order ID
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
//                 decoration: BoxDecoration(
//                   color: GlobalColors.primaryBlue,
//                   borderRadius: const BorderRadius.only(
//                     bottomLeft: Radius.circular(20),
//                     bottomRight: Radius.circular(20),
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Order ID",
//                       style: TextStyle(
//                         color: GlobalColors.white.withOpacity(0.9),
//                         fontSize: 14,
//                       ),
//                     ),
//                     Text(
//                       displayId,
//                       style: const TextStyle(
//                         color: GlobalColors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       "$bags Bags • $category",
//                       style: TextStyle(
//                         color: GlobalColors.white.withOpacity(0.9),
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Order Tracking
//               Expanded(
//                 child: SingleChildScrollView(
//                   physics: const BouncingScrollPhysics(),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Current Status Card with Order Info
//                         Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: GlobalColors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: AppColors.shadowGrey.withOpacity(0.1),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Status Header
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         "Current Status",
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: AppColors.secondaryText,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         currentStatusText,
//                                         style: TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                           color: statusColor,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 12, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: isOnTime 
//                                           ? GlobalColors.success.withOpacity(0.1)
//                                           : GlobalColors.warning.withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     child: Text(
//                                       isOnTime ? "On Time" : "Delayed",
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w600,
//                                         color: isOnTime 
//                                             ? GlobalColors.success
//                                             : GlobalColors.warning,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 16),

//                               // Divider
//                               Container(
//                                 height: 1,
//                                 color: AppColors.borderGrey,
//                               ),
//                               const SizedBox(height: 16),

//                               // Order Information
//                               Column(
//                                 children: [
//                                   _buildInfoRow("Order Date", _formatDate(createdAt)),
//                                   const SizedBox(height: 12),
//                                   _buildInfoRow("Customer", customerName),
//                                   const SizedBox(height: 12),
//                                   _buildInfoRow("Mobile", mobile),
//                                   const SizedBox(height: 12),
//                                   _buildInfoRow("Delivery Address", address),
//                                   const SizedBox(height: 12),
//                                   _buildInfoRow("Weight", "$weight kg"),
//                                   const SizedBox(height: 12),
//                                   _buildInfoRow("Total Amount", "₹$totalPrice"),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 20),

//                         // Title
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 4),
//                           child: Text(
//                             "Order Timeline",
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: AppColors.primaryText,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 12),

//                         // Timeline
//                         Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: GlobalColors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: AppColors.shadowGrey.withOpacity(0.1),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: timelineSteps.map((step) {
//                               return _buildTimelineStep(
//                                 step['title'],
//                                 step['description'],
//                                 step['time'],
//                                 isCompleted: step['isCompleted'],
//                                 isActive: step['isActive'],
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
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
//         // Blue Header (still shown even in error state)
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
//               const SizedBox(height: 4),
//               Text(
//                 widget.orderId.substring(0, 8),
//                 style: const TextStyle(
//                   color: GlobalColors.white,
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
//                   color: AppColors.secondaryText.withOpacity(0.5),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Order Not Found",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.primaryText,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Unable to load order details",
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: AppColors.secondaryText,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _fetchOrderDetails,
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

//   bool _isDeliveryOnTime(String status) {
//     // Simple logic - pending/processing orders are on time
//     return status == 'pending' || status == 'packing' || status == 'ready_for_dispatch';
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
//         currentIndex = 0; // Show all steps as not completed for cancelled
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
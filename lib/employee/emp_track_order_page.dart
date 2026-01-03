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
  late Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  void _fetchOrderDetails() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = context.read<OrderProvider>();
      // Find the order by ID
      final foundOrder = orderProvider.orders.firstWhere(
        (order) => order['id'].toString() == widget.orderId,
        orElse: () => {},
      );
      
      if (foundOrder.isNotEmpty) {
        setState(() {
          _order = foundOrder;
        });
      } else {
        // If not found in local cache, fetch from provider
        orderProvider.fetchOrders().then((_) {
          final updatedOrder = orderProvider.orders.firstWhere(
            (order) => order['id'].toString() == widget.orderId,
            orElse: () => {},
          );
          setState(() {
            _order = updatedOrder;
          });
        });
      }
    });
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
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (_order == null && orderProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_order == null || _order!.isEmpty) {
            return _buildErrorState();
          }

          final order = _order!;
          final displayId = order['order_number'] ??
                         order['display_id'] ??
                         '#${order['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}';
          final status = (order['status'] ?? 'pending').toString().toLowerCase();
          final customerName = order['customer_name'] ?? 'Customer';
          final category = order['category'] ?? order['feed_category'] ?? 'N/A';
          final bags = order['bags'] ?? 0;
          final weight = order['weight'] ?? 0;
          final totalPrice = order['total_price'] ?? 0;
          final address = order['customer_address'] ?? 'Address not provided';
          final mobile = order['customer_mobile'] ?? 'N/A';
          final createdAt = order['created_at'] ?? '';

          // Determine timeline steps based on status
          final timelineSteps = _getTimelineSteps(status);
          final currentStatusText = _getStatusText(status);
          final statusColor = _getStatusColor(status);
          final isOnTime = _isDeliveryOnTime(status);

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
                    const SizedBox(height: 4),
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
                                      color: isOnTime 
                                          ? GlobalColors.success.withOpacity(0.1)
                                          : GlobalColors.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isOnTime ? "On Time" : "Delayed",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isOnTime 
                                            ? GlobalColors.success
                                            : GlobalColors.warning,
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
        },
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
        // Blue Header (still shown even in error state)
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
              const SizedBox(height: 4),
              Text(
                widget.orderId.substring(0, 8),
                style: const TextStyle(
                  color: GlobalColors.white,
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
                  color: AppColors.secondaryText.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  "Order Not Found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Unable to load order details",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchOrderDetails,
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

  bool _isDeliveryOnTime(String status) {
    // Simple logic - pending/processing orders are on time
    return status == 'pending' || status == 'packing' || status == 'ready_for_dispatch';
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
        currentIndex = 0; // Show all steps as not completed for cancelled
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
// import 'package:flutter/material.dart';
// import 'package:mega_pro/global/global_variables.dart';

// class TrackOrderScreen extends StatelessWidget {
//   final String orderId;

//   const TrackOrderScreen({super.key, required this.orderId});

//   @override
//   Widget build(BuildContext context) {
//     Color primary = GlobalColors.primaryBlue;

//     return Scaffold(
//       backgroundColor: AppColors.softGreyBg,
//       appBar: AppBar(
//         backgroundColor: primary,
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           "Feed Order Form",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         leading: IconButton(
//           icon:
//               const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     /// ORDER CARD
//                     Card(
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16)),
//                       elevation: 4,
//                       shadowColor: AppColors.borderGrey,
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment:
//                                   MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Column(
//                                   crossAxisAlignment:
//                                       CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       "Order Number",
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         color:
//                                             AppColors.secondaryText,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       orderId,
//                                       style: const TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 Container(
//                                   padding:
//                                       const EdgeInsets.symmetric(
//                                           horizontal: 12,
//                                           vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color:
//                                         AppColors.successLight,
//                                     borderRadius:
//                                         BorderRadius.circular(50),
//                                   ),
//                                   child: Row(
//                                     children: const [
//                                       Icon(Icons.check_circle,
//                                           color:
//                                               GlobalColors.success,
//                                           size: 16),
//                                       SizedBox(width: 4),
//                                       Text(
//                                         "Paid",
//                                         style: TextStyle(
//                                             fontSize: 12,
//                                             fontWeight:
//                                                 FontWeight.bold),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const Divider(height: 24),
//                             Row(
//                               crossAxisAlignment:
//                                   CrossAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   width: 48,
//                                   height: 48,
//                                   decoration: BoxDecoration(
//                                     color: AppColors.lightBlue,
//                                     borderRadius:
//                                         BorderRadius.circular(12),
//                                   ),
//                                   child: Icon(Icons.location_on,
//                                       color: primary, size: 24),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         "Current Location",
//                                         style: TextStyle(
//                                           fontSize: 10,
//                                           fontWeight:
//                                               FontWeight.bold,
//                                           color:
//                                               AppColors.secondaryText,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       const Text(
//                                         "Near Springfield Hwy 42",
//                                         style: TextStyle(
//                                             fontSize: 16,
//                                             fontWeight:
//                                                 FontWeight.bold),
//                                       ),
//                                       const SizedBox(height: 6),
//                                       Row(
//                                         children: [
//                                           Container(
//                                             width: 8,
//                                             height: 8,
//                                             decoration:
//                                                 const BoxDecoration(
//                                               color: GlobalColors
//                                                   .success,
//                                               shape: BoxShape.circle,
//                                             ),
//                                           ),
//                                           const SizedBox(width: 6),
//                                           Text(
//                                             "Updated just now",
//                                             style: TextStyle(
//                                               fontSize: 10,
//                                               color:
//                                                   AppColors.secondaryText,
//                                             ),
//                                           ),
//                                         ],
//                                       )
//                                     ],
//                                   ),
//                                 )
//                               ],
//                             ),
//                             const Divider(height: 24),
//                             Row(
//                               children: [
//                                 const CircleAvatar(
//                                   radius: 24,
//                                   backgroundImage: NetworkImage(
//                                       "https://lh3.googleusercontent.com/aida-public/AB6AXuAJAgWdMQjS9wZlonocS9M8prP0hFBjQ8rUEcYLH3vKs6fRMLkJvGCjwZotsTVIIruNC6_c0d0rz4O0tvJ_KZwz77yvpUjpqjjuLdbfZvRBze6ACUMDcMde__ijr8n_cLuOmC0R-uWmAcTmkWhSjyK1Mgt868_09_azJKqdiAGQ0lFkVAaTlN31Xf-AWpoAWUs3dU78wc_p5uidxzGoL9bo-Cfg3ArQBWqh3uUaH8S7sCurlLtU_08KkA8Xf_pwh1GQLHX_amZ3M5CR"),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: const [
//                                       Text(
//                                         "Mike R.",
//                                         style: TextStyle(
//                                             fontWeight:
//                                                 FontWeight.bold,
//                                             fontSize: 14),
//                                       ),
//                                       Text(
//                                         "Truck #TX-409 • Cattle Feed Unit",
//                                         style: TextStyle(
//                                             fontSize: 12,
//                                             color:
//                                                 GlobalColors.textGrey),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 ElevatedButton(
//                                   onPressed: () {},
//                                   style:
//                                       ElevatedButton.styleFrom(
//                                     backgroundColor: primary,
//                                     shape:
//                                         RoundedRectangleBorder(
//                                       borderRadius:
//                                           BorderRadius.circular(12),
//                                     ),
//                                     padding:
//                                         const EdgeInsets.all(12),
//                                   ),
//                                   child: const Icon(Icons.call,
//                                       color: Colors.white),
//                                 )
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     /// DELIVERY PROGRESS
//                     Card(
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16)),
//                       elevation: 4,
//                       shadowColor: AppColors.borderGrey,
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment:
//                               CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "Delivery Progress",
//                               style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight:
//                                       FontWeight.bold),
//                             ),
//                             const SizedBox(height: 16),
//                             Column(
//                               children: [
//                                 timelineStep(
//                                     Icons.inventory_2,
//                                     GlobalColors
//                                         .chartBackgroundBar,
//                                     "Order Placed",
//                                     "Your order has been received.",
//                                     "10:00 AM"),
//                                 timelineStep(
//                                     Icons.check_circle,
//                                     GlobalColors
//                                         .chartBackgroundBar,
//                                     "Packed & Ready",
//                                     "Quality check completed.",
//                                     "11:30 AM"),
//                                 timelineStep(
//                                     Icons.local_shipping,
//                                     GlobalColors.primaryBlue,
//                                     "Out for Delivery",
//                                     "Driver is on the way to your farm.",
//                                     "Now",
//                                     isActive: true),
//                                 timelineStep(
//                                     Icons.home,
//                                     AppColors.mutedText,
//                                     "Delivered",
//                                     "Expected arrival at main gate.",
//                                     "Est. 2:00 PM"),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget timelineStep(
//     IconData icon,
//     Color iconColor,
//     String title,
//     String subtitle,
//     String time, {
//     bool isActive = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Column(
//             children: [
//               Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   color: iconColor,
//                   shape: BoxShape.circle,
//                   boxShadow: isActive
//                       ? [
//                           BoxShadow(
//                             color: GlobalColors
//                                 .chartBackgroundBar,
//                             blurRadius: 8,
//                             spreadRadius: 1,
//                           )
//                         ]
//                       : null,
//                 ),
//                 child: Icon(icon,
//                     color: isActive
//                         ? Colors.white
//                         : GlobalColors.black,
//                     size: 18),
//               ),
//               Container(
//                 width: 2,
//                 height: 50,
//                 color: GlobalColors.chartGrid,
//               ),
//             ],
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment:
//                       MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontWeight: isActive
//                             ? FontWeight.bold
//                             : FontWeight.w600,
//                         fontSize: 14,
//                         color: isActive
//                             ? GlobalColors.primaryBlue
//                             : GlobalColors.black,
//                       ),
//                     ),
//                     Text(
//                       time,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: isActive
//                             ? GlobalColors.primaryBlue
//                             : GlobalColors.textGrey,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   subtitle,
//                   style: const TextStyle(
//                     fontSize: 12,
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
// }

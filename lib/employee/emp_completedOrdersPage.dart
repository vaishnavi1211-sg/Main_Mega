import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_order_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CompletedOrdersPage extends StatefulWidget {
  const CompletedOrdersPage({super.key});

  @override
  State<CompletedOrdersPage> createState() => _CompletedOrdersPageState();
}

class _CompletedOrdersPageState extends State<CompletedOrdersPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  @override
  void initState() {
    super.initState();
    // Fetch orders when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: GlobalColors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlobalColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Completed Orders",
          style: TextStyle(
            color: GlobalColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.orders.isEmpty && !orderProvider.loading) {
            return _buildEmptyState();
          }

          if (orderProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter orders - only show completed or cancelled orders
          final completedOrders = orderProvider.orders.where((order) {
            final status = (order['status'] ?? '').toString().toLowerCase();
            final customerName = (order['customer_name'] ?? '').toString().toLowerCase();
            final orderId = (order['id'] ?? '').toString().toLowerCase();
            final orderNumber = (order['order_number'] ?? '').toString().toLowerCase();
            final searchLower = _query.toLowerCase();
            
            return (status == 'completed' || status == 'cancelled' || status == 'delivered') && 
                   (customerName.contains(searchLower) || 
                    orderId.contains(searchLower) ||
                    orderNumber.contains(searchLower));
          }).toList();

          // Group orders by month
          final Map<String, List<Map<String, dynamic>>> groupedOrders = {};
          for (var order in completedOrders) {
            try {
              final dateString = order['created_at'] ?? order['updated_at'];
              if (dateString != null) {
                final date = DateTime.parse(dateString);
                final month = DateFormat('MMMM yyyy').format(date);
                
                if (!groupedOrders.containsKey(month)) {
                  groupedOrders[month] = [];
                }
                groupedOrders[month]!.add(order);
              }
            } catch (e) {
              // If date parsing fails, add to unknown month
              if (!groupedOrders.containsKey('Unknown Date')) {
                groupedOrders['Unknown Date'] = [];
              }
              groupedOrders['Unknown Date']!.add(order);
            }
          }

          return Column(
            children: [
              // Header Section
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Completed Orders",
                      style: TextStyle(
                        color: GlobalColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Delivered and cancelled order history",
                      style: TextStyle(
                        color: GlobalColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search Box
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
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: "Search by order number or customer...",
                            prefixIcon: const Icon(Icons.search,
                                color: GlobalColors.primaryBlue),
                            filled: true,
                            fillColor: AppColors.softGreyBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Orders List Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order History",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            "${completedOrders.length} Orders",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Orders List
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: groupedOrders.length,
                          itemBuilder: (context, index) {
                            final month = groupedOrders.keys.elementAt(index);
                            final monthOrders = groupedOrders[month]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Month Header
                                Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 8, top: index > 0 ? 16 : 0),
                                  child: Text(
                                    month,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                                
                                // Orders for this month
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: monthOrders.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, orderIndex) {
                                    final order = monthOrders[orderIndex];
                                    return _buildOrderCard(order);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final displayId = order['order_number'] ??
                   order['display_id'] ??
                   '#${order['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}';
    final status = (order['status'] ?? '').toString().toLowerCase();
    final isCancelled = status == 'cancelled';
    final isDelivered = status == 'delivered' || status == 'completed';
    final statusColor = _getStatusColor(status);
    final statusText = status.toUpperCase();
    
    // Get price - use 'total_price' column name
    final price = order['total_price'] ?? order['price'] ?? 0;
    final priceValue = price is num ? price : (int.tryParse(price.toString()) ?? 0);
    
    // Format date
    String formattedDate = 'N/A';
    try {
      final dateString = order['created_at'] ?? order['updated_at'];
      if (dateString != null) {
        final date = DateTime.parse(dateString);
        formattedDate = DateFormat('dd MMM').format(date);
      }
    } catch (e) {
      formattedDate = 'Invalid Date';
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.borderGrey,
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID and Customer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayId,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          order['customer_name'] ?? 'No Name',
                          style: TextStyle(
                            fontSize: 13,
                            color: isCancelled
                                ? AppColors.secondaryText
                                : AppColors.primaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and Bags
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.scale,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  "${order['bags'] ?? 0} Bags",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Weight
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  "${order['weight'] ?? 'N/A'} kg",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom row with amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Amount",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "₹$priceValue",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
                if (isDelivered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: GlobalColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: GlobalColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Completed",
                          style: TextStyle(
                            fontSize: 12,
                            color: GlobalColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  Widget _buildEmptyState() {
    return Column(
      children: [
        // Header Section
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Completed Orders",
                style: TextStyle(
                  color: GlobalColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Delivered and cancelled order history",
                style: TextStyle(
                  color: GlobalColors.white,
                  fontSize: 14,
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
                  Icons.check_circle_outline,
                  size: 80,
                  color: AppColors.secondaryText.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  "No Completed Orders",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "No orders have been completed or cancelled yet",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
      case 'delivered':
        return GlobalColors.success;
      case 'cancelled':
        return GlobalColors.danger;
      case 'pending':
        return GlobalColors.warning;
      case 'packing':
      case 'ready_for_dispatch':
        return Colors.orange;
      case 'dispatched':
        return GlobalColors.primaryBlue;
      default:
        return Colors.grey;
    }
  }
}
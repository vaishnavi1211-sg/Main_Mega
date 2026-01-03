import 'package:flutter/material.dart';
import 'package:mega_pro/employee/emp_track_order_page.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_order_provider.dart';
import 'package:provider/provider.dart';

class RecentOrdersScreen extends StatefulWidget {
  const RecentOrdersScreen({super.key});

  @override
  State<RecentOrdersScreen> createState() => _RecentOrdersScreenState();
}

class _RecentOrdersScreenState extends State<RecentOrdersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _visibleCount = 10;
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
          "Recent Orders",
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

          // Filter orders - only show pending orders
          final pendingOrders = orderProvider.orders.where((order) {
            final status = (order['status'] ?? '').toString().toLowerCase();
            final customerName = (order['customer_name'] ?? '').toString().toLowerCase();
            final orderId = (order['id'] ?? '').toString().toLowerCase();
            final searchLower = _query.toLowerCase();
            
            return status == 'pending' && 
                   (customerName.contains(searchLower) || 
                    orderId.contains(searchLower));
          }).toList();

          // Group orders by date
          final ordersByDate = _groupOrdersByDate(pendingOrders);
          final visibleOrders = _getVisibleOrders(ordersByDate, _visibleCount);

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
                      "Recently Added Orders",
                      style: TextStyle(
                        color: GlobalColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Orders waiting for processing",
                      style: TextStyle(
                        color: GlobalColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Orders List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
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
                          onChanged: (v) {
                            setState(() => _query = v);
                          },
                          decoration: InputDecoration(
                            hintText: "Search by order ID or customer...",
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
                            "Pending Orders",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            "Showing ${visibleOrders.length} of ${pendingOrders.length}",
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
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: visibleOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = visibleOrders[index];
                            final showHeader = index == 0 || 
                                _getDateString(visibleOrders[index - 1]['created_at']) != 
                                _getDateString(order['created_at']);
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                                    child: Text(
                                      _getDateString(order['created_at']),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ),
                                _buildOrderCard(order),
                              ],
                            );
                          },
                        ),
                      ),

                      // Load More Button
                      if (_visibleCount < pendingOrders.length)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _visibleCount += 10;
                                });
                              },
                              icon: const Icon(Icons.expand_more, size: 20),
                              label: const Text("Load More Orders"),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: GlobalColors.primaryBlue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
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
  final status = (order['status'] ?? 'pending').toString().toLowerCase();
  final disabled = status == 'cancelled';
  final statusColor = _getStatusColor(status);
  final statusText = status.toUpperCase();
  
  // Get category - try multiple field names
  final category = order['category'] ?? 
                  order['feed_category'] ?? 
                  'N/A';
  
  // Get price - use 'total_price' column name
  final price = order['total_price'] ?? order['price'] ?? 0;
  final priceValue = price is num ? price : 
                    (int.tryParse(price.toString()) ?? 0);

  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackOrderScreen(orderId: order['id']),
        ),
      );
    },
    borderRadius: BorderRadius.circular(12),
    child: Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.borderGrey,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Order ID and Customer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "#${order['id'] ?? 'N/A'}",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order['customer_name'] ?? 'No Name',
                        style: TextStyle(
                          fontSize: 13,
                          color: disabled
                              ? AppColors.secondaryText
                              : AppColors.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 16),

            // Order Details - Show Price and Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailColumn(
                  "Bags", 
                  "${order['bags'] ?? 0} Bags", 
                  Icons.scale
                ),
                _buildDetailColumn(
                  "Price", 
                  "₹${priceValue.toString()}", 
                  Icons.currency_rupee
                ),
                _buildDetailColumn(
                  "Category", 
                  category.toString(), 
                  Icons.category
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDetailColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.secondaryText,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
      ],
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
                "Pending Orders",
                style: TextStyle(
                  color: GlobalColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Orders waiting for processing",
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
                  Icons.timer_outlined,
                  size: 80,
                  color: AppColors.secondaryText.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  "No Pending Orders",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "All orders are processed!",
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
        return GlobalColors.success;
      case 'pending':
        return GlobalColors.warning;
      case 'cancelled':
        return GlobalColors.danger;
      case 'dispatched':
        return GlobalColors.primaryBlue;
      case 'delivered':
        return GlobalColors.success;
      default:
        return Colors.grey;
    }
  }

  String _getDateString(String? dateString) {
    if (dateString == null) return "Unknown Date";
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final orderDate = DateTime(date.year, date.month, date.day);
      
      if (orderDate == today) {
        return "TODAY, ${_formatDate(date)}";
      } else if (orderDate == yesterday) {
        return "YESTERDAY, ${_formatDate(date)}";
      } else {
        return _formatDate(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${date.day} ${months[date.month - 1]}';
  }

  Map<String, List<Map<String, dynamic>>> _groupOrdersByDate(List<Map<String, dynamic>> orders) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var order in orders) {
      final dateKey = _getDateString(order['created_at']);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(order);
    }
    
    return grouped;
  }

  List<Map<String, dynamic>> _getVisibleOrders(
      Map<String, List<Map<String, dynamic>>> groupedOrders, 
      int visibleCount) {
    final List<Map<String, dynamic>> visible = [];
    int count = 0;
    
    for (var date in groupedOrders.keys) {
      for (var order in groupedOrders[date]!) {
        if (count >= visibleCount) break;
        visible.add(order);
        count++;
      }
      if (count >= visibleCount) break;
    }
    
    return visible;
  }
}
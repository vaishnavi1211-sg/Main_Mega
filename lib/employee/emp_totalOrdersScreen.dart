import 'package:flutter/material.dart';
import 'package:mega_pro/employee/emp_track_order_page.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_order_provider.dart';
import 'package:provider/provider.dart';

class TotalOrdersPage extends StatefulWidget {
  const TotalOrdersPage({super.key});

  @override
  State<TotalOrdersPage> createState() => _TotalOrdersPageState();
}

class _TotalOrdersPageState extends State<TotalOrdersPage> {
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
          "Total Orders",
          style: TextStyle(
            color: GlobalColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        if (orderProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderProvider.orders.isEmpty) {
          return _buildEmptyState();
        }

          // Filter orders based on search query
          final filtered = orderProvider.orders.where((order) {
            final customerName = (order['customer_name'] ?? '').toString().toLowerCase();
            final orderId = (order['id'] ?? '').toString().toLowerCase();
            final orderNumber = (order['order_number'] ?? '').toString().toLowerCase();
            final searchLower = _query.toLowerCase();
            
            return customerName.contains(searchLower) || 
                   orderId.contains(searchLower) ||
                   orderNumber.contains(searchLower);
          }).toList();

          // Group orders by date
          final ordersByDate = _groupOrdersByDate(filtered);
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
                      "All Orders",
                      style: TextStyle(
                        color: GlobalColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "View and manage all customer orders",
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
                          onChanged: (v) {
                            setState(() => _query = v.toLowerCase());
                          },
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
                            "All Orders",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            "Showing ${visibleOrders.length} of ${filtered.length}",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Orders List
                      Flexible(
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
                      if (_visibleCount < filtered.length)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
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
    final displayId = order['order_number'] ??
                   order['display_id'] ??
                   '#${order['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}';
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
                              color: disabled
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
              const SizedBox(height: 16),

              // Order Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: _buildDetailColumn(
                      "Bags", 
                      "${order['bags'] ?? 0}",
                      Icons.scale,
                      "Bags"
                    ),
                  ),
                  Flexible(
                    child: _buildDetailColumn(
                      "Price", 
                      "₹${priceValue.toString()}",
                      Icons.currency_rupee,
                      "Total"
                    ),
                  ),
                  Flexible(
                    child: _buildDetailColumn(
                      "Category", 
                      category.toString(),
                      Icons.category,
                      ""
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String title, String value, IconData icon, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          unit.isEmpty ? value : "$value $unit",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
                "All Orders",
                style: TextStyle(
                  color: GlobalColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "View and manage all customer orders",
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
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: AppColors.secondaryText.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  "No orders yet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start by creating your first order",
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
      case 'pending':
        return GlobalColors.warning;
      case 'cancelled':
        return GlobalColors.danger;
      case 'packing':
      case 'ready_for_dispatch':
        return Colors.orange;
      case 'dispatched':
        return GlobalColors.primaryBlue;
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
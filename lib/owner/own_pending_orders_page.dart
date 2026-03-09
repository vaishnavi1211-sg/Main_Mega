import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:mega_pro/services/supabase_services.dart';
import 'package:intl/intl.dart';

class PendingOrdersDetailsPage extends StatefulWidget {
  final DashboardData dashboardData;
  
  const PendingOrdersDetailsPage({super.key, required this.dashboardData});

  @override
  State<PendingOrdersDetailsPage> createState() => _PendingOrdersDetailsPageState();
}

class _PendingOrdersDetailsPageState extends State<PendingOrdersDetailsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingOrders = [];
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPendingOrders();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _pendingOrders = await _supabaseService.getPendingOrders();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_searchQuery.isEmpty) return _pendingOrders;
    
    final query = _searchQuery.toLowerCase();
    return _pendingOrders.where((order) {
      final customerName = (order['customer_name'] as String?)?.toLowerCase() ?? '';
      final phone = (order['customer_phone'] as String?)?.toLowerCase() ?? '';
      return customerName.contains(query) || phone.contains(query);
    }).toList();
  }

  double get _totalPendingAmount {
    return _pendingOrders.fold(0.0, (sum, order) {
      return sum + ((order['total_price'] as num?)?.toDouble() ?? 0.0);
    });
  }

  int get _totalBags {
    return _pendingOrders.fold(0, (sum, order) {
      return sum + (int.tryParse(order['bags']?.toString() ?? '0') ?? 0);
    });
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Customer Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person, color: GlobalColors.primaryBlue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['customer_name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order['customer_phone']?.toString() ?? 'No phone',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Order Details Grid - Fixed with proper sizing
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildDetailCard(
                        'Category',
                        order['feed_category']?.toString() ?? 'N/A',
                        Icons.category,
                        Colors.blue,
                      ),
                      _buildDetailCard(
                        'Bags',
                        order['bags']?.toString() ?? '0',
                        Icons.inventory,
                        Colors.orange,
                      ),
                      _buildDetailCard(
                        'Payment',
                        order['payment_method']?.toString() ?? 'N/A',
                        Icons.payment,
                        Colors.green,
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Amount Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GlobalColors.primaryBlue,
                      GlobalColors.primaryBlue.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##,###').format(order['total_price'] ?? 0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.currency_rupee,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Date Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ordered on ${order['created_at'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(order['created_at'].toString())) : 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Pending Orders',
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadPendingOrders,
              tooltip: 'Refresh',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by customer or phone...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: GlobalColors.primaryBlue),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading pending orders...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadPendingOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _pendingOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'All Clear!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No pending orders at the moment',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Summary Cards
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  'Pending',
                                  _pendingOrders.length.toString(),
                                  Icons.pending_actions,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Total Bags',
                                  _totalBags.toString(),
                                  Icons.inventory,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildSummaryCard(
                            'Pending Amount',
                            '₹${NumberFormat('#,##,###').format(_totalPendingAmount)}',
                            Icons.currency_rupee,
                            Colors.green,
                            isFullWidth: true,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Results Count
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _searchQuery.isEmpty
                                    ? '${_filteredOrders.length} pending orders'
                                    : '${_filteredOrders.length} matches found',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Updated ${DateFormat('HH:mm').format(DateTime.now())}',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Orders List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              return _buildOrderCard(order);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isFullWidth ? 20 : 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final customerName = order['customer_name']?.toString() ?? 'Unknown Customer';
    final amount = (order['total_price'] as num?)?.toDouble() ?? 0.0;
    final category = order['feed_category']?.toString() ?? '';
    final bags = order['bags']?.toString() ?? '0';
    final createdAt = order['created_at']?.toString();
    final orderDate = createdAt != null ? DateTime.parse(createdAt) : DateTime.now();
    final timeAgo = _getTimeAgo(orderDate);
    final phone = order['customer_phone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        customerName.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'PENDING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Time Ago Row (removed order ID)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Category and Bags Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          category.isNotEmpty ? category : 'No category',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory, size: 12, color: Colors.purple.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '$bags bags',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer Row with Phone and Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (phone.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.shade200,
                        ),
                      ),
                      child: Text(
                        '₹${NumberFormat('#,##,###').format(amount)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



















// import 'package:flutter/material.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:mega_pro/services/supabase_services.dart';
// import 'package:intl/intl.dart';

// class PendingOrdersDetailsPage extends StatefulWidget {
//   final DashboardData dashboardData;
  
//   const PendingOrdersDetailsPage({super.key, required this.dashboardData});

//   @override
//   State<PendingOrdersDetailsPage> createState() => _PendingOrdersDetailsPageState();
// }

// class _PendingOrdersDetailsPageState extends State<PendingOrdersDetailsPage> {
//   final SupabaseService _supabaseService = SupabaseService();
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _pendingOrders = [];
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _loadPendingOrders();
//   }

//   Future<void> _loadPendingOrders() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _error = null;
//       });

//       _pendingOrders = await _supabaseService.getPendingOrders();
      
//       setState(() {
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _updateOrderStatus(String orderId, String newStatus) async {
//     try {
//       await _supabaseService.updateOrderStatus(orderId, newStatus);

//       _loadPendingOrders();
      
//       await _supabaseService.logActivity(
//         activityType: 'order_updated',
//         description: 'Order #$orderId status changed to $newStatus',
//       );
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Order updated to $newStatus'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to update order: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Color _getUrgencyColor(DateTime orderDate) {
//     final hoursDiff = DateTime.now().difference(orderDate).inHours;
//     if (hoursDiff > 48) return Colors.red;
//     if (hoursDiff > 24) return Colors.orange;
//     return Colors.blue;
//   }

//   String _getTimeAgo(DateTime date) {
//     final diff = DateTime.now().difference(date);
//     if (diff.inDays > 0) return '${diff.inDays}d ago';
//     if (diff.inHours > 0) return '${diff.inHours}h ago';
//     if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
//     return 'Just now';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         title: const Text(
//           'Pending Orders',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _loadPendingOrders,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.error, color: Colors.red, size: 48),
//                       const SizedBox(height: 16),
//                       Text('Error: $_error'),
//                       const SizedBox(height: 20),
//                       ElevatedButton(
//                         onPressed: _loadPendingOrders,
//                         child: const Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 )
//               : _pendingOrders.isEmpty
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.check_circle, color: Colors.green, size: 60),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'All clear!',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.green,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'No pending orders',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : Column(
//                       children: [
//                         Container(
//                           margin: const EdgeInsets.all(16),
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.orange.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: Colors.orange.withOpacity(0.3)),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(Icons.warning, color: Colors.orange.shade700, size: 32),
//                               const SizedBox(width: 16),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       '${_pendingOrders.length} Pending Orders',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w700,
//                                         color: Colors.orange.shade700,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       'Needs immediate attention',
//                                       style: TextStyle(
//                                         fontSize: 13,
//                                         color: Colors.orange.shade600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         Expanded(
//                           child: ListView.builder(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             itemCount: _pendingOrders.length,
//                             itemBuilder: (context, index) {
//                               final order = _pendingOrders[index];
//                               final orderId = order['id']?.toString() ?? 'N/A';
//                               final customerName = order['customer_name']?.toString() ?? 'Unknown';
//                               final amount = (order['total_price'] as num?)?.toDouble() ?? 0.0;
//                               final category = order['feed_category']?.toString() ?? '';
//                               final bags = order['bags']?.toString() ?? '0';
//                               final createdAt = order['created_at']?.toString();
//                               final orderDate = createdAt != null
//                                   ? DateTime.parse(createdAt)
//                                   : DateTime.now();
//                               final timeAgo = _getTimeAgo(orderDate);
//                               final isUrgent = DateTime.now().difference(orderDate).inHours > 24;

//                               return Container(
//                                 margin: const EdgeInsets.only(bottom: 12),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(12),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.05),
//                                       blurRadius: 4,
//                                       offset: const Offset(0, 2),
//                                     ),
//                                   ],
//                                   border: isUrgent
//                                       ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
//                                       : null,
//                                 ),
//                                 child: Column(
//                                   children: [
//                                     ListTile(
//                                       contentPadding: const EdgeInsets.all(16),
//                                       leading: Container(
//                                         width: 48,
//                                         height: 48,
//                                         decoration: BoxDecoration(
//                                           color: _getUrgencyColor(orderDate).withOpacity(0.1),
//                                           borderRadius: BorderRadius.circular(12),
//                                         ),
//                                         child: Icon(
//                                           isUrgent ? Icons.warning : Icons.pending,
//                                           color: _getUrgencyColor(orderDate),
//                                           size: 24,
//                                         ),
//                                       ),
//                                       title: Text(
//                                         customerName,
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.w600,
//                                           fontSize: 15,
//                                         ),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       subtitle: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           const SizedBox(height: 4),
//                                           Text(
//                                             'Order #$orderId • $timeAgo',
//                                             style: TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.grey.shade600,
//                                             ),
//                                           ),
//                                           const SizedBox(height: 4),
//                                           Wrap(
//                                             spacing: 8,
//                                             children: [
//                                               Container(
//                                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.blue.withOpacity(0.1),
//                                                   borderRadius: BorderRadius.circular(4),
//                                                 ),
//                                                 child: Text(
//                                                   '$bags bags',
//                                                   style: TextStyle(
//                                                     fontSize: 11,
//                                                     color: Colors.blue.shade700,
//                                                   ),
//                                                 ),
//                                               ),
//                                               if (category.isNotEmpty)
//                                                 Container(
//                                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                                                   decoration: BoxDecoration(
//                                                     color: Colors.green.withOpacity(0.1),
//                                                     borderRadius: BorderRadius.circular(4),
//                                                   ),
//                                                   child: Text(
//                                                     category,
//                                                     style: TextStyle(
//                                                       fontSize: 11,
//                                                       color: Colors.green.shade700,
//                                                     ),
//                                                   ),
//                                                 ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                       trailing: Column(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         crossAxisAlignment: CrossAxisAlignment.end,
//                                         children: [
//                                           Text(
//                                             '₹${NumberFormat('#,##,###').format(amount)}',
//                                             style: const TextStyle(
//                                               fontSize: 15,
//                                               fontWeight: FontWeight.w700,
//                                               color: Colors.black87,
//                                             ),
//                                           ),
//                                           const SizedBox(height: 4),
//                                           if (isUrgent)
//                                             Container(
//                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                               decoration: BoxDecoration(
//                                                 color: Colors.red.withOpacity(0.1),
//                                                 borderRadius: BorderRadius.circular(10),
//                                               ),
//                                               child: Text(
//                                                 'URGENT',
//                                                 style: TextStyle(
//                                                   fontSize: 10,
//                                                   color: Colors.red,
//                                                   fontWeight: FontWeight.w600,
//                                                 ),
//                                               ),
//                                             ),
//                                         ],
//                                       ),
//                                     ),
                                    
//                                     Padding(
//                                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                                       child: Row(
//                                         children: [
//                                           Expanded(
//                                             child: OutlinedButton.icon(
//                                               icon: const Icon(Icons.check, size: 18),
//                                               label: const Text('Complete'),
//                                               style: OutlinedButton.styleFrom(
//                                                 foregroundColor: Colors.green,
//                                                 side: BorderSide(color: Colors.green.shade300),
//                                               ),
//                                               onPressed: () {
//                                                 _updateOrderStatus(orderId, 'completed');
//                                               },
//                                             ),
//                                           ),
//                                           const SizedBox(width: 8),
//                                           Expanded(
//                                             child: OutlinedButton.icon(
//                                               icon: const Icon(Icons.local_shipping, size: 18),
//                                               label: const Text('Dispatch'),
//                                               style: OutlinedButton.styleFrom(
//                                                 foregroundColor: Colors.blue,
//                                                 side: BorderSide(color: Colors.blue.shade300),
//                                               ),
//                                               onPressed: () {
//                                                 _updateOrderStatus(orderId, 'dispatched');
//                                               },
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//     );
//   }
// }









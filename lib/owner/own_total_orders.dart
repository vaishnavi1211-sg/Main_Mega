import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:mega_pro/services/supabase_services.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatefulWidget {
  final DashboardData dashboardData;
  
  const OrderDetailsPage({super.key, required this.dashboardData});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  
  final List<String> _statusFilters = ['All', 'Pending', 'Completed', 'Dispatched', 'Cancelled'];
  String _selectedStatus = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String? _error;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
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

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _orders = await _supabaseService.getAllOrders();
      
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
    var filtered = _orders;
    
    // Apply status filter
    if (_selectedStatus != 'All') {
      filtered = filtered.where((order) {
        final status = (order['status'] as String?)?.toLowerCase() ?? '';
        return status == _selectedStatus.toLowerCase();
      }).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((order) {
        final customerName = (order['customer_name'] as String?)?.toLowerCase() ?? '';
        final phone = (order['customer_phone'] as String?)?.toLowerCase() ?? '';
        final category = (order['feed_category'] as String?)?.toLowerCase() ?? '';
        return customerName.contains(query) || phone.contains(query) || category.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  Map<String, int> get _orderStats {
    int total = _orders.length;
    int pending = _orders.where((o) => (o['status'] as String?)?.toLowerCase() == 'pending').length;
    int completed = _orders.where((o) => (o['status'] as String?)?.toLowerCase() == 'completed').length;
    int dispatched = _orders.where((o) => (o['status'] as String?)?.toLowerCase() == 'dispatched').length;
    int cancelled = _orders.where((o) => (o['status'] as String?)?.toLowerCase() == 'cancelled').length;
    
    return {
      'total': total,
      'pending': pending,
      'completed': completed,
      'dispatched': dispatched,
      'cancelled': cancelled,
    };
  }

  double get _totalRevenue {
    return _orders.fold(0.0, (sum, order) {
      return sum + ((order['total_price'] as num?)?.toDouble() ?? 0.0);
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'dispatched':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'dispatched':
        return Icons.local_shipping;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_cart;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Order Management',
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
              onPressed: _loadOrders,
              tooltip: 'Refresh',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              // Search Bar
              Padding(
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
                      hintText: 'Search by customer name or phone...',
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
            ],
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
                    'Loading orders...',
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
                        onPressed: _loadOrders,
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
              : _filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off : Icons.shopping_cart,
                              color: Colors.grey.shade400,
                              size: 60,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty ? 'No matching orders found' : 'No orders yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? 'Try adjusting your search'
                                : 'Orders will appear here once created',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Filter Chips
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.white,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _statusFilters.map((status) {
                                final isSelected = _selectedStatus == status;
                                final statusColor = status == 'All' 
                                    ? GlobalColors.primaryBlue 
                                    : _getStatusColor(status);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(status),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedStatus = status;
                                      });
                                    },
                                    backgroundColor: Colors.grey.shade50,
                                    selectedColor: statusColor.withOpacity(0.1),
                                    checkmarkColor: statusColor,
                                    labelStyle: TextStyle(
                                      color: isSelected ? statusColor : Colors.grey.shade700,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected ? statusColor : Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
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
                                '${_filteredOrders.length} orders found',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSummaryDialog,
        backgroundColor: GlobalColors.primaryBlue,
        icon: const Icon(Icons.analytics, color: Colors.white),
        label: const Text(
          'Summary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final customerName = order['customer_name']?.toString() ?? 'Unknown Customer';
    final amount = (order['total_price'] as num?)?.toDouble() ?? 0.0;
    final status = order['status']?.toString() ?? 'pending';
    final createdAt = order['created_at']?.toString();
    final date = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAt))
        : 'Date N/A';
    final bags = order['bags']?.toString() ?? '0';
    
    final statusColor = _getStatusColor(status);
    
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
                // Customer Name and Status Row
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Date Row
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Bags and Amount Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bags
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory, size: 12, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '$bags bags',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Amount
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

  void _showSummaryDialog() {
    final stats = _orderStats;
    final totalRevenue = _totalRevenue;
    
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
                    'Order Summary',
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
              
              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildSummaryCard(
                    'Total Orders',
                    stats['total'].toString(),
                    Icons.shopping_cart,
                    GlobalColors.primaryBlue,
                  ),
                  _buildSummaryCard(
                    'Pending',
                    stats['pending'].toString(),
                    Icons.pending,
                    const Color(0xFFF59E0B),
                  ),
                  _buildSummaryCard(
                    'Completed',
                    stats['completed'].toString(),
                    Icons.check_circle,
                    const Color(0xFF10B981),
                  ),
                  _buildSummaryCard(
                    'Dispatched',
                    stats['dispatched'].toString(),
                    Icons.local_shipping,
                    const Color(0xFF3B82F6),
                  ),
                  _buildSummaryCard(
                    'Cancelled',
                    stats['cancelled'].toString(),
                    Icons.cancel,
                    const Color(0xFFEF4444),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Revenue Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade600,
                      Colors.green.shade800,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Revenue',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##,###').format(totalRevenue)}',
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
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order['status']?.toString() ?? '').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatusIcon(order['status']?.toString() ?? ''),
                          color: _getStatusColor(order['status']?.toString() ?? ''),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['customer_name']?.toString() ?? 'Order Details',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Order placed on ${order['created_at'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(order['created_at'].toString())) : 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Details
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildDetailSection(
                          'Customer Information',
                          [
                            {'label': 'Name', 'value': order['customer_name']?.toString() ?? 'N/A', 'icon': Icons.person},
                            {'label': 'Phone', 'value': order['customer_phone']?.toString() ?? 'N/A', 'icon': Icons.phone},
                            {'label': 'Email', 'value': order['customer_email']?.toString() ?? 'N/A', 'icon': Icons.email},
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildDetailSection(
                          'Order Information',
                          [
                            {'label': 'Category', 'value': order['feed_category']?.toString() ?? 'N/A', 'icon': Icons.category},
                            {'label': 'Bags', 'value': order['bags']?.toString() ?? '0', 'icon': Icons.inventory},
                            {'label': 'Payment Method', 'value': order['payment_method']?.toString() ?? 'N/A', 'icon': Icons.payment},
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildDetailSection(
                          'Status & Timeline',
                          [
                            {'label': 'Status', 'value': order['status']?.toString() ?? 'pending', 'icon': Icons.info},
                            {'label': 'Created', 'value': order['created_at'] != null
                                ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(order['created_at'].toString()))
                                : 'N/A', 'icon': Icons.access_time},
                            {'label': 'Last Updated', 'value': order['updated_at'] != null
                                ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(order['updated_at'].toString()))
                                : 'N/A', 'icon': Icons.update},
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Amount Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade600,
                                Colors.green.shade800,
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
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Close Button
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
      },
    );
  }

  Widget _buildDetailSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final isStatus = item['label'] == 'Status';
              final statusColor = isStatus 
                  ? _getStatusColor(item['value'] as String)
                  : null;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${item['label']}:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isStatus
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['value'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              item['value'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

















// import 'package:flutter/material.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:mega_pro/services/supabase_services.dart';
// import 'package:intl/intl.dart';

// class OrderDetailsPage extends StatefulWidget {
//   final DashboardData dashboardData;
  
//   const OrderDetailsPage({super.key, required this.dashboardData});

//   @override
//   State<OrderDetailsPage> createState() => _OrderDetailsPageState();
// }

// class _OrderDetailsPageState extends State<OrderDetailsPage> with SingleTickerProviderStateMixin {
//   final SupabaseService _supabaseService = SupabaseService();
//   late TabController _tabController;
  
//   final List<String> _statusFilters = ['All', 'Pending', 'Completed', 'Dispatched', 'Cancelled'];
//   String _selectedStatus = 'All';
//   String _searchQuery = '';
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _orders = [];
//   String? _error;
  
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _loadOrders();
//     _searchController.addListener(_onSearchChanged);
//   }

//   void _onSearchChanged() {
//     setState(() {
//       _searchQuery = _searchController.text;
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadOrders() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _error = null;
//       });

//       _orders = await _supabaseService.getAllOrders();
      
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

//   List<Map<String, dynamic>> get _filteredOrders {
//     var filtered = _orders;
    
//     // Apply status filter
//     if (_selectedStatus != 'All') {
//       filtered = filtered.where((order) {
//         final status = (order['status'] as String?)?.toLowerCase() ?? '';
//         return status == _selectedStatus.toLowerCase();
//       }).toList();
//     }
    
//     // Apply search filter
//     if (_searchQuery.isNotEmpty) {
//       final query = _searchQuery.toLowerCase();
//       filtered = filtered.where((order) {
//         final customerName = (order['customer_name'] as String?)?.toLowerCase() ?? '';
//         final phone = (order['customer_phone'] as String?)?.toLowerCase() ?? '';
//         final category = (order['feed_category'] as String?)?.toLowerCase() ?? '';
//         return customerName.contains(query) || phone.contains(query) || category.contains(query);
//       }).toList();
//     }
    
//     return filtered;
//   }

//   Map<String, int> get _orderStats {
//     int total = _orders.length;
//     int pending = _orders.where((o) => (o['status'] as String?)?.toLowerCase() == 'pending').length;
//     int completed = _orders.where((o) => (o['status'] as String?)?.toLowerCase() == 'completed').length;
//     int dispatched = _orders.where((o) => (o['status'] as String?)?.toLowerCase() == 'dispatched').length;
//     int cancelled = _orders.where((o) => (o['status'] as String?)?.toLowerCase() == 'cancelled').length;
    
//     return {
//       'total': total,
//       'pending': pending,
//       'completed': completed,
//       'dispatched': dispatched,
//       'cancelled': cancelled,
//     };
//   }

//   double get _totalRevenue {
//     return _orders.fold(0.0, (sum, order) {
//       return sum + ((order['total_price'] as num?)?.toDouble() ?? 0.0);
//     });
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'completed':
//         return const Color(0xFF10B981);
//       case 'pending':
//         return const Color(0xFFF59E0B);
//       case 'dispatched':
//         return const Color(0xFF3B82F6);
//       case 'cancelled':
//         return const Color(0xFFEF4444);
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getStatusIcon(String status) {
//     switch (status.toLowerCase()) {
//       case 'completed':
//         return Icons.check_circle;
//       case 'pending':
//         return Icons.pending;
//       case 'dispatched':
//         return Icons.local_shipping;
//       case 'cancelled':
//         return Icons.cancel;
//       default:
//         return Icons.shopping_cart;
//     }
//   }

//   String _truncateText(String text, int maxLength) {
//     if (text.length <= maxLength) return text;
//     return '${text.substring(0, maxLength)}...';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final stats = _orderStats;
    
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         title: const Text(
//           'Order Management',
//           style: TextStyle(
//             color: Colors.white, 
//             fontWeight: FontWeight.w600,
//             fontSize: 20,
//           ),
//         ),
//         leading: IconButton(
//           icon: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 8),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: IconButton(
//               icon: const Icon(Icons.refresh, color: Colors.white),
//               onPressed: _loadOrders,
//               tooltip: 'Refresh',
//             ),
//           ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(80),
//           child: Column(
//             children: [
//               // Search Bar
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 10,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: 'Search by customer name or phone...',
//                       hintStyle: TextStyle(color: Colors.grey.shade400),
//                       prefixIcon: const Icon(Icons.search, color: GlobalColors.primaryBlue),
//                       suffixIcon: _searchQuery.isNotEmpty
//                           ? IconButton(
//                               icon: const Icon(Icons.clear, color: Colors.grey),
//                               onPressed: () {
//                                 _searchController.clear();
//                               },
//                             )
//                           : null,
//                       border: InputBorder.none,
//                       contentPadding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: _isLoading
//           ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text(
//                     'Loading orders...',
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             )
//           : _error != null
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.red.shade50,
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Failed to load orders',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey.shade800,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 32),
//                         child: Text(
//                           _error!,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(color: Colors.grey.shade600),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       ElevatedButton.icon(
//                         onPressed: _loadOrders,
//                         icon: const Icon(Icons.refresh),
//                         label: const Text('Try Again'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: GlobalColors.primaryBlue,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               : _filteredOrders.isEmpty
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade100,
//                               shape: BoxShape.circle,
//                             ),
//                             child: Icon(
//                               _searchQuery.isNotEmpty ? Icons.search_off : Icons.shopping_cart,
//                               color: Colors.grey.shade400,
//                               size: 60,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             _searchQuery.isNotEmpty ? 'No matching orders found' : 'No orders yet',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey.shade800,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             _searchQuery.isNotEmpty 
//                                 ? 'Try adjusting your search'
//                                 : 'Orders will appear here once created',
//                             style: TextStyle(color: Colors.grey.shade600),
//                           ),
//                         ],
//                       ),
//                     )
//                   : Column(
//                       children: [
//                         // Filter Tabs
//                         Container(
//                           color: Colors.white,
//                           child: TabBar(
//                             controller: _tabController,
//                             indicatorColor: GlobalColors.primaryBlue,
//                             indicatorWeight: 3,
//                             labelColor: GlobalColors.primaryBlue,
//                             unselectedLabelColor: Colors.grey.shade600,
//                             labelStyle: const TextStyle(fontWeight: FontWeight.w600),
//                             tabs: [
//                               Tab(
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     const Icon(Icons.shopping_cart, size: 18),
//                                     const SizedBox(width: 8),
//                                     Text('All (${stats['total']})'),
//                                   ],
//                                 ),
//                               ),
//                               Tab(
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Container(
//                                       width: 8,
//                                       height: 8,
//                                       decoration: const BoxDecoration(
//                                         color: Color(0xFFF59E0B),
//                                         shape: BoxShape.circle,
//                                       ),
//                                     ),
//                                     const SizedBox(width: 8),
//                                     Text('Pending (${stats['pending']})'),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
                        
//                         // Filter Chips
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                           color: Colors.white,
//                           child: SingleChildScrollView(
//                             scrollDirection: Axis.horizontal,
//                             child: Row(
//                               children: _statusFilters.map((status) {
//                                 final isSelected = _selectedStatus == status;
//                                 final statusColor = status == 'All' 
//                                     ? GlobalColors.primaryBlue 
//                                     : _getStatusColor(status);
                                
//                                 return Padding(
//                                   padding: const EdgeInsets.only(right: 8),
//                                   child: FilterChip(
//                                     label: Text(status),
//                                     selected: isSelected,
//                                     onSelected: (selected) {
//                                       setState(() {
//                                         _selectedStatus = status;
//                                       });
//                                     },
//                                     backgroundColor: Colors.grey.shade50,
//                                     selectedColor: statusColor.withOpacity(0.1),
//                                     checkmarkColor: statusColor,
//                                     labelStyle: TextStyle(
//                                       color: isSelected ? statusColor : Colors.grey.shade700,
//                                       fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(20),
//                                       side: BorderSide(
//                                         color: isSelected ? statusColor : Colors.grey.shade300,
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                           ),
//                         ),
                        
//                         const SizedBox(height: 8),
                        
//                         // Results Count
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 '${_filteredOrders.length} orders found',
//                                 style: TextStyle(
//                                   color: Colors.grey.shade600,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                               Text(
//                                 'Updated ${DateFormat('HH:mm').format(DateTime.now())}',
//                                 style: TextStyle(
//                                   color: Colors.grey.shade400,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
                        
//                         const SizedBox(height: 8),
                        
//                         // Orders List
//                         Expanded(
//                           child: ListView.builder(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             itemCount: _filteredOrders.length,
//                             itemBuilder: (context, index) {
//                               final order = _filteredOrders[index];
//                               return _buildOrderCard(order);
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _showSummaryDialog,
//         backgroundColor: GlobalColors.primaryBlue,
//         icon: const Icon(Icons.analytics, color: Colors.white),
//         label: const Text(
//           'Summary',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }

//   Widget _buildOrderCard(Map<String, dynamic> order) {
//     final customerName = order['customer_name']?.toString() ?? 'Unknown Customer';
//     final amount = (order['total_price'] as num?)?.toDouble() ?? 0.0;
//     final status = order['status']?.toString() ?? 'pending';
//     final createdAt = order['created_at']?.toString();
//     final date = createdAt != null
//         ? DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAt))
//         : 'Date N/A';
//     final category = order['feed_category']?.toString() ?? '';
//     final bags = order['bags']?.toString() ?? '0';
    
//     final statusColor = _getStatusColor(status);
    
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () => _showOrderDetails(order),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Customer Name and Status Row
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         customerName.toUpperCase(),
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 16,
//                           color: Colors.black87,
//                           letterSpacing: 0.5,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: statusColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: statusColor.withOpacity(0.3),
//                           width: 1,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Container(
//                             width: 8,
//                             height: 8,
//                             decoration: BoxDecoration(
//                               color: statusColor,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             status.toUpperCase(),
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: FontWeight.w600,
//                               color: statusColor,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
                
//                 const SizedBox(height: 12),
                
//                 // Date Row
//                 Row(
//                   children: [
//                     Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
//                     const SizedBox(width: 6),
//                     Text(
//                       date,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade600,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
                
//                 const SizedBox(height: 10),
                
//                 // Category and Bags Row
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.withOpacity(0.08),
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(
//                             color: Colors.blue.withOpacity(0.2),
//                           ),
//                         ),
//                         child: Text(
//                           category.isNotEmpty ? _truncateText(category, 25) : 'No category',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.blue.shade700,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.08),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: Colors.green.withOpacity(0.2),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.inventory, size: 12, color: Colors.green.shade700),
//                           const SizedBox(width: 4),
//                           Text(
//                             '$bags bags',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.green.shade700,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
                
//                 const SizedBox(height: 12),
                
//                 // Amount
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade50,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: Colors.green.shade200,
//                         ),
//                       ),
//                       child: Text(
//                         '₹${NumberFormat('#,##,###').format(amount)}',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.green.shade800,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showSummaryDialog() {
//     final stats = _orderStats;
//     final totalRevenue = _totalRevenue;
    
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Order Summary',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
              
//               // Stats Grid
//               GridView.count(
//                 shrinkWrap: true,
//                 crossAxisCount: 2,
//                 childAspectRatio: 1.5,
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//                 children: [
//                   _buildSummaryCard(
//                     'Total Orders',
//                     stats['total'].toString(),
//                     Icons.shopping_cart,
//                     GlobalColors.primaryBlue,
//                   ),
//                   _buildSummaryCard(
//                     'Pending',
//                     stats['pending'].toString(),
//                     Icons.pending,
//                     const Color(0xFFF59E0B),
//                   ),
//                   _buildSummaryCard(
//                     'Completed',
//                     stats['completed'].toString(),
//                     Icons.check_circle,
//                     const Color(0xFF10B981),
//                   ),
//                   _buildSummaryCard(
//                     'Dispatched',
//                     stats['dispatched'].toString(),
//                     Icons.local_shipping,
//                     const Color(0xFF3B82F6),
//                   ),
//                   _buildSummaryCard(
//                     'Cancelled',
//                     stats['cancelled'].toString(),
//                     Icons.cancel,
//                     const Color(0xFFEF4444),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: 20),
              
//               // Revenue Card
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.green.shade600,
//                       Colors.green.shade800,
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Total Revenue',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.8),
//                             fontSize: 14,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           '₹${NumberFormat('#,##,###').format(totalRevenue)}',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Icon(
//                         Icons.currency_rupee,
//                         color: Colors.white,
//                         size: 30,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               const SizedBox(height: 16),
              
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: GlobalColors.primaryBlue,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text(
//                     'Close',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: color.withOpacity(0.2),
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showOrderDetails(Map<String, dynamic> order) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return DraggableScrollableSheet(
//           initialChildSize: 0.7,
//           minChildSize: 0.5,
//           maxChildSize: 0.9,
//           expand: false,
//           builder: (context, scrollController) {
//             return Container(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   // Handle
//                   Container(
//                     width: 40,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade300,
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // Header
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: _getStatusColor(order['status']?.toString() ?? '').withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           _getStatusIcon(order['status']?.toString() ?? ''),
//                           color: _getStatusColor(order['status']?.toString() ?? ''),
//                           size: 24,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               order['customer_name']?.toString() ?? 'Order Details',
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             Text(
//                               'Order placed on ${order['created_at'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(order['created_at'].toString())) : 'N/A'}',
//                               style: TextStyle(
//                                 color: Colors.grey.shade600,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 24),
                  
//                   // Details
//                   Expanded(
//                     child: ListView(
//                       controller: scrollController,
//                       children: [
//                         _buildDetailSection(
//                           'Customer Information',
//                           [
//                             {'label': 'Name', 'value': order['customer_name']?.toString() ?? 'N/A', 'icon': Icons.person},
//                             {'label': 'Phone', 'value': order['customer_phone']?.toString() ?? 'N/A', 'icon': Icons.phone},
//                             {'label': 'Email', 'value': order['customer_email']?.toString() ?? 'N/A', 'icon': Icons.email},
//                           ],
//                         ),
                        
//                         const SizedBox(height: 16),
                        
//                         _buildDetailSection(
//                           'Order Information',
//                           [
//                             {'label': 'Category', 'value': order['feed_category']?.toString() ?? 'N/A', 'icon': Icons.category},
//                             {'label': 'Bags', 'value': order['bags']?.toString() ?? '0', 'icon': Icons.inventory},
//                             {'label': 'Payment Method', 'value': order['payment_method']?.toString() ?? 'N/A', 'icon': Icons.payment},
//                           ],
//                         ),
                        
//                         const SizedBox(height: 16),
                        
//                         _buildDetailSection(
//                           'Status & Timeline',
//                           [
//                             {'label': 'Status', 'value': order['status']?.toString() ?? 'pending', 'icon': Icons.info},
//                             {'label': 'Created', 'value': order['created_at'] != null
//                                 ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(order['created_at'].toString()))
//                                 : 'N/A', 'icon': Icons.access_time},
//                             {'label': 'Last Updated', 'value': order['updated_at'] != null
//                                 ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(order['updated_at'].toString()))
//                                 : 'N/A', 'icon': Icons.update},
//                           ],
//                         ),
                        
//                         const SizedBox(height: 16),
                        
//                         // Amount Card
//                         Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.green.shade600,
//                                 Colors.green.shade800,
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Total Amount',
//                                     style: TextStyle(
//                                       color: Colors.white.withOpacity(0.8),
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     '₹${NumberFormat('#,##,###').format(order['total_price'] ?? 0)}',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 28,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               Container(
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white.withOpacity(0.2),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Icon(
//                                   Icons.receipt_long,
//                                   color: Colors.white,
//                                   size: 30,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
                  
//                   const SizedBox(height: 16),
                  
//                   // Close Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: GlobalColors.primaryBlue,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         'Close',
//                         style: TextStyle(color: Colors.white, fontSize: 16),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildDetailSection(String title, List<Map<String, dynamic>> items) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: items.length,
//             separatorBuilder: (context, index) => Divider(
//               height: 1,
//               color: Colors.grey.shade200,
//             ),
//             itemBuilder: (context, index) {
//               final item = items[index];
//               final isStatus = item['label'] == 'Status';
//               final statusColor = isStatus 
//                   ? _getStatusColor(item['value'] as String)
//                   : null;
              
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 child: Row(
//                   children: [
//                     Icon(
//                       item['icon'] as IconData,
//                       size: 18,
//                       color: Colors.grey.shade500,
//                     ),
//                     const SizedBox(width: 12),
//                     SizedBox(
//                       width: 100,
//                       child: Text(
//                         '${item['label']}:',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: isStatus
//                           ? Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: statusColor!.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Container(
//                                     width: 6,
//                                     height: 6,
//                                     decoration: BoxDecoration(
//                                       color: statusColor,
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     item['value'],
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w500,
//                                       color: statusColor,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             )
//                           : Text(
//                               item['value'],
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black87,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }


















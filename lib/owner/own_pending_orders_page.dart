import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:mega_pro/services/supabase_services.dart';
import 'package:intl/intl.dart';

class PendingOrdersDetailsPage extends StatefulWidget {
  const PendingOrdersDetailsPage({super.key, required DashboardData dashboardData});

  @override
  State<PendingOrdersDetailsPage> createState() => _PendingOrdersDetailsPageState();
}

class _PendingOrdersDetailsPageState extends State<PendingOrdersDetailsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingOrders = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingOrders();
  }

  Future<void> _loadPendingOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use the service method
      _pendingOrders = (await _supabaseService.getPendingOrders());
      
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

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabaseService.updateOrderStatus(orderId, newStatus);

      // Refresh the list
      _loadPendingOrders();
      
      // Log activity
      await _supabaseService.logActivity(
        activityType: 'order_updated',
        description: 'Order #$orderId status changed to $newStatus',
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getUrgencyColor(DateTime orderDate) {
    final hoursDiff = DateTime.now().difference(orderDate).inHours;
    if (hoursDiff > 48) return Colors.red;
    if (hoursDiff > 24) return Colors.orange;
    return Colors.blue;
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPendingOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadPendingOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 60),
                          const SizedBox(height: 16),
                          const Text(
                            'All clear!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No pending orders',
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
                        // Summary Card
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange.shade700, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_pendingOrders.length} Pending Orders',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Needs immediate attention',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Orders List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _pendingOrders.length,
                            itemBuilder: (context, index) {
                              final order = _pendingOrders[index];
                              final orderId = order['id']?.toString() ?? 'N/A';
                              final customerName = order['customer_name']?.toString() ?? 'Unknown';
                              final amount = (order['total_price'] as num?)?.toDouble() ?? 0.0;
                              final category = order['feed_category']?.toString() ?? '';
                              final bags = order['bags']?.toString() ?? '0';
                              final createdAt = order['created_at']?.toString();
                              final orderDate = createdAt != null
                                  ? DateTime.parse(createdAt)
                                  : DateTime.now();
                              final timeAgo = _getTimeAgo(orderDate);
                              final isUrgent = DateTime.now().difference(orderDate).inHours > 24;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: isUrgent
                                      ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _getUrgencyColor(orderDate).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isUrgent ? Icons.warning : Icons.pending,
                                          color: _getUrgencyColor(orderDate),
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        customerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            'Order #$orderId • $timeAgo',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '$bags bags',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                ),
                                              ),
                                              if (category.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    category,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.green.shade700,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${NumberFormat('#,##,###').format(amount)}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (isUrgent)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                'URGENT',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Action Buttons
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.check, size: 18),
                                              label: const Text('Complete'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.green,
                                                side: BorderSide(color: Colors.green.shade300),
                                              ),
                                              onPressed: () {
                                                _updateOrderStatus(orderId, 'completed');
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.local_shipping, size: 18),
                                              label: const Text('Dispatch'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.blue,
                                                side: BorderSide(color: Colors.blue.shade300),
                                              ),
                                              onPressed: () {
                                                _updateOrderStatus(orderId, 'dispatched');
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
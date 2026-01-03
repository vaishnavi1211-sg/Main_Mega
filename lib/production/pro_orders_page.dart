import 'package:flutter/material.dart';
import 'package:mega_pro/providers/pro_orders_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductionOrdersPage extends StatefulWidget {
  const ProductionOrdersPage({super.key, required Map productionProfile, required Null Function() onDataChanged});

  @override
  State<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
}

class _ProductionOrdersPageState extends State<ProductionOrdersPage> {
  Map<String, bool> _selectedOrders = {};
  bool _isSelectionMode = false;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSelectedOrders();
    });
  }
  
  void _loadSelectedOrders() {
    // Changed to ProductionOrdersProvider
    final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: false);
    _selectedOrders.clear();
    for (var order in ordersProvider.orders) {
      _selectedOrders[order.id] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('=== ProductionOrdersPage build called ===');
    print('_isSelectionMode: $_isSelectionMode');
    
    // Changed to ProductionOrdersProvider
    final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: true);
    print('ordersProvider.isLoading: ${ordersProvider.isLoading}');
    print('ordersProvider.error: ${ordersProvider.error}');
    print('ordersProvider.orders.length: ${ordersProvider.orders.length}');
    print('ordersProvider.filteredOrders.length: ${ordersProvider.filteredOrders.length}');
    
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text(
                'Select Orders',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              )
            : Text(
                'Production Orders',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
        backgroundColor: _isSelectionMode ? GlobalColors.primaryBlue.withOpacity(0.9) : GlobalColors.primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedOrders.updateAll((key, value) => false);
                      _selectAll = false;
                    });
                  },
                  tooltip: 'Cancel Selection',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Changed to ProductionOrdersProvider
                    Provider.of<ProductionOrdersProvider>(context, listen: false).refresh();
                  },
                ),
              ],
      ),
      body: Consumer<ProductionOrdersProvider>( // Changed to ProductionOrdersProvider
        builder: (context, ordersProvider, child) {
          if (ordersProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Orders',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ordersProvider.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ordersProvider.refresh(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalColors.primaryBlue,
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              if (!_isSelectionMode) _buildStatistics(ordersProvider),
              
              if (!_isSelectionMode) _buildFilterTabs(ordersProvider),
              
              if (_isSelectionMode) _buildBulkSelectionToolbar(ordersProvider),
              
              Expanded(child: _buildOrdersList(ordersProvider)),
            ],
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: () {
                final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
                if (selectedCount > 0) {
                  // Changed to ProductionOrdersProvider
                  _showBulkStatusUpdateDialog(context.read<ProductionOrdersProvider>());
                }
              },
              backgroundColor: GlobalColors.primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.check_circle),
              label: Text(
                'Update ${_selectedOrders.values.where((isSelected) => isSelected).length}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
    );
  }

  // Changed parameter type to ProductionOrdersProvider
  Widget _buildStatistics(ProductionOrdersProvider ordersProvider) {
    final stats = ordersProvider.getStatistics();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statCard('Total', stats['total']!, Colors.blue, Icons.receipt),
            const SizedBox(width: 12),
            _statCard('Pending', stats['pending']!, Colors.orange, Icons.pending),
            const SizedBox(width: 12),
            _statCard('Packing', stats['packing']!, Colors.blue, Icons.inventory),
            const SizedBox(width: 12),
            _statCard('Ready', stats['ready_for_dispatch']!, Colors.purple, Icons.local_shipping),
            const SizedBox(width: 12),
            _statCard('Dispatched', stats['dispatched']!, Colors.indigo, Icons.directions_car),
            const SizedBox(width: 12),
            _statCard('Delivered', stats['delivered']!, Colors.green, Icons.check_circle),
            const SizedBox(width: 12),
            _statCard('Completed', stats['completed']!, Colors.green, Icons.done_all),
            const SizedBox(width: 12),
            _statCard('Cancelled', stats['cancelled']!, Colors.red, Icons.cancel),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // Changed parameter type to ProductionOrdersProvider
  Widget _buildFilterTabs(ProductionOrdersProvider ordersProvider) {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Packing', 'value': 'packing'},
      {'label': 'Ready', 'value': 'ready_for_dispatch'},
      {'label': 'Dispatched', 'value': 'dispatched'},
      {'label': 'Delivered', 'value': 'delivered'},
      {'label': 'Completed', 'value': 'completed'},
      {'label': 'Cancelled', 'value': 'cancelled'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = ordersProvider.filter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  filter['label']!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
                selected: isSelected,
                selectedColor: GlobalColors.primaryBlue,
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (selected) {
                  ordersProvider.setFilter(filter['value']!);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Changed parameter type to ProductionOrdersProvider
  Widget _buildBulkSelectionToolbar(ProductionOrdersProvider ordersProvider) {
    final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: GlobalColors.primaryBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: _selectAll,
            onChanged: (value) {
              setState(() {
                _selectAll = value ?? false;
                for (var order in ordersProvider.filteredOrders) {
                  _selectedOrders[order.id] = _selectAll;
                }
              });
            },
            activeColor: Colors.white,
            checkColor: GlobalColors.primaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectAll 
                  ? 'All ${ordersProvider.filteredOrders.length} selected'
                  : '$selectedCount selected',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Changed parameter type to ProductionOrdersProvider
  Widget _buildOrdersList(ProductionOrdersProvider ordersProvider) {
    if (ordersProvider.isLoading && ordersProvider.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: GlobalColors.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Loading orders...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (ordersProvider.filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ordersProvider.filter == 'all'
                  ? 'No orders available'
                  : 'No ${ordersProvider.filter.replaceAll('_', ' ')} orders',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: GlobalColors.primaryBlue,
      onRefresh: () async {
        await ordersProvider.refresh();
        _loadSelectedOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ordersProvider.filteredOrders.length,
        itemBuilder: (context, index) {
          final order = ordersProvider.filteredOrders[index];
          // Changed to ProductionOrderItem
          return _buildOrderCard(order, context, ordersProvider);
        },
      ),
    );
  }

  // Changed parameter type from OrderItem to ProductionOrderItem
  Widget _buildOrderCard(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
    final isSelected = _selectedOrders[order.id] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
        border: _isSelectionMode && isSelected
            ? Border.all(color: GlobalColors.primaryBlue, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                _selectedOrders[order.id] = !isSelected;
              });
            } else {
              _showOrderDetails(order, context, ordersProvider);
            }
          },
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedOrders[order.id] = true;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 4),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          _selectedOrders[order.id] = value ?? false;
                        });
                      },
                      activeColor: GlobalColors.primaryBlue,
                    ),
                  ),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${order.id.substring(0, 8)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: order.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: order.statusColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(order.statusIcon, size: 14, color: order.statusColor),
                                const SizedBox(width: 6),
                                Text(
                                  order.displayStatus,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: order.statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _infoRow('Customer:', order.customerName),
                      _infoRow('Product:', order.productName),
                      _infoRow('Bags:', order.displayQuantity),
                      
                      if (order.customerMobile.isNotEmpty)
                        _infoRow('Mobile:', order.customerMobile),
                      
                      if (order.customerAddress.isNotEmpty)
                        _infoRow('Address:', order.customerAddress),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${order.totalPrice}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  Text(
                                    'Total Price',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${order.pricePerBag}/bag',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Text(
                                    'Price per Bag',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (!_isSelectionMode && 
                          order.status.toLowerCase() != 'completed' &&
                          order.status.toLowerCase() != 'cancelled')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showStatusUpdateDialog(order, context, ordersProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Update Status',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Changed parameter types from OrderItem to ProductionOrderItem and OrdersProvider to ProductionOrdersProvider
  Future<void> _showStatusUpdateDialog(
    ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) async {
  final statusOptions = ordersProvider.getNextStatusOptions(order);
  
  Map<String, String> statusDisplayNames = {
    'pending': 'Pending',
    'packing': 'Packing',
    'ready_for_dispatch': 'Ready for Dispatch',
    'dispatched': 'Dispatched',
    'delivered': 'Delivered',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };
  
  if (statusOptions.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No status updates available for this order'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Add this to make it scrollable
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height
        ),
        child: SingleChildScrollView( // Make it scrollable
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Update Order Status',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current: ${order.displayStatus}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: order.statusColor,
                  ),
                ),
                const SizedBox(height: 20),
                
                ...statusOptions.map((status) {
                  final displayName = statusDisplayNames[status] ?? status;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4), // Add some padding
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        size: 20,
                        color: _getStatusColor(status),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      Navigator.pop(context);
                      await _updateOrderStatus(
                        order,
                        status,
                        context,
                        ordersProvider,
                      );
                    },
                  );
                }).toList(),
                
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  // Changed parameter types from OrderItem to ProductionOrderItem and OrdersProvider to ProductionOrdersProvider
  Future<void> _updateOrderStatus(
      ProductionOrderItem order, String newStatus, BuildContext context, ProductionOrdersProvider ordersProvider) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await ordersProvider.updateOrderStatus(order, newStatus);
      
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        final displayNames = {
          'pending': 'Pending',
          'packing': 'Packing',
          'ready_for_dispatch': 'Ready for Dispatch',
          'dispatched': 'Dispatched',
          'delivered': 'Delivered',
          'completed': 'Completed',
          'cancelled': 'Cancelled',
        };
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Order status updated to ${displayNames[newStatus] ?? newStatus}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Changed parameter type from OrdersProvider to ProductionOrdersProvider
  Future<void> _showBulkStatusUpdateDialog(ProductionOrdersProvider ordersProvider) async {
  final selectedOrderIds = _selectedOrders.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
  
  if (selectedOrderIds.isEmpty) return;
  
  Map<String, String> statusDisplayNames = {
    'pending': 'Pending',
    'packing': 'Packing',
    'ready_for_dispatch': 'Ready for Dispatch',
    'dispatched': 'Dispatched',
    'delivered': 'Delivered',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };
  
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Make it scrollable
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bulk Update Status',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Updating ${selectedOrderIds.length} orders',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                
                Text(
                  'Select New Status:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status options for bulk update
                Column(
                  children: ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled']
                      .map((status) {
                    final displayName = statusDisplayNames[status] ?? status;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getStatusIcon(status),
                          size: 20,
                          color: _getStatusColor(status),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        Navigator.pop(context);
                        await _updateBulkOrderStatus(selectedOrderIds, status, ordersProvider);
                      },
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  // Changed parameter type from OrdersProvider to ProductionOrdersProvider
  Future<void> _updateBulkOrderStatus(
      List<String> orderIds, 
      String newStatus, 
      ProductionOrdersProvider ordersProvider) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Update all selected orders
      await ordersProvider.updateBulkOrderStatus(orderIds, newStatus);
      
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      setState(() {
        _isSelectionMode = false;
        _selectedOrders.updateAll((key, value) => false);
        _selectAll = false;
      });

      if (context.mounted) {
        final displayNames = {
          'pending': 'Pending',
          'packing': 'Packing',
          'ready_for_dispatch': 'Ready for Dispatch',
          'dispatched': 'Dispatched',
          'delivered': 'Delivered',
          'completed': 'Completed',
          'cancelled': 'Cancelled',
        };
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${orderIds.length} orders updated to ${displayNames[newStatus] ?? newStatus}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Changed parameter types from OrderItem to ProductionOrderItem and OrdersProvider to ProductionOrdersProvider
  void _showOrderDetails(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: GlobalColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: GlobalColors.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '#${order.id.substring(0, 8)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: order.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: order.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      order.displayStatus,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: order.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _detailRow('Customer Name', order.customerName, Icons.person),
              _detailRow('Customer Mobile', order.customerMobile, Icons.phone),
              _detailRow('Customer Address', order.customerAddress, Icons.location_on),
              
              _detailRow('Product', order.productName, Icons.inventory),
              _detailRow('Bags', '${order.bags} Bags', Icons.shopping_bag),
              _detailRow('Weight per Bag', '${order.weightPerBag} ${order.weightUnit}', Icons.scale),
              _detailRow('Total Weight', '${order.totalWeight} ${order.weightUnit}', Icons.scale),
              _detailRow('Price per Bag', '₹${order.pricePerBag}', Icons.currency_rupee),
              _detailRow('Total Price', '₹${order.totalPrice}', Icons.currency_rupee),
              
              if (order.remarks != null && order.remarks!.isNotEmpty)
                _detailRow('Remarks', order.remarks!, Icons.note),
              
              _detailRow('Created Date', 
                DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                Icons.calendar_today,
              ),
              if (order.updatedAt != null)
                _detailRow('Last Updated',
                  DateFormat('dd MMM yyyy, hh:mm a').format(order.updatedAt!),
                  Icons.update,
                ),
              
              const SizedBox(height: 24),
              
              if (order.status.toLowerCase() != 'completed' &&
                  order.status.toLowerCase() != 'cancelled')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showStatusUpdateDialog(order, context, ordersProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalColors.primaryBlue,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Update Status',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'packing':
        return Colors.blue;
      case 'ready_for_dispatch':
        return Colors.purple;
      case 'dispatched':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'packing':
        return Icons.inventory;
      case 'ready_for_dispatch':
        return Icons.local_shipping;
      case 'dispatched':
        return Icons.directions_car;
      case 'delivered':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }
}



// import 'package:flutter/material.dart';
// import 'package:mega_pro/providers/pro_orders_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';

// class ProductionOrdersPage extends StatefulWidget {
//   const ProductionOrdersPage({super.key, required Map productionProfile, required Null Function() onDataChanged});

//   @override
//   State<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
// }

// class _ProductionOrdersPageState extends State<ProductionOrdersPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: Text(
//           'Production Orders',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               Provider.of<OrdersProvider>(context, listen: false).refresh();
//             },
//           ),
//         ],
//       ),
//       body: Consumer<OrdersProvider>(
//         builder: (context, ordersProvider, child) {
//           // Show error if any
//           if (ordersProvider.error != null) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(
//                       Icons.error_outline,
//                       size: 64,
//                       color: Colors.red,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Error Loading Orders',
//                       style: GoogleFonts.poppins(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.red,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       ordersProvider.error!,
//                       textAlign: TextAlign.center,
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: () => ordersProvider.refresh(),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: GlobalColors.primaryBlue,
//                       ),
//                       child: const Text(
//                         'Retry',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }

//           return Column(
//             children: [
//               // Statistics Cards
//               _buildStatistics(ordersProvider),
              
//               // Filter Tabs
//               _buildFilterTabs(ordersProvider),
              
//               // Orders List
//               Expanded(child: _buildOrdersList(ordersProvider)),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildStatistics(OrdersProvider ordersProvider) {
//     final stats = ordersProvider.getStatistics();
    
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             _statCard('Total', stats['total']!, Colors.blue, Icons.receipt),
//             const SizedBox(width: 12),
//             _statCard('Pending', stats['pending']!, Colors.orange, Icons.pending),
//             const SizedBox(width: 12),
//             _statCard('Packing', stats['packing']!, Colors.blue, Icons.inventory),
//             const SizedBox(width: 12),
//             _statCard('Ready', stats['ready_for_dispatch']!, Colors.purple, Icons.local_shipping),
//             const SizedBox(width: 12),
//             _statCard('Dispatched', stats['dispatched']!, Colors.indigo, Icons.directions_car),
//             const SizedBox(width: 12),
//             _statCard('Delivered', stats['delivered']!, Colors.green, Icons.check_circle),
//             const SizedBox(width: 12),
//             _statCard('Completed', stats['completed']!, Colors.green, Icons.done_all),
//             const SizedBox(width: 12),
//             _statCard('Cancelled', stats['cancelled']!, Colors.red, Icons.cancel),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _statCard(String title, int count, Color color, IconData icon) {
//     return Container(
//       width: 110,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(icon, size: 16, color: color),
//               ),
//               const Spacer(),
//               Text(
//                 count.toString(),
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             title,
//             style: GoogleFonts.poppins(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[700],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterTabs(OrdersProvider ordersProvider) {
//     final filters = [
//       {'label': 'All', 'value': 'all'},
//       {'label': 'Pending', 'value': 'pending'},
//       {'label': 'Packing', 'value': 'packing'},
//       {'label': 'Ready', 'value': 'ready_for_dispatch'},
//       {'label': 'Dispatched', 'value': 'dispatched'},
//       {'label': 'Delivered', 'value': 'delivered'},
//       {'label': 'Completed', 'value': 'completed'},
//       {'label': 'Cancelled', 'value': 'cancelled'},
//     ];

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(
//           bottom: BorderSide(color: Colors.grey[200]!),
//         ),
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: filters.map((filter) {
//             final isSelected = ordersProvider.filter == filter['value'];
//             return Padding(
//               padding: const EdgeInsets.only(right: 8),
//               child: ChoiceChip(
//                 label: Text(
//                   filter['label']!,
//                   style: GoogleFonts.poppins(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w500,
//                     color: isSelected ? Colors.white : Colors.grey[700],
//                   ),
//                 ),
//                 selected: isSelected,
//                 selectedColor: GlobalColors.primaryBlue,
//                 backgroundColor: Colors.grey[100],
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 onSelected: (selected) {
//                   ordersProvider.setFilter(filter['value']!);
//                 },
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildOrdersList(OrdersProvider ordersProvider) {
//     if (ordersProvider.isLoading && ordersProvider.orders.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(color: GlobalColors.primaryBlue),
//             const SizedBox(height: 16),
//             Text(
//               'Loading orders...',
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     if (ordersProvider.filteredOrders.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.receipt_long_outlined,
//               size: 80,
//               color: Colors.grey[300],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No orders found',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               ordersProvider.filter == 'all'
//                   ? 'No orders available'
//                   : 'No ${ordersProvider.filter.replaceAll('_', ' ')} orders',
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.grey[500],
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       color: GlobalColors.primaryBlue,
//       onRefresh: () => ordersProvider.refresh(),
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: ordersProvider.filteredOrders.length,
//         itemBuilder: (context, index) {
//           final order = ordersProvider.filteredOrders[index];
//           return _buildOrderCard(order, context, ordersProvider);
//         },
//       ),
//     );
//   }

//   Widget _buildOrderCard(OrderItem order, BuildContext context, OrdersProvider ordersProvider) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () => _showOrderDetails(order, context, ordersProvider),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header with order ID and status
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Order #${order.id.substring(0, 8)}',
//                             style: GoogleFonts.poppins(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: order.statusColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: order.statusColor.withOpacity(0.3)),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(order.statusIcon, size: 14, color: order.statusColor),
//                           const SizedBox(width: 6),
//                           Text(
//                             order.displayStatus,
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: order.statusColor,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 12),

//                 // Customer and Product Info
//                 _infoRow('Customer:', order.customerName),
//                 _infoRow('Product:', order.productName),
//                 _infoRow('Quantity:', order.displayQuantity),
                
//                 if (order.customerMobile != null)
//                   _infoRow('Mobile:', order.customerMobile!),
                
//                 if (order.customerAddress != null)
//                   _infoRow('Address:', order.customerAddress!),

//                 const SizedBox(height: 12),

//                 // Price Info
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.blue[50],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               '₹${order.totalPrice}',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.blue[700],
//                               ),
//                             ),
//                             Text(
//                               'Total Price',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 11,
//                                 color: Colors.blue[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.green[50],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               '₹${order.pricePerBag}/bag',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.green[700],
//                               ),
//                             ),
//                             Text(
//                               'Price per Bag',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 11,
//                                 color: Colors.green[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 12),

//                 // Update button
//                 if (order.status.toLowerCase() != 'completed' &&
//                     order.status.toLowerCase() != 'cancelled')
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () => _showStatusUpdateDialog(order, context, ordersProvider),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: GlobalColors.primaryBlue,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Update Status',
//                         style: GoogleFonts.poppins(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _infoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               label,
//               style: GoogleFonts.poppins(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: GoogleFonts.poppins(
//                 fontSize: 13,
//                 color: Colors.black,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _showStatusUpdateDialog(
//       OrderItem order, BuildContext context, OrdersProvider ordersProvider) async {
//     final statusOptions = ordersProvider.getNextStatusOptions(order);
    
//     // Map database status to display names
//     Map<String, String> statusDisplayNames = {
//       'pending': 'Pending',
//       'packing': 'Packing',
//       'ready_for_dispatch': 'Ready for Dispatch',
//       'dispatched': 'Dispatched',
//       'delivered': 'Delivered',
//       'completed': 'Completed',
//       'cancelled': 'Cancelled',
//     };
    
//     if (statusOptions.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No status updates available for this order'),
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
//         return Container(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: Container(
//                   width: 60,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 'Update Order Status',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Order #${order.id.substring(0, 8)}',
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Current: ${order.displayStatus}',
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: order.statusColor,
//                 ),
//               ),
//               const SizedBox(height: 20),
              
//               ...statusOptions.map((status) {
//                 final displayName = statusDisplayNames[status] ?? status;
//                 return ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   leading: Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(status).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(
//                       _getStatusIcon(status),
//                       size: 20,
//                       color: _getStatusColor(status),
//                     ),
//                   ),
//                   title: Text(
//                     displayName,
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                   onTap: () async {
//                     Navigator.pop(context);
//                     await _updateOrderStatus(
//                       order,
//                       status, // Send the database status value
//                       context,
//                       ordersProvider,
//                     );
//                   },
//                 );
//               }).toList(),
              
//               const SizedBox(height: 20),
//               OutlinedButton(
//                 onPressed: () => Navigator.pop(context),
//                 style: OutlinedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 48),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: Text(
//                   'Cancel',
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _updateOrderStatus(
//       OrderItem order, String newStatus, BuildContext context, OrdersProvider ordersProvider) async {
//     try {
//       // Show loading
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       // Update status
//       await ordersProvider.updateOrderStatus(order, newStatus);
      
//       // Close loading dialog
//       if (context.mounted) {
//         Navigator.pop(context);
//       }

//       // Show success message
//       if (context.mounted) {
//         final displayNames = {
//           'pending': 'Pending',
//           'packing': 'Packing',
//           'ready_for_dispatch': 'Ready for Dispatch',
//           'dispatched': 'Dispatched',
//           'delivered': 'Delivered',
//           'completed': 'Completed',
//           'cancelled': 'Cancelled',
//         };
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('✅ Order status updated to ${displayNames[newStatus] ?? newStatus}'),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       // Close loading dialog
//       if (context.mounted) {
//         Navigator.pop(context);
//       }
      
//       // Show error message
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('❌ Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }

//   void _showOrderDetails(OrderItem order, BuildContext context, OrdersProvider ordersProvider) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Center(
//                 child: Container(
//                   width: 60,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 children: [
//                   Container(
//                     width: 50,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       color: GlobalColors.primaryBlue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(
//                       Icons.receipt_long,
//                       color: GlobalColors.primaryBlue,
//                       size: 28,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Order Details',
//                           style: GoogleFonts.poppins(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black,
//                           ),
//                         ),
//                         Text(
//                           '#${order.id.substring(0, 8)}',
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: order.statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: order.statusColor.withOpacity(0.3)),
//                     ),
//                     child: Text(
//                       order.displayStatus,
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                         color: order.statusColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
              
//               // Order details
//               _detailRow('Customer Name', order.customerName, Icons.person),
//               if (order.customerMobile != null)
//                 _detailRow('Customer Mobile', order.customerMobile!, Icons.phone),
//               if (order.customerAddress != null)
//                 _detailRow('Customer Address', order.customerAddress!, Icons.location_on),
              
//               _detailRow('Product', order.productName, Icons.inventory),
//               _detailRow('Bags', '${order.quantity.toInt()} Bags', Icons.shopping_bag),
//               _detailRow('Weight per Bag', '${order.weightPerBag} kg', Icons.scale),
//               _detailRow('Total Weight', '${order.totalWeight} kg', Icons.scale),
//               _detailRow('Price per Bag', '₹${order.pricePerBag}', Icons.currency_rupee),
//               _detailRow('Total Price', '₹${order.totalPrice}', Icons.currency_rupee),
              
//               if (order.remarks != null && order.remarks!.isNotEmpty)
//                 _detailRow('Remarks', order.remarks!, Icons.note),
              
//               _detailRow('Created Date', 
//                 DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
//                 Icons.calendar_today,
//               ),
//               if (order.updatedAt != null)
//                 _detailRow('Last Updated',
//                   DateFormat('dd MMM yyyy, hh:mm a').format(order.updatedAt!),
//                   Icons.update,
//                 ),
              
//               const SizedBox(height: 24),
              
//               if (order.status.toLowerCase() != 'completed' &&
//                   order.status.toLowerCase() != 'cancelled')
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     _showStatusUpdateDialog(order, context, ordersProvider);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: GlobalColors.primaryBlue,
//                     minimumSize: const Size(double.infinity, 48),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Text(
//                     'Update Status',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               const SizedBox(height: 8),
//               OutlinedButton(
//                 onPressed: () => Navigator.pop(context),
//                 style: OutlinedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 48),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: Text(
//                   'Close',
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _detailRow(String label, String value, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 18, color: Colors.grey[600]),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               label,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Text(
//               value,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.black,
//               ),
//               textAlign: TextAlign.right,
//             ),
//           ),
//         ],
      
//       ),
//     );
    
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Colors.orange;
//       case 'packing':
//         return Colors.blue;
//       case 'ready_for_dispatch':
//         return Colors.purple;
//       case 'dispatched':
//         return Colors.indigo;
//       case 'delivered':
//         return Colors.green;
//       case 'completed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getStatusIcon(String status) {
//     switch (status.toLowerCase()) {
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
// }
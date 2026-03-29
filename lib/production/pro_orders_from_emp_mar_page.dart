import 'package:flutter/material.dart';
import 'package:mega_pro/models/order_item_model.dart';
import 'package:mega_pro/providers/emp_order_provider.dart';
import 'package:mega_pro/providers/pro_orders_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductionOrdersPage extends StatefulWidget {
  final Map productionProfile;
  final VoidCallback onDataChanged;

  const ProductionOrdersPage({
    super.key, 
    required this.productionProfile,
    required this.onDataChanged,
  });

  @override
  State<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
}

class _ProductionOrdersPageState extends State<ProductionOrdersPage> with SingleTickerProviderStateMixin {
  Map<String, bool> _selectedOrders = {};
  bool _isSelectionMode = false;
  bool _selectAll = false;
  bool _isLoadingTimeout = false;
  bool _isRefreshing = false;
  
  // Track mounted state manually
  bool _isMounted = true;
  
  // Animation controller for smooth transitions
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _setupLoadingTimeout();
    _loadInitialData();
    
    // Register callbacks after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerNotificationCallbacks();
    });
  }

  void _setupLoadingTimeout() {
    // Set a timeout for loading
    Future.delayed(const Duration(seconds: 10), () {
      if (_isMounted) {
        final provider = Provider.of<ProductionOrdersProvider>(context, listen: false);
        if (provider.isLoading) {
          setState(() {
            _isLoadingTimeout = true;
          });
        }
      }
    });
  }

  void _registerNotificationCallbacks() {
    try {
      final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      print('🔔 [OrdersPage] Registering notification callbacks...');
      
      ordersProvider.setNotificationCallbacks(
        onWhatsApp: (orderData, newStatus, {notes}) async {
          print('📱 [OrdersPage] WhatsApp callback triggered for order ${orderData['order_number']}');
          await orderProvider.sendOrderWhatsAppNotification(
            context: context,
            orderId: orderData['id'],
            order: orderData,
            showDialog: false,
          );
        },
        onEmail: (orderData, newStatus, {notes}) async {
          print('📧 [OrdersPage] Email callback triggered for order ${orderData['order_number']}');
          await orderProvider.sendOrderEmailNotification(
            context: context,
            orderId: orderData['id'],
            order: orderData,
          );
        },
      );
      
      print('✅ [OrdersPage] Notification callbacks registered successfully');
    } catch (e) {
      print('❌ [OrdersPage] Failed to register callbacks: $e');
    }
  }

  // FIXED: Load initial data with mounted check
  Future<void> _loadInitialData() async {
    if (!_isMounted) return;
    
    try {
      final provider = Provider.of<ProductionOrdersProvider>(context, listen: false);
      if (provider.orders.isEmpty && !provider.isLoading) {
        await provider.refresh();
      }
    } catch (e) {
      print('❌ Error loading initial data: $e');
    }
  }

  // FIXED: Smooth refresh with mounted checks
  Future<void> _handleRefresh() async {
    if (!_isMounted) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final provider = Provider.of<ProductionOrdersProvider>(context, listen: false);
      await provider.refresh();
    } catch (e) {
      print('❌ Refresh error: $e');
    } finally {
      if (_isMounted) {
        setState(() {
          _isRefreshing = false;
          _isLoadingTimeout = false;
        });
      }
    }
    
    if (_isMounted) {
      _setupLoadingTimeout();
    }
  }
  
  @override
  void dispose() {
    _isMounted = false;
    _animationController.dispose();
    _selectedOrders.clear();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Re-register callbacks on each build to ensure they're set
    _registerNotificationCallbacks();
    
    try {
      final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: true);
      
      // Check for timeout
      if (_isLoadingTimeout && ordersProvider.isLoading) {
        return _buildTimeoutScreen(ordersProvider);
      }
      
      if (ordersProvider.error != null && ordersProvider.orders.isEmpty) {
        return _buildErrorState(ordersProvider);
      }

      return Scaffold(
        backgroundColor: GlobalColors.background,
        appBar: AppBar(
          title: Text(
            _isSelectionMode ? 'Select Orders' : 'Received Orders',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: _isSelectionMode ? GlobalColors.primaryBlue.withOpacity(0.9) : GlobalColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedOrders.clear();
                        _selectAll = false;
                      });
                    },
                    tooltip: 'Cancel Selection',
                  ),
                ]
              : [
                  IconButton(
                    icon: AnimatedRotation(
                      turns: _isRefreshing ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      child: Icon(
                        _isRefreshing ? Icons.refresh : Icons.refresh,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _isRefreshing ? null : _handleRefresh,
                  ),
                ],
        ),
        body: Consumer<ProductionOrdersProvider>(
          builder: (context, ordersProvider, child) {
            return Column(
              children: [
                if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
                  _buildStatistics(ordersProvider),
                
                if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
                  _buildFilterTabs(ordersProvider),
                
                if (_isSelectionMode) 
                  _buildBulkSelectionToolbar(ordersProvider),
                
                Expanded(
                  child: _buildOrdersList(ordersProvider),
                ),
              ],
            );
          },
        ),
        floatingActionButton: _isSelectionMode
            ? Builder(
                builder: (context) {
                  final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
                  return FloatingActionButton.extended(
                    onPressed: selectedCount > 0 
                        ? () => _showBulkStatusUpdateDialog(context.read<ProductionOrdersProvider>())
                        : null,
                    backgroundColor: GlobalColors.primaryBlue,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      'Update $selectedCount',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              )
            : null,
      );
    } catch (e, stackTrace) {
      print('❌ Error in ProductionOrdersPage build: $e');
      print('❌ Stack trace: $stackTrace');
      return _buildErrorFallback();
    }
  }

  Widget _buildTimeoutScreen(ProductionOrdersProvider provider) {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        title: const Text('Received Orders'),
        backgroundColor: GlobalColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_off, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Loading is taking too long',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (!_isMounted) return;
                  setState(() {
                    _isLoadingTimeout = false;
                    _isRefreshing = true;
                  });
                  provider.refresh().then((_) {
                    if (_isMounted) {
                      setState(() {
                        _isRefreshing = false;
                      });
                    }
                  }).catchError((error) {
                    if (_isMounted) {
                      setState(() {
                        _isRefreshing = false;
                      });
                    }
                  });
                  if (_isMounted) {
                    _setupLoadingTimeout();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: GlobalColors.primaryBlue),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ProductionOrdersProvider ordersProvider) {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        title: Text(
          'Received Orders',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: GlobalColors.primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (!_isMounted) return;
              setState(() {
                _isRefreshing = true;
              });
              ordersProvider.refresh().then((_) {
                if (_isMounted) {
                  setState(() {
                    _isRefreshing = false;
                  });
                }
              }).catchError((error) {
                if (_isMounted) {
                  setState(() {
                    _isRefreshing = false;
                  });
                }
              });
            },
          ),
        ],
      ),
      body: Center(
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
                ordersProvider.error ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (!_isMounted) return;
                  setState(() {
                    _isRefreshing = true;
                  });
                  ordersProvider.refresh().then((_) {
                    if (_isMounted) {
                      setState(() {
                        _isRefreshing = false;
                      });
                    }
                  }).catchError((error) {
                    if (_isMounted) {
                      setState(() {
                        _isRefreshing = false;
                      });
                    }
                  });
                },
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
      ),
    );
  }

  Widget _buildErrorFallback() {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        title: const Text('Received Orders'),
        backgroundColor: GlobalColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try restarting the app',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (!_isMounted) return;
                  setState(() {
                    _isRefreshing = true;
                  });
                  Provider.of<ProductionOrdersProvider>(context, listen: false).refresh().then((_) {
                    if (_isMounted) {
                      setState(() {
                        _isRefreshing = false;
                      });
                    }
                  }).catchError((error) {
                    if (_isMounted) {
                      setState(() {
                        _isRefreshing = false;
                      });
                    }
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: GlobalColors.primaryBlue),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                  if (selected) {
                    ordersProvider.setFilter(filter['value']!);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

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

  Widget _buildOrdersList(ProductionOrdersProvider ordersProvider) {
    // Show loading only if no orders and loading
    if (ordersProvider.orders.isEmpty) {
      if (ordersProvider.isLoading) {
        return _buildInitialLoading('Loading orders...');
      }
      return _buildEmptyState(ordersProvider);
    }

    // Show filtered orders
    if (ordersProvider.filteredOrders.isEmpty) {
      return _buildEmptyFilterState(ordersProvider);
    }

    return RefreshIndicator(
      color: GlobalColors.primaryBlue,
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ordersProvider.filteredOrders.length + (ordersProvider.hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == ordersProvider.filteredOrders.length) {
            return _buildLoadMoreButton(ordersProvider);
          }
          
          final order = ordersProvider.filteredOrders[index];
          return _buildOrderCard(order, context, ordersProvider);
        },
      ),
    );
  }

  Widget _buildInitialLoading(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: GlobalColors.primaryBlue),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(ProductionOrdersProvider ordersProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ordersProvider.isLoading
            ? const CircularProgressIndicator(color: GlobalColors.primaryBlue)
            : ElevatedButton(
                onPressed: ordersProvider.hasMoreData ? () {
                  ordersProvider.loadMore();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(ordersProvider.hasMoreData ? 'Load More Orders' : 'No More Orders'),
              ),
      ),
    );
  }

  Widget _buildEmptyState(ProductionOrdersProvider ordersProvider) {
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
            'Pull down to refresh',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (!_isMounted) return;
              setState(() {
                _isRefreshing = true;
              });
              ordersProvider.refresh().then((_) {
                if (_isMounted) {
                  setState(() {
                    _isRefreshing = false;
                  });
                }
              }).catchError((error) {
                if (_isMounted) {
                  setState(() {
                    _isRefreshing = false;
                  });
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.primaryBlue,
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState(ProductionOrdersProvider ordersProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${ordersProvider.filter.replaceAll('_', ' ')} orders',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the filter',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ordersProvider.setFilter('all');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.primaryBlue,
            ),
            child: const Text(
              'Show All Orders',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

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
                _updateSelectAllStatus(ordersProvider);
              });
            } else {
              _showOrderDetails(order, context, ordersProvider);
            }
          },
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedOrders[order.id] = true;
              _updateSelectAllStatus(ordersProvider);
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
                          _updateSelectAllStatus(ordersProvider);
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
                      _infoRow('District:', order.district.isNotEmpty ? order.district : 'Not specified'),
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

  void _updateSelectAllStatus(ProductionOrdersProvider ordersProvider) {
    if (!_isMounted) return;
    
    if (ordersProvider.filteredOrders.isEmpty) {
      _selectAll = false;
      return;
    }
    
    bool allSelected = true;
    for (var order in ordersProvider.filteredOrders) {
      if (!(_selectedOrders[order.id] ?? false)) {
        allSelected = false;
        break;
      }
    }
    _selectAll = allSelected;
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

  // FIXED: Status update with mounted checks
  Future<void> _showStatusUpdateDialog(
    ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) async {
    
    if (!_isMounted) return;
    
    final statusOptions = [
      'pending', 
      'packing', 
      'ready_for_dispatch', 
      'dispatched', 
      'delivered', 
      'completed', 
      'cancelled'
    ].where((s) => s != order.status.toLowerCase()).toList();
    
    final statusDisplayNames = {
      'pending': 'Pending',
      'packing': 'Packing',
      'ready_for_dispatch': 'Ready for Dispatch',
      'dispatched': 'Dispatched',
      'delivered': 'Delivered',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    };
    
    if (statusOptions.isEmpty) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No status updates available for this order'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
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

  // FIXED: Update order status with mounted checks
  Future<void> _updateOrderStatus(
    ProductionOrderItem order, String newStatus, BuildContext context, ProductionOrdersProvider ordersProvider) async {
    
    if (!_isMounted) return;
    
    // Show loading indicator
    final snackBar = SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Text('Updating order status...'),
        ],
      ),
      backgroundColor: GlobalColors.primaryBlue,
      duration: const Duration(seconds: 2),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    try {
      print('📝 Attempting to update order ${order.id} to status: $newStatus');
      
      // THIS IS THE IMPORTANT LINE - Make sure this is calling the provider
      await ordersProvider.updateOrderStatus(order, newStatus);
      
      if (!_isMounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Order status updated to ${_getStatusDisplayName(newStatus)}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      print('❌ Error updating order status: $e');
      
      if (!_isMounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Pending';
      case 'packing': return 'Packing';
      case 'ready_for_dispatch': return 'Ready for Dispatch';
      case 'dispatched': return 'Dispatched';
      case 'delivered': return 'Delivered';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  // FIXED: Bulk update with mounted checks
  Future<void> _showBulkStatusUpdateDialog(ProductionOrdersProvider ordersProvider) async {
    if (!_isMounted) return;
    
    final selectedOrderIds = _selectedOrders.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (selectedOrderIds.isEmpty) return;
    
    final statusDisplayNames = {
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
      isScrollControlled: true,
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

  // FIXED: Bulk update without loading dialog and with mounted checks
  Future<void> _updateBulkOrderStatus(
    List<String> orderIds, 
    String newStatus, 
    ProductionOrdersProvider ordersProvider) async {
    
    if (!_isMounted) return;
    
    // Show a snackbar instead of loading dialog
    final snackBar = SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Text('Updating ${orderIds.length} orders...'),
        ],
      ),
      backgroundColor: GlobalColors.primaryBlue,
      duration: const Duration(seconds: 1),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    try {
      print('📝 Bulk updating ${orderIds.length} orders to: $newStatus');
      
      // Get the actual order objects from the provider
      final ordersToUpdate = ordersProvider.orders
          .where((order) => orderIds.contains(order.id))
          .toList();
      
      await ordersProvider.updateBulkOrderStatus(ordersToUpdate.map((o) => o.id).toList(), newStatus);
      
      if (!_isMounted) return;
      
      // Close the progress snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Exit selection mode
      setState(() {
        _isSelectionMode = false;
        _selectedOrders.clear();
        _selectAll = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${orderIds.length} orders updated to ${_getStatusDisplayName(newStatus)}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      print('❌ Bulk update error: $e');
      
      if (!_isMounted) return;
      
      // Close the progress snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _updateBulkOrderStatus(orderIds, newStatus, ordersProvider);
            },
          ),
        ),
      );
    }
  }

  void _showOrderDetails(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
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
                  _detailRow('District', order.district.isNotEmpty ? order.district : 'Not specified', Icons.map),
                  
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






























//does not trigger msgs

// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/order_item_model.dart';
// import 'package:mega_pro/providers/pro_orders_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';

// class ProductionOrdersPage extends StatefulWidget {
//   final Map productionProfile;
//   final VoidCallback onDataChanged;

//   const ProductionOrdersPage({
//     super.key, 
//     required this.productionProfile,
//     required this.onDataChanged,
//   });

//   @override
//   State<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
// }

// class _ProductionOrdersPageState extends State<ProductionOrdersPage> with SingleTickerProviderStateMixin {
//   Map<String, bool> _selectedOrders = {};
//   bool _isSelectionMode = false;
//   bool _selectAll = false;
//   bool _isLoadingTimeout = false;
//   bool _isRefreshing = false;
  
//   // Track mounted state manually
//   bool _isMounted = true;
  
//   // Animation controller for smooth transitions
//   late AnimationController _animationController;

//   @override
//   void initState() {
//     super.initState();
//     _isMounted = true;
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _setupLoadingTimeout();
//     _loadInitialData();
//   }

//   void _setupLoadingTimeout() {
//     // Set a timeout for loading
//     Future.delayed(const Duration(seconds: 10), () {
//       if (_isMounted) {
//         final provider = Provider.of<ProductionOrdersProvider>(context, listen: false);
//         if (provider.isLoading) {
//           setState(() {
//             _isLoadingTimeout = true;
//           });
//         }
//       }
//     });
//   }

//   // FIXED: Load initial data with mounted check
//   Future<void> _loadInitialData() async {
//     if (!_isMounted) return;
    
//     try {
//       final provider = Provider.of<ProductionOrdersProvider>(context, listen: false);
//       if (provider.orders.isEmpty && !provider.isLoading) {
//         await provider.refresh();
//       }
//     } catch (e) {
//       print('❌ Error loading initial data: $e');
//     }
//   }

//   // FIXED: Smooth refresh with mounted checks
//   Future<void> _handleRefresh() async {
//     if (!_isMounted) return;
    
//     setState(() {
//       _isRefreshing = true;
//     });
    
//     try {
//       final provider = Provider.of<ProductionOrdersProvider>(context, listen: false);
//       await provider.refresh();
//     } catch (e) {
//       print('❌ Refresh error: $e');
//     } finally {
//       if (_isMounted) {
//         setState(() {
//           _isRefreshing = false;
//           _isLoadingTimeout = false;
//         });
//       }
//     }
    
//     if (_isMounted) {
//       _setupLoadingTimeout();
//     }
//   }
  
//   @override
//   void dispose() {
//     _isMounted = false;
//     _animationController.dispose();
//     _selectedOrders.clear();
//     super.dispose();
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     try {
//       final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: true);
      
//       // Check for timeout
//       if (_isLoadingTimeout && ordersProvider.isLoading) {
//         return _buildTimeoutScreen(ordersProvider);
//       }
      
//       if (ordersProvider.error != null && ordersProvider.orders.isEmpty) {
//         return _buildErrorState(ordersProvider);
//       }

//       return Scaffold(
//         backgroundColor: GlobalColors.background,
//         appBar: AppBar(
//           title: Text(
//             _isSelectionMode ? 'Select Orders' : 'Received Orders',
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               fontSize: 20,
//             ),
//           ),
//           backgroundColor: _isSelectionMode ? GlobalColors.primaryBlue.withOpacity(0.9) : GlobalColors.primaryBlue,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           actions: _isSelectionMode
//               ? [
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () {
//                       setState(() {
//                         _isSelectionMode = false;
//                         _selectedOrders.clear();
//                         _selectAll = false;
//                       });
//                     },
//                     tooltip: 'Cancel Selection',
//                   ),
//                 ]
//               : [
//                   IconButton(
//                     icon: AnimatedRotation(
//                       turns: _isRefreshing ? 1 : 0,
//                       duration: const Duration(milliseconds: 500),
//                       child: Icon(
//                         _isRefreshing ? Icons.refresh : Icons.refresh,
//                         color: Colors.white,
//                       ),
//                     ),
//                     onPressed: _isRefreshing ? null : _handleRefresh,
//                   ),
//                 ],
//         ),
//         body: Consumer<ProductionOrdersProvider>(
//           builder: (context, ordersProvider, child) {
//             return Column(
//               children: [
//                 if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
//                   _buildStatistics(ordersProvider),
                
//                 if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
//                   _buildFilterTabs(ordersProvider),
                
//                 if (_isSelectionMode) 
//                   _buildBulkSelectionToolbar(ordersProvider),
                
//                 Expanded(
//                   child: _buildOrdersList(ordersProvider),
//                 ),
//               ],
//             );
//           },
//         ),
//         floatingActionButton: _isSelectionMode
//             ? Builder(
//                 builder: (context) {
//                   final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
//                   return FloatingActionButton.extended(
//                     onPressed: selectedCount > 0 
//                         ? () => _showBulkStatusUpdateDialog(context.read<ProductionOrdersProvider>())
//                         : null,
//                     backgroundColor: GlobalColors.primaryBlue,
//                     foregroundColor: Colors.white,
//                     icon: const Icon(Icons.check_circle),
//                     label: Text(
//                       'Update $selectedCount',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   );
//                 },
//               )
//             : null,
//       );
//     } catch (e, stackTrace) {
//       print('❌ Error in ProductionOrdersPage build: $e');
//       print('❌ Stack trace: $stackTrace');
//       return _buildErrorFallback();
//     }
//   }

//   Widget _buildTimeoutScreen(ProductionOrdersProvider provider) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: const Text('Received Orders'),
//         backgroundColor: GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.timer_off, size: 64, color: Colors.orange),
//               const SizedBox(height: 16),
//               Text(
//                 'Loading is taking too long',
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Please check your internet connection',
//                 style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   if (!_isMounted) return;
//                   setState(() {
//                     _isLoadingTimeout = false;
//                     _isRefreshing = true;
//                   });
//                   provider.refresh().then((_) {
//                     if (_isMounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   }).catchError((error) {
//                     if (_isMounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   });
//                   if (_isMounted) {
//                     _setupLoadingTimeout();
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(backgroundColor: GlobalColors.primaryBlue),
//                 child: const Text('Retry', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState(ProductionOrdersProvider ordersProvider) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: Text(
//           'Received Orders',
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
//               if (!_isMounted) return;
//               setState(() {
//                 _isRefreshing = true;
//               });
//               ordersProvider.refresh().then((_) {
//                 if (_isMounted) {
//                   setState(() {
//                     _isRefreshing = false;
//                   });
//                 }
//               }).catchError((error) {
//                 if (_isMounted) {
//                   setState(() {
//                     _isRefreshing = false;
//                   });
//                 }
//               });
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 size: 64,
//                 color: Colors.red,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Error Loading Orders',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.red,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 ordersProvider.error ?? 'Unknown error occurred',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   if (!_isMounted) return;
//                   setState(() {
//                     _isRefreshing = true;
//                   });
//                   ordersProvider.refresh().then((_) {
//                     if (_isMounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   }).catchError((error) {
//                     if (_isMounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   });
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                 ),
//                 child: const Text(
//                   'Retry',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorFallback() {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: const Text('Received Orders'),
//         backgroundColor: GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, size: 64, color: Colors.red),
//               const SizedBox(height: 16),
//               Text(
//                 'Something went wrong',
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Please try restarting the app',
//                 style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   if (!_isMounted) return;
//                   setState(() {
//                     _isRefreshing = true;
//                   });
//                   Provider.of<ProductionOrdersProvider>(context, listen: false).refresh().then((_) {
//                     if (_isMounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   }).catchError((error) {
//                     if (_isMounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   });
//                 },
//                 style: ElevatedButton.styleFrom(backgroundColor: GlobalColors.primaryBlue),
//                 child: const Text('Retry', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatistics(ProductionOrdersProvider ordersProvider) {
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

//   Widget _buildFilterTabs(ProductionOrdersProvider ordersProvider) {
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
//                   if (selected) {
//                     ordersProvider.setFilter(filter['value']!);
//                   }
//                 },
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildBulkSelectionToolbar(ProductionOrdersProvider ordersProvider) {
//     final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: GlobalColors.primaryBlue,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Checkbox(
//             value: _selectAll,
//             onChanged: (value) {
//               setState(() {
//                 _selectAll = value ?? false;
//                 for (var order in ordersProvider.filteredOrders) {
//                   _selectedOrders[order.id] = _selectAll;
//                 }
//               });
//             },
//             activeColor: Colors.white,
//             checkColor: GlobalColors.primaryBlue,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               _selectAll 
//                   ? 'All ${ordersProvider.filteredOrders.length} selected'
//                   : '$selectedCount selected',
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrdersList(ProductionOrdersProvider ordersProvider) {
//     // Show loading only if no orders and loading
//     if (ordersProvider.orders.isEmpty) {
//       if (ordersProvider.isLoading) {
//         return _buildInitialLoading('Loading orders...');
//       }
//       return _buildEmptyState(ordersProvider);
//     }

//     // Show filtered orders
//     if (ordersProvider.filteredOrders.isEmpty) {
//       return _buildEmptyFilterState(ordersProvider);
//     }

//     return RefreshIndicator(
//       color: GlobalColors.primaryBlue,
//       onRefresh: _handleRefresh,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: ordersProvider.filteredOrders.length + (ordersProvider.hasMoreData ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == ordersProvider.filteredOrders.length) {
//             return _buildLoadMoreButton(ordersProvider);
//           }
          
//           final order = ordersProvider.filteredOrders[index];
//           return _buildOrderCard(order, context, ordersProvider);
//         },
//       ),
//     );
//   }

//   Widget _buildInitialLoading(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(color: GlobalColors.primaryBlue),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadMoreButton(ProductionOrdersProvider ordersProvider) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Center(
//         child: ordersProvider.isLoading
//             ? const CircularProgressIndicator(color: GlobalColors.primaryBlue)
//             : ElevatedButton(
//                 onPressed: ordersProvider.hasMoreData ? () {
//                   ordersProvider.loadMore();
//                 } : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: Text(ordersProvider.hasMoreData ? 'Load More Orders' : 'No More Orders'),
//               ),
//       ),
//     );
//   }

//   Widget _buildEmptyState(ProductionOrdersProvider ordersProvider) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.receipt_long_outlined,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No orders found',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Pull down to refresh',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () {
//               if (!_isMounted) return;
//               setState(() {
//                 _isRefreshing = true;
//               });
//               ordersProvider.refresh().then((_) {
//                 if (_isMounted) {
//                   setState(() {
//                     _isRefreshing = false;
//                   });
//                 }
//               }).catchError((error) {
//                 if (_isMounted) {
//                   setState(() {
//                     _isRefreshing = false;
//                   });
//                 }
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: GlobalColors.primaryBlue,
//             ),
//             child: const Text(
//               'Refresh',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyFilterState(ProductionOrdersProvider ordersProvider) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.filter_list_off,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No ${ordersProvider.filter.replaceAll('_', ' ')} orders',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Try changing the filter',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () {
//               ordersProvider.setFilter('all');
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: GlobalColors.primaryBlue,
//             ),
//             child: const Text(
//               'Show All Orders',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrderCard(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
//     final isSelected = _selectedOrders[order.id] ?? false;
    
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
//         border: _isSelectionMode && isSelected
//             ? Border.all(color: GlobalColors.primaryBlue, width: 2)
//             : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () {
//             if (_isSelectionMode) {
//               setState(() {
//                 _selectedOrders[order.id] = !isSelected;
//                 _updateSelectAllStatus(ordersProvider);
//               });
//             } else {
//               _showOrderDetails(order, context, ordersProvider);
//             }
//           },
//           onLongPress: () {
//             setState(() {
//               _isSelectionMode = true;
//               _selectedOrders[order.id] = true;
//               _updateSelectAllStatus(ordersProvider);
//             });
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (_isSelectionMode)
//                   Padding(
//                     padding: const EdgeInsets.only(right: 12, top: 4),
//                     child: Checkbox(
//                       value: isSelected,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedOrders[order.id] = value ?? false;
//                           _updateSelectAllStatus(ordersProvider);
//                         });
//                       },
//                       activeColor: GlobalColors.primaryBlue,
//                     ),
//                   ),
                
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Order #${order.id.substring(0, 8)}',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: order.statusColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: order.statusColor.withOpacity(0.3)),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(order.statusIcon, size: 14, color: order.statusColor),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   order.displayStatus,
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                     color: order.statusColor,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       _infoRow('Customer:', order.customerName),
//                       _infoRow('Product:', order.productName),
//                       _infoRow('District:', order.district.isNotEmpty ? order.district : 'Not specified'),
//                       _infoRow('Bags:', order.displayQuantity),
                      
//                       if (order.customerMobile.isNotEmpty)
//                         _infoRow('Mobile:', order.customerMobile),
                      
//                       if (order.customerAddress.isNotEmpty)
//                         _infoRow('Address:', order.customerAddress),

//                       const SizedBox(height: 12),

//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.totalPrice}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.blue[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Total Price',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.blue[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.pricePerBag}/bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.green[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Price per Bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.green[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       if (!_isSelectionMode && 
//                           order.status.toLowerCase() != 'completed' &&
//                           order.status.toLowerCase() != 'cancelled')
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () => _showStatusUpdateDialog(order, context, ordersProvider),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: GlobalColors.primaryBlue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Update Status',
//                               style: GoogleFonts.poppins(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _updateSelectAllStatus(ProductionOrdersProvider ordersProvider) {
//     if (!_isMounted) return;
    
//     if (ordersProvider.filteredOrders.isEmpty) {
//       _selectAll = false;
//       return;
//     }
    
//     bool allSelected = true;
//     for (var order in ordersProvider.filteredOrders) {
//       if (!(_selectedOrders[order.id] ?? false)) {
//         allSelected = false;
//         break;
//       }
//     }
//     _selectAll = allSelected;
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

//   // FIXED: Status update with mounted checks
//   Future<void> _showStatusUpdateDialog(
//     ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) async {
    
//     if (!_isMounted) return;
    
//     final statusOptions = [
//       'pending', 
//       'packing', 
//       'ready_for_dispatch', 
//       'dispatched', 
//       'delivered', 
//       'completed', 
//       'cancelled'
//     ].where((s) => s != order.status.toLowerCase()).toList();
    
//     final statusDisplayNames = {
//       'pending': 'Pending',
//       'packing': 'Packing',
//       'ready_for_dispatch': 'Ready for Dispatch',
//       'dispatched': 'Dispatched',
//       'delivered': 'Delivered',
//       'completed': 'Completed',
//       'cancelled': 'Cancelled',
//     };
    
//     if (statusOptions.isEmpty) {
//       if (_isMounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('No status updates available for this order'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       }
//       return;
//     }
    
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.8,
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 60,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Update Order Status',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Order #${order.id.substring(0, 8)}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Current: ${order.displayStatus}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: order.statusColor,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   ...statusOptions.map((status) {
//                     final displayName = statusDisplayNames[status] ?? status;
//                     return ListTile(
//                       contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                       leading: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: _getStatusColor(status).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           _getStatusIcon(status),
//                           size: 20,
//                           color: _getStatusColor(status),
//                         ),
//                       ),
//                       title: Text(
//                         displayName,
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                       onTap: () async {
//                         Navigator.pop(context);
//                         await _updateOrderStatus(
//                           order,
//                           status,
//                           context,
//                           ordersProvider,
//                         );
//                       },
//                     );
//                   }).toList(),
                  
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // FIXED: Update order status with mounted checks
//   Future<void> _updateOrderStatus(
//   ProductionOrderItem order, String newStatus, BuildContext context, ProductionOrdersProvider ordersProvider) async {
  
//   if (!_isMounted) return;
  
//   // Show loading indicator
//   final snackBar = SnackBar(
//     content: Row(
//       children: [
//         const SizedBox(
//           width: 20,
//           height: 20,
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//           ),
//         ),
//         const SizedBox(width: 16),
//         Text('Updating order status...'),
//       ],
//     ),
//     backgroundColor: GlobalColors.primaryBlue,
//     duration: const Duration(seconds: 2),
//   );
  
//   ScaffoldMessenger.of(context).showSnackBar(snackBar);
  
//   try {
//     print('📝 Attempting to update order ${order.id} to status: $newStatus');
    
//     // THIS IS THE IMPORTANT LINE - Make sure this is calling the provider
//     await ordersProvider.updateOrderStatus(order, newStatus);
    
//     if (!_isMounted) return;
    
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('✅ Order status updated to ${_getStatusDisplayName(newStatus)}'),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 2),
//       ),
//     );
    
//   } catch (e) {
//     print('❌ Error updating order status: $e');
    
//     if (!_isMounted) return;
    
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('❌ Error: ${e.toString()}'),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
// }
//   String _getStatusDisplayName(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending': return 'Pending';
//       case 'packing': return 'Packing';
//       case 'ready_for_dispatch': return 'Ready for Dispatch';
//       case 'dispatched': return 'Dispatched';
//       case 'delivered': return 'Delivered';
//       case 'completed': return 'Completed';
//       case 'cancelled': return 'Cancelled';
//       default: return status;
//     }
//   }

//   // FIXED: Bulk update with mounted checks
//   Future<void> _showBulkStatusUpdateDialog(ProductionOrdersProvider ordersProvider) async {
//     if (!_isMounted) return;
    
//     final selectedOrderIds = _selectedOrders.entries
//         .where((entry) => entry.value)
//         .map((entry) => entry.key)
//         .toList();
    
//     if (selectedOrderIds.isEmpty) return;
    
//     final statusDisplayNames = {
//       'pending': 'Pending',
//       'packing': 'Packing',
//       'ready_for_dispatch': 'Ready for Dispatch',
//       'dispatched': 'Dispatched',
//       'delivered': 'Delivered',
//       'completed': 'Completed',
//       'cancelled': 'Cancelled',
//     };
    
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.7,
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 60,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Bulk Update Status',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Updating ${selectedOrderIds.length} orders',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   Text(
//                     'Select New Status:',
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
                  
//                   Column(
//                     children: ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled']
//                         .map((status) {
//                       final displayName = statusDisplayNames[status] ?? status;
//                       return ListTile(
//                         contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                         leading: Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: _getStatusColor(status).withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Icon(
//                             _getStatusIcon(status),
//                             size: 20,
//                             color: _getStatusColor(status),
//                           ),
//                         ),
//                         title: Text(
//                           displayName,
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                         onTap: () async {
//                           Navigator.pop(context);
//                           await _updateBulkOrderStatus(selectedOrderIds, status, ordersProvider);
//                         },
//                       );
//                     }).toList(),
//                   ),
                  
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // FIXED: Bulk update without loading dialog and with mounted checks
//   Future<void> _updateBulkOrderStatus(
//     List<String> orderIds, 
//     String newStatus, 
//     ProductionOrdersProvider ordersProvider) async {
    
//     if (!_isMounted) return;
    
//     // Show a snackbar instead of loading dialog
//     final snackBar = SnackBar(
//       content: Row(
//         children: [
//           const SizedBox(
//             width: 20,
//             height: 20,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Text('Updating ${orderIds.length} orders...'),
//         ],
//       ),
//       backgroundColor: GlobalColors.primaryBlue,
//       duration: const Duration(seconds: 1),
//     );
    
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
//     try {
//       print('📝 Bulk updating ${orderIds.length} orders to: $newStatus');
      
//       // Get the actual order objects from the provider
//       final ordersToUpdate = ordersProvider.orders
//           .where((order) => orderIds.contains(order.id))
//           .toList();
      
//       await ordersProvider.updateBulkOrderStatus(ordersToUpdate.cast<String>(), newStatus);
      
//       if (!_isMounted) return;
      
//       // Close the progress snackbar
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
//       // Exit selection mode
//       setState(() {
//         _isSelectionMode = false;
//         _selectedOrders.clear();
//         _selectAll = false;
//       });
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ ${orderIds.length} orders updated to ${_getStatusDisplayName(newStatus)}'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 3),
//         ),
//       );
      
//     } catch (e) {
//       print('❌ Bulk update error: $e');
      
//       if (!_isMounted) return;
      
//       // Close the progress snackbar
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 4),
//           action: SnackBarAction(
//             label: 'Retry',
//             textColor: Colors.white,
//             onPressed: () {
//               _updateBulkOrderStatus(orderIds, newStatus, ordersProvider);
//             },
//           ),
//         ),
//       );
//     }
//   }

//   void _showOrderDetails(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return DraggableScrollableSheet(
//           initialChildSize: 0.9,
//           minChildSize: 0.5,
//           maxChildSize: 0.95,
//           expand: false,
//           builder: (context, scrollController) {
//             return Container(
//               padding: const EdgeInsets.all(24),
//               child: ListView(
//                 controller: scrollController,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 60,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       Container(
//                         width: 50,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           color: GlobalColors.primaryBlue.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           Icons.receipt_long,
//                           color: GlobalColors.primaryBlue,
//                           size: 28,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Order Details',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black,
//                               ),
//                             ),
//                             Text(
//                               '#${order.id.substring(0, 8)}',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: order.statusColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: order.statusColor.withOpacity(0.3)),
//                         ),
//                         child: Text(
//                           order.displayStatus,
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                             color: order.statusColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
                  
//                   _detailRow('Customer Name', order.customerName, Icons.person),
//                   _detailRow('Customer Mobile', order.customerMobile, Icons.phone),
//                   _detailRow('Customer Address', order.customerAddress, Icons.location_on),
//                   _detailRow('District', order.district.isNotEmpty ? order.district : 'Not specified', Icons.map),
                  
//                   _detailRow('Product', order.productName, Icons.inventory),
//                   _detailRow('Bags', '${order.bags} Bags', Icons.shopping_bag),
//                   _detailRow('Weight per Bag', '${order.weightPerBag} ${order.weightUnit}', Icons.scale),
//                   _detailRow('Total Weight', '${order.totalWeight} ${order.weightUnit}', Icons.scale),
//                   _detailRow('Price per Bag', '₹${order.pricePerBag}', Icons.currency_rupee),
//                   _detailRow('Total Price', '₹${order.totalPrice}', Icons.currency_rupee),
                  
//                   if (order.remarks != null && order.remarks!.isNotEmpty)
//                     _detailRow('Remarks', order.remarks!, Icons.note),
                  
//                   _detailRow('Created Date', 
//                     DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
//                     Icons.calendar_today,
//                   ),
//                   if (order.updatedAt != null)
//                     _detailRow('Last Updated',
//                       DateFormat('dd MMM yyyy, hh:mm a').format(order.updatedAt!),
//                       Icons.update,
//                     ),
                  
//                   const SizedBox(height: 24),
                  
//                   if (order.status.toLowerCase() != 'completed' &&
//                       order.status.toLowerCase() != 'cancelled')
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _showStatusUpdateDialog(order, context, ordersProvider);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: GlobalColors.primaryBlue,
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Update Status',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 8),
//                   OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 48),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Close',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
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


























// import 'package:flutter/material.dart';
// import 'package:mega_pro/providers/emp_order_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';

// class ProductionOrdersPage extends StatefulWidget {
//   final Map<String, dynamic> productionProfile; // Fixed type
//   final VoidCallback onDataChanged; // Fixed type
  
//   const ProductionOrdersPage({
//     super.key, 
//     required this.productionProfile, 
//     required this.onDataChanged
//   });

//   @override
//   State<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
// }

// class _ProductionOrdersPageState extends State<ProductionOrdersPage> {
//   Map<String, bool> _selectedOrders = {};
//   bool _isSelectionMode = false;
//   bool _selectAll = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadSelectedOrders();
//     });
//   }
  
//   void _loadSelectedOrders() {
//     final ordersProvider = Provider.of<OrderProvider>(context, listen: false);
//     _selectedOrders.clear();
//     for (var order in ordersProvider.orders) {
//       _selectedOrders[order['id'].toString()] = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     print('=== ProductionOrdersPage build called ===');
//     print('_isSelectionMode: $_isSelectionMode');
    
//     final ordersProvider = Provider.of<OrderProvider>(context, listen: true);
//     print('ordersProvider.loading: ${ordersProvider.loading}');
//     print('ordersProvider.error: ${ordersProvider.error}');
//     print('ordersProvider.orders.length: ${ordersProvider.orders.length}');
    
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: _isSelectionMode 
//             ? Text(
//                 'Select Orders',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 20,
//                 ),
//               )
//             : Text(
//                 'Production Orders',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 20,
//                 ),
//               ),
//         backgroundColor: _isSelectionMode ? GlobalColors.primaryBlue.withOpacity(0.9) : GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 0,
//         actions: _isSelectionMode
//             ? [
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () {
//                     setState(() {
//                       _isSelectionMode = false;
//                       _selectedOrders.updateAll((key, value) => false);
//                       _selectAll = false;
//                     });
//                   },
//                   tooltip: 'Cancel Selection',
//                 ),
//               ]
//             : [
//                 IconButton(
//                   icon: const Icon(Icons.refresh),
//                   onPressed: () {
//                     Provider.of<OrderProvider>(context, listen: false).refresh();
//                   },
//                 ),
//               ],
//       ),
//       body: Consumer<OrderProvider>(
//         builder: (context, ordersProvider, child) {
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
//               if (!_isSelectionMode) _buildStatistics(ordersProvider),
              
//               if (!_isSelectionMode) _buildFilterTabs(ordersProvider),
              
//               if (_isSelectionMode) _buildBulkSelectionToolbar(ordersProvider),
              
//               Expanded(child: _buildOrdersList(ordersProvider)),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: _isSelectionMode
//           ? FloatingActionButton.extended(
//               onPressed: () {
//                 final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
//                 if (selectedCount > 0) {
//                   _showBulkStatusUpdateDialog(context.read<OrderProvider>());
//                 }
//               },
//               backgroundColor: GlobalColors.primaryBlue,
//               foregroundColor: Colors.white,
//               icon: const Icon(Icons.check_circle),
//               label: Text(
//                 'Update ${_selectedOrders.values.where((isSelected) => isSelected).length}',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             )
//           : null,
//     );
//   }

//   Widget _buildStatistics(OrderProvider ordersProvider) {
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

//   Widget _buildFilterTabs(OrderProvider ordersProvider) {
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
//                   // You'll need to add a filter property and method in OrderProvider
//                   // For now, we'll just refresh with status
//                   ordersProvider.fetchOrders(status: filter['value'] == 'all' ? null : filter['value']);
//                 },
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildBulkSelectionToolbar(OrderProvider ordersProvider) {
//     final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: GlobalColors.primaryBlue,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Checkbox(
//             value: _selectAll,
//             onChanged: (value) {
//               setState(() {
//                 _selectAll = value ?? false;
//                 // You'll need to implement filteredOrders in OrderProvider
//                 for (var order in ordersProvider.orders) {
//                   _selectedOrders[order['id'].toString()] = _selectAll;
//                 }
//               });
//             },
//             activeColor: Colors.white,
//             checkColor: GlobalColors.primaryBlue,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               _selectAll 
//                   ? 'All ${ordersProvider.orders.length} selected'
//                   : '$selectedCount selected',
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrdersList(OrderProvider ordersProvider) {
//     if (ordersProvider.loading && ordersProvider.orders.isEmpty) {
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

//     if (ordersProvider.orders.isEmpty) {
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
//               'No orders available',
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
//       onRefresh: () async {
//         await ordersProvider.refresh();
//         _loadSelectedOrders();
//       },
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: ordersProvider.orders.length + (ordersProvider.hasMoreData ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == ordersProvider.orders.length) {
//             return _buildLoadMoreButton(ordersProvider);
//           }
          
//           final order = ordersProvider.orders[index];
//           return _buildOrderCard(order, context, ordersProvider);
//         },
//       ),
//     );
//   }

//   Widget _buildLoadMoreButton(OrderProvider ordersProvider) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Center(
//         child: ordersProvider.loading
//             ? CircularProgressIndicator(color: GlobalColors.primaryBlue)
//             : ElevatedButton(
//                 onPressed: ordersProvider.hasMoreData ? () {
//                   ordersProvider.loadMore();
//                 } : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Load More Orders'),
//               ),
//       ),
//     );
//   }

//   Widget _buildOrderCard(Map<String, dynamic> order, BuildContext context, OrderProvider ordersProvider) {
//     final orderId = order['id'].toString();
//     final isSelected = _selectedOrders[orderId] ?? false;
    
//     // Safely get values with null checks
//     final id = order['id']?.toString() ?? '';
//     final createdAt = order['created_at'] != null 
//         ? DateTime.parse(order['created_at']) 
//         : DateTime.now();
//     final status = order['status']?.toString() ?? 'pending';
//     final customerName = order['customer_name']?.toString() ?? 'N/A';
//     final productName = order['feed_category']?.toString() ?? 'N/A';
//     final bags = order['bags'] ?? 0;
//     final totalPrice = order['total_price'] ?? 0;
//     final pricePerBag = order['price_per_bag'] ?? 0;
//     final customerMobile = order['customer_mobile']?.toString() ?? '';
//     final customerAddress = order['customer_address']?.toString() ?? '';
    
//     final statusColor = _getStatusColor(status);
//     final statusIcon = _getStatusIcon(status);
//     final displayStatus = _getDisplayStatus(status);
    
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
//         border: _isSelectionMode && isSelected
//             ? Border.all(color: GlobalColors.primaryBlue, width: 2)
//             : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () {
//             if (_isSelectionMode) {
//               setState(() {
//                 _selectedOrders[orderId] = !isSelected;
//               });
//             } else {
//               _showOrderDetails(order, context, ordersProvider);
//             }
//           },
//           onLongPress: () {
//             setState(() {
//               _isSelectionMode = true;
//               _selectedOrders[orderId] = true;
//             });
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (_isSelectionMode)
//                   Padding(
//                     padding: const EdgeInsets.only(right: 12, top: 4),
//                     child: Checkbox(
//                       value: isSelected,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedOrders[orderId] = value ?? false;
//                         });
//                       },
//                       activeColor: GlobalColors.primaryBlue,
//                     ),
//                   ),
                
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Order #${id.length >= 8 ? id.substring(0, 8) : id}',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: statusColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: statusColor.withOpacity(0.3)),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(statusIcon, size: 14, color: statusColor),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   displayStatus,
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                     color: statusColor,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       _infoRow('Customer:', customerName),
//                       _infoRow('Product:', productName),
//                       _infoRow('Bags:', '$bags Bags'),
                      
//                       if (customerMobile.isNotEmpty)
//                         _infoRow('Mobile:', customerMobile),
                      
//                       if (customerAddress.isNotEmpty)
//                         _infoRow('Address:', customerAddress),

//                       const SizedBox(height: 12),

//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹$totalPrice',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.blue[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Total Price',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.blue[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹$pricePerBag/bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.green[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Price per Bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.green[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       if (!_isSelectionMode && 
//                           status.toLowerCase() != 'completed' &&
//                           status.toLowerCase() != 'cancelled')
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () => _showStatusUpdateDialog(order, context, ordersProvider),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: GlobalColors.primaryBlue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Update Status',
//                               style: GoogleFonts.poppins(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
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
//     Map<String, dynamic> order, BuildContext context, OrderProvider ordersProvider) async {
    
//     final statusOptions = _getNextStatusOptions(order['status']?.toString() ?? 'pending');
    
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
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('No status updates available for this order'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       }
//       return;
//     }
    
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.8,
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 60,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Update Order Status',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Order #${order['id'].toString().substring(0, 8)}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Current: ${_getDisplayStatus(order['status']?.toString() ?? 'pending')}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: _getStatusColor(order['status']?.toString() ?? 'pending'),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   ...statusOptions.map((status) {
//                     final displayName = statusDisplayNames[status] ?? status;
//                     return ListTile(
//                       contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                       leading: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: _getStatusColor(status).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           _getStatusIcon(status),
//                           size: 20,
//                           color: _getStatusColor(status),
//                         ),
//                       ),
//                       title: Text(
//                         displayName,
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                       onTap: () async {
//                         Navigator.pop(context);
//                         await _updateOrderStatus(
//                           order,
//                           status,
//                           context,
//                           ordersProvider,
//                         );
//                       },
//                     );
//                   }).toList(),
                  
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   List<String> _getNextStatusOptions(String currentStatus) {
//     switch (currentStatus.toLowerCase()) {
//       case 'pending':
//         return ['packing', 'cancelled'];
//       case 'packing':
//         return ['ready_for_dispatch', 'cancelled'];
//       case 'ready_for_dispatch':
//         return ['dispatched', 'cancelled'];
//       case 'dispatched':
//         return ['delivered', 'cancelled'];
//       case 'delivered':
//         return ['completed'];
//       case 'completed':
//       case 'cancelled':
//       default:
//         return [];
//     }
//   }

//   Future<void> _updateOrderStatus(
//       Map<String, dynamic> order, String newStatus, BuildContext context, OrderProvider ordersProvider) async {
//     try {
//       if (!context.mounted) return;
      
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       await ordersProvider.updateOrderStatus(order['id'].toString(), newStatus);
      
//       if (!context.mounted) return;
      
//       Navigator.pop(context);

//       final displayNames = {
//         'pending': 'Pending',
//         'packing': 'Packing',
//         'ready_for_dispatch': 'Ready for Dispatch',
//         'dispatched': 'Dispatched',
//         'delivered': 'Delivered',
//         'completed': 'Completed',
//         'cancelled': 'Cancelled',
//       };
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ Order status updated to ${displayNames[newStatus] ?? newStatus}'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     } catch (e) {
//       if (!context.mounted) return;
      
//       Navigator.pop(context);
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }

//   Future<void> _showBulkStatusUpdateDialog(OrderProvider ordersProvider) async {
//     final selectedOrderIds = _selectedOrders.entries
//         .where((entry) => entry.value)
//         .map((entry) => entry.key)
//         .toList();
    
//     if (selectedOrderIds.isEmpty) return;
    
//     Map<String, String> statusDisplayNames = {
//       'pending': 'Pending',
//       'packing': 'Packing',
//       'ready_for_dispatch': 'Ready for Dispatch',
//       'dispatched': 'Dispatched',
//       'delivered': 'Delivered',
//       'completed': 'Completed',
//       'cancelled': 'Cancelled',
//     };
    
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.7,
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 60,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Bulk Update Status',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Updating ${selectedOrderIds.length} orders',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   Text(
//                     'Select New Status:',
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
                  
//                   Column(
//                     children: ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled']
//                         .map((status) {
//                       final displayName = statusDisplayNames[status] ?? status;
//                       return ListTile(
//                         contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                         leading: Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: _getStatusColor(status).withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Icon(
//                             _getStatusIcon(status),
//                             size: 20,
//                             color: _getStatusColor(status),
//                           ),
//                         ),
//                         title: Text(
//                           displayName,
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                         onTap: () async {
//                           Navigator.pop(context);
//                           await _updateBulkOrderStatus(selectedOrderIds, status, ordersProvider);
//                         },
//                       );
//                     }).toList(),
//                   ),
                  
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _updateBulkOrderStatus(
//       List<String> orderIds, 
//       String newStatus, 
//       OrderProvider ordersProvider) async {
//     try {
//       if (!context.mounted) return;
      
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       // Update all selected orders one by one
//       for (String orderId in orderIds) {
//         await ordersProvider.updateOrderStatus(orderId, newStatus);
//       }
      
//       if (!context.mounted) return;
      
//       Navigator.pop(context);
      
//       setState(() {
//         _isSelectionMode = false;
//         _selectedOrders.updateAll((key, value) => false);
//         _selectAll = false;
//       });

//       final displayNames = {
//         'pending': 'Pending',
//         'packing': 'Packing',
//         'ready_for_dispatch': 'Ready for Dispatch',
//         'dispatched': 'Dispatched',
//         'delivered': 'Delivered',
//         'completed': 'Completed',
//         'cancelled': 'Cancelled',
//       };
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ ${orderIds.length} orders updated to ${displayNames[newStatus] ?? newStatus}'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     } catch (e) {
//       if (!context.mounted) return;
      
//       Navigator.pop(context);
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }

//   void _showOrderDetails(Map<String, dynamic> order, BuildContext context, OrderProvider ordersProvider) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         final id = order['id']?.toString() ?? '';
//         final createdAt = order['created_at'] != null 
//             ? DateTime.parse(order['created_at']) 
//             : DateTime.now();
//         final updatedAt = order['updated_at'] != null 
//             ? DateTime.tryParse(order['updated_at']) 
//             : null;
//         final status = order['status']?.toString() ?? 'pending';
//         final customerName = order['customer_name']?.toString() ?? 'N/A';
//         final customerMobile = order['customer_mobile']?.toString() ?? 'N/A';
//         final customerAddress = order['customer_address']?.toString() ?? 'N/A';
//         final district = order['district']?.toString() ?? 'N/A';
//         final productName = order['feed_category']?.toString() ?? 'N/A';
//         final bags = order['bags'] ?? 0;
//         final weightPerBag = order['weight_per_bag'] ?? 0;
//         final weightUnit = order['weight_unit']?.toString() ?? 'kg';
//         final totalWeight = order['total_weight'] ?? 0;
//         final pricePerBag = order['price_per_bag'] ?? 0;
//         final totalPrice = order['total_price'] ?? 0;
//         final remarks = order['remarks']?.toString();
        
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
//                           '#${id.length >= 8 ? id.substring(0, 8) : id}',
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
//                       color: _getStatusColor(status).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
//                     ),
//                     child: Text(
//                       _getDisplayStatus(status),
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                         color: _getStatusColor(status),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
              
//               _detailRow('Customer Name', customerName, Icons.person),
//               _detailRow('Customer Mobile', customerMobile, Icons.phone),
//               _detailRow('Customer Address', customerAddress, Icons.location_on),
//               _detailRow('District', district, Icons.map),
              
//               _detailRow('Product', productName, Icons.inventory),
//               _detailRow('Bags', '$bags Bags', Icons.shopping_bag),
//               _detailRow('Weight per Bag', '$weightPerBag $weightUnit', Icons.scale),
//               _detailRow('Total Weight', '$totalWeight $weightUnit', Icons.scale),
//               _detailRow('Price per Bag', '₹$pricePerBag', Icons.currency_rupee),
//               _detailRow('Total Price', '₹$totalPrice', Icons.currency_rupee),
              
//               if (remarks != null && remarks.isNotEmpty)
//                 _detailRow('Remarks', remarks, Icons.note),
              
//               _detailRow('Created Date', 
//                 DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
//                 Icons.calendar_today,
//               ),
//               if (updatedAt != null)
//                 _detailRow('Last Updated',
//                   DateFormat('dd MMM yyyy, hh:mm a').format(updatedAt),
//                   Icons.update,
//                 ),
              
//               const SizedBox(height: 24),
              
//               if (status.toLowerCase() != 'completed' &&
//                   status.toLowerCase() != 'cancelled')
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

//   String _getDisplayStatus(String status) {
//     switch (status.toLowerCase()) {
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































// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/order_item_model.dart';
// import 'package:mega_pro/providers/pro_orders_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';

// class ProductionOrdersPage extends StatefulWidget {
//   final Map productionProfile;
//   final VoidCallback onDataChanged;

//   const ProductionOrdersPage({
//     super.key, 
//     required this.productionProfile,
//     required this.onDataChanged,
//   });

//   @override
//   State<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
// }

// class _ProductionOrdersPageState extends State<ProductionOrdersPage> with SingleTickerProviderStateMixin {
//   Map<String, bool> _selectedOrders = {};
//   bool _isSelectionMode = false;
//   bool _selectAll = false;
//   bool _isLoadingTimeout = false;
//   bool _isRefreshing = false;
  
//   // Animation controller for smooth transitions
//   late AnimationController _animationController;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _setupLoadingTimeout();
//     _loadInitialData();
//   }

//   void _setupLoadingTimeout() {
//     // Set a timeout for loading
//     Future.delayed(const Duration(seconds: 10), () {
//       if (mounted) {
//         final provider = Provider.of<ProductionOrdersProvider>(context, listen: false);
//         if (provider.isLoading) {
//           setState(() {
//             _isLoadingTimeout = true;
//           });
//         }
//       }
//     });
//   }

//   // FIXED: Load initial data with proper error handling
//   Future<void> _loadInitialData() async {
//     try {
//       final provider = Provider.of<ProductionOrdersProvider>(context, listen: false);
//       if (provider.orders.isEmpty && !provider.isLoading) {
//         // Call the appropriate method - either refresh() or fetchOrders()
//         // Let's use refresh() which is safer
//         await provider.refresh();
//       }
//     } catch (e) {
//       print('❌ Error loading initial data: $e');
//     }
//   }

//   // FIXED: Smooth refresh without glitch
//   Future<void> _handleRefresh() async {
//     setState(() {
//       _isRefreshing = true;
//     });
    
//     try {
//       final provider = Provider.of<ProductionOrdersProvider>(context, listen: false);
//       await provider.refresh();
//     } catch (e) {
//       print('❌ Refresh error: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isRefreshing = false;
//           _isLoadingTimeout = false;
//         });
//       }
//     }
    
//     _setupLoadingTimeout();
//   }
  
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _selectedOrders.clear();
//     super.dispose();
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     try {
//       final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: true);
      
//       // Check for timeout
//       if (_isLoadingTimeout && ordersProvider.isLoading) {
//         return _buildTimeoutScreen(ordersProvider);
//       }
      
//       if (ordersProvider.error != null && ordersProvider.orders.isEmpty) {
//         return _buildErrorState(ordersProvider);
//       }

//       return Scaffold(
//         backgroundColor: GlobalColors.background,
//         appBar: AppBar(
//           title: Text(
//             _isSelectionMode ? 'Select Orders' : 'Received Orders',
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               fontSize: 20,
//             ),
//           ),
//           backgroundColor: _isSelectionMode ? GlobalColors.primaryBlue.withOpacity(0.9) : GlobalColors.primaryBlue,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           actions: _isSelectionMode
//               ? [
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () {
//                       setState(() {
//                         _isSelectionMode = false;
//                         _selectedOrders.clear();
//                         _selectAll = false;
//                       });
//                     },
//                     tooltip: 'Cancel Selection',
//                   ),
//                 ]
//               : [
//                   IconButton(
//                     icon: AnimatedRotation(
//                       turns: _isRefreshing ? 1 : 0,
//                       duration: const Duration(milliseconds: 500),
//                       child: Icon(
//                         _isRefreshing ? Icons.refresh : Icons.refresh,
//                         color: Colors.white,
//                       ),
//                     ),
//                     onPressed: _isRefreshing ? null : _handleRefresh,
//                   ),
//                 ],
//         ),
//         body: Consumer<ProductionOrdersProvider>(
//           builder: (context, ordersProvider, child) {
//             return Column(
//               children: [
//                 if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
//                   _buildStatistics(ordersProvider),
                
//                 if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
//                   _buildFilterTabs(ordersProvider),
                
//                 if (_isSelectionMode) 
//                   _buildBulkSelectionToolbar(ordersProvider),
                
//                 Expanded(
//                   child: _buildOrdersList(ordersProvider),
//                 ),
//               ],
//             );
//           },
//         ),
//         floatingActionButton: _isSelectionMode
//             ? Builder(
//                 builder: (context) {
//                   final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
//                   return FloatingActionButton.extended(
//                     onPressed: selectedCount > 0 
//                         ? () => _showBulkStatusUpdateDialog(context.read<ProductionOrdersProvider>())
//                         : null,
//                     backgroundColor: GlobalColors.primaryBlue,
//                     foregroundColor: Colors.white,
//                     icon: const Icon(Icons.check_circle),
//                     label: Text(
//                       'Update $selectedCount',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   );
//                 },
//               )
//             : null,
//       );
//     } catch (e, stackTrace) {
//       print('❌ Error in ProductionOrdersPage build: $e');
//       print('❌ Stack trace: $stackTrace');
//       return _buildErrorFallback();
//     }
//   }

//   Widget _buildTimeoutScreen(ProductionOrdersProvider provider) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: const Text('Received Orders'),
//         backgroundColor: GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.timer_off, size: 64, color: Colors.orange),
//               const SizedBox(height: 16),
//               Text(
//                 'Loading is taking too long',
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Please check your internet connection',
//                 style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _isLoadingTimeout = false;
//                     _isRefreshing = true;
//                   });
//                   provider.refresh().then((_) {
//                     if (mounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   }).catchError((error) {
//                     if (mounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   });
//                   _setupLoadingTimeout();
//                 },
//                 style: ElevatedButton.styleFrom(backgroundColor: GlobalColors.primaryBlue),
//                 child: const Text('Retry', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState(ProductionOrdersProvider ordersProvider) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: Text(
//           'Received Orders',
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
//               setState(() {
//                 _isRefreshing = true;
//               });
//               ordersProvider.refresh().then((_) {
//                 if (mounted) {
//                   setState(() {
//                     _isRefreshing = false;
//                   });
//                 }
//               }).catchError((error) {
//                 if (mounted) {
//                   setState(() {
//                     _isRefreshing = false;
//                   });
//                 }
//               });
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 size: 64,
//                 color: Colors.red,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Error Loading Orders',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.red,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 ordersProvider.error ?? 'Unknown error occurred',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _isRefreshing = true;
//                   });
//                   ordersProvider.refresh().then((_) {
//                     if (mounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   }).catchError((error) {
//                     if (mounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   });
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                 ),
//                 child: const Text(
//                   'Retry',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorFallback() {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: const Text('Received Orders'),
//         backgroundColor: GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, size: 64, color: Colors.red),
//               const SizedBox(height: 16),
//               Text(
//                 'Something went wrong',
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Please try restarting the app',
//                 style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _isRefreshing = true;
//                   });
//                   Provider.of<ProductionOrdersProvider>(context, listen: false).refresh().then((_) {
//                     if (mounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   }).catchError((error) {
//                     if (mounted) {
//                       setState(() {
//                         _isRefreshing = false;
//                       });
//                     }
//                   });
//                 },
//                 style: ElevatedButton.styleFrom(backgroundColor: GlobalColors.primaryBlue),
//                 child: const Text('Retry', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatistics(ProductionOrdersProvider ordersProvider) {
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

//   Widget _buildFilterTabs(ProductionOrdersProvider ordersProvider) {
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
//                   if (selected) {
//                     ordersProvider.setFilter(filter['value']!);
//                   }
//                 },
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildBulkSelectionToolbar(ProductionOrdersProvider ordersProvider) {
//     final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: GlobalColors.primaryBlue,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Checkbox(
//             value: _selectAll,
//             onChanged: (value) {
//               setState(() {
//                 _selectAll = value ?? false;
//                 for (var order in ordersProvider.filteredOrders) {
//                   _selectedOrders[order.id] = _selectAll;
//                 }
//               });
//             },
//             activeColor: Colors.white,
//             checkColor: GlobalColors.primaryBlue,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               _selectAll 
//                   ? 'All ${ordersProvider.filteredOrders.length} selected'
//                   : '$selectedCount selected',
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrdersList(ProductionOrdersProvider ordersProvider) {
//     // Show loading only if no orders and loading
//     if (ordersProvider.orders.isEmpty) {
//       if (ordersProvider.isLoading) {
//         return _buildInitialLoading('Loading orders...');
//       }
//       return _buildEmptyState(ordersProvider);
//     }

//     // Show filtered orders
//     if (ordersProvider.filteredOrders.isEmpty) {
//       return _buildEmptyFilterState(ordersProvider);
//     }

//     return RefreshIndicator(
//       color: GlobalColors.primaryBlue,
//       onRefresh: _handleRefresh,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: ordersProvider.filteredOrders.length + (ordersProvider.hasMoreData ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == ordersProvider.filteredOrders.length) {
//             return _buildLoadMoreButton(ordersProvider);
//           }
          
//           final order = ordersProvider.filteredOrders[index];
//           return _buildOrderCard(order, context, ordersProvider);
//         },
//       ),
//     );
//   }

//   Widget _buildInitialLoading(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(color: GlobalColors.primaryBlue),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadMoreButton(ProductionOrdersProvider ordersProvider) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Center(
//         child: ordersProvider.isLoading
//             ? const CircularProgressIndicator(color: GlobalColors.primaryBlue)
//             : ElevatedButton(
//                 onPressed: ordersProvider.hasMoreData ? () {
//                   ordersProvider.loadMore();
//                 } : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: Text(ordersProvider.hasMoreData ? 'Load More Orders' : 'No More Orders'),
//               ),
//       ),
//     );
//   }

//   Widget _buildEmptyState(ProductionOrdersProvider ordersProvider) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.receipt_long_outlined,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No orders found',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Pull down to refresh',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 _isRefreshing = true;
//               });
//               ordersProvider.refresh().then((_) {
//                 if (mounted) {
//                   setState(() {
//                     _isRefreshing = false;
//                   });
//                 }
//               }).catchError((error) {
//                 if (mounted) {
//                   setState(() {
//                     _isRefreshing = false;
//                   });
//                 }
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: GlobalColors.primaryBlue,
//             ),
//             child: const Text(
//               'Refresh',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyFilterState(ProductionOrdersProvider ordersProvider) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.filter_list_off,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No ${ordersProvider.filter.replaceAll('_', ' ')} orders',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Try changing the filter',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () {
//               ordersProvider.setFilter('all');
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: GlobalColors.primaryBlue,
//             ),
//             child: const Text(
//               'Show All Orders',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrderCard(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
//     final isSelected = _selectedOrders[order.id] ?? false;
    
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
//         border: _isSelectionMode && isSelected
//             ? Border.all(color: GlobalColors.primaryBlue, width: 2)
//             : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () {
//             if (_isSelectionMode) {
//               setState(() {
//                 _selectedOrders[order.id] = !isSelected;
//                 _updateSelectAllStatus(ordersProvider);
//               });
//             } else {
//               _showOrderDetails(order, context, ordersProvider);
//             }
//           },
//           onLongPress: () {
//             setState(() {
//               _isSelectionMode = true;
//               _selectedOrders[order.id] = true;
//               _updateSelectAllStatus(ordersProvider);
//             });
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (_isSelectionMode)
//                   Padding(
//                     padding: const EdgeInsets.only(right: 12, top: 4),
//                     child: Checkbox(
//                       value: isSelected,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedOrders[order.id] = value ?? false;
//                           _updateSelectAllStatus(ordersProvider);
//                         });
//                       },
//                       activeColor: GlobalColors.primaryBlue,
//                     ),
//                   ),
                
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Order #${order.id.substring(0, 8)}',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: order.statusColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: order.statusColor.withOpacity(0.3)),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(order.statusIcon, size: 14, color: order.statusColor),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   order.displayStatus,
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                     color: order.statusColor,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       _infoRow('Customer:', order.customerName),
//                       _infoRow('Product:', order.productName),
//                       _infoRow('District:', order.district.isNotEmpty ? order.district : 'Not specified'),
//                       _infoRow('Bags:', order.displayQuantity),
                      
//                       if (order.customerMobile.isNotEmpty)
//                         _infoRow('Mobile:', order.customerMobile),
                      
//                       if (order.customerAddress.isNotEmpty)
//                         _infoRow('Address:', order.customerAddress),

//                       const SizedBox(height: 12),

//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.totalPrice}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.blue[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Total Price',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.blue[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.pricePerBag}/bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.green[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Price per Bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.green[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       if (!_isSelectionMode && 
//                           order.status.toLowerCase() != 'completed' &&
//                           order.status.toLowerCase() != 'cancelled')
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () => _showStatusUpdateDialog(order, context, ordersProvider),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: GlobalColors.primaryBlue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Update Status',
//                               style: GoogleFonts.poppins(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _updateSelectAllStatus(ProductionOrdersProvider ordersProvider) {
//     if (ordersProvider.filteredOrders.isEmpty) {
//       _selectAll = false;
//       return;
//     }
    
//     bool allSelected = true;
//     for (var order in ordersProvider.filteredOrders) {
//       if (!(_selectedOrders[order.id] ?? false)) {
//         allSelected = false;
//         break;
//       }
//     }
//     _selectAll = allSelected;
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

//   // FIXED: Status update without loading dialog
//   Future<void> _showStatusUpdateDialog(
//     ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) async {
    
//     final statusOptions = [
//       'pending', 
//       'packing', 
//       'ready_for_dispatch', 
//       'dispatched', 
//       'delivered', 
//       'completed', 
//       'cancelled'
//     ].where((s) => s != order.status.toLowerCase()).toList();
    
//     final statusDisplayNames = {
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
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.8,
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 60,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Update Order Status',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Order #${order.id.substring(0, 8)}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Current: ${order.displayStatus}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: order.statusColor,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   ...statusOptions.map((status) {
//                     final displayName = statusDisplayNames[status] ?? status;
//                     return ListTile(
//                       contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                       leading: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: _getStatusColor(status).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           _getStatusIcon(status),
//                           size: 20,
//                           color: _getStatusColor(status),
//                         ),
//                       ),
//                       title: Text(
//                         displayName,
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                       onTap: () async {
//                         Navigator.pop(context);
//                         await _updateOrderStatus(
//                           order,
//                           status,
//                           context,
//                           ordersProvider,
//                         );
//                       },
//                     );
//                   }).toList(),
                  
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // FIXED: Update order status without loading dialog
//   Future<void> _updateOrderStatus(
//     ProductionOrderItem order, String newStatus, BuildContext context, ProductionOrdersProvider ordersProvider) async {
    
//     // Show a snackbar instead of loading dialog
//     final snackBar = SnackBar(
//       content: Row(
//         children: [
//           const SizedBox(
//             width: 20,
//             height: 20,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Text('Updating order status...'),
//         ],
//       ),
//       backgroundColor: GlobalColors.primaryBlue,
//       duration: const Duration(seconds: 1),
//     );
    
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
//     try {
//       print('📝 Attempting to update order ${order.id} to status: $newStatus');
      
//       await ordersProvider.updateOrderStatus(order, newStatus);
      
//       // Close the progress snackbar
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
//       // Show success snackbar
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ Order status updated to ${_getStatusDisplayName(newStatus)}'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           duration: const Duration(seconds: 2),
//         ),
//       );
      
//     } catch (e) {
//       print('❌ Error updating order status: $e');
      
//       // Close the progress snackbar
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           duration: const Duration(seconds: 3),
//           action: SnackBarAction(
//             label: 'Retry',
//             textColor: Colors.white,
//             onPressed: () {
//               _updateOrderStatus(order, newStatus, context, ordersProvider);
//             },
//           ),
//         ),
//       );
//     }
//   }

//   String _getStatusDisplayName(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending': return 'Pending';
//       case 'packing': return 'Packing';
//       case 'ready_for_dispatch': return 'Ready for Dispatch';
//       case 'dispatched': return 'Dispatched';
//       case 'delivered': return 'Delivered';
//       case 'completed': return 'Completed';
//       case 'cancelled': return 'Cancelled';
//       default: return status;
//     }
//   }

//   Future<void> _showBulkStatusUpdateDialog(ProductionOrdersProvider ordersProvider) async {
//     final selectedOrderIds = _selectedOrders.entries
//         .where((entry) => entry.value)
//         .map((entry) => entry.key)
//         .toList();
    
//     if (selectedOrderIds.isEmpty) return;
    
//     final statusDisplayNames = {
//       'pending': 'Pending',
//       'packing': 'Packing',
//       'ready_for_dispatch': 'Ready for Dispatch',
//       'dispatched': 'Dispatched',
//       'delivered': 'Delivered',
//       'completed': 'Completed',
//       'cancelled': 'Cancelled',
//     };
    
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.7,
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 60,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Bulk Update Status',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Updating ${selectedOrderIds.length} orders',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   Text(
//                     'Select New Status:',
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
                  
//                   Column(
//                     children: ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled']
//                         .map((status) {
//                       final displayName = statusDisplayNames[status] ?? status;
//                       return ListTile(
//                         contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                         leading: Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: _getStatusColor(status).withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Icon(
//                             _getStatusIcon(status),
//                             size: 20,
//                             color: _getStatusColor(status),
//                           ),
//                         ),
//                         title: Text(
//                           displayName,
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                         onTap: () async {
//                           Navigator.pop(context);
//                           await _updateBulkOrderStatus(selectedOrderIds, status, ordersProvider);
//                         },
//                       );
//                     }).toList(),
//                   ),
                  
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // FIXED: Bulk update without loading dialog
//   Future<void> _updateBulkOrderStatus(
//     List<String> orderIds, 
//     String newStatus, 
//     ProductionOrdersProvider ordersProvider) async {
    
//     // Show a snackbar instead of loading dialog
//     final snackBar = SnackBar(
//       content: Row(
//         children: [
//           const SizedBox(
//             width: 20,
//             height: 20,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Text('Updating ${orderIds.length} orders...'),
//         ],
//       ),
//       backgroundColor: GlobalColors.primaryBlue,
//       duration: const Duration(seconds: 1),
//     );
    
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
//     try {
//       print('📝 Bulk updating ${orderIds.length} orders to: $newStatus');
      
//       // Get the actual order objects from the provider
//       final ordersToUpdate = ordersProvider.orders
//           .where((order) => orderIds.contains(order.id))
//           .toList();
      
//       await ordersProvider.updateBulkOrderStatus(ordersToUpdate.cast<String>(), newStatus);
      
//       // Close the progress snackbar
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
//       // Exit selection mode
//       setState(() {
//         _isSelectionMode = false;
//         _selectedOrders.clear();
//         _selectAll = false;
//       });
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ ${orderIds.length} orders updated to ${_getStatusDisplayName(newStatus)}'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 3),
//         ),
//       );
      
//     } catch (e) {
//       print('❌ Bulk update error: $e');
      
//       // Close the progress snackbar
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 4),
//           action: SnackBarAction(
//             label: 'Retry',
//             textColor: Colors.white,
//             onPressed: () {
//               _updateBulkOrderStatus(orderIds, newStatus, ordersProvider);
//             },
//           ),
//         ),
//       );
//     }
//   }

//   void _showOrderDetails(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return DraggableScrollableSheet(
//           initialChildSize: 0.9,
//           minChildSize: 0.5,
//           maxChildSize: 0.95,
//           expand: false,
//           builder: (context, scrollController) {
//             return Container(
//               padding: const EdgeInsets.all(24),
//               child: ListView(
//                 controller: scrollController,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 60,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       Container(
//                         width: 50,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           color: GlobalColors.primaryBlue.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           Icons.receipt_long,
//                           color: GlobalColors.primaryBlue,
//                           size: 28,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Order Details',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black,
//                               ),
//                             ),
//                             Text(
//                               '#${order.id.substring(0, 8)}',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: order.statusColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: order.statusColor.withOpacity(0.3)),
//                         ),
//                         child: Text(
//                           order.displayStatus,
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                             color: order.statusColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
                  
//                   _detailRow('Customer Name', order.customerName, Icons.person),
//                   _detailRow('Customer Mobile', order.customerMobile, Icons.phone),
//                   _detailRow('Customer Address', order.customerAddress, Icons.location_on),
//                   _detailRow('District', order.district.isNotEmpty ? order.district : 'Not specified', Icons.map),
                  
//                   _detailRow('Product', order.productName, Icons.inventory),
//                   _detailRow('Bags', '${order.bags} Bags', Icons.shopping_bag),
//                   _detailRow('Weight per Bag', '${order.weightPerBag} ${order.weightUnit}', Icons.scale),
//                   _detailRow('Total Weight', '${order.totalWeight} ${order.weightUnit}', Icons.scale),
//                   _detailRow('Price per Bag', '₹${order.pricePerBag}', Icons.currency_rupee),
//                   _detailRow('Total Price', '₹${order.totalPrice}', Icons.currency_rupee),
                  
//                   if (order.remarks != null && order.remarks!.isNotEmpty)
//                     _detailRow('Remarks', order.remarks!, Icons.note),
                  
//                   _detailRow('Created Date', 
//                     DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
//                     Icons.calendar_today,
//                   ),
//                   if (order.updatedAt != null)
//                     _detailRow('Last Updated',
//                       DateFormat('dd MMM yyyy, hh:mm a').format(order.updatedAt!),
//                       Icons.update,
//                     ),
                  
//                   const SizedBox(height: 24),
                  
//                   if (order.status.toLowerCase() != 'completed' &&
//                       order.status.toLowerCase() != 'cancelled')
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _showStatusUpdateDialog(order, context, ordersProvider);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: GlobalColors.primaryBlue,
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Update Status',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 8),
//                   OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 48),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Close',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
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
















// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/order_item_model.dart';
// import 'package:mega_pro/providers/pro_orders_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';

// class ProductionOrdersPage extends StatefulWidget {
//   final Map productionProfile;
//   final VoidCallback onDataChanged;

//   const ProductionOrdersPage({
//     super.key, 
//     required this.productionProfile,
//     required this.onDataChanged,
//   });

//   @override
//   State<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
// }

// class _ProductionOrdersPageState extends State<ProductionOrdersPage> {
//   Map<String, bool> _selectedOrders = {};
//   bool _isSelectionMode = false;
//   bool _selectAll = false;
//   bool _isLoadingTimeout = false;

//   @override
//   void initState() {
//     super.initState();
//     _setupLoadingTimeout();
//   }

//   void _setupLoadingTimeout() {
//     // Set a timeout for loading
//     Future.delayed(const Duration(seconds: 10), () {
//       if (mounted) {
//         final provider = Provider.of<ProductionOrdersProvider>(context, listen: false);
//         if (provider.isLoading || provider.isQuickLoading) {
//           setState(() {
//             _isLoadingTimeout = true;
//           });
//         }
//       }
//     });
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     try {
//       final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: true);
      
//       // Check for timeout
//       if (_isLoadingTimeout && (ordersProvider.isLoading || ordersProvider.isQuickLoading)) {
//         return _buildTimeoutScreen(ordersProvider);
//       }
      
//       if (ordersProvider.error != null && ordersProvider.orders.isEmpty) {
//         return _buildErrorState(ordersProvider);
//       }

//       return Scaffold(
//         backgroundColor: GlobalColors.background,
//         appBar: AppBar(
//           title: Text(
//             _isSelectionMode ? 'Select Orders' : 'Received Orders',
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               fontSize: 20,
//             ),
//           ),
//           backgroundColor: _isSelectionMode ? GlobalColors.primaryBlue.withOpacity(0.9) : GlobalColors.primaryBlue,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           actions: _isSelectionMode
//               ? [
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () {
//                       setState(() {
//                         _isSelectionMode = false;
//                         _selectedOrders.clear();
//                         _selectAll = false;
//                       });
//                     },
//                     tooltip: 'Cancel Selection',
//                   ),
//                 ]
//               : [
//                   IconButton(
//                     icon: const Icon(Icons.refresh),
//                     onPressed: () {
//                       setState(() {
//                         _isLoadingTimeout = false;
//                       });
//                       ordersProvider.refresh();
//                       _setupLoadingTimeout();
//                     },
//                   ),
//                 ],
//         ),
//         body: Consumer<ProductionOrdersProvider>(
//           builder: (context, ordersProvider, child) {
//             return Column(
//               children: [
//                 if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
//                   _buildStatistics(ordersProvider),
                
//                 if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
//                   _buildFilterTabs(ordersProvider),
                
//                 if (_isSelectionMode) 
//                   _buildBulkSelectionToolbar(ordersProvider),
                
//                 Expanded(
//                   child: _buildOrdersList(ordersProvider),
//                 ),
//               ],
//             );
//           },
//         ),
//         floatingActionButton: _isSelectionMode
//             ? Builder(
//                 builder: (context) {
//                   final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
//                   return FloatingActionButton.extended(
//                     onPressed: selectedCount > 0 
//                         ? () => _showBulkStatusUpdateDialog(context.read<ProductionOrdersProvider>())
//                         : null,
//                     backgroundColor: GlobalColors.primaryBlue,
//                     foregroundColor: Colors.white,
//                     icon: const Icon(Icons.check_circle),
//                     label: Text(
//                       'Update $selectedCount',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   );
//                 },
//               )
//             : null,
//       );
//     } catch (e, stackTrace) {
//       print('❌ Error in ProductionOrdersPage build: $e');
//       print('❌ Stack trace: $stackTrace');
//       return _buildErrorFallback();
//     }
//   }

//   Widget _buildTimeoutScreen(ProductionOrdersProvider provider) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: Text('Received Orders'),
//         backgroundColor: GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.timer_off, size: 64, color: Colors.orange),
//               SizedBox(height: 16),
//               Text(
//                 'Loading is taking too long',
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 'Please check your internet connection',
//                 style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
//               ),
//               SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _isLoadingTimeout = false;
//                   });
//                   provider.refresh();
//                   _setupLoadingTimeout();
//                 },
//                 style: ElevatedButton.styleFrom(backgroundColor: GlobalColors.primaryBlue),
//                 child: Text('Retry', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState(ProductionOrdersProvider ordersProvider) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: Text(
//           'Received Orders',
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
//               ordersProvider.refresh();
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 size: 64,
//                 color: Colors.red,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Error Loading Orders',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.red,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 ordersProvider.error ?? 'Unknown error occurred',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   ordersProvider.refresh();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                 ),
//                 child: const Text(
//                   'Retry',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorFallback() {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: Text('Received Orders'),
//         backgroundColor: GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.error_outline, size: 64, color: Colors.red),
//               SizedBox(height: 16),
//               Text(
//                 'Something went wrong',
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 'Please try restarting the app',
//                 style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
//               ),
//               SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   Provider.of<ProductionOrdersProvider>(context, listen: false).refresh();
//                 },
//                 style: ElevatedButton.styleFrom(backgroundColor: GlobalColors.primaryBlue),
//                 child: Text('Retry', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatistics(ProductionOrdersProvider ordersProvider) {
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

//   Widget _buildFilterTabs(ProductionOrdersProvider ordersProvider) {
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
//                   if (selected) {
//                     ordersProvider.setFilter(filter['value']!);
//                   }
//                 },
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildBulkSelectionToolbar(ProductionOrdersProvider ordersProvider) {
//     final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: GlobalColors.primaryBlue,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Checkbox(
//             value: _selectAll,
//             onChanged: (value) {
//               setState(() {
//                 _selectAll = value ?? false;
//                 for (var order in ordersProvider.filteredOrders) {
//                   _selectedOrders[order.id] = _selectAll;
//                 }
//               });
//             },
//             activeColor: Colors.white,
//             checkColor: GlobalColors.primaryBlue,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               _selectAll 
//                   ? 'All ${ordersProvider.filteredOrders.length} selected'
//                   : '$selectedCount selected',
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrdersList(ProductionOrdersProvider ordersProvider) {
//     // Show loading only if no orders and loading
//     if (ordersProvider.orders.isEmpty) {
//       if (ordersProvider.isQuickLoading || ordersProvider.isLoading) {
//         return _buildInitialLoading('Loading orders...');
//       }
//       return _buildEmptyState(ordersProvider);
//     }

//     // Show filtered orders
//     if (ordersProvider.filteredOrders.isEmpty) {
//       return _buildEmptyFilterState(ordersProvider);
//     }

//     return RefreshIndicator(
//       color: GlobalColors.primaryBlue,
//       onRefresh: () async {
//         await ordersProvider.refresh();
//         _loadSelectedOrders(ordersProvider);
//         setState(() {
//           _isLoadingTimeout = false;
//         });
//         _setupLoadingTimeout();
//       },
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: ordersProvider.filteredOrders.length + (ordersProvider.hasMoreData ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == ordersProvider.filteredOrders.length) {
//             return _buildLoadMoreButton(ordersProvider);
//           }
          
//           final order = ordersProvider.filteredOrders[index];
//           return _buildOrderCard(order, context, ordersProvider);
//         },
//       ),
//     );
//   }

//   Widget _buildInitialLoading(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(color: GlobalColors.primaryBlue),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextButton(
//             onPressed: () {
//               Provider.of<ProductionOrdersProvider>(context, listen: false).refresh();
//             },
//             child: Text(
//               'Retry',
//               style: GoogleFonts.poppins(
//                 color: GlobalColors.primaryBlue,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadMoreButton(ProductionOrdersProvider ordersProvider) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Center(
//         child: ordersProvider.isLoading
//             ? CircularProgressIndicator(color: GlobalColors.primaryBlue)
//             : ElevatedButton(
//                 onPressed: ordersProvider.hasMoreData ? () {
//                   ordersProvider.loadMore();
//                 } : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: Text(ordersProvider.hasMoreData ? 'Load More Orders' : 'No More Orders'),
//               ),
//       ),
//     );
//   }

//   Widget _buildEmptyState(ProductionOrdersProvider ordersProvider) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.receipt_long_outlined,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No orders found',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Pull down to refresh',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () {
//               ordersProvider.refresh();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: GlobalColors.primaryBlue,
//             ),
//             child: const Text(
//               'Refresh',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyFilterState(ProductionOrdersProvider ordersProvider) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.filter_list_off,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No ${ordersProvider.filter.replaceAll('_', ' ')} orders',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Try changing the filter',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () {
//               ordersProvider.setFilter('all');
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: GlobalColors.primaryBlue,
//             ),
//             child: const Text(
//               'Show All Orders',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrderCard(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
//     final isSelected = _selectedOrders[order.id] ?? false;
    
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
//         border: _isSelectionMode && isSelected
//             ? Border.all(color: GlobalColors.primaryBlue, width: 2)
//             : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () {
//             if (_isSelectionMode) {
//               setState(() {
//                 _selectedOrders[order.id] = !isSelected;
//               });
//             } else {
//               _showOrderDetails(order, context, ordersProvider);
//             }
//           },
//           onLongPress: () {
//             setState(() {
//               _isSelectionMode = true;
//               _selectedOrders[order.id] = true;
//             });
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (_isSelectionMode)
//                   Padding(
//                     padding: const EdgeInsets.only(right: 12, top: 4),
//                     child: Checkbox(
//                       value: isSelected,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedOrders[order.id] = value ?? false;
//                         });
//                       },
//                       activeColor: GlobalColors.primaryBlue,
//                     ),
//                   ),
                
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Order #${order.id.substring(0, 8)}',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: order.statusColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: order.statusColor.withOpacity(0.3)),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(order.statusIcon, size: 14, color: order.statusColor),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   order.displayStatus,
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                     color: order.statusColor,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       _infoRow('Customer:', order.customerName),
//                       _infoRow('Product:', order.productName),
//                       _infoRow('District:', order.district.isNotEmpty ? order.district : 'Not specified'),
//                       _infoRow('Bags:', order.displayQuantity),
                      
//                       if (order.customerMobile.isNotEmpty)
//                         _infoRow('Mobile:', order.customerMobile),
                      
//                       if (order.customerAddress.isNotEmpty)
//                         _infoRow('Address:', order.customerAddress),

//                       const SizedBox(height: 12),

//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.totalPrice}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.blue[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Total Price',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.blue[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.pricePerBag}/bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.green[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Price per Bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.green[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       if (!_isSelectionMode && 
//                           order.status.toLowerCase() != 'completed' &&
//                           order.status.toLowerCase() != 'cancelled')
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () => _showStatusUpdateDialog(order, context, ordersProvider),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: GlobalColors.primaryBlue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Update Status',
//                               style: GoogleFonts.poppins(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
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
//     ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) async {
    
//     final statusOptions = [
//   'pending', 
//   'packing', 
//   'ready_for_dispatch', 
//   'dispatched', 
//   'delivered', 
//   'completed', 
//   'cancelled'
// ].where((s) => s != order.status.toLowerCase()).toList();
    
//     final statusDisplayNames = {
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
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.8,
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 60,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Update Order Status',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Order #${order.id.substring(0, 8)}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Current: ${order.displayStatus}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: order.statusColor,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   ...statusOptions.map((status) {
//                     final displayName = statusDisplayNames[status] ?? status;
//                     return ListTile(
//                       contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                       leading: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: _getStatusColor(status).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           _getStatusIcon(status),
//                           size: 20,
//                           color: _getStatusColor(status),
//                         ),
//                       ),
//                       title: Text(
//                         displayName,
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                       onTap: () async {
//                         Navigator.pop(context);
//                         await _updateOrderStatus(
//                           order,
//                           status,
//                           context,
//                           ordersProvider,
//                         );
//                       },
//                     );
//                   }).toList(),
                  
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//  // In _updateOrderStatus function, add better error handling
// Future<void> _updateOrderStatus(
//     ProductionOrderItem order, String newStatus, BuildContext context, ProductionOrdersProvider ordersProvider) async {
//   try {
//     if (!context.mounted) return;
    
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(
//         child: CircularProgressIndicator(),
//       ),
//     );

//     // Ensure status is lowercase and trimmed
//     final normalizedStatus = newStatus.toLowerCase().trim();
//     print('📝 Attempting to update order ${order.id} to status: $normalizedStatus');
    
//     await ordersProvider.updateOrderStatus(order, normalizedStatus);
    
//     if (context.mounted) {
//       Navigator.pop(context); // Close loading dialog
//     }

//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ Order status updated to ${_getStatusDisplayName(normalizedStatus)}'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   } catch (e) {
//     print('❌ Error in _updateOrderStatus: $e');
    
//     if (context.mounted) {
//       // Close loading dialog if it's still open
//       try {
//         Navigator.pop(context);
//       } catch (_) {}
//     }
    
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           duration: const Duration(seconds: 3),
//           action: SnackBarAction(
//             label: 'Retry',
//             textColor: Colors.white,
//             onPressed: () {
//               _updateOrderStatus(order, newStatus, context, ordersProvider);
//             },
//           ),
//         ),
//       );
//     }
//   }
// }


//   String _getStatusDisplayName(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending': return 'Pending';
//       case 'packing': return 'Packing';
//       case 'ready_for_dispatch': return 'Ready for Dispatch';
//       case 'dispatched': return 'Dispatched';
//       case 'delivered': return 'Delivered';
//       case 'completed': return 'Completed';
//       case 'cancelled': return 'Cancelled';
//       default: return status;
//     }
//   }

//   Future<void> _showBulkStatusUpdateDialog(ProductionOrdersProvider ordersProvider) async {
//     final selectedOrderIds = _selectedOrders.entries
//         .where((entry) => entry.value)
//         .map((entry) => entry.key)
//         .toList();
    
//     if (selectedOrderIds.isEmpty) return;
    
//     final statusDisplayNames = {
//       'pending': 'Pending',
//       'packing': 'Packing',
//       'ready_for_dispatch': 'Ready for Dispatch',
//       'dispatched': 'Dispatched',
//       'delivered': 'Delivered',
//       'completed': 'Completed',
//       'cancelled': 'Cancelled',
//     };
    
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.7,
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 60,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Bulk Update Status',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Updating ${selectedOrderIds.length} orders',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   Text(
//                     'Select New Status:',
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
                  
//                   Column(
//                     children: ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled']
//                         .map((status) {
//                       final displayName = statusDisplayNames[status] ?? status;
//                       return ListTile(
//                         contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                         leading: Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: _getStatusColor(status).withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Icon(
//                             _getStatusIcon(status),
//                             size: 20,
//                             color: _getStatusColor(status),
//                           ),
//                         ),
//                         title: Text(
//                           displayName,
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                         onTap: () async {
//                           Navigator.pop(context);
//                           await _updateBulkOrderStatus(selectedOrderIds, status, ordersProvider);
//                         },
//                       );
//                     }).toList(),
//                   ),
                  
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // Add this to your production_orders_page.dart in the bulk update section
// // Replace your existing _updateBulkOrderStatus with this:
// Future<void> _updateBulkOrderStatus(
//     List<String> orderIds, 
//     String newStatus, 
//     ProductionOrdersProvider ordersProvider) async {
//   try {
//     if (!context.mounted) return;
    
//     // Show progress dialog
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 16),
//             Text('Updating ${orderIds.length} orders...'),
//             const SizedBox(height: 8),
//             Text(
//               'This may take a few seconds',
//               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       ),
//     );

//     print('📝 Bulk updating ${orderIds.length} orders to: $newStatus');
//     await ordersProvider.updateBulkOrderStatus(orderIds, newStatus);
    
//     if (context.mounted) {
//       // Close progress dialog
//       if (Navigator.canPop(context)) {
//         Navigator.pop(context);
//       }
      
//       // Exit selection mode
//       setState(() {
//         _isSelectionMode = false;
//         _selectedOrders.clear();
//         _selectAll = false;
//       });
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ ${orderIds.length} orders updated to ${_getStatusDisplayName(newStatus)}'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
    
//   } catch (e) {
//     print('❌ Bulk update error: $e');
    
//     if (context.mounted) {
//       // Close progress dialog
//       if (Navigator.canPop(context)) {
//         Navigator.pop(context);
//       }
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 4),
//           action: SnackBarAction(
//             label: 'Retry',
//             textColor: Colors.white,
//             onPressed: () {
//               _updateBulkOrderStatus(orderIds, newStatus, ordersProvider);
//             },
//           ),
//         ),
//       );
//     }
//   }
// }

//   void _showOrderDetails(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
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
              
//               _detailRow('Customer Name', order.customerName, Icons.person),
//               _detailRow('Customer Mobile', order.customerMobile, Icons.phone),
//               _detailRow('Customer Address', order.customerAddress, Icons.location_on),
//               _detailRow('District', order.district.isNotEmpty ? order.district : 'Not specified', Icons.map),
              
//               _detailRow('Product', order.productName, Icons.inventory),
//               _detailRow('Bags', '${order.bags} Bags', Icons.shopping_bag),
//               _detailRow('Weight per Bag', '${order.weightPerBag} ${order.weightUnit}', Icons.scale),
//               _detailRow('Total Weight', '${order.totalWeight} ${order.weightUnit}', Icons.scale),
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

//   void _loadSelectedOrders(ProductionOrdersProvider ordersProvider) {
//     _selectedOrders.clear();
//     for (var order in ordersProvider.orders) {
//       _selectedOrders[order.id] = false;
//     }
//   }

//   @override
//   void dispose() {
//     _selectedOrders.clear();
//     super.dispose();
//   }
// }

















// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/order_item_model.dart';
// import 'package:mega_pro/providers/pro_orders_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ProductionOrdersPage extends StatefulWidget {
//   const ProductionOrdersPage({super.key, required Map productionProfile, required Null Function() onDataChanged});

//   @override
//   State<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
// }

// class _ProductionOrdersPageState extends State<ProductionOrdersPage> {
//   Map<String, bool> _selectedOrders = {};
//   bool _isSelectionMode = false;
//   bool _selectAll = false;

//   @override
//   void initState() {
//     super.initState();
//     _getProductionManagerDistrict();
//   }

//   Future<void> _getProductionManagerDistrict() async {
//   try {
//     final ordersProvider = Provider.of<ProductionOrdersProvider>(
//       context, 
//       listen: false
//     );
    
//     // Get the current user
//     final user = Supabase.instance.client.auth.currentUser;
//     if (user != null) {
//       print('👤 DEBUG: Getting district for user ID: ${user.id}');
//       print('👤 DEBUG: User email: ${user.email}');
      
//       // Try to get district from emp_profile table
//       print('🔍 DEBUG: Querying emp_profile table for user...');
//       final response = await Supabase.instance.client
//           .from('emp_profile')  // Changed from 'profiles' to 'emp_profile'
//           .select('id, emp_id, full_name, email, role, district, position')
//           .eq('user_id', user.id)  // Changed from 'id' to 'user_id'
//           .maybeSingle();
      
//       print('🔍 DEBUG: emp_profile query response: $response');
      
//       if (response != null) {
//         print('✅ DEBUG: Employee profile found');
//         print('   👤 ID: ${response['id']}');
//         print('   👤 Employee ID: ${response['emp_id']}');
//         print('   👤 Name: ${response['full_name']}');
//         print('   👤 Email: ${response['email']}');
//         print('   👤 Role: ${response['role']}');
//         print('   👤 Position: ${response['position']}');
//         print('   📍 District: ${response['district']}');
        
//         if (response['district'] != null) {
//           final district = response['district'].toString();
//           print('📍 Production manager district found: $district');
//           ordersProvider.setProductionManagerDistrict(district);
//         } else {
//           print('⚠️ WARNING: No district found in employee profile');
//           print('⚠️ WARNING: Production manager will see ALL orders');
//         }
//       } else {
//         print('❌ ERROR: No employee profile found for user');
//         print('❌ ERROR: Check if emp_profile table has record for user_id: ${user.id}');
//       }
//     } else {
//       print('❌ ERROR: No authenticated user found');
//     }
//   } catch (e) {
//     print('❌ ERROR getting production manager district: $e');
//     print('❌ ERROR Stack trace: $e');
//   }
// }
  
//   @override
//   Widget build(BuildContext context) {
//     final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: true);
    
//     // Show district info if available
//     final districtInfo = ordersProvider.productionManagerDistrict != null &&
//         ordersProvider.productionManagerDistrict!.isNotEmpty
//         ? ' (District: ${ordersProvider.productionManagerDistrict})'
//         : '';
    
//     // Show error only if we have an error and no orders at all
//     if (ordersProvider.error != null && ordersProvider.orders.isEmpty) {
//       return Scaffold(
//         backgroundColor: GlobalColors.background,
//         appBar: AppBar(
//           title: Text(
//             'Received Orders ',
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               fontSize: 20,
//             ),
//           ),
//           backgroundColor: GlobalColors.primaryBlue,
//           foregroundColor: Colors.white,
//           centerTitle: true,
//           elevation: 0,
//         ),
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.error_outline,
//                   size: 64,
//                   color: Colors.red,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Error Loading Orders',
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.red,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   ordersProvider.error!,
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () {
//                     ordersProvider.refresh();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: GlobalColors.primaryBlue,
//                   ),
//                   child: const Text(
//                     'Retry',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: _isSelectionMode 
//             ? Text(
//                 'Select Orders$districtInfo',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 20,
//                 ),
//               )
//             : Text(
//                 'Received Orders',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 20,
//                 ),
//               ),
//         backgroundColor: _isSelectionMode ? GlobalColors.primaryBlue.withOpacity(0.9) : GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: _isSelectionMode
//             ? [
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () {
//                     setState(() {
//                       _isSelectionMode = false;
//                       _selectedOrders.updateAll((key, value) => false);
//                       _selectAll = false;
//                     });
//                   },
//                   tooltip: 'Cancel Selection',
//                 ),
//               ]
//             : [
//                 IconButton(
//                   icon: const Icon(Icons.refresh),
//                   onPressed: () {
//                     ordersProvider.refresh();
//                   },
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.info_outline),
//                   onPressed: () {
//                     _showDistrictInfo(ordersProvider);
//                   },
//                   tooltip: 'District Info',
//                 ),
//               ],
//       ),
//       body: Consumer<ProductionOrdersProvider>(
//         builder: (context, ordersProvider, child) {
//           return Column(
//             children: [
//               if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
//                 _buildStatistics(ordersProvider),
              
//               if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
//                 _buildFilterTabs(ordersProvider),
              
//               if (_isSelectionMode) 
//                 _buildBulkSelectionToolbar(ordersProvider),
              
//               Expanded(
//                 child: _buildOrdersList(ordersProvider),
//               ),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: _isSelectionMode
//           ? Builder(
//               builder: (context) {
//                 final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
//                 return FloatingActionButton.extended(
//                   onPressed: () {
//                     if (selectedCount > 0) {
//                       _showBulkStatusUpdateDialog(context.read<ProductionOrdersProvider>());
//                     }
//                   },
//                   backgroundColor: GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                   icon: const Icon(Icons.check_circle),
//                   label: Text(
//                     'Update $selectedCount',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 );
//               },
//             )
//           : null,
//     );
//   }

//   Widget _buildStatistics(ProductionOrdersProvider ordersProvider) {
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

//   Widget _buildFilterTabs(ProductionOrdersProvider ordersProvider) {
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

//   Widget _buildBulkSelectionToolbar(ProductionOrdersProvider ordersProvider) {
//     final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: GlobalColors.primaryBlue,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Checkbox(
//             value: _selectAll,
//             onChanged: (value) {
//               setState(() {
//                 _selectAll = value ?? false;
//                 for (var order in ordersProvider.filteredOrders) {
//                   _selectedOrders[order.id] = _selectAll;
//                 }
//               });
//             },
//             activeColor: Colors.white,
//             checkColor: GlobalColors.primaryBlue,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               _selectAll 
//                   ? 'All ${ordersProvider.filteredOrders.length} selected'
//                   : '$selectedCount selected',
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrdersList(ProductionOrdersProvider ordersProvider) {
//     // Show initial loading only if we have no orders and are loading
//     if (ordersProvider.isQuickLoading && ordersProvider.orders.isEmpty) {
//       return _buildInitialLoading('Loading recent orders...');
//     }
    
//     // Show loading for full load if we have quick-loaded orders
//     if (ordersProvider.isLoading && !ordersProvider.initialLoadComplete && ordersProvider.orders.isNotEmpty) {
//       return Column(
//         children: [
//           Expanded(
//             child: RefreshIndicator(
//               color: GlobalColors.primaryBlue,
//               onRefresh: () async {
//                 await ordersProvider.refresh();
//                 _loadSelectedOrders(ordersProvider);
//               },
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: ordersProvider.orders.length,
//                 itemBuilder: (context, index) {
//                   final order = ordersProvider.orders[index];
//                   return _buildOrderCard(order, context, ordersProvider);
//                 },
//               ),
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.white,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(color: GlobalColors.primaryBlue),
//                 const SizedBox(width: 12),
//                 Text(
//                   'Loading complete order details...',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       );
//     }

//     if (ordersProvider.filteredOrders.isEmpty) {
//       return _buildEmptyState(ordersProvider);
//     }

//     return RefreshIndicator(
//       color: GlobalColors.primaryBlue,
//       onRefresh: () async {
//         await ordersProvider.refresh();
//         _loadSelectedOrders(ordersProvider);
//       },
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: ordersProvider.filteredOrders.length + (ordersProvider.hasMoreData ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == ordersProvider.filteredOrders.length) {
//             return _buildLoadMoreButton(ordersProvider);
//           }
          
//           final order = ordersProvider.filteredOrders[index];
//           return _buildOrderCard(order, context, ordersProvider);
//         },
//       ),
//     );
//   }

//   Widget _buildInitialLoading(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(color: GlobalColors.primaryBlue),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadMoreButton(ProductionOrdersProvider ordersProvider) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Center(
//         child: ordersProvider.isLoading
//             ? CircularProgressIndicator(color: GlobalColors.primaryBlue)
//             : ElevatedButton(
//                 onPressed: () {
//                   ordersProvider.loadMore();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Load More Orders'),
//               ),
//       ),
//     );
//   }

//   Widget _buildEmptyState(ProductionOrdersProvider ordersProvider) {
//     final district = ordersProvider.productionManagerDistrict;
//     final districtMessage = district != null && district.isNotEmpty
//         ? 'for district: $district'
//         : '';
    
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.receipt_long_outlined,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No orders found',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             ordersProvider.filter == 'all'
//                 ? 'No orders available $districtMessage'
//                 : 'No ${ordersProvider.filter.replaceAll('_', ' ')} orders $districtMessage',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           if (!ordersProvider.isQuickLoading && !ordersProvider.isLoading)
//             ElevatedButton(
//               onPressed: () {
//                 ordersProvider.refresh();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: GlobalColors.primaryBlue,
//               ),
//               child: const Text(
//                 'Refresh',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrderCard(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
//     final isSelected = _selectedOrders[order.id] ?? false;
    
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
//         border: _isSelectionMode && isSelected
//             ? Border.all(color: GlobalColors.primaryBlue, width: 2)
//             : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () {
//             if (_isSelectionMode) {
//               setState(() {
//                 _selectedOrders[order.id] = !isSelected;
//               });
//             } else {
//               _showOrderDetails(order, context, ordersProvider);
//             }
//           },
//           onLongPress: () {
//             setState(() {
//               _isSelectionMode = true;
//               _selectedOrders[order.id] = true;
//             });
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (_isSelectionMode)
//                   Padding(
//                     padding: const EdgeInsets.only(right: 12, top: 4),
//                     child: Checkbox(
//                       value: isSelected,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedOrders[order.id] = value ?? false;
//                         });
//                       },
//                       activeColor: GlobalColors.primaryBlue,
//                     ),
//                   ),
                
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Order #${order.id.substring(0, 8)}',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: order.statusColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: order.statusColor.withOpacity(0.3)),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(order.statusIcon, size: 14, color: order.statusColor),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   order.displayStatus,
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                     color: order.statusColor,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       _infoRow('Customer:', order.customerName),
//                       _infoRow('Product:', order.productName),
//                       _infoRow('District:', order.district.isNotEmpty ? order.district : 'Not specified'),
//                       _infoRow('Bags:', order.displayQuantity),
                      
//                       if (order.customerMobile.isNotEmpty)
//                         _infoRow('Mobile:', order.customerMobile),
                      
//                       if (order.customerAddress.isNotEmpty)
//                         _infoRow('Address:', order.customerAddress),

//                       const SizedBox(height: 12),

//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.totalPrice}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.blue[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Total Price',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.blue[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.pricePerBag}/bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.green[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Price per Bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.green[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       if (!_isSelectionMode && 
//                           order.status.toLowerCase() != 'completed' &&
//                           order.status.toLowerCase() != 'cancelled')
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () => _showStatusUpdateDialog(order, context, ordersProvider),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: GlobalColors.primaryBlue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Update Status',
//                               style: GoogleFonts.poppins(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
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
//     ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) async {
//   final statusOptions = ordersProvider.getNextStatusOptions(order);
  
//   Map<String, String> statusDisplayNames = {
//     'pending': 'Pending',
//     'packing': 'Packing',
//     'ready_for_dispatch': 'Ready for Dispatch',
//     'dispatched': 'Dispatched',
//     'delivered': 'Delivered',
//     'completed': 'Completed',
//     'cancelled': 'Cancelled',
//   };
  
//   if (statusOptions.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('No status updates available for this order'),
//         backgroundColor: Colors.orange,
//       ),
//     );
//     return;
//   }
  
//   await showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (context) {
//       return Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.8,
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 60,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Update Order Status',
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Order #${order.id.substring(0, 8)}',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Current: ${order.displayStatus}',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: order.statusColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 ...statusOptions.map((status) {
//                   final displayName = statusDisplayNames[status] ?? status;
//                   return ListTile(
//                     contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                     leading: Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(status).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Icon(
//                         _getStatusIcon(status),
//                         size: 20,
//                         color: _getStatusColor(status),
//                       ),
//                     ),
//                     title: Text(
//                       displayName,
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                     onTap: () async {
//                       Navigator.pop(context);
//                       await _updateOrderStatus(
//                         order,
//                         status,
//                         context,
//                         ordersProvider,
//                       );
//                     },
//                   );
//                 }).toList(),
                
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 48),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Cancel',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }

//   Future<void> _updateOrderStatus(
//       ProductionOrderItem order, String newStatus, BuildContext context, ProductionOrdersProvider ordersProvider) async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       await ordersProvider.updateOrderStatus(order, newStatus);
      
//       if (context.mounted) {
//         Navigator.pop(context);
//       }

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
//       if (context.mounted) {
//         Navigator.pop(context);
//       }
      
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

//   Future<void> _showBulkStatusUpdateDialog(ProductionOrdersProvider ordersProvider) async {
//   final selectedOrderIds = _selectedOrders.entries
//       .where((entry) => entry.value)
//       .map((entry) => entry.key)
//       .toList();
  
//   if (selectedOrderIds.isEmpty) return;
  
//   Map<String, String> statusDisplayNames = {
//     'pending': 'Pending',
//     'packing': 'Packing',
//     'ready_for_dispatch': 'Ready for Dispatch',
//     'dispatched': 'Dispatched',
//     'delivered': 'Delivered',
//     'completed': 'Completed',
//     'cancelled': 'Cancelled',
//   };
  
//   await showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (context) {
//       return Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.7,
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 60,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Bulk Update Status',
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Updating ${selectedOrderIds.length} orders',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 Text(
//                   'Select New Status:',
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
                
//                 Column(
//                   children: ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled']
//                       .map((status) {
//                     final displayName = statusDisplayNames[status] ?? status;
//                     return ListTile(
//                       contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                       leading: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: _getStatusColor(status).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           _getStatusIcon(status),
//                           size: 20,
//                           color: _getStatusColor(status),
//                         ),
//                       ),
//                       title: Text(
//                         displayName,
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                       onTap: () async {
//                         Navigator.pop(context);
//                         await _updateBulkOrderStatus(selectedOrderIds, status, ordersProvider);
//                       },
//                     );
//                   }).toList(),
//                 ),
                
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 48),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Cancel',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }

//   Future<void> _updateBulkOrderStatus(
//       List<String> orderIds, 
//       String newStatus, 
//       ProductionOrdersProvider ordersProvider) async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       await ordersProvider.updateBulkOrderStatus(orderIds, newStatus);
      
//       if (context.mounted) {
//         Navigator.pop(context);
//       }
      
//       setState(() {
//         _isSelectionMode = false;
//         _selectedOrders.updateAll((key, value) => false);
//         _selectAll = false;
//       });

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
//             content: Text('✅ ${orderIds.length} orders updated to ${displayNames[newStatus] ?? newStatus}'),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       if (context.mounted) {
//         Navigator.pop(context);
//       }
      
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

//   void _showOrderDetails(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
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
              
//               _detailRow('Customer Name', order.customerName, Icons.person),
//               _detailRow('Customer Mobile', order.customerMobile, Icons.phone),
//               _detailRow('Customer Address', order.customerAddress, Icons.location_on),
//               _detailRow('District', order.district.isNotEmpty ? order.district : 'Not specified', Icons.map),
              
//               _detailRow('Product', order.productName, Icons.inventory),
//               _detailRow('Bags', '${order.bags} Bags', Icons.shopping_bag),
//               _detailRow('Weight per Bag', '${order.weightPerBag} ${order.weightUnit}', Icons.scale),
//               _detailRow('Total Weight', '${order.totalWeight} ${order.weightUnit}', Icons.scale),
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

//   void _loadSelectedOrders(ProductionOrdersProvider ordersProvider) {
//     _selectedOrders.clear();
//     for (var order in ordersProvider.orders) {
//       _selectedOrders[order.id] = false;
//     }
//   }

//   void _showDistrictInfo(ProductionOrdersProvider ordersProvider) {
//     final district = ordersProvider.productionManagerDistrict;
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Row(
//             children: [
//               Icon(Icons.map_outlined, color: GlobalColors.primaryBlue),
//               const SizedBox(width: 8),
//               Text(
//                 'District Data',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           content: Text(
//             district != null && district.isNotEmpty
//                 ? 'You are viewing orders only from:\n\n📌 $district\n\nOnly orders from this district will appear in your list.'
//                 : 'No district filter is applied.\n\n⚠️ You are viewing orders from all districts.',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }




















// // import 'package:flutter/material.dart';
// // import 'package:mega_pro/providers/pro_orders_provider.dart';
// // import 'package:provider/provider.dart';
// // import 'package:intl/intl.dart';
// // import 'package:mega_pro/global/global_variables.dart';
// // import 'package:google_fonts/google_fonts.dart';

// // class ProductionOrdersPage extends StatefulWidget {
// //   const ProductionOrdersPage({super.key, required Map productionProfile, required Null Function() onDataChanged});

// //   @override
// //   State<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
// // }

// // class _ProductionOrdersPageState extends State<ProductionOrdersPage> {
// //   Map<String, bool> _selectedOrders = {};
// //   bool _isSelectionMode = false;
// //   bool _selectAll = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     // No need for manual initialization, provider handles it
// //   }
  
// //   @override
// //   Widget build(BuildContext context) {
// //     final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: true);
    
// //     // Show error only if we have an error and no orders at all
// //     if (ordersProvider.error != null && ordersProvider.orders.isEmpty) {
// //       return Scaffold(
// //         backgroundColor: GlobalColors.background,
// //         appBar: AppBar(
// //           title: Text(
// //             'Production Orders',
// //             style: GoogleFonts.poppins(
// //               fontWeight: FontWeight.w600,
// //               fontSize: 20,
// //             ),
// //           ),
// //           backgroundColor: GlobalColors.primaryBlue,
// //           foregroundColor: Colors.white,
// //           centerTitle: true,
// //           elevation: 0,
// //         ),
// //         body: Center(
// //           child: Padding(
// //             padding: const EdgeInsets.all(20.0),
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 const Icon(
// //                   Icons.error_outline,
// //                   size: 64,
// //                   color: Colors.red,
// //                 ),
// //                 const SizedBox(height: 16),
// //                 Text(
// //                   'Error Loading Orders',
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.w600,
// //                     color: Colors.red,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 Text(
// //                   ordersProvider.error!,
// //                   textAlign: TextAlign.center,
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 14,
// //                     color: Colors.grey[600],
// //                   ),
// //                 ),
// //                 const SizedBox(height: 16),
// //                 ElevatedButton(
// //                   onPressed: () {
// //                     ordersProvider.refresh();
// //                   },
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: GlobalColors.primaryBlue,
// //                   ),
// //                   child: const Text(
// //                     'Retry',
// //                     style: TextStyle(color: Colors.white),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       );
// //     }

// //     return Scaffold(
// //       backgroundColor: GlobalColors.background,
// //       appBar: AppBar(
// //         title: _isSelectionMode 
// //             ? Text(
// //                 'Select Orders',
// //                 style: GoogleFonts.poppins(
// //                   fontWeight: FontWeight.w600,
// //                   fontSize: 20,
// //                 ),
// //               )
// //             : Text(
// //                 'Production Orders',
// //                 style: GoogleFonts.poppins(
// //                   fontWeight: FontWeight.w600,
// //                   fontSize: 20,
// //                 ),
// //               ),
// //         backgroundColor: _isSelectionMode ? GlobalColors.primaryBlue.withOpacity(0.9) : GlobalColors.primaryBlue,
// //         foregroundColor: Colors.white,
// //         centerTitle: true,
// //         elevation: 0,
// //         actions: _isSelectionMode
// //             ? [
// //                 IconButton(
// //                   icon: const Icon(Icons.close),
// //                   onPressed: () {
// //                     setState(() {
// //                       _isSelectionMode = false;
// //                       _selectedOrders.updateAll((key, value) => false);
// //                       _selectAll = false;
// //                     });
// //                   },
// //                   tooltip: 'Cancel Selection',
// //                 ),
// //               ]
// //             : [
// //                 IconButton(
// //                   icon: const Icon(Icons.refresh),
// //                   onPressed: () {
// //                     ordersProvider.refresh();
// //                   },
// //                 ),
// //               ],
// //       ),
// //       body: Consumer<ProductionOrdersProvider>(
// //         builder: (context, ordersProvider, child) {
// //           return Column(
// //             children: [
// //               if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
// //                 _buildStatistics(ordersProvider),
              
// //               if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
// //                 _buildFilterTabs(ordersProvider),
              
// //               if (_isSelectionMode) 
// //                 _buildBulkSelectionToolbar(ordersProvider),
              
// //               Expanded(
// //                 child: _buildOrdersList(ordersProvider),
// //               ),
// //             ],
// //           );
// //         },
// //       ),
// //       floatingActionButton: _isSelectionMode
// //           ? Builder(
// //               builder: (context) {
// //                 final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
// //                 return FloatingActionButton.extended(
// //                   onPressed: () {
// //                     if (selectedCount > 0) {
// //                       _showBulkStatusUpdateDialog(context.read<ProductionOrdersProvider>());
// //                     }
// //                   },
// //                   backgroundColor: GlobalColors.primaryBlue,
// //                   foregroundColor: Colors.white,
// //                   icon: const Icon(Icons.check_circle),
// //                   label: Text(
// //                     'Update $selectedCount',
// //                     style: GoogleFonts.poppins(
// //                       fontWeight: FontWeight.w500,
// //                     ),
// //                   ),
// //                 );
// //               },
// //             )
// //           : null,
// //     );
// //   }

// //   Widget _buildStatistics(ProductionOrdersProvider ordersProvider) {
// //     final stats = ordersProvider.getStatistics();
    
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.withOpacity(0.1),
// //             blurRadius: 10,
// //             spreadRadius: 1,
// //           ),
// //         ],
// //       ),
// //       child: SingleChildScrollView(
// //         scrollDirection: Axis.horizontal,
// //         child: Row(
// //           children: [
// //             _statCard('Total', stats['total']!, Colors.blue, Icons.receipt),
// //             const SizedBox(width: 12),
// //             _statCard('Pending', stats['pending']!, Colors.orange, Icons.pending),
// //             const SizedBox(width: 12),
// //             _statCard('Packing', stats['packing']!, Colors.blue, Icons.inventory),
// //             const SizedBox(width: 12),
// //             _statCard('Ready', stats['ready_for_dispatch']!, Colors.purple, Icons.local_shipping),
// //             const SizedBox(width: 12),
// //             _statCard('Dispatched', stats['dispatched']!, Colors.indigo, Icons.directions_car),
// //             const SizedBox(width: 12),
// //             _statCard('Delivered', stats['delivered']!, Colors.green, Icons.check_circle),
// //             const SizedBox(width: 12),
// //             _statCard('Completed', stats['completed']!, Colors.green, Icons.done_all),
// //             const SizedBox(width: 12),
// //             _statCard('Cancelled', stats['cancelled']!, Colors.red, Icons.cancel),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _statCard(String title, int count, Color color, IconData icon) {
// //     return Container(
// //       width: 110,
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: color.withOpacity(0.1),
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: color.withOpacity(0.2)),
// //       ),
// //       child: Column(
// //         children: [
// //           Row(
// //             children: [
// //               Container(
// //                 padding: const EdgeInsets.all(4),
// //                 decoration: BoxDecoration(
// //                   color: color.withOpacity(0.2),
// //                   borderRadius: BorderRadius.circular(8),
// //                 ),
// //                 child: Icon(icon, size: 16, color: color),
// //               ),
// //               const Spacer(),
// //               Text(
// //                 count.toString(),
// //                 style: GoogleFonts.poppins(
// //                   fontSize: 18,
// //                   fontWeight: FontWeight.w600,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 8),
// //           Text(
// //             title,
// //             style: GoogleFonts.poppins(
// //               fontSize: 12,
// //               fontWeight: FontWeight.w500,
// //               color: Colors.grey[700],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildFilterTabs(ProductionOrdersProvider ordersProvider) {
// //     final filters = [
// //       {'label': 'All', 'value': 'all'},
// //       {'label': 'Pending', 'value': 'pending'},
// //       {'label': 'Packing', 'value': 'packing'},
// //       {'label': 'Ready', 'value': 'ready_for_dispatch'},
// //       {'label': 'Dispatched', 'value': 'dispatched'},
// //       {'label': 'Delivered', 'value': 'delivered'},
// //       {'label': 'Completed', 'value': 'completed'},
// //       {'label': 'Cancelled', 'value': 'cancelled'},
// //     ];

// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         border: Border(
// //           bottom: BorderSide(color: Colors.grey[200]!),
// //         ),
// //       ),
// //       child: SingleChildScrollView(
// //         scrollDirection: Axis.horizontal,
// //         child: Row(
// //           children: filters.map((filter) {
// //             final isSelected = ordersProvider.filter == filter['value'];
// //             return Padding(
// //               padding: const EdgeInsets.only(right: 8),
// //               child: ChoiceChip(
// //                 label: Text(
// //                   filter['label']!,
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 13,
// //                     fontWeight: FontWeight.w500,
// //                     color: isSelected ? Colors.white : Colors.grey[700],
// //                   ),
// //                 ),
// //                 selected: isSelected,
// //                 selectedColor: GlobalColors.primaryBlue,
// //                 backgroundColor: Colors.grey[100],
// //                 shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(20),
// //                 ),
// //                 onSelected: (selected) {
// //                   ordersProvider.setFilter(filter['value']!);
// //                 },
// //               ),
// //             );
// //           }).toList(),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildBulkSelectionToolbar(ProductionOrdersProvider ordersProvider) {
// //     final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
    
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //       decoration: BoxDecoration(
// //         color: GlobalColors.primaryBlue,
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.1),
// //             blurRadius: 8,
// //             spreadRadius: 1,
// //           ),
// //         ],
// //       ),
// //       child: Row(
// //         children: [
// //           Checkbox(
// //             value: _selectAll,
// //             onChanged: (value) {
// //               setState(() {
// //                 _selectAll = value ?? false;
// //                 for (var order in ordersProvider.filteredOrders) {
// //                   _selectedOrders[order.id] = _selectAll;
// //                 }
// //               });
// //             },
// //             activeColor: Colors.white,
// //             checkColor: GlobalColors.primaryBlue,
// //           ),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: Text(
// //               _selectAll 
// //                   ? 'All ${ordersProvider.filteredOrders.length} selected'
// //                   : '$selectedCount selected',
// //               style: GoogleFonts.poppins(
// //                 color: Colors.white,
// //                 fontSize: 16,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildOrdersList(ProductionOrdersProvider ordersProvider) {
// //     // Show initial loading only if we have no orders and are loading
// //     if (ordersProvider.isQuickLoading && ordersProvider.orders.isEmpty) {
// //       return _buildInitialLoading('Loading recent orders...');
// //     }
    
// //     // Show loading for full load if we have quick-loaded orders
// //     if (ordersProvider.isLoading && !ordersProvider.initialLoadComplete && ordersProvider.orders.isNotEmpty) {
// //       return Column(
// //         children: [
// //           Expanded(
// //             child: RefreshIndicator(
// //               color: GlobalColors.primaryBlue,
// //               onRefresh: () async {
// //                 await ordersProvider.refresh();
// //                 _loadSelectedOrders();
// //               },
// //               child: ListView.builder(
// //                 padding: const EdgeInsets.all(16),
// //                 itemCount: ordersProvider.orders.length,
// //                 itemBuilder: (context, index) {
// //                   final order = ordersProvider.orders[index];
// //                   return _buildOrderCard(order, context, ordersProvider);
// //                 },
// //               ),
// //             ),
// //           ),
// //           Container(
// //             padding: const EdgeInsets.all(16),
// //             color: Colors.white,
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 CircularProgressIndicator(color: GlobalColors.primaryBlue),
// //                 const SizedBox(width: 12),
// //                 Text(
// //                   'Loading complete order details...',
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 14,
// //                     color: Colors.grey[600],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       );
// //     }

// //     if (ordersProvider.filteredOrders.isEmpty) {
// //       return _buildEmptyState(ordersProvider);
// //     }

// //     return RefreshIndicator(
// //       color: GlobalColors.primaryBlue,
// //       onRefresh: () async {
// //         await ordersProvider.refresh();
// //         _loadSelectedOrders();
// //       },
// //       child: ListView.builder(
// //         padding: const EdgeInsets.all(16),
// //         itemCount: ordersProvider.filteredOrders.length + (ordersProvider.hasMoreData ? 1 : 0),
// //         itemBuilder: (context, index) {
// //           if (index == ordersProvider.filteredOrders.length) {
// //             return _buildLoadMoreButton(ordersProvider);
// //           }
          
// //           final order = ordersProvider.filteredOrders[index];
// //           return _buildOrderCard(order, context, ordersProvider);
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildInitialLoading(String message) {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           CircularProgressIndicator(color: GlobalColors.primaryBlue),
// //           const SizedBox(height: 16),
// //           Text(
// //             message,
// //             style: GoogleFonts.poppins(
// //               fontSize: 14,
// //               color: Colors.grey[600],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildLoadMoreButton(ProductionOrdersProvider ordersProvider) {
// //     return Padding(
// //       padding: const EdgeInsets.all(16.0),
// //       child: Center(
// //         child: ordersProvider.isLoading
// //             ? CircularProgressIndicator(color: GlobalColors.primaryBlue)
// //             : ElevatedButton(
// //                 onPressed: () {
// //                   ordersProvider.loadMore();
// //                 },
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: GlobalColors.primaryBlue,
// //                   foregroundColor: Colors.white,
// //                 ),
// //                 child: const Text('Load More Orders'),
// //               ),
// //       ),
// //     );
// //   }

// //   Widget _buildEmptyState(ProductionOrdersProvider ordersProvider) {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(
// //             Icons.receipt_long_outlined,
// //             size: 80,
// //             color: Colors.grey[300],
// //           ),
// //           const SizedBox(height: 16),
// //           Text(
// //             'No orders found',
// //             style: GoogleFonts.poppins(
// //               fontSize: 18,
// //               fontWeight: FontWeight.w500,
// //               color: Colors.grey[600],
// //             ),
// //           ),
// //           const SizedBox(height: 8),
// //           Text(
// //             ordersProvider.filter == 'all'
// //                 ? 'No orders available'
// //                 : 'No ${ordersProvider.filter.replaceAll('_', ' ')} orders',
// //             style: GoogleFonts.poppins(
// //               fontSize: 14,
// //               color: Colors.grey[500],
// //             ),
// //           ),
// //           const SizedBox(height: 16),
// //           if (!ordersProvider.isQuickLoading && !ordersProvider.isLoading)
// //             ElevatedButton(
// //               onPressed: () {
// //                 ordersProvider.refresh();
// //               },
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: GlobalColors.primaryBlue,
// //               ),
// //               child: const Text(
// //                 'Refresh',
// //                 style: TextStyle(color: Colors.white),
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildOrderCard(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
// //     final isSelected = _selectedOrders[order.id] ?? false;
    
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.withOpacity(0.1),
// //             blurRadius: 8,
// //             spreadRadius: 1,
// //           ),
// //         ],
// //         border: _isSelectionMode && isSelected
// //             ? Border.all(color: GlobalColors.primaryBlue, width: 2)
// //             : null,
// //       ),
// //       child: Material(
// //         color: Colors.transparent,
// //         child: InkWell(
// //           borderRadius: BorderRadius.circular(12),
// //           onTap: () {
// //             if (_isSelectionMode) {
// //               setState(() {
// //                 _selectedOrders[order.id] = !isSelected;
// //               });
// //             } else {
// //               _showOrderDetails(order, context, ordersProvider);
// //             }
// //           },
// //           onLongPress: () {
// //             setState(() {
// //               _isSelectionMode = true;
// //               _selectedOrders[order.id] = true;
// //             });
// //           },
// //           child: Padding(
// //             padding: const EdgeInsets.all(16),
// //             child: Row(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 if (_isSelectionMode)
// //                   Padding(
// //                     padding: const EdgeInsets.only(right: 12, top: 4),
// //                     child: Checkbox(
// //                       value: isSelected,
// //                       onChanged: (value) {
// //                         setState(() {
// //                           _selectedOrders[order.id] = value ?? false;
// //                         });
// //                       },
// //                       activeColor: GlobalColors.primaryBlue,
// //                     ),
// //                   ),
                
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Row(
// //                         children: [
// //                           Expanded(
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   'Order #${order.id.substring(0, 8)}',
// //                                   style: GoogleFonts.poppins(
// //                                     fontSize: 16,
// //                                     fontWeight: FontWeight.w600,
// //                                     color: Colors.black,
// //                                   ),
// //                                 ),
// //                                 const SizedBox(height: 4),
// //                                 Text(
// //                                   DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
// //                                   style: GoogleFonts.poppins(
// //                                     fontSize: 12,
// //                                     color: Colors.grey[600],
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                           Container(
// //                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //                             decoration: BoxDecoration(
// //                               color: order.statusColor.withOpacity(0.1),
// //                               borderRadius: BorderRadius.circular(20),
// //                               border: Border.all(color: order.statusColor.withOpacity(0.3)),
// //                             ),
// //                             child: Row(
// //                               children: [
// //                                 Icon(order.statusIcon, size: 14, color: order.statusColor),
// //                                 const SizedBox(width: 6),
// //                                 Text(
// //                                   order.displayStatus,
// //                                   style: GoogleFonts.poppins(
// //                                     fontSize: 12,
// //                                     fontWeight: FontWeight.w500,
// //                                     color: order.statusColor,
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ],
// //                       ),

// //                       const SizedBox(height: 12),

// //                       _infoRow('Customer:', order.customerName),
// //                       _infoRow('Product:', order.productName),
// //                       _infoRow('Bags:', order.displayQuantity),
                      
// //                       if (order.customerMobile.isNotEmpty)
// //                         _infoRow('Mobile:', order.customerMobile),
                      
// //                       if (order.customerAddress.isNotEmpty)
// //                         _infoRow('Address:', order.customerAddress),

// //                       const SizedBox(height: 12),

// //                       Row(
// //                         children: [
// //                           Expanded(
// //                             child: Container(
// //                               padding: const EdgeInsets.all(8),
// //                               decoration: BoxDecoration(
// //                                 color: Colors.blue[50],
// //                                 borderRadius: BorderRadius.circular(8),
// //                               ),
// //                               child: Column(
// //                                 crossAxisAlignment: CrossAxisAlignment.start,
// //                                 children: [
// //                                   Text(
// //                                     '₹${order.totalPrice}',
// //                                     style: GoogleFonts.poppins(
// //                                       fontSize: 14,
// //                                       fontWeight: FontWeight.w600,
// //                                       color: Colors.blue[700],
// //                                     ),
// //                                   ),
// //                                   Text(
// //                                     'Total Price',
// //                                     style: GoogleFonts.poppins(
// //                                       fontSize: 11,
// //                                       color: Colors.blue[600],
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ),
// //                           const SizedBox(width: 8),
// //                           Expanded(
// //                             child: Container(
// //                               padding: const EdgeInsets.all(8),
// //                               decoration: BoxDecoration(
// //                                 color: Colors.green[50],
// //                                 borderRadius: BorderRadius.circular(8),
// //                               ),
// //                               child: Column(
// //                                 crossAxisAlignment: CrossAxisAlignment.start,
// //                                 children: [
// //                                   Text(
// //                                     '₹${order.pricePerBag}/bag',
// //                                     style: GoogleFonts.poppins(
// //                                       fontSize: 14,
// //                                       fontWeight: FontWeight.w600,
// //                                       color: Colors.green[700],
// //                                     ),
// //                                   ),
// //                                   Text(
// //                                     'Price per Bag',
// //                                     style: GoogleFonts.poppins(
// //                                       fontSize: 11,
// //                                       color: Colors.green[600],
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),

// //                       const SizedBox(height: 12),

// //                       if (!_isSelectionMode && 
// //                           order.status.toLowerCase() != 'completed' &&
// //                           order.status.toLowerCase() != 'cancelled')
// //                         SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: () => _showStatusUpdateDialog(order, context, ordersProvider),
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: GlobalColors.primaryBlue,
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(8),
// //                               ),
// //                             ),
// //                             child: Text(
// //                               'Update Status',
// //                               style: GoogleFonts.poppins(
// //                                 color: Colors.white,
// //                                 fontWeight: FontWeight.w500,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _infoRow(String label, String value) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 6),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           SizedBox(
// //             width: 80,
// //             child: Text(
// //               label,
// //               style: GoogleFonts.poppins(
// //                 fontSize: 13,
// //                 fontWeight: FontWeight.w500,
// //                 color: Colors.grey[700],
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             child: Text(
// //               value,
// //               style: GoogleFonts.poppins(
// //                 fontSize: 13,
// //                 color: Colors.black,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Future<void> _showStatusUpdateDialog(
// //     ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) async {
// //   final statusOptions = ordersProvider.getNextStatusOptions(order);
  
// //   Map<String, String> statusDisplayNames = {
// //     'pending': 'Pending',
// //     'packing': 'Packing',
// //     'ready_for_dispatch': 'Ready for Dispatch',
// //     'dispatched': 'Dispatched',
// //     'delivered': 'Delivered',
// //     'completed': 'Completed',
// //     'cancelled': 'Cancelled',
// //   };
  
// //   if (statusOptions.isEmpty) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Text('No status updates available for this order'),
// //         backgroundColor: Colors.orange,
// //       ),
// //     );
// //     return;
// //   }
  
// //   await showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     shape: const RoundedRectangleBorder(
// //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //     ),
// //     builder: (context) {
// //       return Container(
// //         constraints: BoxConstraints(
// //           maxHeight: MediaQuery.of(context).size.height * 0.8,
// //         ),
// //         child: SingleChildScrollView(
// //           child: Padding(
// //             padding: const EdgeInsets.all(24),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Center(
// //                   child: Container(
// //                     width: 60,
// //                     height: 4,
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey[300],
// //                       borderRadius: BorderRadius.circular(2),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 Text(
// //                   'Update Order Status',
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.w600,
// //                     color: Colors.black,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   'Order #${order.id.substring(0, 8)}',
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 14,
// //                     color: Colors.grey[600],
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   'Current: ${order.displayStatus}',
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 14,
// //                     fontWeight: FontWeight.w500,
// //                     color: order.statusColor,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
                
// //                 ...statusOptions.map((status) {
// //                   final displayName = statusDisplayNames[status] ?? status;
// //                   return ListTile(
// //                     contentPadding: const EdgeInsets.symmetric(vertical: 4),
// //                     leading: Container(
// //                       width: 40,
// //                       height: 40,
// //                       decoration: BoxDecoration(
// //                         color: _getStatusColor(status).withOpacity(0.1),
// //                         borderRadius: BorderRadius.circular(10),
// //                       ),
// //                       child: Icon(
// //                         _getStatusIcon(status),
// //                         size: 20,
// //                         color: _getStatusColor(status),
// //                       ),
// //                     ),
// //                     title: Text(
// //                       displayName,
// //                       style: GoogleFonts.poppins(
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                     ),
// //                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
// //                     onTap: () async {
// //                       Navigator.pop(context);
// //                       await _updateOrderStatus(
// //                         order,
// //                         status,
// //                         context,
// //                         ordersProvider,
// //                       );
// //                     },
// //                   );
// //                 }).toList(),
                
// //                 const SizedBox(height: 20),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: OutlinedButton(
// //                     onPressed: () => Navigator.pop(context),
// //                     style: OutlinedButton.styleFrom(
// //                       minimumSize: const Size(double.infinity, 48),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                     ),
// //                     child: Text(
// //                       'Cancel',
// //                       style: GoogleFonts.poppins(
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       );
// //     },
// //   );
// // }

// //   Future<void> _updateOrderStatus(
// //       ProductionOrderItem order, String newStatus, BuildContext context, ProductionOrdersProvider ordersProvider) async {
// //     try {
// //       showDialog(
// //         context: context,
// //         barrierDismissible: false,
// //         builder: (context) => const Center(
// //           child: CircularProgressIndicator(),
// //         ),
// //       );

// //       await ordersProvider.updateOrderStatus(order, newStatus);
      
// //       if (context.mounted) {
// //         Navigator.pop(context);
// //       }

// //       if (context.mounted) {
// //         final displayNames = {
// //           'pending': 'Pending',
// //           'packing': 'Packing',
// //           'ready_for_dispatch': 'Ready for Dispatch',
// //           'dispatched': 'Dispatched',
// //           'delivered': 'Delivered',
// //           'completed': 'Completed',
// //           'cancelled': 'Cancelled',
// //         };
        
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('✅ Order status updated to ${displayNames[newStatus] ?? newStatus}'),
// //             backgroundColor: Colors.green,
// //             behavior: SnackBarBehavior.floating,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             duration: const Duration(seconds: 2),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       if (context.mounted) {
// //         Navigator.pop(context);
// //       }
      
// //       if (context.mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('❌ Error: ${e.toString()}'),
// //             backgroundColor: Colors.red,
// //             behavior: SnackBarBehavior.floating,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             duration: const Duration(seconds: 3),
// //           ),
// //         );
// //       }
// //     }
// //   }

// //   Future<void> _showBulkStatusUpdateDialog(ProductionOrdersProvider ordersProvider) async {
// //   final selectedOrderIds = _selectedOrders.entries
// //       .where((entry) => entry.value)
// //       .map((entry) => entry.key)
// //       .toList();
  
// //   if (selectedOrderIds.isEmpty) return;
  
// //   Map<String, String> statusDisplayNames = {
// //     'pending': 'Pending',
// //     'packing': 'Packing',
// //     'ready_for_dispatch': 'Ready for Dispatch',
// //     'dispatched': 'Dispatched',
// //     'delivered': 'Delivered',
// //     'completed': 'Completed',
// //     'cancelled': 'Cancelled',
// //   };
  
// //   await showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     shape: const RoundedRectangleBorder(
// //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //     ),
// //     builder: (context) {
// //       return Container(
// //         constraints: BoxConstraints(
// //           maxHeight: MediaQuery.of(context).size.height * 0.7,
// //         ),
// //         child: SingleChildScrollView(
// //           child: Padding(
// //             padding: const EdgeInsets.all(24),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Center(
// //                   child: Container(
// //                     width: 60,
// //                     height: 4,
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey[300],
// //                       borderRadius: BorderRadius.circular(2),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 Text(
// //                   'Bulk Update Status',
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.w600,
// //                     color: Colors.black,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   'Updating ${selectedOrderIds.length} orders',
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 14,
// //                     color: Colors.grey[600],
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
                
// //                 Text(
// //                   'Select New Status:',
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.w500,
// //                     color: Colors.black,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 12),
                
// //                 Column(
// //                   children: ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled']
// //                       .map((status) {
// //                     final displayName = statusDisplayNames[status] ?? status;
// //                     return ListTile(
// //                       contentPadding: const EdgeInsets.symmetric(vertical: 4),
// //                       leading: Container(
// //                         width: 40,
// //                         height: 40,
// //                         decoration: BoxDecoration(
// //                           color: _getStatusColor(status).withOpacity(0.1),
// //                           borderRadius: BorderRadius.circular(10),
// //                         ),
// //                         child: Icon(
// //                           _getStatusIcon(status),
// //                           size: 20,
// //                           color: _getStatusColor(status),
// //                         ),
// //                       ),
// //                       title: Text(
// //                         displayName,
// //                         style: GoogleFonts.poppins(
// //                           fontWeight: FontWeight.w500,
// //                         ),
// //                       ),
// //                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
// //                       onTap: () async {
// //                         Navigator.pop(context);
// //                         await _updateBulkOrderStatus(selectedOrderIds, status, ordersProvider);
// //                       },
// //                     );
// //                   }).toList(),
// //                 ),
                
// //                 const SizedBox(height: 20),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: OutlinedButton(
// //                     onPressed: () => Navigator.pop(context),
// //                     style: OutlinedButton.styleFrom(
// //                       minimumSize: const Size(double.infinity, 48),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                     ),
// //                     child: Text(
// //                       'Cancel',
// //                       style: GoogleFonts.poppins(
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       );
// //     },
// //   );
// // }

// //   Future<void> _updateBulkOrderStatus(
// //       List<String> orderIds, 
// //       String newStatus, 
// //       ProductionOrdersProvider ordersProvider) async {
// //     try {
// //       showDialog(
// //         context: context,
// //         barrierDismissible: false,
// //         builder: (context) => const Center(
// //           child: CircularProgressIndicator(),
// //         ),
// //       );

// //       await ordersProvider.updateBulkOrderStatus(orderIds, newStatus);
      
// //       if (context.mounted) {
// //         Navigator.pop(context);
// //       }
      
// //       setState(() {
// //         _isSelectionMode = false;
// //         _selectedOrders.updateAll((key, value) => false);
// //         _selectAll = false;
// //       });

// //       if (context.mounted) {
// //         final displayNames = {
// //           'pending': 'Pending',
// //           'packing': 'Packing',
// //           'ready_for_dispatch': 'Ready for Dispatch',
// //           'dispatched': 'Dispatched',
// //           'delivered': 'Delivered',
// //           'completed': 'Completed',
// //           'cancelled': 'Cancelled',
// //         };
        
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('✅ ${orderIds.length} orders updated to ${displayNames[newStatus] ?? newStatus}'),
// //             backgroundColor: Colors.green,
// //             behavior: SnackBarBehavior.floating,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             duration: const Duration(seconds: 3),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       if (context.mounted) {
// //         Navigator.pop(context);
// //       }
      
// //       if (context.mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('❌ Error: ${e.toString()}'),
// //             backgroundColor: Colors.red,
// //             behavior: SnackBarBehavior.floating,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             duration: const Duration(seconds: 3),
// //           ),
// //         );
// //       }
// //     }
// //   }

// //   void _showOrderDetails(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) {
// //         return SingleChildScrollView(
// //           padding: const EdgeInsets.all(24),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Center(
// //                 child: Container(
// //                   width: 60,
// //                   height: 4,
// //                   decoration: BoxDecoration(
// //                     color: Colors.grey[300],
// //                     borderRadius: BorderRadius.circular(2),
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 20),
// //               Row(
// //                 children: [
// //                   Container(
// //                     width: 50,
// //                     height: 50,
// //                     decoration: BoxDecoration(
// //                       color: GlobalColors.primaryBlue.withOpacity(0.1),
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                     child: Icon(
// //                       Icons.receipt_long,
// //                       color: GlobalColors.primaryBlue,
// //                       size: 28,
// //                     ),
// //                   ),
// //                   const SizedBox(width: 16),
// //                   Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text(
// //                           'Order Details',
// //                           style: GoogleFonts.poppins(
// //                             fontSize: 18,
// //                             fontWeight: FontWeight.w600,
// //                             color: Colors.black,
// //                           ),
// //                         ),
// //                         Text(
// //                           '#${order.id.substring(0, 8)}',
// //                           style: GoogleFonts.poppins(
// //                             fontSize: 14,
// //                             color: Colors.grey[600],
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   Container(
// //                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //                     decoration: BoxDecoration(
// //                       color: order.statusColor.withOpacity(0.1),
// //                       borderRadius: BorderRadius.circular(20),
// //                       border: Border.all(color: order.statusColor.withOpacity(0.3)),
// //                     ),
// //                     child: Text(
// //                       order.displayStatus,
// //                       style: GoogleFonts.poppins(
// //                         fontSize: 12,
// //                         fontWeight: FontWeight.w500,
// //                         color: order.statusColor,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 24),
              
// //               _detailRow('Customer Name', order.customerName, Icons.person),
// //               _detailRow('Customer Mobile', order.customerMobile, Icons.phone),
// //               _detailRow('Customer Address', order.customerAddress, Icons.location_on),
              
// //               _detailRow('Product', order.productName, Icons.inventory),
// //               _detailRow('Bags', '${order.bags} Bags', Icons.shopping_bag),
// //               _detailRow('Weight per Bag', '${order.weightPerBag} ${order.weightUnit}', Icons.scale),
// //               _detailRow('Total Weight', '${order.totalWeight} ${order.weightUnit}', Icons.scale),
// //               _detailRow('Price per Bag', '₹${order.pricePerBag}', Icons.currency_rupee),
// //               _detailRow('Total Price', '₹${order.totalPrice}', Icons.currency_rupee),
              
// //               if (order.remarks != null && order.remarks!.isNotEmpty)
// //                 _detailRow('Remarks', order.remarks!, Icons.note),
              
// //               _detailRow('Created Date', 
// //                 DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
// //                 Icons.calendar_today,
// //               ),
// //               if (order.updatedAt != null)
// //                 _detailRow('Last Updated',
// //                   DateFormat('dd MMM yyyy, hh:mm a').format(order.updatedAt!),
// //                   Icons.update,
// //                 ),
              
// //               const SizedBox(height: 24),
              
// //               if (order.status.toLowerCase() != 'completed' &&
// //                   order.status.toLowerCase() != 'cancelled')
// //                 ElevatedButton(
// //                   onPressed: () {
// //                     Navigator.pop(context);
// //                     _showStatusUpdateDialog(order, context, ordersProvider);
// //                   },
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: GlobalColors.primaryBlue,
// //                     minimumSize: const Size(double.infinity, 48),
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                   ),
// //                   child: Text(
// //                     'Update Status',
// //                     style: GoogleFonts.poppins(
// //                       fontWeight: FontWeight.w600,
// //                       color: Colors.white,
// //                     ),
// //                   ),
// //                 ),
// //               const SizedBox(height: 8),
// //               OutlinedButton(
// //                 onPressed: () => Navigator.pop(context),
// //                 style: OutlinedButton.styleFrom(
// //                   minimumSize: const Size(double.infinity, 48),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                 ),
// //                 child: Text(
// //                   'Close',
// //                   style: GoogleFonts.poppins(
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   Widget _detailRow(String label, String value, IconData icon) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 8),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Icon(icon, size: 18, color: Colors.grey[600]),
// //           const SizedBox(width: 12),
// //           Expanded(
// //             child: Text(
// //               label,
// //               style: GoogleFonts.poppins(
// //                 fontSize: 14,
// //                 color: Colors.grey[600],
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             flex: 2,
// //             child: Text(
// //               value,
// //               style: GoogleFonts.poppins(
// //                 fontSize: 14,
// //                 color: Colors.black,
// //               ),
// //               textAlign: TextAlign.right,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Color _getStatusColor(String status) {
// //     switch (status.toLowerCase()) {
// //       case 'pending':
// //         return Colors.orange;
// //       case 'packing':
// //         return Colors.blue;
// //       case 'ready_for_dispatch':
// //         return Colors.purple;
// //       case 'dispatched':
// //         return Colors.indigo;
// //       case 'delivered':
// //         return Colors.green;
// //       case 'completed':
// //         return Colors.green;
// //       case 'cancelled':
// //         return Colors.red;
// //       default:
// //         return Colors.grey;
// //     }
// //   }

// //   IconData _getStatusIcon(String status) {
// //     switch (status.toLowerCase()) {
// //       case 'pending':
// //         return Icons.pending_actions;
// //       case 'packing':
// //         return Icons.inventory;
// //       case 'ready_for_dispatch':
// //         return Icons.local_shipping;
// //       case 'dispatched':
// //         return Icons.directions_car;
// //       case 'delivered':
// //         return Icons.check_circle;
// //       case 'completed':
// //         return Icons.done_all;
// //       case 'cancelled':
// //         return Icons.cancel;
// //       default:
// //         return Icons.receipt;
// //     }
// //   }

// //   void _loadSelectedOrders() {
// //     final ordersProvider = Provider.of<ProductionOrdersProvider>(
// //       context, 
// //       listen: false
// //     );
// //     _selectedOrders.clear();
// //     for (var order in ordersProvider.orders) {
// //       _selectedOrders[order.id] = false;
// //     }
// //   }
// // }

















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
//   Map<String, bool> _selectedOrders = {};
//   bool _isSelectionMode = false;
//   bool _selectAll = false;
//   bool _initialized = false;

//   @override
//   void initState() {
//     super.initState();
//     // Load data immediately
//     Future.microtask(() => _initializeData());
//   }
  
//   Future<void> _initializeData() async {
//     final ordersProvider = Provider.of<ProductionOrdersProvider>(
//       context, 
//       listen: false
//     );
    
//     // Quick load will show data immediately
//     // Full load happens in background automatically
    
//     _loadSelectedOrders();
//     setState(() {
//       _initialized = true;
//     });
//   }
  
//   void _loadSelectedOrders() {
//     final ordersProvider = Provider.of<ProductionOrdersProvider>(
//       context, 
//       listen: false
//     );
//     _selectedOrders.clear();
//     for (var order in ordersProvider.orders) {
//       _selectedOrders[order.id] = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: true);
    
//     // Don't show error if still initializing
//     if (ordersProvider.error != null && ordersProvider.orders.isEmpty && _initialized) {
//       return Scaffold(
//         backgroundColor: GlobalColors.background,
//         appBar: AppBar(
//           title: Text(
//             'Production Orders',
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               fontSize: 20,
//             ),
//           ),
//           backgroundColor: GlobalColors.primaryBlue,
//           foregroundColor: Colors.white,
//           centerTitle: true,
//           elevation: 0,
//         ),
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.error_outline,
//                   size: 64,
//                   color: Colors.red,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Error Loading Orders',
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.red,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   ordersProvider.error!,
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () {
//                     ordersProvider.refresh();
//                     _initializeData();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: GlobalColors.primaryBlue,
//                   ),
//                   child: const Text(
//                     'Retry',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: _isSelectionMode 
//             ? Text(
//                 'Select Orders',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 20,
//                 ),
//               )
//             : Text(
//                 'Production Orders',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 20,
//                 ),
//               ),
//         backgroundColor: _isSelectionMode ? GlobalColors.primaryBlue.withOpacity(0.9) : GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 0,
//         actions: _isSelectionMode
//             ? [
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () {
//                     setState(() {
//                       _isSelectionMode = false;
//                       _selectedOrders.updateAll((key, value) => false);
//                       _selectAll = false;
//                     });
//                   },
//                   tooltip: 'Cancel Selection',
//                 ),
//               ]
//             : [
//                 IconButton(
//                   icon: const Icon(Icons.refresh),
//                   onPressed: () {
//                     ordersProvider.refresh();
//                   },
//                 ),
//               ],
//       ),
//       body: Consumer<ProductionOrdersProvider>(
//         builder: (context, ordersProvider, child) {
//           return Column(
//             children: [
//               if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
//                 _buildStatistics(ordersProvider),
              
//               if (!_isSelectionMode && ordersProvider.orders.isNotEmpty) 
//                 _buildFilterTabs(ordersProvider),
              
//               if (_isSelectionMode) 
//                 _buildBulkSelectionToolbar(ordersProvider),
              
//               Expanded(
//                 child: _buildOrdersList(ordersProvider),
//               ),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: _isSelectionMode
//           ? Builder(
//               builder: (context) {
//                 final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
//                 return FloatingActionButton.extended(
//                   onPressed: () {
//                     if (selectedCount > 0) {
//                       _showBulkStatusUpdateDialog(context.read<ProductionOrdersProvider>());
//                     }
//                   },
//                   backgroundColor: GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                   icon: const Icon(Icons.check_circle),
//                   label: Text(
//                     'Update $selectedCount',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 );
//               },
//             )
//           : null,
//     );
//   }

//   Widget _buildStatistics(ProductionOrdersProvider ordersProvider) {
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

//   Widget _buildFilterTabs(ProductionOrdersProvider ordersProvider) {
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

//   Widget _buildBulkSelectionToolbar(ProductionOrdersProvider ordersProvider) {
//     final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: GlobalColors.primaryBlue,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Checkbox(
//             value: _selectAll,
//             onChanged: (value) {
//               setState(() {
//                 _selectAll = value ?? false;
//                 for (var order in ordersProvider.filteredOrders) {
//                   _selectedOrders[order.id] = _selectAll;
//                 }
//               });
//             },
//             activeColor: Colors.white,
//             checkColor: GlobalColors.primaryBlue,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               _selectAll 
//                   ? 'All ${ordersProvider.filteredOrders.length} selected'
//                   : '$selectedCount selected',
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrdersList(ProductionOrdersProvider ordersProvider) {
//     if (ordersProvider.isLoading && ordersProvider.orders.isEmpty && !_initialized) {
//       return _buildInitialLoading();
//     }

//     if (ordersProvider.filteredOrders.isEmpty) {
//       return _buildEmptyState(ordersProvider);
//     }

//     return RefreshIndicator(
//       color: GlobalColors.primaryBlue,
//       onRefresh: () async {
//         await ordersProvider.refresh();
//         _loadSelectedOrders();
//       },
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: ordersProvider.filteredOrders.length + (ordersProvider.hasMoreData ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == ordersProvider.filteredOrders.length) {
//             return _buildLoadMoreButton(ordersProvider);
//           }
          
//           final order = ordersProvider.filteredOrders[index];
//           return _buildOrderCard(order, context, ordersProvider);
//         },
//       ),
//     );
//   }

//   Widget _buildInitialLoading() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(color: GlobalColors.primaryBlue),
//           const SizedBox(height: 16),
//           Text(
//             'Loading orders...',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadMoreButton(ProductionOrdersProvider ordersProvider) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Center(
//         child: ordersProvider.isLoading
//             ? CircularProgressIndicator(color: GlobalColors.primaryBlue)
//             : ElevatedButton(
//                 onPressed: () {
//                   ordersProvider.loadMore();
//                 },
//                 child: const Text('Load More Orders'),
//               ),
//       ),
//     );
//   }

//   Widget _buildEmptyState(ProductionOrdersProvider ordersProvider) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.receipt_long_outlined,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No orders found',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             ordersProvider.filter == 'all'
//                 ? 'No orders available'
//                 : 'No ${ordersProvider.filter.replaceAll('_', ' ')} orders',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrderCard(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
//     final isSelected = _selectedOrders[order.id] ?? false;
    
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
//         border: _isSelectionMode && isSelected
//             ? Border.all(color: GlobalColors.primaryBlue, width: 2)
//             : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () {
//             if (_isSelectionMode) {
//               setState(() {
//                 _selectedOrders[order.id] = !isSelected;
//               });
//             } else {
//               _showOrderDetails(order, context, ordersProvider);
//             }
//           },
//           onLongPress: () {
//             setState(() {
//               _isSelectionMode = true;
//               _selectedOrders[order.id] = true;
//             });
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (_isSelectionMode)
//                   Padding(
//                     padding: const EdgeInsets.only(right: 12, top: 4),
//                     child: Checkbox(
//                       value: isSelected,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedOrders[order.id] = value ?? false;
//                         });
//                       },
//                       activeColor: GlobalColors.primaryBlue,
//                     ),
//                   ),
                
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Order #${order.id.substring(0, 8)}',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: order.statusColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: order.statusColor.withOpacity(0.3)),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(order.statusIcon, size: 14, color: order.statusColor),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   order.displayStatus,
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                     color: order.statusColor,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       _infoRow('Customer:', order.customerName),
//                       _infoRow('Product:', order.productName),
//                       _infoRow('Bags:', order.displayQuantity),
                      
//                       if (order.customerMobile.isNotEmpty)
//                         _infoRow('Mobile:', order.customerMobile),
                      
//                       if (order.customerAddress.isNotEmpty)
//                         _infoRow('Address:', order.customerAddress),

//                       const SizedBox(height: 12),

//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.totalPrice}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.blue[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Total Price',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.blue[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.pricePerBag}/bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.green[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Price per Bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.green[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       if (!_isSelectionMode && 
//                           order.status.toLowerCase() != 'completed' &&
//                           order.status.toLowerCase() != 'cancelled')
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () => _showStatusUpdateDialog(order, context, ordersProvider),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: GlobalColors.primaryBlue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Update Status',
//                               style: GoogleFonts.poppins(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
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
//     ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) async {
//   final statusOptions = ordersProvider.getNextStatusOptions(order);
  
//   Map<String, String> statusDisplayNames = {
//     'pending': 'Pending',
//     'packing': 'Packing',
//     'ready_for_dispatch': 'Ready for Dispatch',
//     'dispatched': 'Dispatched',
//     'delivered': 'Delivered',
//     'completed': 'Completed',
//     'cancelled': 'Cancelled',
//   };
  
//   if (statusOptions.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('No status updates available for this order'),
//         backgroundColor: Colors.orange,
//       ),
//     );
//     return;
//   }
  
//   await showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (context) {
//       return Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.8,
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 60,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Update Order Status',
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Order #${order.id.substring(0, 8)}',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Current: ${order.displayStatus}',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: order.statusColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 ...statusOptions.map((status) {
//                   final displayName = statusDisplayNames[status] ?? status;
//                   return ListTile(
//                     contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                     leading: Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(status).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Icon(
//                         _getStatusIcon(status),
//                         size: 20,
//                         color: _getStatusColor(status),
//                       ),
//                     ),
//                     title: Text(
//                       displayName,
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                     onTap: () async {
//                       Navigator.pop(context);
//                       await _updateOrderStatus(
//                         order,
//                         status,
//                         context,
//                         ordersProvider,
//                       );
//                     },
//                   );
//                 }).toList(),
                
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 48),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Cancel',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }

//   Future<void> _updateOrderStatus(
//       ProductionOrderItem order, String newStatus, BuildContext context, ProductionOrdersProvider ordersProvider) async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       await ordersProvider.updateOrderStatus(order, newStatus);
      
//       if (context.mounted) {
//         Navigator.pop(context);
//       }

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
//       if (context.mounted) {
//         Navigator.pop(context);
//       }
      
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

//   Future<void> _showBulkStatusUpdateDialog(ProductionOrdersProvider ordersProvider) async {
//   final selectedOrderIds = _selectedOrders.entries
//       .where((entry) => entry.value)
//       .map((entry) => entry.key)
//       .toList();
  
//   if (selectedOrderIds.isEmpty) return;
  
//   Map<String, String> statusDisplayNames = {
//     'pending': 'Pending',
//     'packing': 'Packing',
//     'ready_for_dispatch': 'Ready for Dispatch',
//     'dispatched': 'Dispatched',
//     'delivered': 'Delivered',
//     'completed': 'Completed',
//     'cancelled': 'Cancelled',
//   };
  
//   await showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (context) {
//       return Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.7,
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 60,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Bulk Update Status',
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Updating ${selectedOrderIds.length} orders',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 Text(
//                   'Select New Status:',
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
                
//                 Column(
//                   children: ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled']
//                       .map((status) {
//                     final displayName = statusDisplayNames[status] ?? status;
//                     return ListTile(
//                       contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                       leading: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: _getStatusColor(status).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           _getStatusIcon(status),
//                           size: 20,
//                           color: _getStatusColor(status),
//                         ),
//                       ),
//                       title: Text(
//                         displayName,
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                       onTap: () async {
//                         Navigator.pop(context);
//                         await _updateBulkOrderStatus(selectedOrderIds, status, ordersProvider);
//                       },
//                     );
//                   }).toList(),
//                 ),
                
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 48),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Cancel',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }

//   Future<void> _updateBulkOrderStatus(
//       List<String> orderIds, 
//       String newStatus, 
//       ProductionOrdersProvider ordersProvider) async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       await ordersProvider.updateBulkOrderStatus(orderIds, newStatus);
      
//       if (context.mounted) {
//         Navigator.pop(context);
//       }
      
//       setState(() {
//         _isSelectionMode = false;
//         _selectedOrders.updateAll((key, value) => false);
//         _selectAll = false;
//       });

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
//             content: Text('✅ ${orderIds.length} orders updated to ${displayNames[newStatus] ?? newStatus}'),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       if (context.mounted) {
//         Navigator.pop(context);
//       }
      
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

//   void _showOrderDetails(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
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
              
//               _detailRow('Customer Name', order.customerName, Icons.person),
//               _detailRow('Customer Mobile', order.customerMobile, Icons.phone),
//               _detailRow('Customer Address', order.customerAddress, Icons.location_on),
              
//               _detailRow('Product', order.productName, Icons.inventory),
//               _detailRow('Bags', '${order.bags} Bags', Icons.shopping_bag),
//               _detailRow('Weight per Bag', '${order.weightPerBag} ${order.weightUnit}', Icons.scale),
//               _detailRow('Total Weight', '${order.totalWeight} ${order.weightUnit}', Icons.scale),
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
//   Map<String, bool> _selectedOrders = {};
//   bool _isSelectionMode = false;
//   bool _selectAll = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadSelectedOrders();
//     });
//   }
  
//   void _loadSelectedOrders() {
//     // Changed to ProductionOrdersProvider
//     final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: false);
//     _selectedOrders.clear();
//     for (var order in ordersProvider.orders) {
//       _selectedOrders[order.id] = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     print('=== ProductionOrdersPage build called ===');
//     print('_isSelectionMode: $_isSelectionMode');
    
//     // Changed to ProductionOrdersProvider
//     final ordersProvider = Provider.of<ProductionOrdersProvider>(context, listen: true);
//     print('ordersProvider.isLoading: ${ordersProvider.isLoading}');
//     print('ordersProvider.error: ${ordersProvider.error}');
//     print('ordersProvider.orders.length: ${ordersProvider.orders.length}');
//     print('ordersProvider.filteredOrders.length: ${ordersProvider.filteredOrders.length}');
    
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         title: _isSelectionMode 
//             ? Text(
//                 'Select Orders',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 20,
//                 ),
//               )
//             : Text(
//                 'Production Orders',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 20,
//                 ),
//               ),
//         backgroundColor: _isSelectionMode ? GlobalColors.primaryBlue.withOpacity(0.9) : GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 0,
//         actions: _isSelectionMode
//             ? [
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () {
//                     setState(() {
//                       _isSelectionMode = false;
//                       _selectedOrders.updateAll((key, value) => false);
//                       _selectAll = false;
//                     });
//                   },
//                   tooltip: 'Cancel Selection',
//                 ),
//               ]
//             : [
//                 IconButton(
//                   icon: const Icon(Icons.refresh),
//                   onPressed: () {
//                     // Changed to ProductionOrdersProvider
//                     Provider.of<ProductionOrdersProvider>(context, listen: false).refresh();
//                   },
//                 ),
//               ],
//       ),
//       body: Consumer<ProductionOrdersProvider>( // Changed to ProductionOrdersProvider
//         builder: (context, ordersProvider, child) {
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
//               if (!_isSelectionMode) _buildStatistics(ordersProvider),
              
//               if (!_isSelectionMode) _buildFilterTabs(ordersProvider),
              
//               if (_isSelectionMode) _buildBulkSelectionToolbar(ordersProvider),
              
//               Expanded(child: _buildOrdersList(ordersProvider)),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: _isSelectionMode
//           ? FloatingActionButton.extended(
//               onPressed: () {
//                 final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
//                 if (selectedCount > 0) {
//                   // Changed to ProductionOrdersProvider
//                   _showBulkStatusUpdateDialog(context.read<ProductionOrdersProvider>());
//                 }
//               },
//               backgroundColor: GlobalColors.primaryBlue,
//               foregroundColor: Colors.white,
//               icon: const Icon(Icons.check_circle),
//               label: Text(
//                 'Update ${_selectedOrders.values.where((isSelected) => isSelected).length}',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             )
//           : null,
//     );
//   }

//   // Changed parameter type to ProductionOrdersProvider
//   Widget _buildStatistics(ProductionOrdersProvider ordersProvider) {
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

//   // Changed parameter type to ProductionOrdersProvider
//   Widget _buildFilterTabs(ProductionOrdersProvider ordersProvider) {
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

//   // Changed parameter type to ProductionOrdersProvider
//   Widget _buildBulkSelectionToolbar(ProductionOrdersProvider ordersProvider) {
//     final selectedCount = _selectedOrders.values.where((isSelected) => isSelected).length;
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: GlobalColors.primaryBlue,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Checkbox(
//             value: _selectAll,
//             onChanged: (value) {
//               setState(() {
//                 _selectAll = value ?? false;
//                 for (var order in ordersProvider.filteredOrders) {
//                   _selectedOrders[order.id] = _selectAll;
//                 }
//               });
//             },
//             activeColor: Colors.white,
//             checkColor: GlobalColors.primaryBlue,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               _selectAll 
//                   ? 'All ${ordersProvider.filteredOrders.length} selected'
//                   : '$selectedCount selected',
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Changed parameter type to ProductionOrdersProvider
//   Widget _buildOrdersList(ProductionOrdersProvider ordersProvider) {
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
//       onRefresh: () async {
//         await ordersProvider.refresh();
//         _loadSelectedOrders();
//       },
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: ordersProvider.filteredOrders.length,
//         itemBuilder: (context, index) {
//           final order = ordersProvider.filteredOrders[index];
//           // Changed to ProductionOrderItem
//           return _buildOrderCard(order, context, ordersProvider);
//         },
//       ),
//     );
//   }

//   // Changed parameter type from OrderItem to ProductionOrderItem
//   Widget _buildOrderCard(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
//     final isSelected = _selectedOrders[order.id] ?? false;
    
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
//         border: _isSelectionMode && isSelected
//             ? Border.all(color: GlobalColors.primaryBlue, width: 2)
//             : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () {
//             if (_isSelectionMode) {
//               setState(() {
//                 _selectedOrders[order.id] = !isSelected;
//               });
//             } else {
//               _showOrderDetails(order, context, ordersProvider);
//             }
//           },
//           onLongPress: () {
//             setState(() {
//               _isSelectionMode = true;
//               _selectedOrders[order.id] = true;
//             });
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (_isSelectionMode)
//                   Padding(
//                     padding: const EdgeInsets.only(right: 12, top: 4),
//                     child: Checkbox(
//                       value: isSelected,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedOrders[order.id] = value ?? false;
//                         });
//                       },
//                       activeColor: GlobalColors.primaryBlue,
//                     ),
//                   ),
                
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Order #${order.id.substring(0, 8)}',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: order.statusColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: order.statusColor.withOpacity(0.3)),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(order.statusIcon, size: 14, color: order.statusColor),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   order.displayStatus,
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                     color: order.statusColor,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       _infoRow('Customer:', order.customerName),
//                       _infoRow('Product:', order.productName),
//                       _infoRow('Bags:', order.displayQuantity),
                      
//                       if (order.customerMobile.isNotEmpty)
//                         _infoRow('Mobile:', order.customerMobile),
                      
//                       if (order.customerAddress.isNotEmpty)
//                         _infoRow('Address:', order.customerAddress),

//                       const SizedBox(height: 12),

//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.totalPrice}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.blue[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Total Price',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.blue[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[50],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '₹${order.pricePerBag}/bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.green[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     'Price per Bag',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       color: Colors.green[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 12),

//                       if (!_isSelectionMode && 
//                           order.status.toLowerCase() != 'completed' &&
//                           order.status.toLowerCase() != 'cancelled')
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () => _showStatusUpdateDialog(order, context, ordersProvider),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: GlobalColors.primaryBlue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Update Status',
//                               style: GoogleFonts.poppins(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
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

//   // Changed parameter types from OrderItem to ProductionOrderItem and OrdersProvider to ProductionOrdersProvider
//   Future<void> _showStatusUpdateDialog(
//     ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) async {
//   final statusOptions = ordersProvider.getNextStatusOptions(order);
  
//   Map<String, String> statusDisplayNames = {
//     'pending': 'Pending',
//     'packing': 'Packing',
//     'ready_for_dispatch': 'Ready for Dispatch',
//     'dispatched': 'Dispatched',
//     'delivered': 'Delivered',
//     'completed': 'Completed',
//     'cancelled': 'Cancelled',
//   };
  
//   if (statusOptions.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('No status updates available for this order'),
//         backgroundColor: Colors.orange,
//       ),
//     );
//     return;
//   }
  
//   await showModalBottomSheet(
//     context: context,
//     isScrollControlled: true, // Add this to make it scrollable
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (context) {
//       return Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height
//         ),
//         child: SingleChildScrollView( // Make it scrollable
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 60,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Update Order Status',
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Order #${order.id.substring(0, 8)}',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Current: ${order.displayStatus}',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: order.statusColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 ...statusOptions.map((status) {
//                   final displayName = statusDisplayNames[status] ?? status;
//                   return ListTile(
//                     contentPadding: const EdgeInsets.symmetric(vertical: 4), // Add some padding
//                     leading: Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(status).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Icon(
//                         _getStatusIcon(status),
//                         size: 20,
//                         color: _getStatusColor(status),
//                       ),
//                     ),
//                     title: Text(
//                       displayName,
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                     onTap: () async {
//                       Navigator.pop(context);
//                       await _updateOrderStatus(
//                         order,
//                         status,
//                         context,
//                         ordersProvider,
//                       );
//                     },
//                   );
//                 }).toList(),
                
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 48),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Cancel',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }

//   // Changed parameter types from OrderItem to ProductionOrderItem and OrdersProvider to ProductionOrdersProvider
//   Future<void> _updateOrderStatus(
//       ProductionOrderItem order, String newStatus, BuildContext context, ProductionOrdersProvider ordersProvider) async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       await ordersProvider.updateOrderStatus(order, newStatus);
      
//       if (context.mounted) {
//         Navigator.pop(context);
//       }

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
//       if (context.mounted) {
//         Navigator.pop(context);
//       }
      
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

//   // Changed parameter type from OrdersProvider to ProductionOrdersProvider
//   Future<void> _showBulkStatusUpdateDialog(ProductionOrdersProvider ordersProvider) async {
//   final selectedOrderIds = _selectedOrders.entries
//       .where((entry) => entry.value)
//       .map((entry) => entry.key)
//       .toList();
  
//   if (selectedOrderIds.isEmpty) return;
  
//   Map<String, String> statusDisplayNames = {
//     'pending': 'Pending',
//     'packing': 'Packing',
//     'ready_for_dispatch': 'Ready for Dispatch',
//     'dispatched': 'Dispatched',
//     'delivered': 'Delivered',
//     'completed': 'Completed',
//     'cancelled': 'Cancelled',
//   };
  
//   await showModalBottomSheet(
//     context: context,
//     isScrollControlled: true, // Make it scrollable
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (context) {
//       return Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.7,
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 60,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Bulk Update Status',
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Updating ${selectedOrderIds.length} orders',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 Text(
//                   'Select New Status:',
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
                
//                 // Status options for bulk update
//                 Column(
//                   children: ['pending', 'packing', 'ready_for_dispatch', 'dispatched', 'delivered', 'completed', 'cancelled']
//                       .map((status) {
//                     final displayName = statusDisplayNames[status] ?? status;
//                     return ListTile(
//                       contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                       leading: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: _getStatusColor(status).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           _getStatusIcon(status),
//                           size: 20,
//                           color: _getStatusColor(status),
//                         ),
//                       ),
//                       title: Text(
//                         displayName,
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                       onTap: () async {
//                         Navigator.pop(context);
//                         await _updateBulkOrderStatus(selectedOrderIds, status, ordersProvider);
//                       },
//                     );
//                   }).toList(),
//                 ),
                
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 48),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Cancel',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }

//   // Changed parameter type from OrdersProvider to ProductionOrdersProvider
//   Future<void> _updateBulkOrderStatus(
//       List<String> orderIds, 
//       String newStatus, 
//       ProductionOrdersProvider ordersProvider) async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       // Update all selected orders
//       await ordersProvider.updateBulkOrderStatus(orderIds, newStatus);
      
//       if (context.mounted) {
//         Navigator.pop(context);
//       }
      
//       setState(() {
//         _isSelectionMode = false;
//         _selectedOrders.updateAll((key, value) => false);
//         _selectAll = false;
//       });

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
//             content: Text('✅ ${orderIds.length} orders updated to ${displayNames[newStatus] ?? newStatus}'),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       if (context.mounted) {
//         Navigator.pop(context);
//       }
      
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

//   // Changed parameter types from OrderItem to ProductionOrderItem and OrdersProvider to ProductionOrdersProvider
//   void _showOrderDetails(ProductionOrderItem order, BuildContext context, ProductionOrdersProvider ordersProvider) {
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
              
//               _detailRow('Customer Name', order.customerName, Icons.person),
//               _detailRow('Customer Mobile', order.customerMobile, Icons.phone),
//               _detailRow('Customer Address', order.customerAddress, Icons.location_on),
              
//               _detailRow('Product', order.productName, Icons.inventory),
//               _detailRow('Bags', '${order.bags} Bags', Icons.shopping_bag),
//               _detailRow('Weight per Bag', '${order.weightPerBag} ${order.weightUnit}', Icons.scale),
//               _detailRow('Total Weight', '${order.totalWeight} ${order.weightUnit}', Icons.scale),
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
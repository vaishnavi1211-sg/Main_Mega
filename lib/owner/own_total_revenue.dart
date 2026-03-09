import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Extended District Revenue Data class to include tons
class ExtendedDistrictRevenueData extends DistrictRevenueData {
  final double totalTons;
  
  ExtendedDistrictRevenueData({
    required String district,
    required String branch,
    required double revenue,
    required int orders,
    required double growth,
    required List<String> topProducts,
    required this.totalTons,
  }) : super(
    district: district,
    branch: branch,
    revenue: revenue,
    orders: orders,
    growth: growth,
    topProducts: topProducts,
  );
}

class DistrictWiseRevenuePage extends StatefulWidget {
  final DashboardData dashboardData;
  
  const DistrictWiseRevenuePage({super.key, required this.dashboardData});

  @override
  State<DistrictWiseRevenuePage> createState() => _DistrictWiseRevenuePageState();
}

class _DistrictWiseRevenuePageState extends State<DistrictWiseRevenuePage> with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Complete list of all Maharashtra districts
  final List<String> _allMaharashtraDistricts = [
    "Ahmednagar", "Akola", "Amravati", "Aurangabad", "Beed", "Bhandara",
    "Buldhana", "Chandrapur", "Dhule", "Gadchiroli", "Gondiya", "Hingoli",
    "Jalgaon", "Jalna", "Kolhapur", "Latur", "Mumbai City", "Mumbai Suburban",
    "Nagpur", "Nanded", "Nandurbar", "Nashik", "Osmanabad", "Palghar",
    "Parbhani", "Pune", "Raigad", "Ratnagiri", "Sangli", "Satara",
    "Sindhudurg", "Solapur", "Thane", "Wardha", "Washim", "Yavatmal"
  ];
  
  // Real-time data using extended class
  List<ExtendedDistrictRevenueData> _districts = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdated;
  
  // Filters
  String _selectedFilter = 'This Month';
  final List<String> _filters = ['Today', 'This Week', 'This Month', 'Last Month', 'This Year'];
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Real-time subscription
  StreamSubscription? _ordersSubscription;
  
  // Date ranges for filters
  DateTime get _filterStartDate {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'Last Month':
        return DateTime(now.year, now.month - 1, 1);
      case 'This Year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }
  
  DateTime get _filterEndDate {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case 'This Week':
        return now;
      case 'This Month':
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case 'Last Month':
        return DateTime(now.year, now.month, 0, 23, 59, 59);
      case 'This Year':
        return DateTime(now.year, 12, 31, 23, 59, 59);
      default:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadDistrictData();
    _setupRealtimeSubscription();
    _animationController.forward();
  }

  void _setupRealtimeSubscription() {
    try {
      _ordersSubscription = _supabase
          .from('emp_mar_orders')
          .stream(primaryKey: ['id'])
          .listen((_) {
            print('🔄 Orders changed, updating district revenue...');
            _loadDistrictData();
          }, onError: (error) {
            print('❌ Realtime subscription error: $error');
          });
    } catch (e) {
      print('❌ Failed to setup realtime subscription: $e');
    }
  }

  Future<void> _loadDistrictData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final startDateStr = _filterStartDate.toIso8601String().split('T')[0];
      final endDateStr = _filterEndDate.toIso8601String().split('T')[0];

      print('📊 Fetching district data from $startDateStr to $endDateStr');

      // Fetch all orders for the period
      final ordersResponse = await _supabase
          .from('emp_mar_orders')
          .select('''
            id,
            customer_name,
            district,
            total_price,
            feed_category,
            total_weight,
            weight_unit,
            created_at,
            status
          ''')
          .eq('status', 'completed')
          .gte('created_at', startDateStr)
          .lte('created_at', endDateStr);

      print('📦 Fetched ${ordersResponse.length} completed orders');

      // Create a map of district to orders
      final Map<String, List<Map<String, dynamic>>> districtOrdersMap = {};
      
      for (var order in ordersResponse) {
        final district = order['district']?.toString() ?? 'Unknown District';
        if (!districtOrdersMap.containsKey(district)) {
          districtOrdersMap[district] = [];
        }
        districtOrdersMap[district]!.add(order);
      }

      // Calculate metrics for ALL districts (including those with no orders)
      final List<ExtendedDistrictRevenueData> allDistrictData = [];
      
      for (var district in _allMaharashtraDistricts) {
        final orders = districtOrdersMap[district] ?? [];
        
        double revenue = 0;
        int orderCount = 0;
        Map<String, int> productCount = {};
        double totalTons = 0.0;
        
        // Calculate metrics if there are orders
        for (var order in orders) {
          revenue += (order['total_price'] ?? 0).toDouble();
          orderCount++;
          totalTons += _calculateWeightInTons(order);
          
          final category = order['feed_category'] ?? 'Unknown';
          productCount[category] = (productCount[category] ?? 0) + 1;
        }

        // Get previous period data for growth calculation (only if there are orders)
        double growth = 0;
        if (orderCount > 0) {
          final previousStartDate = _filterStartDate.subtract(
            Duration(days: _filterEndDate.difference(_filterStartDate).inDays)
          );
          final previousEndDate = _filterStartDate.subtract(const Duration(days: 1));
          
          final previousOrders = await _supabase
              .from('emp_mar_orders')
              .select('total_price')
              .eq('status', 'completed')
              .eq('district', district)
              .gte('created_at', previousStartDate.toIso8601String().split('T')[0])
              .lte('created_at', previousEndDate.toIso8601String().split('T')[0]);
          
          double previousRevenue = 0;
          for (var order in previousOrders) {
            previousRevenue += (order['total_price'] ?? 0).toDouble();
          }

          if (previousRevenue > 0) {
            growth = ((revenue - previousRevenue) / previousRevenue) * 100;
          }
        }

        // Get top products (only if there are orders)
        final topProductsList = productCount.entries
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final topProducts = topProductsList.take(3).map((e) => e.key).toList();

        allDistrictData.add(ExtendedDistrictRevenueData(
          district: district,
          branch: 'Main Branch',
          revenue: revenue,
          orders: orderCount,
          growth: growth,
          topProducts: topProducts,
          totalTons: totalTons,
        ));
      }

      // Sort by revenue (highest first) - districts with revenue will be at top
      allDistrictData.sort((a, b) => b.revenue.compareTo(a.revenue));

      if (mounted) {
        setState(() {
          _districts = allDistrictData;
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });
        _animationController.reset();
        _animationController.forward();
      }

      print('✅ District data processed: ${allDistrictData.length} districts');
      print('📊 Districts with revenue: ${allDistrictData.where((d) => d.revenue > 0).length}');
      print('📊 Districts without revenue: ${allDistrictData.where((d) => d.revenue == 0).length}');
      
    } catch (e) {
      print('❌ Error loading district data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _calculateWeightInTons(Map<String, dynamic> order) {
    double weightInKg = 0.0;
    final weightUnit = order['weight_unit']?.toString().toLowerCase() ?? 'kg';
    final totalWeight = (order['total_weight'] as num?)?.toDouble() ?? 0.0;
    
    if (weightUnit == 'kg') {
      weightInKg = totalWeight;
    } else if (weightUnit == 'g' || weightUnit == 'gm') {
      weightInKg = totalWeight / 1000;
    } else if (weightUnit == 'ton' || weightUnit == 'tonne') {
      weightInKg = totalWeight * 1000;
    }
    
    return weightInKg / 1000; // Convert to tons
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Color _getDistrictColor(String district) {
    final colors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFF7C3AED), // Purple
      const Color(0xFF059669), // Green
      const Color(0xFFDC2626), // Red
      const Color(0xFFD97706), // Orange
      const Color(0xFF0891B2), // Cyan
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF9333EA), // Violet
    ];
    
    final hash = district.hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'District Revenue',
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            if (_lastUpdated != null)
              Text(
                'Updated ${DateFormat('HH:mm').format(_lastUpdated!)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoading ? null : () => _loadDistrictData(),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: _isLoading && _districts.isEmpty
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _districts.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: GlobalColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(GlobalColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading district data...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching revenue by district',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
          const SizedBox(height: 24),
          Text(
            'Failed to load data',
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDistrictData,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_city,
              color: Colors.orange.shade400,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No district data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No completed orders found for selected period',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => setState(() => _selectedFilter = 'This Month'),
            icon: const Icon(Icons.filter_alt),
            label: const Text('Change Filter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: GlobalColors.primaryBlue,
              side: const BorderSide(color: GlobalColors.primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final totalRevenue = _districts.fold(0.0, (sum, d) => sum + d.revenue);
    final totalOrders = _districts.fold(0, (sum, d) => sum + d.orders);
    final totalTons = _districts.fold(0.0, (sum, d) => sum + d.totalTons);
    
    final activeDistricts = _districts.where((d) => d.revenue > 0).length;
    
    return RefreshIndicator(
      onRefresh: _loadDistrictData,
      color: GlobalColors.primaryBlue,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Filter Chips
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter by Period',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          '${_filterStartDate.day} ${DateFormat('MMM').format(_filterStartDate)} - ${_filterEndDate.day} ${DateFormat('MMM').format(_filterEndDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedFilter = filter);
                                  _loadDistrictData();
                                }
                              },
                              backgroundColor: Colors.grey.shade50,
                              selectedColor: GlobalColors.primaryBlue.withOpacity(0.1),
                              checkmarkColor: GlobalColors.primaryBlue,
                              labelStyle: TextStyle(
                                color: isSelected ? GlobalColors.primaryBlue : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? GlobalColors.primaryBlue : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Summary Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Revenue',
                      '₹${NumberFormat.compact().format(totalRevenue)}',
                      Icons.currency_rupee,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Orders',
                      NumberFormat.compact().format(totalOrders),
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Quantity',
                      '${totalTons.toStringAsFixed(1)} T',
                      Icons.scale,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Active/Total',
                      '$activeDistricts/${_districts.length}',
                      Icons.location_city,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Maharashtra Districts (${_districts.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  
                ],
              ),
            ),
          ),
          
          // District List - Show ALL districts
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final district = _districts[index];
                final percentage = totalRevenue > 0 
                    ? (district.revenue / totalRevenue * 100)
                    : 0;
                    
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildDistrictCard(district, percentage.toDouble(), index),
                );
              },
              childCount: _districts.length,
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _buildDistrictCard(ExtendedDistrictRevenueData district, double percentage, int index) {
    final color = _getDistrictColor(district.district);
    final hasRevenue = district.revenue > 0;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: !hasRevenue ? Border.all(color: Colors.grey.shade200, width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: hasRevenue ? () => _showDistrictDetails(district) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Rank and Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: hasRevenue ? color.withOpacity(0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hasRevenue ? color : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // District Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            district.district,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: hasRevenue ? Colors.black87 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.scale, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                '${district.totalTons.toStringAsFixed(1)} T',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasRevenue ? Colors.purple.shade600 : Colors.grey.shade500,
                                  fontWeight: hasRevenue ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Revenue
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          hasRevenue ? '₹${NumberFormat.compact().format(district.revenue)}' : 'No Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasRevenue ? FontWeight.w700 : FontWeight.normal,
                            color: hasRevenue ? Colors.green.shade700 : Colors.grey.shade500,
                          ),
                        ),
                        if (hasRevenue) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: district.growth >= 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  district.growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 10,
                                  color: district.growth >= 0 ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${district.growth.abs().toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: district.growth >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                if (hasRevenue) ...[
                  const SizedBox(height: 12),
                  
                  // Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Orders and Products
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${district.orders} orders',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (district.topProducts.isNotEmpty)
                        Expanded(
                          child: Text(
                            district.topProducts.join(' • '),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDistrictDetails(ExtendedDistrictRevenueData district) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _getDistrictColor(district.district).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                district.district[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _getDistrictColor(district.district),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  district.district,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total Quantity: ${district.totalTons.toStringAsFixed(1)} Tons',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 11,
                        mainAxisSpacing: 11,
                        children: [
                          _buildDetailStatCard(
                            'Revenue',
                            '₹${NumberFormat('#,##,###').format(district.revenue)}',
                            Icons.currency_rupee,
                            Colors.green,
                          ),
                          _buildDetailStatCard(
                            'Orders',
                            district.orders.toString(),
                            Icons.shopping_cart,
                            Colors.blue,
                          ),
                          _buildDetailStatCard(
                            'Quantity',
                            '${district.totalTons.toStringAsFixed(1)} T',
                            Icons.scale,
                            Colors.purple,
                          ),
                          _buildDetailStatCard(
                            'Growth',
                            '${district.growth >= 0 ? '+' : ''}${district.growth.toStringAsFixed(1)}%',
                            district.growth >= 0 ? Icons.trending_up : Icons.trending_down,
                            district.growth >= 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Top Products
                      if (district.topProducts.isNotEmpty) ...[
                        Text(
                          'Top Products',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: district.topProducts.map((product) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                product,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Period Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Data for ${_selectedFilter.toLowerCase()} (${DateFormat('dd MMM').format(_filterStartDate)} - ${DateFormat('dd MMM').format(_filterEndDate)})',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Last Updated
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.update, size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text(
                              'Live updates enabled • Auto-refresh every 30s',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Close Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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
}
import 'package:flutter/material.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:mega_pro/owner/own_emp_details_page.dart';
import 'package:mega_pro/owner/own_pending_orders_page.dart';
import 'package:mega_pro/owner/own_mar_assigning_target.dart';
import 'package:mega_pro/owner/own_total_orders.dart';
import 'package:mega_pro/owner/own_total_revenue.dart';
import 'package:mega_pro/providers/own_dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:intl/intl.dart';

class OwnerDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const OwnerDashboard({super.key, required this.userData});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'Today';
  final List<String> _filters = ['Today', 'This Week', 'This Month', 'This Year'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmation(context);
      },
      child: ChangeNotifierProvider(
        create: (_) => DashboardProvider(),
        child: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            return Scaffold(
              backgroundColor: GlobalColors.background,
              appBar: AppBar(
                backgroundColor: GlobalColors.primaryBlue,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'Owner Dashboard',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white, size: 30),
                    onPressed: () {},
                  ),
                  Consumer<DashboardProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Consumer<DashboardProvider>(
                    builder: (context, provider, _) {
                      return IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () => provider.refresh(),
                      );
                    },
                  ),
                ],
              ),
              body: Consumer<DashboardProvider>(
                builder: (context, provider, _) {
                  return _buildBody(context, provider);
                },
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AssignTargetPage(),
                    ),
                  );
                },
                backgroundColor: GlobalColors.primaryBlue,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildExitDialog(),
        ) ??
        false;
  }

  Widget _buildExitDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        "Exit App?",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: const Text(
        "Are you sure you want to exit?",
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            "Cancel",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            backgroundColor: GlobalColors.primaryBlue,
          ),
          child: const Text(
            "Exit",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, DashboardProvider provider) {
    if (provider.isLoading && provider.dashboardData.totalRevenue == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading Dashboard...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Error: ${provider.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => provider.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SafeArea(
        child: Column(
          children: [
            // Date and Filter Row
            _buildDateFilterRow(),
            const SizedBox(height: 16),

            // Key Metrics Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMetricsGrid(provider.dashboardData),
            ),
            const SizedBox(height: 20),

            // Revenue Chart Section - FIXED
            _buildRevenueChart(provider.dashboardData, provider.revenueChartData),
            const SizedBox(height: 20),

            // Top Products Section - FIXED
            _buildTopProducts(provider.dashboardData),
            const SizedBox(height: 20),

            // Recent Activities
            _buildRecentActivities(provider.dashboardData),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Business Overview',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          // Improved Dropdown Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: GlobalColors.primaryBlue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                iconSize: 20,
                elevation: 2,
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: GlobalColors.primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                items: _filters.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFilter = newValue;
                    });
                  }
                },
                selectedItemBuilder: (BuildContext context) {
                  return _filters.map<Widget>((String value) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(DashboardData dashboardData) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.9,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      padding: const EdgeInsets.all(0),
      children: [
        // Total Revenue Card
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DistrictWiseRevenuePage(dashboardData: dashboardData),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: _buildMetricCard(
            title: 'Total Revenue',
            value: '₹${NumberFormat('#,##,###').format(dashboardData.totalRevenue)}',
            icon: Icons.currency_rupee,
            color: Colors.green,
            growth: dashboardData.revenueGrowth,
            subtitle: 'Completed orders',
          ),
        ),
        
        // Total Orders Card
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailsPage(dashboardData: dashboardData),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: _buildMetricCard(
            title: 'Total Orders',
            value: dashboardData.totalOrders.toString(),
            icon: Icons.shopping_cart,
            color: Colors.blue,
            growth: dashboardData.orderGrowth,
            subtitle: 'All orders',
          ),
        ),
        
        // Active Employees Card
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeDetailsPage(dashboardData: dashboardData),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: _buildMetricCard(
            title: 'Active Employees',
            value: dashboardData.activeEmployees.toString(),
            icon: Icons.people,
            color: Colors.purple,
            growth: dashboardData.employeeGrowth,
            subtitle: 'Current staff',
          ),
        ),
        
        // Pending Orders Card
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PendingOrdersDetailsPage(dashboardData: dashboardData),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: _buildMetricCard(
            title: 'Pending Orders',
            value: dashboardData.pendingOrders.toString(),
            icon: Icons.pending_actions,
            color: Colors.orange,
            isWarning: true,
            subtitle: 'Needs attention',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double growth = 0,
    bool isWarning = false,
    String subtitle = '',
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  child: Icon(icon, size: 22, color: color),
                ),
                if (growth != 0 || isWarning)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isWarning 
                        ? Colors.orange.withOpacity(0.1)
                        : growth >= 0 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isWarning ? Icons.warning : 
                          (growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward),
                          size: 12,
                          color: isWarning ? Colors.orange :
                          (growth >= 0 ? Colors.green : Colors.red),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isWarning ? '!' : '${growth.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isWarning ? Colors.orange :
                            (growth >= 0 ? Colors.green : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // FIXED: Revenue Chart Method
  Widget _buildRevenueChart(DashboardData dashboardData, List<Map<String, dynamic>> chartData) {
    // Check if we have valid chart data
    final hasChartData = chartData.isNotEmpty;
    
    // Calculate max revenue for scaling
    double maxRevenue = 0;
    if (hasChartData) {
      for (var data in chartData) {
        final revenue = (data['revenue'] as num?)?.toDouble() ?? 0;
        if (revenue > maxRevenue) {
          maxRevenue = revenue;
        }
      }
    }
    
    // If maxRevenue is 0 or very small, set a default
    if (maxRevenue <= 0) {
      maxRevenue = 200000; // Default max for empty chart
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last 7 days',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Chart Container
            SizedBox(
              height: 220,
              child: !hasChartData
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No revenue data available',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Chart Bars with Y-axis
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Y-axis labels
                              SizedBox(
                                width: 40,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${NumberFormat.compact().format(maxRevenue)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '₹${NumberFormat.compact().format(maxRevenue * 0.75)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '₹${NumberFormat.compact().format(maxRevenue * 0.5)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '₹${NumberFormat.compact().format(maxRevenue * 0.25)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bars
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: chartData.map((data) {
                                    final day = data['day'] as String? ?? 'Mon';
                                    final revenue = (data['revenue'] as num?)?.toDouble() ?? 0.0;
                                    // Scale height (max bar height = 120)
                                    final height = maxRevenue > 0 ? (revenue / maxRevenue) * 120 : 0.0;
                                    
                                    return _buildBar(
                                      (height > 0 ? height : 0).toDouble(),
                                      day,
                                      revenue > 0 
                                        ? GlobalColors.primaryBlue
                                        : Colors.grey.withOpacity(0.2),
                                      revenue > 0 ? revenue : null,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Revenue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${NumberFormat('#,##,###').format(dashboardData.totalRevenue)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: dashboardData.revenueGrowth >= 0 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        dashboardData.revenueGrowth >= 0 
                          ? Icons.arrow_upward 
                          : Icons.arrow_downward,
                        size: 14,
                        color: dashboardData.revenueGrowth >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dashboardData.revenueGrowth >= 0 ? '+' : ''}${dashboardData.revenueGrowth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: dashboardData.revenueGrowth >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
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

  Widget _buildBar(double height, String label, Color color, [double? revenue]) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: revenue != null && revenue > 0
              ? Tooltip(
                  message: '₹${NumberFormat('#,##,###').format(revenue)}',
                  child: Container(),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (revenue != null && revenue > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '₹${NumberFormat.compact().format(revenue)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // FIXED: Top Products Method
  Widget _buildTopProducts(DashboardData dashboardData) {
    // Get top products from dashboard data - handle null case
    final topProducts = dashboardData.topProducts;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Selling Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'By revenue',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            if (topProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory,
                        color: Colors.grey.shade400,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No product sales data available',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to products page
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        ),
                        child: const Text(
                          'View Products',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: topProducts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  final rankColors = [
                    Colors.amber.shade700,
                    Colors.grey.shade600,
                    Colors.orange.shade700,
                    Colors.blue.shade600,
                    Colors.purple.shade600,
                  ];

                  // Safely extract product data with null checks
                  final productName = product['name']?.toString() ?? 'Unknown Product';
                  final sales = (product['sales'] as num?)?.toInt() ?? 0;
                  final revenue = (product['revenue'] as num?)?.toDouble() ?? 0.0;

                  return Container(
                    margin: EdgeInsets.only(bottom: index == topProducts.length - 1 ? 0 : 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Rank Badge
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: rankColors[index % rankColors.length].withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: rankColors[index % rankColors.length].withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: rankColors[index % rankColors.length],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Product Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$sales sales',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '₹${NumberFormat('#,##,###').format(revenue)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Revenue Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '₹${NumberFormat.compact().format(revenue)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to all products page
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: GlobalColors.primaryBlue.withOpacity(0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All Products',
                      style: TextStyle(
                        color: GlobalColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      color: GlobalColors.primaryBlue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(DashboardData dashboardData) {
    final recentActivities = dashboardData.recentActivities;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Latest updates',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            if (recentActivities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        color: Colors.grey.shade400,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No recent activities',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: recentActivities.map((activity) {
                  // Safely extract activity data
                  final icon = (activity['icon'] as IconData?) ?? Icons.notifications;
                  final color = (activity['color'] as Color?) ?? Colors.grey;
                  final title = activity['title']?.toString() ?? 'Activity';
                  final time = activity['time']?.toString() ?? 'Just now';
                  final description = activity['description']?.toString();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Activity Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Activity Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (description != null && description.isNotEmpty)
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to all activities page
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: GlobalColors.primaryBlue.withOpacity(0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All Activities',
                      style: TextStyle(
                        color: GlobalColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      color: GlobalColors.primaryBlue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






//revenue chart and top products section does not work properly

// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:mega_pro/owner/own_emp_details_page.dart';
// import 'package:mega_pro/owner/own_pending_orders_page.dart';
// import 'package:mega_pro/owner/own_mar_assigning_target.dart';
// import 'package:mega_pro/owner/own_total_orders.dart';
// import 'package:mega_pro/owner/own_total_revenue.dart';
// import 'package:mega_pro/providers/own_dashboard_provider.dart';

// import 'package:provider/provider.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:intl/intl.dart';

// class OwnerDashboard extends StatefulWidget {
//   final Map<String, dynamic> userData;
  
//   const OwnerDashboard({super.key, required this.userData});

//   @override
//   State<OwnerDashboard> createState() => _OwnerDashboardState();
// }

// class _OwnerDashboardState extends State<OwnerDashboard> {
//   final DateTime _selectedDate = DateTime.now();
//   String _selectedFilter = 'Today';
//   final List<String> _filters = ['Today', 'This Week', 'This Month', 'This Year'];

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ignore: deprecated_member_use
//     return WillPopScope(
//       onWillPop: () async {
//         return await _showExitConfirmation(context);
//       },
//       child: ChangeNotifierProvider(
//         create: (_) => DashboardProvider(),
//         child: Consumer<DashboardProvider>(
//           builder: (context, provider, child) {
//             return Scaffold(
//               backgroundColor: GlobalColors.background,
//               appBar: AppBar(
//                 backgroundColor: GlobalColors.primaryBlue,
//                 elevation: 0,
//                 iconTheme: const IconThemeData(color: Colors.white),
//                 title: const Text(
//                   'Owner Dashboard',
//                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//                 ),
//                 actions: [
//                   IconButton(
//                     icon: const Icon(Icons.person, color: Colors.white, size: 30),
//                     onPressed: () {},
//                   ),
//                   Consumer<DashboardProvider>(
//                     builder: (context, provider, _) {
//                       if (provider.isLoading) {
//                         return Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
//                             ),
//                           ),
//                         );
//                       }
//                       return const SizedBox.shrink();
//                     },
//                   ),
//                   Consumer<DashboardProvider>(
//                     builder: (context, provider, _) {
//                       return IconButton(
//                         icon: const Icon(Icons.refresh, color: Colors.white),
//                         onPressed: () => provider.refresh(),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//               body: Consumer<DashboardProvider>(
//                 builder: (context, provider, _) {
//                   return _buildBody(context, provider);
//                 },
//               ),
//               floatingActionButton: FloatingActionButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const AssignTargetPage(),
//                     ),
//                   );
//                 },
//                 backgroundColor: GlobalColors.primaryBlue,
//                 child: const Icon(Icons.add, color: Colors.white),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Future<bool> _showExitConfirmation(BuildContext context) async {
//     return await showDialog<bool>(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) => _buildExitDialog(),
//         ) ??
//         false;
//   }

//   Widget _buildExitDialog() {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       title: const Text(
//         "Exit App?",
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       content: const Text(
//         "Are you sure you want to exit?",
//         style: TextStyle(
//           fontSize: 14,
//           color: Colors.grey,
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(false),
//           child: const Text(
//             "Cancel",
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey,
//             ),
//           ),
//         ),
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(true),
//           style: TextButton.styleFrom(
//             backgroundColor: GlobalColors.primaryBlue,
//           ),
//           child: const Text(
//             "Exit",
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.white,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildBody(BuildContext context, DashboardProvider provider) {
//     if (provider.isLoading && provider.dashboardData.totalRevenue == 0) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text(
//               'Loading Dashboard...',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       );
//     }

//     if (provider.error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 48),
//             const SizedBox(height: 16),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 32),
//               child: Text(
//                 'Error: ${provider.error}',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.red),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => provider.refresh(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: GlobalColors.primaryBlue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//               child: const Text('Retry', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//       );
//     }

//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: SafeArea(
//         child: Column(
//           children: [
//             // Date and Filter Row
//             _buildDateFilterRow(),
//             const SizedBox(height: 16),

//             // Key Metrics Grid
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: _buildMetricsGrid(provider.dashboardData),
//             ),
//             const SizedBox(height: 20),

//             // Revenue Chart Section
//             _buildRevenueChart(provider.dashboardData, provider.revenueChartData),
//             const SizedBox(height: 20),

//             // Top Products Section
//             _buildTopProducts(provider.dashboardData),
//             const SizedBox(height: 20),

//             // Recent Activities
//             _buildRecentActivities(provider.dashboardData),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateFilterRow() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       color: Colors.white,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 DateFormat('EEEE, MMMM d').format(_selectedDate),
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 'Business Overview',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ),
//           // Improved Dropdown Button
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               color: GlobalColors.primaryBlue,
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: _selectedFilter,
//                 icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
//                 iconSize: 20,
//                 elevation: 2,
//                 dropdownColor: Colors.white,
//                 style: const TextStyle(
//                   color: GlobalColors.primaryBlue,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 items: _filters.map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8),
//                       child: Text(
//                         value,
//                         style: const TextStyle(
//                           color: Colors.black87,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   if (newValue != null) {
//                     setState(() {
//                       _selectedFilter = newValue;
//                     });
//                   }
//                 },
//                 selectedItemBuilder: (BuildContext context) {
//                   return _filters.map<Widget>((String value) {
//                     return Container(
//                       alignment: Alignment.center,
//                       child: Text(
//                         value,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     );
//                   }).toList();
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMetricsGrid(DashboardData dashboardData) {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       childAspectRatio: 0.9,
//       crossAxisSpacing: 12,
//       mainAxisSpacing: 12,
//       padding: const EdgeInsets.all(0),
//       children: [
//         // Total Revenue Card
//         InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => DistrictWiseRevenuePage(dashboardData: dashboardData),
//               ),
//             );
//           },
//           borderRadius: BorderRadius.circular(16),
//           child: _buildMetricCard(
//             title: 'Total Revenue',
//             value: '₹${NumberFormat('#,##,###').format(dashboardData.totalRevenue)}',
//             icon: Icons.currency_rupee,
//             color: Colors.green,
//             growth: dashboardData.revenueGrowth,
//             subtitle: 'Completed orders',
//           ),
//         ),
        
//         // Total Orders Card
//         InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) =>  OrderDetailsPage(dashboardData: dashboardData,),
//               ),
//             );
//           },
//           borderRadius: BorderRadius.circular(16),
//           child: _buildMetricCard(
//             title: 'Total Orders',
//             value: dashboardData.totalOrders.toString(),
//             icon: Icons.shopping_cart,
//             color: Colors.blue,
//             growth: dashboardData.orderGrowth,
//             subtitle: 'All orders',
//           ),
//         ),
        
//         // Active Employees Card
//         InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => EmployeeDetailsPage(dashboardData: dashboardData),
//               ),
//             );
//           },
//           borderRadius: BorderRadius.circular(16),
//           child: _buildMetricCard(
//             title: 'Active Employees',
//             value: dashboardData.activeEmployees.toString(),
//             icon: Icons.people,
//             color: Colors.purple,
//             growth: dashboardData.employeeGrowth,
//             subtitle: 'Current staff',
//           ),
//         ),
        
//         // Pending Orders Card
//         InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => PendingOrdersDetailsPage(dashboardData: dashboardData),
//               ),
//             );
//           },
//           borderRadius: BorderRadius.circular(16),
//           child: _buildMetricCard(
//             title: 'Pending Orders',
//             value: dashboardData.pendingOrders.toString(),
//             icon: Icons.pending_actions,
//             color: Colors.orange,
//             isWarning: true,
//             subtitle: 'Needs attention',
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildMetricCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//     double growth = 0,
//     bool isWarning = false,
//     String subtitle = '',
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(icon, size: 22, color: color),
//                 ),
//                 if (growth != 0 || isWarning)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: isWarning 
//                         ? Colors.orange.withOpacity(0.1)
//                         : growth >= 0 
//                           ? Colors.green.withOpacity(0.1) 
//                           : Colors.red.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           isWarning ? Icons.warning : 
//                           (growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward),
//                           size: 12,
//                           color: isWarning ? Colors.orange :
//                           (growth >= 0 ? Colors.green : Colors.red),
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           isWarning ? '!' : '${growth.abs().toStringAsFixed(1)}%',
//                           style: TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             color: isWarning ? Colors.orange :
//                             (growth >= 0 ? Colors.green : Colors.red),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black87,
//               ),
//             ),
//             if (subtitle.isNotEmpty) ...[
//               const SizedBox(height: 2),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRevenueChart(DashboardData dashboardData, List<Map<String, dynamic>> chartData) {
//     // Calculate max revenue for scaling
//     double maxRevenue = 0;
//     bool hasData = false;
    
//     for (var data in chartData) {
//       final revenue = (data['revenue'] as num?)?.toDouble() ?? 0;
//       if (revenue > 0) hasData = true;
//       if (revenue > maxRevenue) {
//         maxRevenue = revenue;
//       }
//     }

//     // If all revenues are 0, use a small default max
//     if (maxRevenue == 0) {
//       maxRevenue = 100000;
//     }

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Revenue Overview',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 // Removed the Details button as requested
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Last 7 days',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Chart Container
//             SizedBox(
//               height: 200, // Increased height for better visibility
//               child: !hasData
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.bar_chart,
//                             color: Colors.grey.shade400,
//                             size: 40,
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'No revenue data',
//                             style: TextStyle(
//                               color: Colors.grey.shade500,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : Column(
//                       children: [
//                         // Chart Bars with Y-axis
//                         Expanded(
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               // Y-axis labels
//                               SizedBox(
//                                 width: 40,
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   children: [
//                                     Text(
//                                       '₹${NumberFormat.compact().format(maxRevenue)}',
//                                       style: TextStyle(
//                                         fontSize: 10,
//                                         color: Colors.grey.shade600,
//                                       ),
//                                     ),
//                                     Text(
//                                       '₹${NumberFormat.compact().format(maxRevenue * 0.75)}',
//                                       style: TextStyle(
//                                         fontSize: 10,
//                                         color: Colors.grey.shade600,
//                                       ),
//                                     ),
//                                     Text(
//                                       '₹${NumberFormat.compact().format(maxRevenue * 0.5)}',
//                                       style: TextStyle(
//                                         fontSize: 10,
//                                         color: Colors.grey.shade600,
//                                       ),
//                                     ),
//                                     Text(
//                                       '₹${NumberFormat.compact().format(maxRevenue * 0.25)}',
//                                       style: TextStyle(
//                                         fontSize: 10,
//                                         color: Colors.grey.shade600,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 20),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               // Bars
//                               Expanded(
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                   children: chartData.map((data) {
//                                     final day = data['day'] as String;
//                                     final revenue = (data['revenue'] as num?)?.toDouble() ?? 0;
//                                     // Scale height (max bar height = 100)
//                                     final height = maxRevenue > 0 ? (revenue / maxRevenue) * 100 : 0;
                                    
//                                     return _buildBar(
//                                       height.toDouble(),
//                                       day,
//                                       revenue > 0 
//                                         ? GlobalColors.primaryBlue
//                                         : Colors.grey.withOpacity(0.2),
//                                       revenue > 0 ? revenue : null,
//                                     );
//                                   }).toList(),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//             ),
            
//             const SizedBox(height: 16),
//             const Divider(height: 1),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Total Revenue',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       '₹${NumberFormat('#,##,###').format(dashboardData.totalRevenue)}',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: dashboardData.revenueGrowth >= 0 
//                       ? Colors.green.withOpacity(0.1)
//                       : Colors.red.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         dashboardData.revenueGrowth >= 0 
//                           ? Icons.arrow_upward 
//                           : Icons.arrow_downward,
//                         size: 14,
//                         color: dashboardData.revenueGrowth >= 0 ? Colors.green : Colors.red,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${dashboardData.revenueGrowth >= 0 ? '+' : ''}${dashboardData.revenueGrowth.toStringAsFixed(1)}%',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: dashboardData.revenueGrowth >= 0 ? Colors.green : Colors.red,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBar(double height, String label, Color color, [double? revenue]) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Container(
//           width: 28, // Slightly wider bars
//           height: height,
//           margin: const EdgeInsets.symmetric(horizontal: 2),
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(6),
//               topRight: Radius.circular(6),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: color.withOpacity(0.3),
//                 blurRadius: 2,
//                 offset: const Offset(0, 1),
//               ),
//             ],
//           ),
//           child: revenue != null && revenue > 0
//               ? Tooltip(
//                   message: '₹${NumberFormat('#,##,###').format(revenue)}',
//                   child: Container(),
//                 )
//               : null,
//         ),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey.shade600,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         if (revenue != null && revenue > 0)
//           Padding(
//             padding: const EdgeInsets.only(top: 4),
//             child: Text(
//               '₹${NumberFormat.compact().format(revenue)}',
//               style: TextStyle(
//                 fontSize: 10,
//                 color: Colors.grey.shade700,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildTopProducts(DashboardData dashboardData) {
//     final topProducts = dashboardData.topProducts;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Top Selling Products',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'By revenue',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             if (topProducts.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 20),
//                 child: Center(
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.inventory,
//                         color: Colors.grey.shade400,
//                         size: 40,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'No product data',
//                         style: TextStyle(
//                           color: Colors.grey.shade500,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               Column(
//                 children: topProducts.asMap().entries.map((entry) {
//                   final index = entry.key;
//                   final product = entry.value;
//                   final rankColors = [
//                     Colors.amber.shade700,
//                     Colors.grey.shade600,
//                     Colors.orange.shade700,
//                   ];

//                   return Container(
//                     margin: EdgeInsets.only(bottom: index == topProducts.length - 1 ? 0 : 12),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: Colors.grey.shade200,
//                         width: 1,
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         // Rank Badge
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: rankColors[index].withOpacity(0.15),
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(
//                               color: rankColors[index].withOpacity(0.3),
//                               width: 1.5,
//                             ),
//                           ),
//                           child: Center(
//                             child: Text(
//                               '${index + 1}',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w700,
//                                 color: rankColors[index],
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
                        
//                         // Product Info
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 product['name'] as String,
//                                 style: const TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.black87,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               const SizedBox(height: 6),
//                               Row(
//                                 children: [
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                     decoration: BoxDecoration(
//                                       color: Colors.blue.withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(6),
//                                     ),
//                                     child: Text(
//                                       '${product['sales']} sales',
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         color: Colors.blue.shade700,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Text(
//                                     '₹${NumberFormat('#,##,###').format(product['revenue'])}',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       color: Colors.green.shade700,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
                        
//                         // Revenue Indicator
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: Colors.green.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(
//                               color: Colors.green.withOpacity(0.3),
//                               width: 1,
//                             ),
//                           ),
//                           child: Text(
//                             '₹${NumberFormat.compact().format(product['revenue'])}',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.green,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
            
//             const SizedBox(height: 8),
//             Center(
//               child: TextButton(
//                 onPressed: () {
//                   // Navigate to all products page
//                 },
//                 style: TextButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   backgroundColor: GlobalColors.primaryBlue.withOpacity(0.1),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       'View All Products',
//                       style: TextStyle(
//                         color: GlobalColors.primaryBlue,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     Icon(
//                       Icons.arrow_forward,
//                       color: GlobalColors.primaryBlue,
//                       size: 16,
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

//   Widget _buildRecentActivities(DashboardData dashboardData) {
//     final recentActivities = dashboardData.recentActivities;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Recent Activities',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Latest updates',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             if (recentActivities.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 20),
//                 child: Center(
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.notifications_none,
//                         color: Colors.grey.shade400,
//                         size: 40,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'No recent activities',
//                         style: TextStyle(
//                           color: Colors.grey.shade500,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               Column(
//                 children: recentActivities.map((activity) {
//                   final icon = activity['icon'] as IconData;
//                   final color = activity['color'] as Color;
                  
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Activity Icon
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: color.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: color.withOpacity(0.2),
//                               width: 1,
//                             ),
//                           ),
//                           child: Icon(
//                             icon,
//                             color: color,
//                             size: 20,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
                        
//                         // Activity Details
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       activity['title'] as String,
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.black87,
//                                       ),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                                   Text(
//                                     activity['time'] as String,
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey.shade500,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               if (activity['description'] != null)
//                                 Text(
//                                   activity['description'] as String,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey.shade600,
//                                   ),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
            
//             const SizedBox(height: 8),
//             Center(
//               child: TextButton(
//                 onPressed: () {
//                   // Navigate to all activities page
//                 },
//                 style: TextButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   backgroundColor: GlobalColors.primaryBlue.withOpacity(0.1),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       'View All Activities',
//                       style: TextStyle(
//                         color: GlobalColors.primaryBlue,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     Icon(
//                       Icons.arrow_forward,
//                       color: GlobalColors.primaryBlue,
//                       size: 16,
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
// }











// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:mega_pro/owner/own_emp_details_page.dart';
// import 'package:mega_pro/owner/own_pending_orders_page.dart';
// import 'package:mega_pro/owner/own_quick_action.dart';
// import 'package:mega_pro/owner/own_total_orders.dart';
// import 'package:mega_pro/owner/own_total_revenue.dart';
// import 'package:mega_pro/providers/own_dashboard_provider.dart';

// import 'package:provider/provider.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:intl/intl.dart';

// class OwnerDashboard extends StatefulWidget {
//   final Map<String, dynamic> userData;
  
//   const OwnerDashboard({super.key, required this.userData});

//   @override
//   State<OwnerDashboard> createState() => _OwnerDashboardState();
// }

// class _OwnerDashboardState extends State<OwnerDashboard> {
//   final DateTime _selectedDate = DateTime.now();
//   String _selectedFilter = 'Today';
//   final List<String> _filters = ['Today', 'This Week', 'This Month', 'This Year'];

//   @override
//   void initState() {
//     super.initState();
//     // The provider will auto-initialize in its constructor
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         // Show exit confirmation when back button is pressed
//         return await _showExitConfirmation(context);
//       },
//       child: ChangeNotifierProvider(
//         create: (_) => DashboardProvider(),
//         child: Consumer<DashboardProvider>(
//           builder: (context, provider, child) {
//             return Scaffold(
//               backgroundColor: GlobalColors.background,
//               appBar: AppBar(
//                 backgroundColor: GlobalColors.primaryBlue,
//                 elevation: 0,
//                 iconTheme: const IconThemeData(color: Colors.white),
//                 title: const Text(
//                   'Owner Dashboard',
//                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//                 ),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.person, color: Colors.white, size: 30),
//               onPressed: () {},
//             ),
//             Consumer<DashboardProvider>(
//               builder: (context, provider, _) {
//                 if (provider.isLoading) {
//                   return Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
//                       ),
//                     ),
//                   );
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//             Consumer<DashboardProvider>(
//               builder: (context, provider, _) {
//                 return IconButton(
//                   icon: const Icon(Icons.refresh, color: Colors.white),
//                   onPressed: () => provider.refresh(),
//                 );
//               },
//             ),
//           ],
//         ),
//         body: Consumer<DashboardProvider>(
//           builder: (context, provider, _) {
//             return _buildBody(context, provider);
//           },
//         ),
//         floatingActionButton: FloatingActionButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const AssignTargetPage(),
//               ),
//             );
//           },
//           backgroundColor: GlobalColors.primaryBlue,
//           child: const Icon(Icons.add, color: Colors.white),
//         ),
//       );
//         },
//         )
//       )
//       );
//   }

//   Future<bool> _showExitConfirmation(BuildContext context) async {
//     return await showDialog<bool>(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) => _buildExitDialog(),
//         ) ??
//         false;
//   }

//   Widget _buildExitDialog() {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       title: const Text(
//         "Exit App?",
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       content: const Text(
//         "Are you sure you want to exit?",
//         style: TextStyle(
//           fontSize: 14,
//           color: Colors.grey,
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(false),
//           child: const Text(
//             "Cancel",
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey,
//             ),
//           ),
//         ),
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(true),
//           style: TextButton.styleFrom(
//             backgroundColor: GlobalColors.primaryBlue,
//           ),
//           child: const Text(
//             "Exit",
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.white,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildBody(BuildContext context, DashboardProvider provider) {
//     if (provider.isLoading && provider.dashboardData.totalRevenue == 0) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text(
//               'Loading Dashboard...',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       );
//     }

//     if (provider.error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 48),
//             const SizedBox(height: 16),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 32),
//               child: Text(
//                 'Error: ${provider.error}',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.red),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => provider.refresh(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: GlobalColors.primaryBlue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//               child: const Text('Retry', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//       );
//     }

//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: SafeArea(
//         child: Column(
//           children: [
//             // Date and Filter Row
//             _buildDateFilterRow(),
//             const SizedBox(height: 16),

//             // Key Metrics Grid
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: _buildMetricsGrid(provider.dashboardData),
//             ),
//             const SizedBox(height: 20),

//             // Revenue Chart Section
//             _buildRevenueChart(provider.dashboardData, provider.revenueChartData),
//             const SizedBox(height: 20),

//             // Top Products Section
//             _buildTopProducts(provider.dashboardData),
//             const SizedBox(height: 20),

//             // Recent Activities
//             _buildRecentActivities(provider.dashboardData),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateFilterRow() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       color: Colors.white,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 DateFormat('EEEE, MMMM d').format(_selectedDate),
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 'Business Overview',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//             decoration: BoxDecoration(
//               color: GlobalColors.primaryBlue.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: GlobalColors.primaryBlue.withOpacity(0.3)),
//             ),
//             child: DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: _selectedFilter,
//                 icon: Icon(Icons.arrow_drop_down, color: GlobalColors.primaryBlue),
//                 items: _filters.map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(
//                       value,
//                       style: TextStyle(color: GlobalColors.primaryBlue, fontSize: 14),
//                     ),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedFilter = newValue!;
//                   });
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMetricsGrid(DashboardData dashboardData) {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       childAspectRatio: 0.9,
//       crossAxisSpacing: 12,
//       mainAxisSpacing: 12,
//       padding: const EdgeInsets.all(0),
//       children: [
//         // Total Revenue Card
//         InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => DistrictWiseRevenuePage(
//                   dashboardData: dashboardData,
//                 ),
//               ),
//             );
//           },
//           borderRadius: BorderRadius.circular(16),
//           child: _buildMetricCard(
//             title: 'Total Revenue',
//             value: '₹${NumberFormat('#,##,###').format(dashboardData.totalRevenue)}',
//             icon: Icons.currency_rupee,
//             color: Colors.green,
//             growth: dashboardData.revenueGrowth,
//             subtitle: 'Completed orders',
//           ),
//         ),
        
//         // Total Orders Card
//         InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => OrderDetailsPage(
//                   dashboardData: dashboardData,
//                 ),
//               ),
//             );
//           },
//           borderRadius: BorderRadius.circular(16),
//           child: _buildMetricCard(
//             title: 'Total Orders',
//             value: dashboardData.totalOrders.toString(),
//             icon: Icons.shopping_cart,
//             color: Colors.blue,
//             growth: dashboardData.orderGrowth,
//             subtitle: 'All orders',
//           ),
//         ),
        
//         // Active Employees Card
//         InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => EmployeeDetailsPage(
//                   dashboardData: dashboardData,
//                 ),
//               ),
//             );
//           },
//           borderRadius: BorderRadius.circular(16),
//           child: _buildMetricCard(
//             title: 'Active Employees',
//             value: dashboardData.activeEmployees.toString(),
//             icon: Icons.people,
//             color: Colors.purple,
//             growth: dashboardData.employeeGrowth,
//             subtitle: 'Current staff',
//           ),
//         ),
        
//         // Pending Orders Card
//         InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => PendingOrdersDetailsPage(
//                   dashboardData: dashboardData,
//                 ),
//               ),
//             );
//           },
//           borderRadius: BorderRadius.circular(16),
//           child: _buildMetricCard(
//             title: 'Pending Orders',
//             value: dashboardData.pendingOrders.toString(),
//             icon: Icons.pending_actions,
//             color: Colors.orange,
//             isWarning: true,
//             subtitle: 'Needs attention',
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildMetricCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//     double growth = 0,
//     bool isWarning = false,
//     String subtitle = '',
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(icon, size: 22, color: color),
//                 ),
//                 if (growth != 0 || isWarning)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: isWarning 
//                         ? Colors.orange.withOpacity(0.1)
//                         : growth >= 0 
//                           ? Colors.green.withOpacity(0.1) 
//                           : Colors.red.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           isWarning ? Icons.warning : 
//                           (growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward),
//                           size: 12,
//                           color: isWarning ? Colors.orange :
//                           (growth >= 0 ? Colors.green : Colors.red),
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           isWarning ? '!' : '${growth.abs().toStringAsFixed(1)}%',
//                           style: TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             color: isWarning ? Colors.orange :
//                             (growth >= 0 ? Colors.green : Colors.red),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black87,
//               ),
//             ),
//             if (subtitle.isNotEmpty) ...[
//               const SizedBox(height: 2),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRevenueChart(DashboardData dashboardData, List<Map<String, dynamic>> chartData) {
//     // Calculate max revenue for scaling
//     int maxRevenue = 0;
//     bool hasData = false;
    
//     for (var data in chartData) {
//       final revenue = data['revenue'] as int;
//       if (revenue > 0) hasData = true;
//       if (revenue > maxRevenue) {
//         maxRevenue = revenue;
//       }
//     }

//     // If all revenues are 0, use a small default max
//     if (maxRevenue == 0) {
//       maxRevenue = 100000;
//     }

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Revenue Overview',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 InkWell(
                  
//                   child: Text(
//                     'Details',
//                     style: TextStyle(
//                       color: GlobalColors.primaryBlue,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Last 7 days',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Chart Container
//             SizedBox(
//               height: 140,
//               child: !hasData
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.bar_chart,
//                             color: Colors.grey.shade400,
//                             size: 40,
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'No revenue data',
//                             style: TextStyle(
//                               color: Colors.grey.shade500,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : Row(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: chartData.map((data) {
//                         final day = data['day'] as String;
//                         final revenue = data['revenue'] as int;
//                         // Scale height (max bar height = 90)
//                         final height = maxRevenue > 0 ? (revenue / maxRevenue) * 90 : 0;
                        
//                         return _buildBar(
//                           height.toDouble(),
//                           day,
//                           revenue > 0 
//                             ? (day == 'Wed' || day == 'Thu' ? GlobalColors.primaryBlue : Colors.blue)
//                             : Colors.grey.withOpacity(0.2),
//                           revenue > 0 ? revenue : null,
//                         );
//                       }).toList(),
//                     ),
//             ),
            
//             const SizedBox(height: 16),
//             const Divider(height: 1),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Total Revenue',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       '₹${NumberFormat('#,##,###').format(dashboardData.totalRevenue)}',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.green.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.arrow_upward, size: 14, color: Colors.green),
//                       const SizedBox(width: 4),
//                       Text(
//                         '+${dashboardData.revenueGrowth.toStringAsFixed(1)}%',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.green,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBar(double height, String label, Color color, [int? revenue]) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Container(
//           width: 22,
//           height: height,
//           margin: const EdgeInsets.symmetric(horizontal: 2),
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(4),
//               topRight: Radius.circular(4),
//             ),
//           ),
//           child: revenue != null && revenue > 0
//               ? Tooltip(
//                   message: '₹${NumberFormat('#,##,###').format(revenue)}',
//                   child: Container(),
//                 )
//               : null,
//         ),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 11,
//             color: Colors.grey.shade600,
//           ),
//         ),
//         if (revenue != null && revenue > 0)
//           Padding(
//             padding: const EdgeInsets.only(top: 2),
//             child: Text(
//               '₹${NumberFormat.compact().format(revenue)}',
//               style: TextStyle(
//                 fontSize: 9,
//                 color: Colors.grey.shade500,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildTopProducts(DashboardData dashboardData) {
//     final topProducts = dashboardData.topProducts;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Top Selling Products',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'By revenue',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             if (topProducts.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 20),
//                 child: Center(
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.inventory,
//                         color: Colors.grey.shade400,
//                         size: 40,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'No product data',
//                         style: TextStyle(
//                           color: Colors.grey.shade500,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               ...topProducts.asMap().entries.map((entry) {
//                 final index = entry.key;
//                 final product = entry.value;
//                 final rankColors = [
//                   Colors.amber.shade700,
//                   Colors.grey.shade600,
//                   Colors.orange.shade700,
//                 ];

//                 return Container(
//                   margin: EdgeInsets.only(bottom: index == topProducts.length - 1 ? 0 : 12),
//                   child: Row(
//                     children: [
//                       // Rank Badge
//                       Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: rankColors[index].withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Center(
//                           child: Text(
//                             '${index + 1}',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w700,
//                               color: rankColors[index],
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
                      
//                       // Product Info
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               product['name'] as String,
//                               style: const TextStyle(
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black87,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(4),
//                                   ),
//                                   child: Text(
//                                     '${product['sales']} sales',
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.blue.shade700,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   '₹${NumberFormat('#,##,###').format(product['revenue'])}',
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.green.shade700,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
                      
//                       // Growth Indicator
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.green.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           '₹${NumberFormat.compact().format(product['revenue'])}',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.green,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
            
//             const SizedBox(height: 8),
//             Center(
//               child: TextButton(
//                 onPressed: () {},
//                 style: TextButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                 ),
//                 child: Text(
//                   'View All Products →',
//                   style: TextStyle(
//                     color: GlobalColors.primaryBlue,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivities(DashboardData dashboardData) {
//     final recentActivities = dashboardData.recentActivities;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Recent Activities',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Latest updates',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             if (recentActivities.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 20),
//                 child: Center(
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.notifications_none,
//                         color: Colors.grey.shade400,
//                         size: 40,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'No recent activities',
//                         style: TextStyle(
//                           color: Colors.grey.shade500,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               Column(
//                 children: recentActivities.map((activity) {
//                   final icon = activity['icon'] as IconData;
//                   final color = activity['color'] as Color;
                  
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Activity Icon
//                         Container(
//                           width: 36,
//                           height: 36,
//                           decoration: BoxDecoration(
//                             color: color.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Icon(
//                             icon,
//                             color: color,
//                             size: 18,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
                        
//                         // Activity Details
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       activity['title'] as String,
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.black87,
//                                       ),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                                   Text(
//                                     activity['time'] as String,
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey.shade500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 2),
//                               if (activity['description'] != null)
//                                 Text(
//                                   activity['description'] as String,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey.shade600,
//                                   ),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
            
//             const SizedBox(height: 8),
//             Center(
//               child: TextButton(
//                 onPressed: () {},
//                 style: TextButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                 ),
//                 child: Text(
//                   'View All Activities →',
//                   style: TextStyle(
//                     color: GlobalColors.primaryBlue,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:mega_pro/owner/own_quick_action.dart';
// import 'package:mega_pro/providers/own_dashboard_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:intl/intl.dart';

// class OwnerDashboard extends StatefulWidget {
//   final Map<String, dynamic> userData;
  
//   const OwnerDashboard({super.key, required this.userData});

//   @override
//   State<OwnerDashboard> createState() => _OwnerDashboardState();
// }

// class _OwnerDashboardState extends State<OwnerDashboard> {
//   final DateTime _selectedDate = DateTime.now();
//   String _selectedFilter = 'Today';
//   final List<String> _filters = ['Today', 'This Week', 'This Month', 'This Year'];

//   @override
//   void initState() {
//     super.initState();
//     // The provider will auto-initialize in its constructor
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => DashboardProvider(),
//       child: Consumer<DashboardProvider>(
//         builder: (context, provider, child) {
//           return Scaffold(
//             backgroundColor: GlobalColors.background,
//             appBar: AppBar(
//               backgroundColor: GlobalColors.primaryBlue,
//               elevation: 0,
//               iconTheme: const IconThemeData(color: Colors.white),
//               title: const Text(
//                 'Owner Dashboard',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//               ),
//               actions: [
//                 IconButton(
//                   icon: const Icon(Icons.person, color: Colors.white, size: 30),
//                   onPressed: () {},
//                 ),
//                 if (provider.isLoading)
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
//                       ),
//                     ),
//                   ),
//                 IconButton(
//                   icon: const Icon(Icons.refresh, color: Colors.white),
//                   onPressed: () => provider.refresh(),
//                 ),
//               ],
//             ),
//             body: _buildBody(context, provider),
//             floatingActionButton: FloatingActionButton(
//               onPressed: () {
//                 Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const AssignTargetPage(),
//       ),
//     );
//               },
//               backgroundColor: GlobalColors.primaryBlue,
//               child: const Icon(Icons.add, color: Colors.white),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildBody(BuildContext context, DashboardProvider provider) {
//     if (provider.isLoading && provider.dashboardData.totalRevenue == 0) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text(
//               'Loading Dashboard...',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       );
//     }

//     if (provider.error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 48),
//             const SizedBox(height: 16),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 32),
//               child: Text(
//                 'Error: ${provider.error}',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.red),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => provider.refresh(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: GlobalColors.primaryBlue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//               child: const Text('Retry', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//       );
//     }

//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: SafeArea(
//         child: Column(
//           children: [
//             // Date and Filter Row
//             _buildDateFilterRow(),
//             const SizedBox(height: 16),

//             // Key Metrics Grid
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: _buildMetricsGrid(provider.dashboardData),
//             ),
//             const SizedBox(height: 20),

//             // Revenue Chart Section
//             _buildRevenueChart(provider.dashboardData, provider.revenueChartData),
//             const SizedBox(height: 20),

//             // Top Products Section
//             _buildTopProducts(provider.dashboardData),
//             const SizedBox(height: 20),

//             // Recent Activities
//             _buildRecentActivities(provider.dashboardData),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateFilterRow() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       color: Colors.white,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 DateFormat('EEEE, MMMM d').format(_selectedDate),
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 'Business Overview',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//             decoration: BoxDecoration(
//               color: GlobalColors.primaryBlue.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: GlobalColors.primaryBlue.withOpacity(0.3)),
//             ),
//             child: DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: _selectedFilter,
//                 icon: Icon(Icons.arrow_drop_down, color: GlobalColors.primaryBlue),
//                 items: _filters.map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(
//                       value,
//                       style: TextStyle(color: GlobalColors.primaryBlue, fontSize: 14),
//                     ),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedFilter = newValue!;
//                   });
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMetricsGrid(DashboardData dashboardData) {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       childAspectRatio: 0.9, // Better aspect ratio
//       crossAxisSpacing: 12,
//       mainAxisSpacing: 12,
//       padding: const EdgeInsets.all(0),
//       children: [
//         _buildMetricCard(
//           title: 'Total Revenue',
//           value: '₹${NumberFormat('#,##,###').format(dashboardData.totalRevenue)}',
//           icon: Icons.currency_rupee,
//           color: Colors.green,
//           growth: dashboardData.revenueGrowth,
//           subtitle: 'Completed orders',
//         ),
//         _buildMetricCard(
//           title: 'Total Orders',
//           value: dashboardData.totalOrders.toString(),
//           icon: Icons.shopping_cart,
//           color: Colors.blue,
//           growth: dashboardData.orderGrowth,
//           subtitle: 'All orders',
//         ),
//         _buildMetricCard(
//           title: 'Active Employees',
//           value: dashboardData.activeEmployees.toString(),
//           icon: Icons.people,
//           color: Colors.purple,
//           growth: dashboardData.employeeGrowth,
//           subtitle: 'Current staff',
//         ),
//         _buildMetricCard(
//           title: 'Pending Orders',
//           value: dashboardData.pendingOrders.toString(),
//           icon: Icons.pending_actions,
//           color: Colors.orange,
//           isWarning: true,
//           subtitle: 'Needs attention',
//         ),
//       ],
//     );
//   }

//   Widget _buildMetricCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//     double growth = 0,
//     bool isWarning = false,
//     String subtitle = '',
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(icon, size: 22, color: color),
//                 ),
//                 if (growth != 0 || isWarning)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: isWarning 
//                         ? Colors.orange.withOpacity(0.1)
//                         : growth >= 0 
//                           ? Colors.green.withOpacity(0.1) 
//                           : Colors.red.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           isWarning ? Icons.warning : 
//                           (growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward),
//                           size: 12,
//                           color: isWarning ? Colors.orange :
//                           (growth >= 0 ? Colors.green : Colors.red),
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           isWarning ? '!' : '${growth.abs().toStringAsFixed(1)}%',
//                           style: TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             color: isWarning ? Colors.orange :
//                             (growth >= 0 ? Colors.green : Colors.red),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black87,
//               ),
//             ),
//             if (subtitle.isNotEmpty) ...[
//               const SizedBox(height: 2),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRevenueChart(DashboardData dashboardData, List<Map<String, dynamic>> chartData) {
//     // Calculate max revenue for scaling
//     int maxRevenue = 0;
//     bool hasData = false;
    
//     for (var data in chartData) {
//       final revenue = data['revenue'] as int;
//       if (revenue > 0) hasData = true;
//       if (revenue > maxRevenue) {
//         maxRevenue = revenue;
//       }
//     }

//     // If all revenues are 0, use a small default max
//     if (maxRevenue == 0) {
//       maxRevenue = 100000;
//     }

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Revenue Overview',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () {},
//                   child: Text(
//                     'Details',
//                     style: TextStyle(
//                       color: GlobalColors.primaryBlue,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Last 7 days',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Chart Container
//             SizedBox(
//               height: 140,
//               child: !hasData
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.bar_chart,
//                             color: Colors.grey.shade400,
//                             size: 40,
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'No revenue data',
//                             style: TextStyle(
//                               color: Colors.grey.shade500,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : Row(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: chartData.map((data) {
//                         final day = data['day'] as String;
//                         final revenue = data['revenue'] as int;
//                         // Scale height (max bar height = 90)
//                         final height = maxRevenue > 0 ? (revenue / maxRevenue) * 90 : 0;
                        
//                         return _buildBar(
//                           height.toDouble(),
//                           day,
//                           revenue > 0 
//                             ? (day == 'Wed' || day == 'Thu' ? GlobalColors.primaryBlue : Colors.blue)
//                             : Colors.grey.withOpacity(0.2),
//                           revenue > 0 ? revenue : null,
//                         );
//                       }).toList(),
//                     ),
//             ),
            
//             const SizedBox(height: 16),
//             const Divider(height: 1),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Total Revenue',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       '₹${NumberFormat('#,##,###').format(dashboardData.totalRevenue)}',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.green.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.arrow_upward, size: 14, color: Colors.green),
//                       const SizedBox(width: 4),
//                       Text(
//                         '+${dashboardData.revenueGrowth.toStringAsFixed(1)}%',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.green,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBar(double height, String label, Color color, [int? revenue]) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Container(
//           width: 22,
//           height: height,
//           margin: const EdgeInsets.symmetric(horizontal: 2),
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(4),
//               topRight: Radius.circular(4),
//             ),
//           ),
//           child: revenue != null && revenue > 0
//               ? Tooltip(
//                   message: '₹${NumberFormat('#,##,###').format(revenue)}',
//                   child: Container(),
//                 )
//               : null,
//         ),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 11,
//             color: Colors.grey.shade600,
//           ),
//         ),
//         if (revenue != null && revenue > 0)
//           Padding(
//             padding: const EdgeInsets.only(top: 2),
//             child: Text(
//               '₹${NumberFormat.compact().format(revenue)}',
//               style: TextStyle(
//                 fontSize: 9,
//                 color: Colors.grey.shade500,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildTopProducts(DashboardData dashboardData) {
//     final topProducts = dashboardData.topProducts;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Top Selling Products',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'By revenue',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             if (topProducts.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 20),
//                 child: Center(
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.inventory,
//                         color: Colors.grey.shade400,
//                         size: 40,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'No product data',
//                         style: TextStyle(
//                           color: Colors.grey.shade500,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               ...topProducts.asMap().entries.map((entry) {
//                 final index = entry.key;
//                 final product = entry.value;
//                 final rankColors = [
//                   Colors.amber.shade700,
//                   Colors.grey.shade600,
//                   Colors.orange.shade700,
//                 ];

//                 return Container(
//                   margin: EdgeInsets.only(bottom: index == topProducts.length - 1 ? 0 : 12),
//                   child: Row(
//                     children: [
//                       // Rank Badge
//                       Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: rankColors[index].withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Center(
//                           child: Text(
//                             '${index + 1}',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w700,
//                               color: rankColors[index],
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
                      
//                       // Product Info
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               product['name'] as String,
//                               style: const TextStyle(
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black87,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(4),
//                                   ),
//                                   child: Text(
//                                     '${product['sales']} sales',
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.blue.shade700,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   '₹${NumberFormat('#,##,###').format(product['revenue'])}',
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.green.shade700,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
                      
//                       // Growth Indicator
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.green.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           '₹${NumberFormat.compact().format(product['revenue'])}',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.green,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
            
//             const SizedBox(height: 8),
//             Center(
//               child: TextButton(
//                 onPressed: () {},
//                 style: TextButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                 ),
//                 child: Text(
//                   'View All Products →',
//                   style: TextStyle(
//                     color: GlobalColors.primaryBlue,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivities(DashboardData dashboardData) {
//     final recentActivities = dashboardData.recentActivities;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Recent Activities',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Latest updates',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             if (recentActivities.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 20),
//                 child: Center(
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.notifications_none,
//                         color: Colors.grey.shade400,
//                         size: 40,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'No recent activities',
//                         style: TextStyle(
//                           color: Colors.grey.shade500,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               Column(
//                 children: recentActivities.map((activity) {
//                   final icon = activity['icon'] as IconData;
//                   final color = activity['color'] as Color;
                  
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Activity Icon
//                         Container(
//                           width: 36,
//                           height: 36,
//                           decoration: BoxDecoration(
//                             color: color.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Icon(
//                             icon,
//                             color: color,
//                             size: 18,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
                        
//                         // Activity Details
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       activity['title'] as String,
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.black87,
//                                       ),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                                   Text(
//                                     activity['time'] as String,
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey.shade500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 2),
//                               if (activity['description'] != null)
//                                 Text(
//                                   activity['description'] as String,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey.shade600,
//                                   ),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
            
//             const SizedBox(height: 8),
//             Center(
//               child: TextButton(
//                 onPressed: () {},
//                 style: TextButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                 ),
//                 child: Text(
//                   'View All Activities →',
//                   style: TextStyle(
//                     color: GlobalColors.primaryBlue,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:mega_pro/providers/own_dashboard_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:intl/intl.dart';

// class OwnerDashboard extends StatefulWidget {
//   final Map<String, dynamic> userData;
  
//   const OwnerDashboard({super.key, required this.userData});

//   @override
//   State<OwnerDashboard> createState() => _OwnerDashboardState();
// }

// class _OwnerDashboardState extends State<OwnerDashboard> {
//   final DateTime _selectedDate = DateTime.now();
//   String _selectedFilter = 'Today';
//   final List<String> _filters = ['Today', 'This Week', 'This Month', 'This Year'];

//   @override
//   void initState() {
//     super.initState();
//     // The provider will auto-initialize in its constructor
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => DashboardProvider(),
//       child: Consumer<DashboardProvider>(
//         builder: (context, provider, child) {
//           return Scaffold(
//             backgroundColor: GlobalColors.background,
//             appBar: AppBar(
//               backgroundColor: GlobalColors.primaryBlue,
//               elevation: 0,
//               iconTheme: const IconThemeData(color: Colors.white),
//               title: const Text(
//                 'Owner Dashboard',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//               ),
//               actions: [
//                 IconButton(
//                   icon: const Icon(Icons.person, color: Colors.white, size: 30),
//                   onPressed: () {},
//                 ),
//                 if (provider.isLoading)
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
//                       ),
//                     ),
//                   ),
//                 IconButton(
//                   icon: const Icon(Icons.refresh, color: Colors.white),
//                   onPressed: () => provider.refresh(),
//                 ),
//               ],
//             ),
//             body: _buildBody(provider),
//             floatingActionButton: FloatingActionButton(
//               onPressed: () {
//                 // Quick action - Add new order
//               },
//               backgroundColor: GlobalColors.primaryBlue,
//               child: const Icon(Icons.add, color: Colors.white),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildBody(DashboardProvider provider) {
//     if (provider.isLoading && provider.dashboardData.totalRevenue == 0) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     if (provider.error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 48),
//             const SizedBox(height: 16),
//             Text(
//               'Error: ${provider.error}',
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.red),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => provider.refresh(),
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }

//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: SafeArea(
//         child: Column(
//           children: [
//             // Date and Filter Row
//             _buildDateFilterRow(),
//             const SizedBox(height: 20),

//             // Key Metrics Grid
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: _buildMetricsGrid(provider.dashboardData),
//             ),
//             const SizedBox(height: 24),

//             // Revenue Chart Section
//             _buildRevenueChart(provider.dashboardData, provider.revenueChartData),
//             const SizedBox(height: 24),

//             // Top Products Section
//             _buildTopProducts(provider.dashboardData),
//             const SizedBox(height: 24),

//             // Recent Activities
//             _buildRecentActivities(provider.dashboardData),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateFilterRow() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       color: Colors.white,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 DateFormat('EEEE, MMMM d').format(_selectedDate),
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 'Business Overview',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//             decoration: BoxDecoration(
//               color: GlobalColors.primaryBlue.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: GlobalColors.primaryBlue.withOpacity(0.3)),
//             ),
//             child: DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: _selectedFilter,
//                 icon: Icon(Icons.arrow_drop_down, color: GlobalColors.primaryBlue),
//                 items: _filters.map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(
//                       value,
//                       style: TextStyle(color: GlobalColors.primaryBlue, fontSize: 16),
//                     ),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedFilter = newValue!;
//                   });
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMetricsGrid(DashboardData dashboardData) {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       childAspectRatio: 1,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: [
//         _buildMetricCard(
//           title: 'Total Revenue',
//           value: '₹${NumberFormat('#,##,###').format(dashboardData.totalRevenue)}',
//           icon: Icons.currency_rupee,
//           color: Colors.green,
//           growth: dashboardData.revenueGrowth,
//         ),
//         _buildMetricCard(
//           title: 'Total Orders',
//           value: dashboardData.totalOrders.toString(),
//           icon: Icons.shopping_cart,
//           color: Colors.blue,
//           growth: dashboardData.orderGrowth,
//         ),
//         _buildMetricCard(
//           title: 'Active Employees',
//           value: dashboardData.activeEmployees.toString(),
//           icon: Icons.people,
//           color: Colors.purple,
//           growth: dashboardData.employeeGrowth,
//         ),
//         _buildMetricCard(
//           title: 'Pending Orders',
//           value: dashboardData.pendingOrders.toString(),
//           icon: Icons.pending_actions,
//           color: Colors.orange,
//           isWarning: true,
//         ),
//       ],
//     );
//   }

//   Widget _buildMetricCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//     double growth = 0,
//     bool isWarning = false,
//   }) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(icon, size: 24, color: color),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: growth >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
//                         size: 12,
//                         color: growth >= 0 ? Colors.green : Colors.red,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${growth.abs().toStringAsFixed(1)}%',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: growth >= 0 ? Colors.green : Colors.red,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRevenueChart(DashboardData dashboardData, List<Map<String, dynamic>> chartData) {
//   return Card(
//     margin: const EdgeInsets.symmetric(horizontal: 16),
//     elevation: 2,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(16),
//     ),
//     color: Colors.white,
//     child: Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Revenue Overview',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {},
//                 child: Text(
//                   'View Details',
//                   style: TextStyle(
//                     color: GlobalColors.primaryBlue,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
          
//           // Responsive chart container
//           LayoutBuilder(
//             builder: (context, constraints) {
//               final availableHeight = constraints.maxHeight;
              
//               // Find max revenue for scaling
//               int maxRevenue = 0;
//               for (var data in chartData) {
//                 final revenue = data['revenue'] as int;
//                 if (revenue > maxRevenue) {
//                   maxRevenue = revenue;
//                 }
//               }

//               // If all revenues are 0, use a small default max to show empty bars
//               if (maxRevenue == 0) {
//                 maxRevenue = 100000; // Default max for empty chart
//               }

//               return SizedBox(
//                 height: 150, // Fixed reasonable height
//                 child: chartData.isEmpty
//                     ? const Center(
//                         child: Text(
//                           'No revenue data available',
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       )
//                     : Row(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: chartData.map((data) {
//                           final day = data['day'] as String;
//                           final revenue = data['revenue'] as int;
//                           // Scale height based on max revenue (max bar height = 100)
//                           final height = maxRevenue > 0 ? (revenue / maxRevenue) * 100 : 0;
                          
//                           return _buildBar(
//                             height.toDouble(),
//                             day,
//                             revenue > 0 
//                               ? (day == 'Wed' || day == 'Thu' ? GlobalColors.primaryBlue : Colors.blue)
//                               : Colors.grey.withOpacity(0.3),
//                             revenue > 0 ? revenue : null,
//                           );
//                         }).toList(),
//                       ),
//               );
//             },
//           ),
          
//           const SizedBox(height: 16),
//           const Divider(),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             alignment: WrapAlignment.spaceBetween,
//             children: [
//               Flexible(
//                 child: Text(
//                   'Total: ₹${NumberFormat('#,##,###').format(dashboardData.totalRevenue)}',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.arrow_upward, size: 12, color: Colors.green),
//                     const SizedBox(width: 4),
//                     Flexible(
//                       child: Text(
//                         '+${dashboardData.revenueGrowth.toStringAsFixed(1)}%',
//                         style: const TextStyle(
//                           fontSize: 11,
//                           color: Colors.green,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     ),
//   );
// }

// Widget _buildBar(double height, String label, Color color, [int? revenue]) {
//   return Flexible(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Tooltip(
//           message: revenue != null ? '₹${NumberFormat('#,##,###').format(revenue)}' : 'No revenue',
//           child: Container(
//             width: 24, // Reduced from 28
//             height: height,
//             margin: const EdgeInsets.symmetric(horizontal: 2),
//             decoration: BoxDecoration(
//               color: color,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(6),
//                 topRight: Radius.circular(6),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 11, // Reduced from 12
//             color: Colors.grey.shade600,
//           ),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         if (revenue != null && revenue > 0)
//           Padding(
//             padding: const EdgeInsets.only(top: 2),
//             child: Text(
//               '₹${NumberFormat.compact().format(revenue)}',
//               style: TextStyle(
//                 fontSize: 9, // Reduced from 10
//                 color: Colors.grey.shade500,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//       ],
//     ),
//   );
// }


//   Widget _buildTopProducts(DashboardData dashboardData) {
//     final topProducts = dashboardData.topProducts;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Top Selling Products',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ...topProducts.map((product) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 16),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: GlobalColors.primaryBlue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         Icons.inventory,
//                         color: GlobalColors.primaryBlue,
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             product['name'] as String,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${product['sales']} sales • ₹${NumberFormat('#,##,###').format(product['revenue'])}',
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         '₹${NumberFormat('#,##,###').format(product['revenue'])}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.green,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//             if (topProducts.isEmpty)
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 20),
//                 child: Center(
//                   child: Text(
//                     'No sales data available',
//                     style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               ),
//             const SizedBox(height: 8),
//             Center(
//               child: TextButton(
//                 onPressed: () {},
//                 child: Text(
//                   'View All Products',
//                   style: TextStyle(
//                     color: GlobalColors.primaryBlue,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivities(DashboardData dashboardData) {
//     final recentActivities = dashboardData.recentActivities;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Recent Activities',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ...recentActivities.map((activity) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 16),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: (activity['color'] as Color).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         activity['icon'] as IconData,
//                         color: activity['color'] as Color,
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             activity['title'] as String,
//                             style: const TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             activity['time'] as String,
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                           if (activity['description'] != null)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 4),
//                               child: Text(
//                                 activity['description'] as String,
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey.shade600,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                     Icon(
//                       Icons.chevron_right,
//                       color: Colors.grey.shade400,
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//             if (recentActivities.isEmpty)
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 20),
//                 child: Center(
//                   child: Text(
//                     'No recent activities',
//                     style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               ),
//             const SizedBox(height: 8),
//             Center(
//               child: TextButton(
//                 onPressed: () {},
//                 child: Text(
//                   'View All Activities',
//                   style: TextStyle(
//                     color: GlobalColors.primaryBlue,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
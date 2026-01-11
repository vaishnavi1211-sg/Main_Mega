import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:mega_pro/models/own_revenue_model.dart';
import 'package:mega_pro/providers/own_dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DistrictWiseRevenuePage extends StatefulWidget {
  const DistrictWiseRevenuePage({super.key, required DashboardData dashboardData});

  @override
  State<DistrictWiseRevenuePage> createState() => _DistrictWiseRevenuePageState();
}

class _DistrictWiseRevenuePageState extends State<DistrictWiseRevenuePage> {
  String _selectedFilter = 'All Districts';
  final List<String> _filters = ['All Districts', 'This Month', 'Last Month', 'This Year'];
  bool _isRefreshing = false;

  Future<void> _refreshData(BuildContext context) async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    
    setState(() {
      _isRefreshing = true;
    });
    
    await provider.loadDistrictRevenueData();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'District Revenue',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterOptions(context),
          ),
          Consumer<DashboardProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: _isRefreshing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isRefreshing
                    ? null
                    : () => _refreshData(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingDistrictData && provider.districtRevenueData.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading district data...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (provider.districtRevenueData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_city, color: Colors.grey.shade400, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'No district data available',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _refreshData(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Load Data',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final districts = provider.districtRevenueData;
          final totalRevenue = districts.fold(0.0, (sum, district) => sum + district.revenue);
          final totalOrders = districts.fold(0, (sum, district) => sum + district.orders);

          return RefreshIndicator(
            onRefresh: () => _refreshData(context),
            child: Column(
              children: [
                // Filter Chip Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: _selectedFilter == filter,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                                // Apply filter logic here
                                _applyFilter(filter, provider);
                              }
                            },
                            backgroundColor: Colors.white,
                            selectedColor: GlobalColors.primaryBlue.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: _selectedFilter == filter
                                  ? GlobalColors.primaryBlue
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            side: BorderSide(
                              color: _selectedFilter == filter
                                  ? GlobalColors.primaryBlue
                                  : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(
                        'Total Revenue',
                        '₹${NumberFormat('#,##,###').format(totalRevenue)}',
                        Colors.green,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade200),
                      _buildSummaryItem(
                        'Total Orders',
                        totalOrders.toString(),
                        Colors.blue,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade200),
                      _buildSummaryItem(
                        'Districts',
                        districts.length.toString(),
                        Colors.purple,
                      ),
                    ],
                  ),
                ),

                // District List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: districts.length,
                    itemBuilder: (context, index) {
                      final district = districts[index];
                      final percentage = totalRevenue > 0 
                        ? (district.revenue / totalRevenue * 100)
                        : 0;

                      return InkWell(
                        onTap: () {
                          _showDistrictDetails(context, district);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
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
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getDistrictColor(index),
                              child: Text(
                                district.district[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              district.district,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  district.branch,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${district.orders} orders',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: district.growth >= 0
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            district.growth >= 0 
                                              ? Icons.arrow_upward 
                                              : Icons.arrow_downward,
                                            size: 10,
                                            color: district.growth >= 0 ? Colors.green : Colors.red,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${district.growth.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: district.growth >= 0 ? Colors.green : Colors.red,
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
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${NumberFormat('#,##,###').format(district.revenue)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% of total',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getDistrictColor(int index) {
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.red.shade700,
      Colors.teal.shade700,
    ];
    return colors[index % colors.length];
  }

  void _applyFilter(String filter, DashboardProvider provider) {
    // Apply filtering logic based on selected filter
    // This would require additional data fetching with date ranges
    debugPrint('Applying filter: $filter');
    
    // For now, just refresh data with the new filter
    // You would need to modify getDistrictRevenueData to accept date ranges
    _refreshData(context);
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter by Period',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ..._filters.map((filter) {
                return ListTile(
                  title: Text(filter),
                  trailing: _selectedFilter == filter
                      ? Icon(Icons.check, color: GlobalColors.primaryBlue)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDistrictDetails(BuildContext context, DistrictRevenueData district) {
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
                    'District Details',
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
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: _getDistrictColor(district.hashCode % 6),
                  child: Text(
                    district.district[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow('District', district.district),
              _buildDetailRow('Branch', district.branch),
              _buildDetailRow('Revenue', '₹${NumberFormat('#,##,###').format(district.revenue)}'),
              _buildDetailRow('Total Orders', district.orders.toString()),
              _buildDetailRow(
                'Growth',
                '${district.growth >= 0 ? '+' : ''}${district.growth.toStringAsFixed(1)}%',
              ),
              if (district.topProducts.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Top Products:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: district.topProducts.map((product) {
                    return Chip(
                      label: Text(product),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ],
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
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      )
    );
  }
}
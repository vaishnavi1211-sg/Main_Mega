import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class DashboardHome extends StatelessWidget {
  final int pendingOrdersCount;
  final int lowStockItems;
  final VoidCallback onRefresh;

  const DashboardHome({
    super.key,
    required this.pendingOrdersCount,
    required this.lowStockItems,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          onRefresh();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Section
              _buildSectionHeader('Overview'),
              const SizedBox(height: 16),
              
              // Stats Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Pending Orders',
                      value: pendingOrdersCount.toString(),
                      icon: Iconsax.receipt_text,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Low Stock Items',
                      value: lowStockItems.toString(),
                      icon: Iconsax.box_2,
                      color: const Color(0xFFF44336),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions Section - REMOVED Production Today
              _buildSectionHeader('Quick Actions'),
              const SizedBox(height: 16),
              
              // Quick Actions Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickActionCard(
                    title: 'Add New Item',
                    icon: Iconsax.add_square,
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      // Navigate to add new item
                    },
                  ),
                  _buildQuickActionCard(
                    title: 'View Inventory',
                    icon: Iconsax.box_1,
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      // Navigate to inventory
                    },
                  ),
                  _buildQuickActionCard(
                    title: 'Process Orders',
                    icon: Iconsax.receipt_edit,
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      // Navigate to process orders
                    },
                  ),
                  _buildQuickActionCard(
                    title: 'Generate Report',
                    icon: Iconsax.document_download,
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      // Generate report
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent Activity Section
              _buildSectionHeader('Recent Activity'),
              const SizedBox(height: 16),
              
              // Recent Activity List
              _buildRecentActivityList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A237E),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final activities = [
      {'title': 'New order received', 'time': '10 min ago', 'icon': Iconsax.receipt_add},
      {'title': 'Item stock updated', 'time': '30 min ago', 'icon': Iconsax.box_tick},
      {'title': 'Production completed', 'time': '1 hour ago', 'icon': Iconsax.tick_circle},
      {'title': 'Quality check passed', 'time': '2 hours ago', 'icon': Iconsax.security_safe},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: activities.map((activity) {
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                activity['icon'] as IconData,
                color: const Color(0xFF2196F3),
                size: 20,
              ),
            ),
            title: Text(
              activity['title'].toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A237E),
              ),
            ),
            trailing: Text(
              activity['time'].toString(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
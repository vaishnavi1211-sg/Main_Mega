import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Mock data - In real app, fetch from API
  final Map<String, dynamic> _dashboardData = {
    'totalRevenue': 2458000,
    'totalOrders': 128,
    'activeEmployees': 24,
    'pendingOrders': 18,
    'revenueGrowth': 12.5,
    'orderGrowth': 8.2,
    'employeeGrowth': 3.5,
    'topProducts': [
      {'name': 'Premium Feed', 'sales': 450, 'revenue': 675000},
      {'name': 'Organic Feed', 'sales': 320, 'revenue': 480000},
      {'name': 'Starter Feed', 'sales': 280, 'revenue': 420000},
    ],
    'recentActivities': [
      {'title': 'New Order Received', 'time': '10 mins ago', 'icon': Icons.shopping_cart, 'color': Colors.green},
      {'title': 'Payment Received', 'time': '30 mins ago', 'icon': Icons.payment, 'color': Colors.blue},
      {'title': 'Stock Updated', 'time': '1 hour ago', 'icon': Icons.inventory, 'color': Colors.orange},
      {'title': 'New Employee Added', 'time': '2 hours ago', 'icon': Icons.person_add, 'color': Colors.purple},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Owner Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SafeArea(
          child: Column(
            children: [
              // Date and Filter Row
              _buildDateFilterRow(),
              const SizedBox(height: 20),

              // Key Metrics Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMetricsGrid(),
              ),
              const SizedBox(height: 24),

              // Revenue Chart Section
              _buildRevenueChart(),
              const SizedBox(height: 24),

              // Top Products Section
              _buildTopProducts(),
              const SizedBox(height: 24),

              // Recent Activities
              _buildRecentActivities(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Quick action - Add new order
        },
        backgroundColor: GlobalColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: GlobalColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GlobalColors.primaryBlue.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                icon: Icon(Icons.arrow_drop_down, color: GlobalColors.primaryBlue),
                items: _filters.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: GlobalColors.primaryBlue, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFilter = newValue!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          title: 'Total Revenue',
          value: '₹${NumberFormat('#,##,###').format(_dashboardData['totalRevenue'])}',
          icon: Icons.currency_rupee,
          color: Colors.green,
          growth: _dashboardData['revenueGrowth'],
        ),
        _buildMetricCard(
          title: 'Total Orders',
          value: _dashboardData['totalOrders'].toString(),
          icon: Icons.shopping_cart,
          color: Colors.blue,
          growth: _dashboardData['orderGrowth'],
        ),
        _buildMetricCard(
          title: 'Active Employees',
          value: _dashboardData['activeEmployees'].toString(),
          icon: Icons.people,
          color: Colors.purple,
          growth: _dashboardData['employeeGrowth'],
        ),
        _buildMetricCard(
          title: 'Pending Orders',
          value: _dashboardData['pendingOrders'].toString(),
          icon: Icons.pending_actions,
          color: Colors.orange,
          isWarning: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? growth,
    bool isWarning = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                if (growth != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: growth >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: growth >= 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${growth.abs()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: growth >= 0 ? Colors.green : Colors.red,
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
                fontSize: 22, // Reduced from 24 for better fit
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Revenue Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      color: GlobalColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Simple bar chart simulation
            Container(
              height: 180, // Reduced from 200 for better fit
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBar(160, 'Mon', Colors.blue),
                  _buildBar(200, 'Tue', Colors.blue),
                  _buildBar(240, 'Wed', GlobalColors.primaryBlue),
                  _buildBar(280, 'Thu', GlobalColors.primaryBlue),
                  _buildBar(220, 'Fri', Colors.blue),
                  _buildBar(180, 'Sat', Colors.blue),
                  _buildBar(120, 'Sun', Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  'Total Revenue: ₹${NumberFormat('#,##,###').format(_dashboardData['totalRevenue'])}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '+${_dashboardData['revenueGrowth']}% from last week',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
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

  Widget _buildBar(double height, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28, // Reduced from 32 for better fit
          height: height / 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _buildTopProducts() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            ..._dashboardData['topProducts'].map((product) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: GlobalColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory,
                        color: GlobalColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product['sales']} sales • ₹${NumberFormat('#,##,###').format(product['revenue'])}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${NumberFormat('#,##,###').format(product['revenue'])}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'View All Products',
                  style: TextStyle(
                    color: GlobalColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            ..._dashboardData['recentActivities'].map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: activity['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        activity['icon'],
                        color: activity['color'],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['time'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'View All Activities',
                  style: TextStyle(
                    color: GlobalColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/owner/own_quick_action.dart';

// class OwnerDashboardClean extends StatelessWidget {
//   const OwnerDashboardClean({super.key, required Map<String, dynamic> userData});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF2563EB),
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         title: const Text(
//           "Owner Dashboard",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//       ),

//       /// Floating Quick Action
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: GlobalColors.primaryBlue,
//         child: const Icon(Icons.flash_on, color: Colors.white),
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => OwnerQuickActionsPage()),
//           );
//         },
//       ),

//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _kpiGrid(),
//             const SizedBox(height: 24),

//             _sectionHeader("Revenue Trend", "Last 6 months"),
//             const SizedBox(height: 12),
//             _revenueTrendChart(),

//             const SizedBox(height: 24),
//             _sectionHeader("Production by Product", "This month (tons)"),
//             const SizedBox(height: 12),
//             _productionBarChart(),

//             const SizedBox(height: 24),
//             _sectionHeader("Branch Performance", "View All"),
//             const SizedBox(height: 12),
//             _branchTile("Mumbai Branch", "₹18.5L", "1.5K tons", "₹15.2L"),
//             _branchTile("Delhi Branch", "₹15.2L", "1.2K tons", "₹12.8L"),
//             _branchTile("Bangalore Branch", "₹13.8L", "1.1K tons", "₹11.6L"),
//           ],
//         ),
//       ),
//     );
//   }

//   /// ---------------- KPI GRID ----------------
//   Widget _kpiGrid() {
//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisSpacing: 12,
//       mainAxisSpacing: 12,
//       children: const [
//         _KpiCard(
//           icon: Icons.currency_rupee,
//           title: "Total Revenue",
//           value: "₹45.2L",
//           growth: "12.5%",
//         ),
//         _KpiCard(
//           icon: Icons.factory,
//           title: "Production",
//           value: "3.8K tons",
//           growth: "8.3%",
//         ),
//         _KpiCard(
//           icon: Icons.shopping_cart,
//           title: "Total Sales",
//           value: "₹38.5L",
//           growth: "15.2%",
//         ),
//         _KpiCard(
//           icon: Icons.people,
//           title: "Active Dealers",
//           value: "156",
//           growth: "-2.1%",
//           down: true,
//         ),
//       ],
//     );
//   }

//   /// ---------------- LINE CHART ----------------
//   Widget _revenueTrendChart() {
//     return _card(
//       SizedBox(
//         height: 220,
//         child: LineChart(
//           LineChartData(
//             minY: 40,
//             maxY: 80,
//             gridData: FlGridData(
//               show: true,
//               horizontalInterval: 10,
//               getDrawingHorizontalLine: (value) =>
//                   FlLine(color: Colors.grey.withOpacity(0.2)),
//             ),
//             borderData: FlBorderData(show: false),
//             titlesData: FlTitlesData(
//               leftTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   interval: 10,
//                   getTitlesWidget: (value, _) => Text(
//                     value.toInt().toString(),
//                     style: const TextStyle(fontSize: 10, color: Colors.grey),
//                   ),
//                 ),
//               ),
//               bottomTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   getTitlesWidget: (value, _) {
//                     const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
//                     return Text(
//                       months[value.toInt()],
//                       style: const TextStyle(fontSize: 10, color: Colors.grey),
//                     );
//                   },
//                 ),
//               ),
//               topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               rightTitles: AxisTitles(
//                 sideTitles: SideTitles(showTitles: false),
//               ),
//             ),
//             lineBarsData: [
//               LineChartBarData(
//                 spots: const [
//                   FlSpot(0, 45),
//                   FlSpot(1, 52),
//                   FlSpot(2, 47),
//                   FlSpot(3, 63),
//                   FlSpot(4, 70),
//                   FlSpot(5, 78),
//                 ],
//                 isCurved: true,
//                 barWidth: 3,
//                 color: GlobalColors.primaryBlue,
//                 dotData: FlDotData(show: true),
//                 belowBarData: BarAreaData(
//                   show: true,
//                   color: GlobalColors.primaryBlue.withOpacity(0.15),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// ---------------- BAR CHART ----------------
//   Widget _productionBarChart() {
//     return _card(
//       SizedBox(
//         height: 250,
//         child: BarChart(
//           BarChartData(
//             maxY: 1300,
//             gridData: FlGridData(
//               show: true,
//               horizontalInterval: 100,
//               getDrawingHorizontalLine: (value) =>
//                   FlLine(color: Colors.grey.withOpacity(0.2)),
//             ),
//             borderData: FlBorderData(show: false),
//             titlesData: FlTitlesData(
//               leftTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   interval: 100,
//                   reservedSize: 28,
//                   getTitlesWidget: (value, _) => Text(
//                     value.toInt().toString(),
//                     style: const TextStyle(fontSize: 9, color: Colors.grey),
//                   ),
//                 ),
//               ),

//               bottomTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   getTitlesWidget: (value, _) {
//                     const labels = ["Feed A", "Feed B", "Feed C", "Feed D"];
//                     return Text(
//                       labels[value.toInt()],
//                       style: const TextStyle(fontSize: 10, color: Colors.grey),
//                     );
//                   },
//                 ),
//               ),
//               topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               rightTitles: AxisTitles(
//                 sideTitles: SideTitles(showTitles: false),
//               ),
//             ),
//             barGroups: [
//               _bar(0, 850),
//               _bar(1, 1200),
//               _bar(2, 950),
//               _bar(3, 780),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   BarChartGroupData _bar(int x, double y) {
//     return BarChartGroupData(
//       x: x,
//       barRods: [
//         BarChartRodData(
//           toY: y,
//           width: 24,
//           borderRadius: BorderRadius.circular(6),
//           color: GlobalColors.primaryBlue.withOpacity(0.25),
//         ),
//       ],
//     );
//   }

//   /// ---------------- BRANCH TILE ----------------
//   Widget _branchTile(
//     String name,
//     String revenue,
//     String production,
//     String sales,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: _boxDecoration(),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 22,
//             backgroundColor: GlobalColors.primaryBlue.withOpacity(0.1),
//             child: Icon(Icons.apartment, color: GlobalColors.primaryBlue),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 8),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     _metric("Revenue", revenue),
//                     _metric("Production", production),
//                     _metric("Sales", sales),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const Icon(Icons.chevron_right),
//         ],
//       ),
//     );
//   }

//   Widget _metric(String title, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//         Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
//       ],
//     );
//   }

//   /// ---------------- COMMON ----------------
//   Widget _sectionHeader(String title, String action) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         Text(action, style: TextStyle(color: GlobalColors.primaryBlue)),
//       ],
//     );
//   }

//   Widget _card(Widget child) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: _boxDecoration(),
//       child: child,
//     );
//   }

//   BoxDecoration _boxDecoration() {
//     return BoxDecoration(
//       color: GlobalColors.white,
//       borderRadius: BorderRadius.circular(16),
//       boxShadow: [
//         BoxShadow(
//           color: GlobalColors.shadow,
//           blurRadius: 10,
//           offset: const Offset(0, 4),
//         ),
//       ],
//     );
//   }
// }

// /// ---------------- KPI CARD ----------------
// class _KpiCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String value;
//   final String growth;
//   final bool down;

//   const _KpiCard({
//     required this.icon,
//     required this.title,
//     required this.value,
//     required this.growth,
//     this.down = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: GlobalColors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: GlobalColors.shadow,
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 28, color: GlobalColors.primaryBlue),
//           const SizedBox(height: 12),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           Text(title, style: const TextStyle(color: Colors.grey)),
//           const SizedBox(height: 8),
//           Text(
//             "${down ? "↓" : "↑"} $growth",
//             style: TextStyle(
//               color: down ? Colors.red : Colors.green,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




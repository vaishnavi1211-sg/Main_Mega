import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/owner/own_quick_action.dart';

class OwnerDashboardClean extends StatelessWidget {
  const OwnerDashboardClean({super.key, required Map<String, dynamic> userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Owner Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      /// Floating Quick Action
      floatingActionButton: FloatingActionButton(
        backgroundColor: GlobalColors.primaryBlue,
        child: const Icon(Icons.flash_on, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OwnerQuickActionsPage()),
          );
        },
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kpiGrid(),
            const SizedBox(height: 24),

            _sectionHeader("Revenue Trend", "Last 6 months"),
            const SizedBox(height: 12),
            _revenueTrendChart(),

            const SizedBox(height: 24),
            _sectionHeader("Production by Product", "This month (tons)"),
            const SizedBox(height: 12),
            _productionBarChart(),

            const SizedBox(height: 24),
            _sectionHeader("Branch Performance", "View All"),
            const SizedBox(height: 12),
            _branchTile("Mumbai Branch", "₹18.5L", "1.5K tons", "₹15.2L"),
            _branchTile("Delhi Branch", "₹15.2L", "1.2K tons", "₹12.8L"),
            _branchTile("Bangalore Branch", "₹13.8L", "1.1K tons", "₹11.6L"),
          ],
        ),
      ),
    );
  }

  /// ---------------- KPI GRID ----------------
  Widget _kpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: const [
        _KpiCard(
          icon: Icons.currency_rupee,
          title: "Total Revenue",
          value: "₹45.2L",
          growth: "12.5%",
        ),
        _KpiCard(
          icon: Icons.factory,
          title: "Production",
          value: "3.8K tons",
          growth: "8.3%",
        ),
        _KpiCard(
          icon: Icons.shopping_cart,
          title: "Total Sales",
          value: "₹38.5L",
          growth: "15.2%",
        ),
        _KpiCard(
          icon: Icons.people,
          title: "Active Dealers",
          value: "156",
          growth: "-2.1%",
          down: true,
        ),
      ],
    );
  }

  /// ---------------- LINE CHART ----------------
  Widget _revenueTrendChart() {
    return _card(
      SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 40,
            maxY: 80,
            gridData: FlGridData(
              show: true,
              horizontalInterval: 10,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.withOpacity(0.2)),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 10,
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
                    return Text(
                      months[value.toInt()],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 45),
                  FlSpot(1, 52),
                  FlSpot(2, 47),
                  FlSpot(3, 63),
                  FlSpot(4, 70),
                  FlSpot(5, 78),
                ],
                isCurved: true,
                barWidth: 3,
                color: GlobalColors.primaryBlue,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: GlobalColors.primaryBlue.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------- BAR CHART ----------------
  Widget _productionBarChart() {
    return _card(
      SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            maxY: 1300,
            gridData: FlGridData(
              show: true,
              horizontalInterval: 100,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.withOpacity(0.2)),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 100,
                  reservedSize: 28,
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ),
              ),

              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    const labels = ["Feed A", "Feed B", "Feed C", "Feed D"];
                    return Text(
                      labels[value.toInt()],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            barGroups: [
              _bar(0, 850),
              _bar(1, 1200),
              _bar(2, 950),
              _bar(3, 780),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 24,
          borderRadius: BorderRadius.circular(6),
          color: GlobalColors.primaryBlue.withOpacity(0.25),
        ),
      ],
    );
  }

  /// ---------------- BRANCH TILE ----------------
  Widget _branchTile(
    String name,
    String revenue,
    String production,
    String sales,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: GlobalColors.primaryBlue.withOpacity(0.1),
            child: Icon(Icons.apartment, color: GlobalColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metric("Revenue", revenue),
                    _metric("Production", production),
                    _metric("Sales", sales),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _metric(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// ---------------- COMMON ----------------
  Widget _sectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(action, style: TextStyle(color: GlobalColors.primaryBlue)),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: child,
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: GlobalColors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: GlobalColors.shadow,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// ---------------- KPI CARD ----------------
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String growth;
  final bool down;

  const _KpiCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.growth,
    this.down = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GlobalColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: GlobalColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: GlobalColors.primaryBlue),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            "${down ? "↓" : "↑"} $growth",
            style: TextStyle(
              color: down ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}




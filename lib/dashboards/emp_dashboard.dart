import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:mega_pro/employee/emp_attendance.dart';
import 'package:mega_pro/employee/emp_attendance_history.dart';
import 'package:mega_pro/employee/emp_completedOrdersPage.dart';
import 'package:mega_pro/employee/emp_create_order_page.dart';
import 'package:mega_pro/employee/emp_pendingOrdersScreen.dart';
import 'package:mega_pro/employee/emp_profile.dart';
import 'package:mega_pro/employee/emp_recent_order_page.dart';
import 'package:mega_pro/employee/emp_totalOrdersScreen.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_attendance_provider.dart';
import 'package:mega_pro/providers/emp_mar_target_provider.dart';
import 'package:mega_pro/providers/emp_order_provider.dart';
import 'package:mega_pro/providers/emp_provider.dart';
import 'package:provider/provider.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key, required Map<String, dynamic> userData});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<EmployeeProvider>().loadEmployeeProfile();
      context.read<OrderProvider>().fetchOrderCounts();
      context.read<AttendanceProvider>().checkTodayAttendance();
    });

    _pages = [
      _DashboardHome(scaffoldKey: _scaffoldKey),
      const CattleFeedOrderScreen(),
      const RecentOrdersScreen(),
      const EmployeeProfileDashboard(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scaffoldBg,
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: GlobalColors.primaryBlue,
        unselectedItemColor: GlobalColors.textGrey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Iconsax.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.add_square),
            label: "Create",
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.receipt_item),
            label: "Orders",
          ),
          BottomNavigationBarItem(icon: Icon(Iconsax.user), label: "Profile"),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final emp = context.watch<EmployeeProvider>().profile;

    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            decoration: const BoxDecoration(
              color: GlobalColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Iconsax.user, color: GlobalColors.primaryBlue),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp?['full_name'] ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(emp?['position'] ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          _drawerTile(Iconsax.calendar_1, "Mark Attendance", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EmployeeAttendancePage(cameras: []),
              ),
            );
          }),
          _drawerTile(Icons.calendar_month, "Attendance History", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AttendanceHistoryPage(),
              ),
            );
          }),
          _drawerTile(Iconsax.receipt_item, "Total Orders", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TotalOrdersPage()),
            );
          }),
          _drawerTile(Iconsax.timer, "Pending Orders", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PendingOrdersPage()),
            );
          }),
          _drawerTile(Iconsax.tick_circle, "Completed Orders", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompletedOrdersPage()),
            );
          }),
          _drawerTile(Iconsax.user, "My Profile", () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 3);
          }),
          const Spacer(),
          _drawerTile(Iconsax.logout, "Logout", () {
            Navigator.pop(context);
          }, danger: true),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _drawerTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: danger ? GlobalColors.danger : GlobalColors.primaryBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? GlobalColors.danger : GlobalColors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}


class _DashboardHome extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _DashboardHome({required this.scaffoldKey});

  @override
  State<_DashboardHome> createState() => __DashboardHomeState();
}

class __DashboardHomeState extends State<_DashboardHome> {
  final ScrollController _scrollController = ScrollController();
  late List<String> months;
  late List<String> monthLabels;

  @override
  void initState() {
    super.initState();
    
    // Generate months for current year (Jan-Dec)
    final now = DateTime.now();
    months = List.generate(12, (index) {
      final month = index + 1; // Months 1-12
      return '${now.year}-${month.toString().padLeft(2, '0')}';
    });
    
    monthLabels = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTargetData();
    });
  }

  Future<void> _loadTargetData() async {
    final empProvider = context.read<EmployeeProvider>();
    final targetProvider = context.read<TargetProvider>();
    
    final empId = empProvider.profile?['emp_id']?.toString();
    if (empId != null && empId.isNotEmpty) {
      await targetProvider.loadTargetData(empId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empProvider = context.watch<EmployeeProvider>();
    final targetProvider = context.watch<TargetProvider>();

    if (empProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final empId = empProvider.profile?['emp_id']?.toString() ?? '';

    // Get target and achieved data
    final targets = targetProvider.getMonthlyTargets(empId, months);
    final achieved = targetProvider.getMonthlyAchieved(empId, months);
    
    // FIXED: Always use 0-100 T scale for vertical axis
    final double maxY = 100.0;
    final double interval = 20.0; // Fixed interval for 0-100 scale

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text("Employee Dashboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Consumer<AttendanceProvider>(
          builder: (context, attendanceProvider, _) => Column(
            children: [
              InkWell(
                onTap: attendanceProvider.attendanceMarkedToday
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmployeeAttendancePage(cameras: []),
                          ),
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: attendanceProvider.attendanceMarkedToday
                        ? Colors.green.shade100
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: attendanceProvider.attendanceMarkedToday
                              ? Colors.green
                              : GlobalColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.calendar_1,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attendanceProvider.attendanceMarkedToday
                                ? "Attendance Marked"
                                : "Mark Attendance",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            attendanceProvider.attendanceMarkedToday
                                ? "Already marked for today"
                                : "Tap to mark now",
                            style: const TextStyle(
                              color: GlobalColors.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Orders Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TotalOrdersPage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _summary(
                        "Total",
                        context.watch<OrderProvider>().totalOrders.toString(),
                        Iconsax.shopping_cart,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PendingOrdersPage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _summary(
                        "Pending",
                        context.watch<OrderProvider>().pendingOrders.toString(),
                        Iconsax.timer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CompletedOrdersPage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _summary(
                        "Completed",
                        context.watch<OrderProvider>().completedOrders.toString(),
                        Iconsax.tick_circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GlobalColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Performance vs Target",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        if (empId.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.refresh, 
                                color: GlobalColors.primaryBlue, size: 20),
                            onPressed: _loadTargetData,
                            tooltip: 'Refresh Targets',
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Monthly comparison in Tons (Jan-Dec)",
                      style: const TextStyle(
                        color: GlobalColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                    
                    // Current month target info
                    if (targets.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Target: ${targets.last.toStringAsFixed(1)} T",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: GlobalColors.primaryBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Achieved: ${achieved.last.toStringAsFixed(1)} T",
                              style: const TextStyle(
                                fontSize: 12,
                                color: GlobalColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 290,
                      child: Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 400, 
                            height: 290,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.center,
                                  groupsSpace: 12,
                                  minY: 0,
                                  maxY: maxY, 
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipBorder: BorderSide(color: Colors.grey.shade300),
                                      tooltipRoundedRadius: 8,
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final month = monthLabels[group.x];
                                        final targetVal = targets[group.x];
                                        final achievedVal = achieved[group.x];
                                        
                                        String tooltipText = "$month\n";
                                        tooltipText += "Target: ${targetVal.toStringAsFixed(1)} T\n";
                                        tooltipText += "Achieved: ${achievedVal.toStringAsFixed(1)} T";
                                        
                                        if (targetVal > 0) {
                                          final percentage = (achievedVal / targetVal * 100);
                                          tooltipText += "\nCompletion: ${percentage.toStringAsFixed(1)}%";
                                        }
                                        
                                        return BarTooltipItem(
                                          tooltipText,
                                          const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: interval, // Fixed at 20
                                        getTitlesWidget: (value, meta) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Text(
                                              "${value.toInt()} T",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 && index < monthLabels.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                monthLabels[index],
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawHorizontalLine: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: interval, // Fixed at 20
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.shade200,
                                        strokeWidth: 0.5,
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  barGroups: List.generate(12, (index) {
                                    return BarChartGroupData(
                                      x: index,
                                      groupVertically: true,
                                      barRods: [
                                        BarChartRodData(
                                          toY: targets[index] > maxY ? maxY : targets[index], // Cap at 100
                                          width: 14,
                                          color: Colors.grey.shade400,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        BarChartRodData(
                                          toY: achieved[index] > maxY ? maxY : achieved[index], // Cap at 100
                                          width: 10,
                                          color: GlobalColors.primaryBlue,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Legend
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Target",
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: GlobalColors.primaryBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Achieved",
                              style: TextStyle(fontSize: 12, color: GlobalColors.primaryBlue, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Summary statistics
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            "Current Target",
                            "${targets.last.toStringAsFixed(1)} T",
                            Colors.grey.shade700,
                          ),
                          _buildStatCard(
                            "Current Achieved",
                            "${achieved.last.toStringAsFixed(1)} T",
                            GlobalColors.primaryBlue,
                          ),
                          _buildStatCard(
                            "Completion",
                            targets.last > 0 
                                ? "${(achieved.last / targets.last * 100).toStringAsFixed(1)}%"
                                : "0%",
                            targets.last > 0 && (achieved.last / targets.last * 100) >= 100
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GlobalColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)],
      ),
      child: Column(
        children: [
          Icon(icon, color: GlobalColors.primaryBlue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: GlobalColors.textGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}










// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:iconsax_flutter/iconsax_flutter.dart';
// import 'package:mega_pro/employee/emp_attendance.dart';
// import 'package:mega_pro/employee/emp_attendance_history.dart';
// import 'package:mega_pro/employee/emp_completedOrdersPage.dart';
// import 'package:mega_pro/employee/emp_create_order_page.dart';
// import 'package:mega_pro/employee/emp_pendingOrdersScreen.dart';
// import 'package:mega_pro/employee/emp_profile.dart';
// import 'package:mega_pro/employee/emp_recent_order_page.dart';
// import 'package:mega_pro/employee/emp_totalOrdersScreen.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/providers/emp_attendance_provider.dart';
// import 'package:mega_pro/providers/emp_order_provider.dart';
// import 'package:mega_pro/providers/emp_provider.dart';
// import 'package:provider/provider.dart';

// class EmployeeDashboard extends StatefulWidget {
//   const EmployeeDashboard({super.key, required Map<String, dynamic> userData});

//   @override
//   State<EmployeeDashboard> createState() => _EmployeeDashboardState();
// }

// class _EmployeeDashboardState extends State<EmployeeDashboard> {
//   int _selectedIndex = 0;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   late final List<Widget> _pages;

//   @override
//   void initState() {
//     super.initState();

//     Future.microtask(() {
//       context.read<EmployeeProvider>().loadEmployeeProfile();
//       context.read<OrderProvider>().fetchOrderCounts();
//       context.read<AttendanceProvider>().checkTodayAttendance();
//     });

//     _pages = [
//       _DashboardHome(scaffoldKey: _scaffoldKey),
//       const CattleFeedOrderScreen(),
//       const RecentOrdersScreen(),
//       const EmployeeProfileDashboard(),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: AppColors.scaffoldBg,
//       drawer: _buildDrawer(context),
//       body: IndexedStack(index: _selectedIndex, children: _pages),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         selectedItemColor: GlobalColors.primaryBlue,
//         unselectedItemColor: GlobalColors.textGrey,
//         type: BottomNavigationBarType.fixed,
//         onTap: (index) => setState(() => _selectedIndex = index),
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Iconsax.home), label: "Home"),
//           BottomNavigationBarItem(
//             icon: Icon(Iconsax.add_square),
//             label: "Create",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Iconsax.receipt_item),
//             label: "Orders",
//           ),
//           BottomNavigationBarItem(icon: Icon(Iconsax.user), label: "Profile"),
//         ],
//       ),
//     );
//   }

//   Drawer _buildDrawer(BuildContext context) {
//     final emp = context.watch<EmployeeProvider>().profile;

//     return Drawer(
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
//             decoration: const BoxDecoration(
//               color: GlobalColors.primaryBlue,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(18),
//                 bottomRight: Radius.circular(18),
//               ),
//             ),
//             child: Row(
//               children: [
//                 const CircleAvatar(
//                   radius: 28,
//                   backgroundColor: Colors.white,
//                   child: Icon(Iconsax.user, color: GlobalColors.primaryBlue),
//                 ),
//                 const SizedBox(width: 14),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(emp?['full_name'] ?? '',
//                         style: const TextStyle(
//                             color: Colors.white, fontWeight: FontWeight.bold)),
//                     Text(emp?['position'] ?? '',
//                         style: const TextStyle(
//                             color: Colors.white70, fontSize: 12)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           _drawerTile(Iconsax.calendar_1, "Mark Attendance", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => const EmployeeAttendancePage(cameras: []),
//               ),
//             );
//           }),
//           _drawerTile(Icons.calendar_month, "Attendance History", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => const AttendanceHistoryPage(),
//               ),
//             );
//           }),
//           _drawerTile(Iconsax.receipt_item, "Total Orders", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const TotalOrdersPage()),
//             );
//           }),
//           _drawerTile(Iconsax.timer, "Pending Orders", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const PendingOrdersPage()),
//             );
//           }),
//           _drawerTile(Iconsax.tick_circle, "Completed Orders", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const CompletedOrdersPage()),
//             );
//           }),
//           _drawerTile(Iconsax.user, "My Profile", () {
//             Navigator.pop(context);
//             setState(() => _selectedIndex = 3);
//           }),
//           const Spacer(),
//           _drawerTile(Iconsax.logout, "Logout", () {
//             Navigator.pop(context);
//           }, danger: true),
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }

//   Widget _drawerTile(
//     IconData icon,
//     String title,
//     VoidCallback onTap, {
//     bool danger = false,
//   }) {
//     return ListTile(
//       leading: Icon(
//         icon,
//         color: danger ? GlobalColors.danger : GlobalColors.primaryBlue,
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: danger ? GlobalColors.danger : GlobalColors.black,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }
// }


// class _DashboardHome extends StatelessWidget {
//   final GlobalKey<ScaffoldState> scaffoldKey;

//   const _DashboardHome({required this.scaffoldKey});

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<EmployeeProvider>();

//     if (provider.loading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     final months = const [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];

//     final target = [80, 80, 80, 80, 80, 80, 85, 85, 85, 90, 90, 90];
//     final achieved = [60, 70, 65, 80, 75, 85, 88, 82, 90, 92, 95, 98];

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white),
//           onPressed: () => scaffoldKey.currentState?.openDrawer(),
//         ),
//         title: const Text("Employee Dashboard",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Consumer<AttendanceProvider>(
//           builder: (context, attendanceProvider, _) => Column(
//             children: [
//               InkWell(
//                 onTap: attendanceProvider.attendanceMarkedToday
//                     ? null
//                     : () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const EmployeeAttendancePage(cameras: []),
//                           ),
//                         );
//                       },
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: attendanceProvider.attendanceMarkedToday
//                         ? Colors.green.shade100
//                         : Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: attendanceProvider.attendanceMarkedToday
//                               ? Colors.green
//                               : GlobalColors.primaryBlue,
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Iconsax.calendar_1,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             attendanceProvider.attendanceMarkedToday
//                                 ? "Attendance Marked"
//                                 : "Mark Attendance",
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 15,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             attendanceProvider.attendanceMarkedToday
//                                 ? "Already marked for today"
//                                 : "Tap to mark now",
//                             style: const TextStyle(
//                               color: GlobalColors.textGrey,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 28),
//               const Text(
//                 "Orders Overview",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => const TotalOrdersPage()),
//                         );
//                       },
//                       borderRadius: BorderRadius.circular(16),
//                       child: _summary(
//                         "Total",
//                         context.watch<OrderProvider>().totalOrders.toString(),
//                         Iconsax.shopping_cart,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => const PendingOrdersPage()),
//                         );
//                       },
//                       borderRadius: BorderRadius.circular(16),
//                       child: _summary(
//                         "Pending",
//                         context.watch<OrderProvider>().pendingOrders.toString(),
//                         Iconsax.timer,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => const CompletedOrdersPage()),
//                         );
//                       },
//                       borderRadius: BorderRadius.circular(16),
//                       child: _summary(
//                         "Completed",
//                         context.watch<OrderProvider>().completedOrders.toString(),
//                         Iconsax.tick_circle,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 28),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: GlobalColors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Performance vs Target",
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 6),
//                     const Text(
//                       "Monthly comparison (0–100%)",
//                       style: TextStyle(
//                         color: GlobalColors.textGrey,
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: SizedBox(
//                         width: 780,
//                         height: 260,
//                         child: BarChart(
//                           BarChartData(
//                             minY: 0,
//                             maxY: 100,
//                             barGroups: List.generate(12, (i) {
//                               return BarChartGroupData(
//                                 x: i,
//                                 barsSpace: 6,
//                                 barRods: [
//                                   BarChartRodData(
//                                     toY: target[i].toDouble(),
//                                     width: 8,
//                                     color: Colors.grey.shade400,
//                                   ),
//                                   BarChartRodData(
//                                     toY: achieved[i].toDouble(),
//                                     width: 8,
//                                     color: GlobalColors.primaryBlue,
//                                   ),
//                                 ],
//                               );
//                             }),
//                             titlesData: FlTitlesData(
//                               leftTitles: AxisTitles(
//                                 sideTitles: SideTitles(
//                                   showTitles: true,
//                                   interval: 20,
//                                   getTitlesWidget: (v, _) => Text(
//                                     "${v.toInt()}%",
//                                     style: const TextStyle(fontSize: 10),
//                                   ),
//                                 ),
//                               ),
//                               bottomTitles: AxisTitles(
//                                 sideTitles: SideTitles(
//                                   showTitles: true,
//                                   getTitlesWidget: (v, _) => Text(
//                                     months[v.toInt()],
//                                     style: const TextStyle(fontSize: 10),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             borderData: FlBorderData(show: false),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _summary(String title, String value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: GlobalColors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: GlobalColors.primaryBlue),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             title,
//             style: const TextStyle(
//               color: GlobalColors.textGrey,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:iconsax_flutter/iconsax_flutter.dart';
// import 'package:mega_pro/employee/emp_attendance.dart';
// import 'package:mega_pro/employee/emp_attendance_history.dart';
// import 'package:mega_pro/employee/emp_completedOrdersPage.dart';
// import 'package:mega_pro/employee/emp_create_order_page.dart';
// import 'package:mega_pro/employee/emp_pendingOrdersScreen.dart';
// import 'package:mega_pro/employee/emp_profile.dart';
// import 'package:mega_pro/employee/emp_recent_order_page.dart';
// import 'package:mega_pro/employee/emp_totalOrdersScreen.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/providers/emp_attendance_provider.dart';
// import 'package:mega_pro/providers/emp_order_provider.dart';
// import 'package:mega_pro/providers/emp_provider.dart';
// import 'package:provider/provider.dart';

// class EmployeeDashboard extends StatefulWidget {
//   const EmployeeDashboard({super.key});

//   @override
//   State<EmployeeDashboard> createState() => _EmployeeDashboardState();
// }

// class _EmployeeDashboardState extends State<EmployeeDashboard> {
//   int _selectedIndex = 0;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   late final List<Widget> _pages;

//   @override
//   void initState() {
//     super.initState();

//     Future.microtask(() {
//       context.read<EmployeeProvider>().loadEmployeeProfile();
//       context.read<OrderProvider>().fetchOrderCounts();
//       context.read<AttendanceProvider>().checkTodayAttendance();
//     });

//     _pages = [
//       _DashboardHome(scaffoldKey: _scaffoldKey),
//       const CattleFeedOrderScreen(),
//       const RecentOrdersScreen(),
//       const EmployeeProfileDashboard(),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: AppColors.scaffoldBg,
//       drawer: _buildDrawer(context),
//       body: IndexedStack(index: _selectedIndex, children: _pages),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         selectedItemColor: GlobalColors.primaryBlue,
//         unselectedItemColor: GlobalColors.textGrey,
//         onTap: (i) => setState(() => _selectedIndex = i),
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Iconsax.home), label: "Home"),
//           BottomNavigationBarItem(
//               icon: Icon(Iconsax.add_square), label: "Create"),
//           BottomNavigationBarItem(
//               icon: Icon(Iconsax.receipt_item), label: "Orders"),
//           BottomNavigationBarItem(icon: Icon(Iconsax.user), label: "Profile"),
//         ],
//       ),
//     );
//   }

//   Drawer _buildDrawer(BuildContext context) {
//     final emp = context.watch<EmployeeProvider>().profile;

//     return Drawer(
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
//             decoration: const BoxDecoration(
//               color: GlobalColors.primaryBlue,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(18),
//                 bottomRight: Radius.circular(18),
//               ),
//             ),
//             child: Row(
//               children: [
//                 const CircleAvatar(
//                   radius: 28,
//                   backgroundColor: Colors.white,
//                   child: Icon(Iconsax.user, color: GlobalColors.primaryBlue),
//                 ),
//                 const SizedBox(width: 14),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(emp?['full_name'] ?? '',
//                         style: const TextStyle(
//                             color: Colors.white, fontWeight: FontWeight.bold)),
//                     Text(emp?['position'] ?? '',
//                         style: const TextStyle(
//                             color: Colors.white70, fontSize: 12)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           _drawerTile(Iconsax.calendar_1, "Mark Attendance", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => const EmployeeAttendancePage(cameras: []),
//               ),
//             );
//           }),
//           _drawerTile(Icons.calendar_month, "Attendance History", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => const AttendanceHistoryPage(),
//               ),
//             );
//           }),
//           _drawerTile(Iconsax.receipt_item, "Total Orders", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const TotalOrdersPage()),
//             );
//           }),
//           _drawerTile(Iconsax.timer, "Pending Orders", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const PendingOrdersPage()),
//             );
//           }),
//           _drawerTile(Iconsax.tick_circle, "Completed Orders", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const CompletedOrdersPage()),
//             );
//           }),
//           _drawerTile(Iconsax.user, "My Profile", () {
//             Navigator.pop(context);
//             setState(() => _selectedIndex = 3);
//           }),
//           const Spacer(),
//           _drawerTile(Iconsax.logout, "Logout", () {
//             Navigator.pop(context);
//           }, danger: true),
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }

//   Widget _drawerTile(
//     IconData icon,
//     String title,
//     VoidCallback onTap, {
//     bool danger = false,
//   }) {
//     return ListTile(
//       leading: Icon(
//         icon,
//         color: danger ? GlobalColors.danger : GlobalColors.primaryBlue,
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: danger ? GlobalColors.danger : GlobalColors.black,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }
// }


// class _DashboardHome extends StatelessWidget {
//   final GlobalKey<ScaffoldState> scaffoldKey;

//   const _DashboardHome({required this.scaffoldKey});

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<EmployeeProvider>();

//     if (provider.loading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     final months = const [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];

//     final target = [80, 80, 80, 80, 80, 80, 85, 85, 85, 90, 90, 90];
//     final achieved = [60, 70, 65, 80, 75, 85, 88, 82, 90, 92, 95, 98];

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white),
//           onPressed: () => scaffoldKey.currentState?.openDrawer(),
//         ),
//         title: const Text("Employee Dashboard",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Consumer<AttendanceProvider>(
//           builder: (context, attendanceProvider, _) => Column(
//             children: [
//               InkWell(
//                 onTap: attendanceProvider.attendanceMarkedToday
//                     ? null
//                     : () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const EmployeeAttendancePage(cameras: []),
//                           ),
//                         );
//                       },
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: attendanceProvider.attendanceMarkedToday
//                         ? Colors.green.shade100
//                         : Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: attendanceProvider.attendanceMarkedToday
//                               ? Colors.green
//                               : GlobalColors.primaryBlue,
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Iconsax.calendar_1,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             attendanceProvider.attendanceMarkedToday
//                                 ? "Attendance Marked"
//                                 : "Mark Attendance",
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 15,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             attendanceProvider.attendanceMarkedToday
//                                 ? "Already marked for today"
//                                 : "Tap to mark now",
//                             style: const TextStyle(
//                               color: GlobalColors.textGrey,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 28),
//               const Text(
//                 "Orders Overview",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => const TotalOrdersPage()),
//                         );
//                       },
//                       borderRadius: BorderRadius.circular(16),
//                       child: _summary(
//                         "Total",
//                         context.watch<OrderProvider>().totalOrders.toString(),
//                         Iconsax.shopping_cart,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => const PendingOrdersPage()),
//                         );
//                       },
//                       borderRadius: BorderRadius.circular(16),
//                       child: _summary(
//                         "Pending",
//                         context.watch<OrderProvider>().pendingOrders.toString(),
//                         Iconsax.timer,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => const CompletedOrdersPage()),
//                         );
//                       },
//                       borderRadius: BorderRadius.circular(16),
//                       child: _summary(
//                         "Completed",
//                         context.watch<OrderProvider>().completedOrders.toString(),
//                         Iconsax.tick_circle,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 28),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: GlobalColors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Performance vs Target",
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 6),
//                     const Text(
//                       "Monthly comparison (0–100%)",
//                       style: TextStyle(
//                         color: GlobalColors.textGrey,
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: SizedBox(
//                         width: 780,
//                         height: 260,
//                         child: BarChart(
//                           BarChartData(
//                             minY: 0,
//                             maxY: 100,
//                             barGroups: List.generate(12, (i) {
//                               return BarChartGroupData(
//                                 x: i,
//                                 barsSpace: 6,
//                                 barRods: [
//                                   BarChartRodData(
//                                     toY: target[i].toDouble(),
//                                     width: 8,
//                                     color: Colors.grey.shade400,
//                                   ),
//                                   BarChartRodData(
//                                     toY: achieved[i].toDouble(),
//                                     width: 8,
//                                     color: GlobalColors.primaryBlue,
//                                   ),
//                                 ],
//                               );
//                             }),
//                             titlesData: FlTitlesData(
//                               leftTitles: AxisTitles(
//                                 sideTitles: SideTitles(
//                                   showTitles: true,
//                                   interval: 20,
//                                   getTitlesWidget: (v, _) => Text(
//                                     "${v.toInt()}%",
//                                     style: const TextStyle(fontSize: 10),
//                                   ),
//                                 ),
//                               ),
//                               bottomTitles: AxisTitles(
//                                 sideTitles: SideTitles(
//                                   showTitles: true,
//                                   getTitlesWidget: (v, _) => Text(
//                                     months[v.toInt()],
//                                     style: const TextStyle(fontSize: 10),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             borderData: FlBorderData(show: false),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _summary(String title, String value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: GlobalColors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: GlobalColors.primaryBlue),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             title,
//             style: const TextStyle(
//               color: GlobalColors.textGrey,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:iconsax_flutter/iconsax_flutter.dart';
// import 'package:mega_pro/employee/emp_attendance.dart';
// import 'package:mega_pro/employee/emp_attendance_history.dart';
// import 'package:mega_pro/employee/emp_completedOrdersPage.dart';
// import 'package:mega_pro/employee/emp_create_order_page.dart';
// import 'package:mega_pro/employee/emp_pendingOrdersScreen.dart';
// import 'package:mega_pro/employee/emp_profile.dart';
// import 'package:mega_pro/employee/emp_recent_order_page.dart';
// import 'package:mega_pro/employee/emp_totalOrdersScreen.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/providers/emp_attendance_provider.dart';
// import 'package:mega_pro/providers/emp_order_provider.dart';
// import 'package:mega_pro/providers/emp_provider.dart';
// import 'package:provider/provider.dart';

// class EmployeeDashboard extends StatefulWidget {
//   const EmployeeDashboard({super.key});

//   @override
//   State<EmployeeDashboard> createState() => _EmployeeDashboardState();
// }

// class _EmployeeDashboardState extends State<EmployeeDashboard> {
//   int _selectedIndex = 0;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   late final List<Widget> _pages;

//   @override
// void initState() {
//   super.initState();

//   Future.microtask(() {
//     context.read<EmployeeProvider>().loadEmployeeProfile();
//     context.read<OrderProvider>().fetchOrderCounts();
//     context.read<AttendanceProvider>().checkTodayAttendance();
//   });



//     _pages = [
//       _DashboardHome(scaffoldKey: _scaffoldKey),
//       const CattleFeedOrderScreen(),
//       const RecentOrdersScreen(),
//       const EmployeeProfileDashboard(),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: AppColors.scaffoldBg,
//       drawer: _buildDrawer(context),
//       body: IndexedStack(index: _selectedIndex, children: _pages),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         selectedItemColor: GlobalColors.primaryBlue,
//         unselectedItemColor: GlobalColors.textGrey,
//         onTap: (i) => setState(() => _selectedIndex = i),
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Iconsax.home), label: "Home"),
//           BottomNavigationBarItem(
//               icon: Icon(Iconsax.add_square), label: "Create"),
//           BottomNavigationBarItem(
//               icon: Icon(Iconsax.receipt_item), label: "Orders"),
//           BottomNavigationBarItem(icon: Icon(Iconsax.user), label: "Profile"),
//         ],
//       ),
//     );
//   }

//   Drawer _buildDrawer(BuildContext context) {
//     final emp = context.watch<EmployeeProvider>().profile;

//     return Drawer(
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
//             decoration: const BoxDecoration(
//               color: GlobalColors.primaryBlue,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(18),
//                 bottomRight: Radius.circular(18),
//               ),
//             ),
//             child: Row(
//               children: [
//                 const CircleAvatar(
//                   radius: 28,
//                   backgroundColor: Colors.white,
//                   child: Icon(Iconsax.user, color: GlobalColors.primaryBlue),
//                 ),
//                 const SizedBox(width: 14),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(emp?['full_name'] ?? '',
//                         style: const TextStyle(
//                             color: Colors.white, fontWeight: FontWeight.bold)),
//                     Text(emp?['position'] ?? '',
//                         style: const TextStyle(
//                             color: Colors.white70, fontSize: 12)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           _drawerTile(Iconsax.calendar_1, "Mark Attendance", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => const EmployeeAttendancePage(cameras: []),
//               ),
//             );
//           }),
//           _drawerTile(Icons.calendar_month, "Attendance History", () {
//   Navigator.pop(context);
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (_) => const AttendanceHistoryPage(),
//     ),
//   );
// },),

//           _drawerTile(Iconsax.receipt_item, "Total Orders", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const TotalOrdersPage()),
//             );
//           }),
//           _drawerTile(Iconsax.timer, "Pending Orders", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const PendingOrdersPage()),
//             );
//           }),
//           _drawerTile(Iconsax.tick_circle, "Completed Orders", () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const CompletedOrdersPage()),
//             );
//           }),
//           _drawerTile(Iconsax.user, "My Profile", () {
//             Navigator.pop(context);
//             setState(() => _selectedIndex = 3);
//           }),
//           const Spacer(),
//           _drawerTile(Iconsax.logout, "Logout", () {
//             Navigator.pop(context);
//           }, danger: true),
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }

//   Widget _drawerTile(
//     IconData icon,
//     String title,
//     VoidCallback onTap, {
//     bool danger = false,
//   }) {
//     return ListTile(
//       leading: Icon(
//         icon,
//         color: danger ? GlobalColors.danger : GlobalColors.primaryBlue,
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: danger ? GlobalColors.danger : GlobalColors.black,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }
// }

// class _DashboardHome extends StatelessWidget {
//   final GlobalKey<ScaffoldState> scaffoldKey;

//   const _DashboardHome({required this.scaffoldKey});

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<EmployeeProvider>();

//     if (provider.loading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     final months = const [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];

//     final target = [80, 80, 80, 80, 80, 80, 85, 85, 85, 90, 90, 90];
//     final achieved = [60, 70, 65, 80, 75, 85, 88, 82, 90, 92, 95, 98];

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white),
//           onPressed: () => scaffoldKey.currentState?.openDrawer(),
//         ),
//         title: const Text("Employee Dashboard",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Consumer<AttendanceProvider>(
//           builder: (context, attendanceProvider, _) => Column(
//             children: [
// InkWell(
//   onTap: attendanceProvider.attendanceMarkedToday
//       ? null
//       : () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => const EmployeeAttendancePage(cameras: []),
//             ),
//           );
//         },
//   child: Container(
//     padding: const EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: attendanceProvider.attendanceMarkedToday
//           ? Colors.green.shade100
//           : Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       boxShadow: [
//         BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: attendanceProvider.attendanceMarkedToday
//                 ? Colors.green
//                 : GlobalColors.primaryBlue,
//             shape: BoxShape.circle,
//           ),
//           child: const Icon(
//             Iconsax.calendar_1,
//             color: Colors.white,
//             size: 20,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               attendanceProvider.attendanceMarkedToday
//                   ? "Attendance Marked"
//                   : "Mark Attendance",
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 15,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               attendanceProvider.attendanceMarkedToday
//                   ? "Already marked for today"
//                   : "Tap to mark now",
//               style: const TextStyle(
//                 color: GlobalColors.textGrey,
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   ),
// ),

//             const SizedBox(height: 28),
//             const Text(
//               "Orders Overview",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: InkWell(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const TotalOrdersPage()),
//                       );
//                     },
//                     borderRadius: BorderRadius.circular(16),
//                     child: _summary("Total",
//   context.watch<OrderProvider>().totalOrders.toString(),
//   Iconsax.shopping_cart,
// ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: InkWell(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const PendingOrdersPage()),
//                       );
//                     },
//                     borderRadius: BorderRadius.circular(16),
//                     child: _summary("Pending",
//   context.watch<OrderProvider>().pendingOrders.toString(),
//   Iconsax.timer,
// ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: InkWell(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const CompletedOrdersPage()),
//                       );
//                     },
//                     borderRadius: BorderRadius.circular(16),
//                     child: _summary("Completed",
//   context.watch<OrderProvider>().completedOrders.toString(),
//   Iconsax.tick_circle,
// ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 28),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: GlobalColors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Performance vs Target",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     "Monthly comparison (0–100%)",
//                     style: TextStyle(
//                       color: GlobalColors.textGrey,
//                       fontSize: 12,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: SizedBox(
//                       width: 780,
//                       height: 260,
//                       child: BarChart(
//                         BarChartData(
//                           minY: 0,
//                           maxY: 100,
//                           barGroups: List.generate(12, (i) {
//                             return BarChartGroupData(
//                               x: i,
//                               barsSpace: 6,
//                               barRods: [
//                                 BarChartRodData(
//                                   toY: target[i].toDouble(),
//                                   width: 8,
//                                   color: Colors.grey.shade400,
//                                 ),
//                                 BarChartRodData(
//                                   toY: achieved[i].toDouble(),
//                                   width: 8,
//                                   color: GlobalColors.primaryBlue,
//                                 ),
//                               ],
//                             );
//                           }),
//                           titlesData: FlTitlesData(
//                             leftTitles: AxisTitles(
//                               sideTitles: SideTitles(
//                                 showTitles: true,
//                                 interval: 20,
//                                 getTitlesWidget: (v, _) => Text(
//                                   "${v.toInt()}%",
//                                   style: const TextStyle(fontSize: 10),
//                                 ),
//                               ),
//                             ),
//                             bottomTitles: AxisTitles(
//                               sideTitles: SideTitles(
//                                 showTitles: true,
//                                 getTitlesWidget: (v, _) => Text(
//                                   months[v.toInt()],
//                                   style: const TextStyle(fontSize: 10),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           borderData: FlBorderData(show: false),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       ),
//     );
//   }

//   Widget _summary(String title, String value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: GlobalColors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: GlobalColors.primaryBlue),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             title,
//             style: const TextStyle(
//               color: GlobalColors.textGrey,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }






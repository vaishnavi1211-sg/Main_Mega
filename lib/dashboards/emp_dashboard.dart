import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:mega_pro/main.dart';
import 'package:mega_pro/providers/emp_attendance_provider.dart';
import 'package:mega_pro/providers/emp_mar_target_provider.dart';
import 'package:mega_pro/providers/emp_order_provider.dart';
import 'package:mega_pro/providers/emp_provider.dart';
import 'package:provider/provider.dart';

class EmployeeDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EmployeeDashboard({super.key, required this.userData});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Store pages in memory to preserve state
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    // Initialize pages once and keep them in memory
    _pages = [
      _DashboardHome(scaffoldKey: _scaffoldKey),
      const CattleFeedOrderScreen(),
      const RecentOrdersScreen(),
      const EmployeeProfileDashboard(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If we're not on the home page, go to home page
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        } else {
          // Show exit dialog
          bool? shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => _buildExitDialog(context),
          );
          return shouldExit ?? false;
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.scaffoldBg,
        drawer: _buildDrawer(context),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: GlobalColors.primaryBlue,
          unselectedItemColor: GlobalColors.textGrey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
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
      ),
    );
  }

  Widget _buildExitDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.transparent,
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [GlobalColors.primaryBlue, Colors.blue[700]!],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [                  
                  Expanded(
                    child: Text(
                      "Exit App?",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text("Are you sure you want to exit?", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800])),
                  const SizedBox(height: 28),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      label: const Text("Cancel"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      label: const Text("Exit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final emp = context.watch<EmployeeProvider>().profile;
    final attendanceProvider = context.watch<AttendanceProvider>();

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
                    Text(
                      emp?['full_name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      emp?['position'] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Only show "Mark Attendance" if NOT already marked today
          if (!attendanceProvider.attendanceMarkedToday)
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
              MaterialPageRoute(builder: (_) => const AttendanceHistoryPage()),
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
          
          // Profile navigation
          _drawerTile(Iconsax.user, "My Profile", () {
            Navigator.pop(context);
            setState(() {
              _selectedIndex = 3;
            });
          }),
          
          const Spacer(),
          _drawerTile(Iconsax.logout, "Logout", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RoleSelectionScreen()),
            );
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

/* ================= DASHBOARD HOME ================= */

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
  bool _isRefreshing = false;
  String? _loadError;
  bool _isInitialized = false;
  bool _isDataLoading = false;
  
  // Store data locally to prevent reloading
  List<double> _targets = List.filled(12, 0.0);
  List<double> _achieved = List.filled(12, 0.0);

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    months = List.generate(
      12,
      (i) => '${now.year}-${(i + 1).toString().padLeft(2, '0')}',
    );

    monthLabels = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Load data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadData();
    });
  }

  Future<void> _initializeAndLoadData() async {
    if (_isInitialized && !_isRefreshing) return;

    setState(() {
      if (!_isInitialized) _isDataLoading = true;
      _loadError = null;
    });

    try {
      // Only load employee profile if not already loaded
      final empProvider = context.read<EmployeeProvider>();
      if (empProvider.profile == null) {
        await empProvider.loadEmployeeProfile();
      }

      final empId = empProvider.profile?['emp_id']?.toString();

      if (empId == null || empId.isEmpty) {
        throw Exception('No employee ID found. Please check your profile.');
      }

      // Load all data concurrently
      await Future.wait([
        _loadTargetData(empId),
        context.read<AttendanceProvider>().checkTodayAttendance(),
      ]);

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Error initializing dashboard: $e');
      setState(() {
        _loadError = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isDataLoading = false;
      });
    }
  }

  Future<void> _loadTargetData(String empId) async {
    final targetProvider = context.read<TargetProvider>();
    
    print('🔄 Loading target data for employee: $empId');

    try {
      await targetProvider.loadTargetData(empId);

      // Get and store data locally
      final targets = targetProvider.getMonthlyTargets(empId, months);
      final achieved = targetProvider.getMonthlyAchieved(empId, months);
      
      // Store locally to prevent reloading
      setState(() {
        _targets = targets;
        _achieved = achieved;
      });

      print('📊 === TARGET DATA LOADED ===');
      print('Targets: $_targets');
      print('Achieved: $_achieved');
      
      for (int i = 0; i < months.length; i++) {
        print('${monthLabels[i]}: Target=${_targets[i]} T, Achieved=${_achieved[i]} T');
      }
    } catch (e) {
      print('❌ Failed to load target data: $e');
      rethrow;
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _loadError = null;
    });

    try {
      final empProvider = context.read<EmployeeProvider>();
      final empId = empProvider.profile?['emp_id']?.toString();
      
      if (empId == null || empId.isEmpty) {
        throw Exception('No employee ID found');
      }

      await Future.wait([
        _loadTargetData(empId),
        context.read<AttendanceProvider>().checkTodayAttendance(),
      ]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      setState(() {});
    } catch (e) {
      print('❌ Error refreshing data: $e');
      setState(() {
        _loadError = 'Refresh failed: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refresh failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen if data is still loading
    if (_isDataLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard...'),
          ],
        ),
      );
    }

    // Check if we have any data to show
    final hasTargets = _targets.any((t) => t > 0);
    final hasAchievements = _achieved.any((a) => a > 0);
    final hasData = hasTargets || hasAchievements;

    // Calculate max value for scaling
    double maxValue = 0;
    if (hasData) {
      for (var target in _targets) {
        if (target > maxValue) maxValue = target;
      }
      for (var achievement in _achieved) {
        if (achievement > maxValue) maxValue = achievement;
      }
      // Add padding for better visualization
      maxValue = maxValue * 1.2;
    } else {
      maxValue = 100.0; // Default value for empty chart
    }

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
        title: const Text(
          "Employee Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Consumer<AttendanceProvider>(
            builder: (context, attendanceProvider, _) => Column(
              children: [
                // Attendance Card
                InkWell(
                  onTap: attendanceProvider.attendanceMarkedToday
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const EmployeeAttendancePage(cameras: []),
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
                        BoxShadow(color: AppColors.shadowGrey, blurRadius: 12),
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
                        Expanded(
                          child: Column(
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
                        ),
                        Icon(
                          attendanceProvider.attendanceMarkedToday
                              ? Icons.check_circle
                              : Icons.arrow_forward_ios,
                          color: attendanceProvider.attendanceMarkedToday
                              ? Colors.green
                              : GlobalColors.primaryBlue,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Orders Overview
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
                              builder: (_) => const TotalOrdersPage(),
                            ),
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
                              builder: (_) => const PendingOrdersPage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: _summary(
                          "Pending",
                          context
                              .watch<OrderProvider>()
                              .pendingOrders
                              .toString(),
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
                              builder: (_) => const CompletedOrdersPage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: _summary(
                          "Completed",
                          context
                              .watch<OrderProvider>()
                              .completedOrders
                              .toString(),
                          Iconsax.tick_circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Performance Chart Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GlobalColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.shadowGrey, blurRadius: 12),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: GlobalColors.primaryBlue.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  DateTime.now().year.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: GlobalColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      

                      // Error message
                      if (_loadError != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _loadError!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 16),
                                onPressed: _refreshData,
                              ),
                            ],
                          ),
                        ),

                      // Current month summary - ALWAYS SHOW
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCurrentMonthStat(
                                monthLabels[DateTime.now().month - 1],
                                "Current Month",
                                GlobalColors.primaryBlue,
                              ),
                              _buildCurrentMonthStat(
                                "${_targets[DateTime.now().month - 1].toStringAsFixed(1)} T",
                                "Target",
                                Colors.grey.shade700,
                              ),
                              _buildCurrentMonthStat(
                                "${_achieved[DateTime.now().month - 1].toStringAsFixed(1)} T",
                                "Achieved",
                                _achieved[DateTime.now().month - 1] >=
                                        _targets[DateTime.now().month - 1]
                                    ? Colors.green
                                    : GlobalColors.primaryBlue,
                              ),
                              _buildCurrentMonthStat(
                                _targets[DateTime.now().month - 1] > 0
                                    ? "${((_achieved[DateTime.now().month - 1] / _targets[DateTime.now().month - 1]) * 100).toStringAsFixed(0)}%"
                                    : "N/A",
                                "Progress",
                                _targets[DateTime.now().month - 1] > 0 &&
                                        _achieved[DateTime.now().month - 1] >=
                                            _targets[DateTime.now().month - 1]
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Chart Container
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // Chart Title
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  hasData
                                      ? "Monthly Targets vs Achievements"
                                      : "Performance Chart",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Scrollbar(
                                controller: _scrollController,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 420,
                                    height: 290,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: BarChart(
                                        _buildBarChartData(
                                          maxValue,
                                          hasData,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Legend - Only show if we have data
                      if (hasData) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(Colors.grey.shade400, "Target"),
                            const SizedBox(width: 20),
                            _buildLegendItem(
                              GlobalColors.primaryBlue,
                              "Achieved",
                            ),
                            const SizedBox(width: 20),
                            _buildLegendItem(Colors.green, "Target Achieved"),
                          ],
                        ),
                      ],

                      // Year Summary - Only show if we have data
                      if (hasData) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Year ${DateTime.now().year} Summary",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildYearSummaryStat(
                                    "Total Target",
                                    "${_targets.fold(0.0, (sum, element) => sum + element).toStringAsFixed(1)} T",
                                    Colors.grey.shade700,
                                  ),
                                  _buildYearSummaryStat(
                                    "Total Achieved",
                                    "${_achieved.fold(0.0, (sum, element) => sum + element).toStringAsFixed(1)} T",
                                    GlobalColors.primaryBlue,
                                  ),
                                  _buildYearSummaryStat(
                                    "Overall Progress",
                                    _targets.fold(
                                              0.0,
                                              (sum, element) => sum + element,
                                            ) >
                                            0
                                        ? "${((_achieved.fold(0.0, (sum, element) => sum + element) / _targets.fold(0.0, (sum, element) => sum + element)) * 100).toStringAsFixed(1)}%"
                                        : "0%",
                                    _targets.fold(
                                                  0.0,
                                                  (sum, element) =>
                                                      sum + element,
                                                ) >
                                                0 &&
                                            (_achieved.fold(
                                                      0.0,
                                                      (sum, element) =>
                                                          sum + element,
                                                    ) /
                                                    _targets.fold(
                                                      0.0,
                                                      (sum, element) =>
                                                          sum + element,
                                                    )) >=
                                                1
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  BarChartData _buildBarChartData(
    double maxValue,
    bool hasData,
  ) {
    // Calculate interval based on max value
    final double interval = maxValue <= 100
        ? 20.0
        : (maxValue / 5).ceilToDouble();

    return BarChartData(
      alignment: BarChartAlignment.center,
      groupsSpace: 12,
      minY: 0,
      maxY: maxValue,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBorder: BorderSide(color: Colors.grey.shade300),
          tooltipRoundedRadius: 8,
          tooltipMargin: 10,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final month = monthLabels[group.x];
            final targetVal = _targets[group.x];
            final achievedVal = _achieved[group.x];
            final progress = targetVal > 0
                ? (achievedVal / targetVal) * 100
                : 0;

            String tooltipText = "📅 $month ${DateTime.now().year}\n";
            tooltipText += "━━━━━━━━━━━━━━━━━━━━\n";
            tooltipText += "🎯 Target: ${targetVal.toStringAsFixed(1)} T\n";
            tooltipText += "📈 Achieved: ${achievedVal.toStringAsFixed(1)} T\n";

            if (targetVal > 0) {
              tooltipText += "📊 Progress: ${progress.toStringAsFixed(1)}%";

              if (progress >= 100) {
                tooltipText += " 🎉 Target Achieved!";
              } else if (progress >= 70) {
                tooltipText += " 🔥 Great Progress!";
              } else if (progress >= 30) {
                tooltipText += " ⚡ Good Progress";
              } else if (progress > 0) {
                tooltipText += " 📈 Getting Started";
              }
            } else {
              tooltipText += "ℹ️ No target assigned";
            }

            return BarTooltipItem(
              tooltipText,
              const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
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
            interval: interval,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  "${value.toInt()} T",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < monthLabels.length) {
                final isCurrentMonth = index == DateTime.now().month - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    monthLabels[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrentMonth
                          ? GlobalColors.primaryBlue
                          : Colors.grey,
                      fontWeight: isCurrentMonth
                          ? FontWeight.w600
                          : FontWeight.w500,
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
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 0.5);
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      barGroups: List.generate(12, (index) {
        final target = _targets[index];
        final achievedValue = _achieved[index];
        final isTargetAchieved = target > 0 && achievedValue >= target;

        return BarChartGroupData(
          x: index,
          groupVertically: true,
          barRods: [
            // Target bar (grey) - always show even if 0
            BarChartRodData(
              toY: target,
              width: 14,
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
            // Achieved bar (blue or green if target achieved)
            BarChartRodData(
              toY: achievedValue,
              width: 10,
              color: isTargetAchieved ? Colors.green : GlobalColors.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        );
      }),
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
            style: const TextStyle(color: GlobalColors.textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildYearSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}












//takes time to load

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:google_fonts/google_fonts.dart';
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
// import 'package:mega_pro/main.dart';
// import 'package:mega_pro/providers/emp_attendance_provider.dart';
// import 'package:mega_pro/providers/emp_mar_target_provider.dart';
// import 'package:mega_pro/providers/emp_order_provider.dart';
// import 'package:mega_pro/providers/emp_provider.dart';
// import 'package:provider/provider.dart';

// class EmployeeDashboard extends StatefulWidget {
//   final Map<String, dynamic> userData;

//   const EmployeeDashboard({super.key, required this.userData});

//   @override
//   State<EmployeeDashboard> createState() => _EmployeeDashboardState();
// }

// class _EmployeeDashboardState extends State<EmployeeDashboard> {
//   int _selectedIndex = 0;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

//   // Define your routes
//   final List<String> _routeNames = [
//     '/home',
//     '/create-order',
//     '/recent-orders',
//     '/profile',
//   ];
// @override
// Widget build(BuildContext context) {
//   return WillPopScope(
//     onWillPop: () async {
//       if (_navigatorKey.currentState != null &&
//           _navigatorKey.currentState!.canPop()) {
//         _navigatorKey.currentState!.pop();
//         return false;
//       } else {
//         if (_selectedIndex != 0) {
//           setState(() {
//             _selectedIndex = 0;
//           });
//           _navigatorKey.currentState?.pushReplacementNamed(_routeNames[0]);
//           return false;
//         } else {
//           // Show exit dialog and wait for result
//           bool? shouldExit = await showDialog<bool>(
//             context: context,
//             builder: (context) => _buildExitDialog(context),
//           );
//           return shouldExit ?? false;
//         }
//       }
//     },
//     child: Scaffold(
//         key: _scaffoldKey,
//         backgroundColor: AppColors.scaffoldBg,
//         drawer: _buildDrawer(context),
//         body: Navigator(
//           key: _navigatorKey,
//           initialRoute: '/home',
//           onGenerateRoute: (RouteSettings settings) {
//             return MaterialPageRoute(
//               builder: (context) {
//                 return _buildPageForRoute(settings.name ?? '/home');
//               },
//               settings: settings,
//             );
//           },
//         ),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           selectedItemColor: GlobalColors.primaryBlue,
//           unselectedItemColor: GlobalColors.textGrey,
//           type: BottomNavigationBarType.fixed,
//           onTap: (index) {
//             if (_selectedIndex != index) {
//               setState(() {
//                 _selectedIndex = index;
//               });
//               // Navigate to the route
//               _navigatorKey.currentState?.pushReplacementNamed(
//                 _routeNames[index],
//               );
//             }
//           },
//           items: const [
//             BottomNavigationBarItem(icon: Icon(Iconsax.home), label: "Home"),
//             BottomNavigationBarItem(
//               icon: Icon(Iconsax.add_square),
//               label: "Create",
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Iconsax.receipt_item),
//               label: "Orders",
//             ),
//             BottomNavigationBarItem(icon: Icon(Iconsax.user), label: "Profile"),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildExitDialog(BuildContext context) {
//   return AlertDialog(
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//     backgroundColor: Colors.transparent,
//     content: Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 20,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [GlobalColors.primaryBlue, Colors.blue[700]!],
//               ),
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//             ),
//             child: Row(
//               children: [                  
//                 Expanded(
//                   child: Text(
//                     "Exit App?",
//                     style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               children: [
//                 Text("Are you sure you want to exit?", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800])),
//                 const SizedBox(height: 28),
                
//               ],
//             ),
//           ),
          
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
//               border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () => Navigator.of(context).pop(false),
//                     label: const Text("Cancel"),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.grey[700],
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       side: BorderSide(color: Colors.grey[400]!),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () => Navigator.of(context).pop(true),
//                     label: const Text("Exit"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: GlobalColors.primaryBlue,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       elevation: 0,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
//   Widget _buildPageForRoute(String routeName) {
//     switch (routeName) {
//       case '/home':
//         return _DashboardHome(scaffoldKey: _scaffoldKey);
//       case '/create-order':
//         return const CattleFeedOrderScreen();
//       case '/recent-orders':
//         return const RecentOrdersScreen();
//       case '/profile':
//         return const EmployeeProfileDashboard();
//       default:
//         return _DashboardHome(scaffoldKey: _scaffoldKey);
//     }
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
//                     Text(
//                       emp?['full_name'] ?? '',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       emp?['position'] ?? '',
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 12,
//                       ),
//                     ),
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
//               MaterialPageRoute(builder: (_) => const AttendanceHistoryPage()),
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
//             _navigatorKey.currentState?.pushReplacementNamed(_routeNames[3]);
//           }),
//           const Spacer(),
//           _drawerTile(Iconsax.logout, "Logout", () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => RoleSelectionScreen()),
//             );
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

// /* ================= DASHBOARD HOME ================= */

// class _DashboardHome extends StatefulWidget {
//   final GlobalKey<ScaffoldState> scaffoldKey;
//   const _DashboardHome({required this.scaffoldKey});

//   @override
//   State<_DashboardHome> createState() => __DashboardHomeState();
// }

// class __DashboardHomeState extends State<_DashboardHome> {
//   final ScrollController _scrollController = ScrollController();

//   late List<String> months;
//   late List<String> monthLabels;
//   bool _isRefreshing = false;
//   String? _loadError;
//   bool _isInitialized = false;
//   bool _isDataLoading = false;

//   @override
//   void initState() {
//     super.initState();

//     final now = DateTime.now();
//     months = List.generate(
//       12,
//       (i) => '${now.year}-${(i + 1).toString().padLeft(2, '0')}',
//     );

//     monthLabels = const [
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

//     // Load data immediately
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeAndLoadData();
//     });
//   }

//   Future<void> _initializeAndLoadData() async {
//     if (_isInitialized) return;

//     setState(() {
//       _isDataLoading = true;
//       _loadError = null;
//     });

//     try {
//       // First load employee profile if not loaded
//       await context.read<EmployeeProvider>().loadEmployeeProfile();

//       // Load all data concurrently
//       await Future.wait([
//         _loadTargetData(),
//         context.read<AttendanceProvider>().checkTodayAttendance(),
//       ]);

//       setState(() {
//         _isInitialized = true;
//       });
//     } catch (e) {
//       print('❌ Error initializing dashboard: $e');
//       setState(() {
//         _loadError = 'Failed to load data: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isDataLoading = false;
//       });
//     }
//   }

//   Future<void> _loadTargetData() async {
//     final empProvider = context.read<EmployeeProvider>();
//     final targetProvider = context.read<TargetProvider>();

//     final empId = empProvider.profile?['emp_id']?.toString();
//     if (empId != null && empId.isNotEmpty) {
//       print('🔄 Loading target data for employee: $empId');

//       try {
//         await targetProvider.loadTargetData(empId);

//         // Debug: Print loaded data
//         final targets = targetProvider.getMonthlyTargets(empId, months);
//         final achieved = targetProvider.getMonthlyAchieved(empId, months);

//         print('📊 === DASHBOARD DATA LOADED ===');
//         for (int i = 0; i < months.length; i++) {
//           if (targets[i] > 0 || achieved[i] > 0) {
//             print(
//               '${monthLabels[i]}: Target=${targets[i]} T, Achieved=${achieved[i]} T',
//             );
//           }
//         }
//       } catch (e) {
//         print('❌ Failed to load target data: $e');
//         throw e; // Re-throw to be caught by parent
//       }
//     } else {
//       throw Exception('No employee ID found. Please check your profile.');
//     }
//   }

//   Future<void> _refreshData() async {
//     if (_isRefreshing) return;

//     setState(() {
//       _isRefreshing = true;
//       _loadError = null;
//     });

//     try {
//       await Future.wait([
//         _loadTargetData(),
//         context.read<AttendanceProvider>().checkTodayAttendance(),
//       ]);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Data refreshed successfully'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );

//       setState(() {});
//     } catch (e) {
//       print('❌ Error refreshing data: $e');
//       setState(() {
//         _loadError = 'Refresh failed: ${e.toString()}';
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Refresh failed: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isRefreshing = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final empProvider = context.watch<EmployeeProvider>();
//     final targetProvider = context.watch<TargetProvider>();

//     // Show loading screen if data is still loading
//     if (_isDataLoading) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Loading dashboard...'),
//           ],
//         ),
//       );
//     }

//     final empId = empProvider.profile?['emp_id']?.toString() ?? '';

//     // Get target and achieved data
//     final targets = targetProvider.getMonthlyTargets(empId, months);
//     final achieved = targetProvider.getMonthlyAchieved(empId, months);

//     // Calculate max value for scaling
//     double maxValue = 0;
//     for (var target in targets) {
//       if (target > maxValue) maxValue = target;
//     }
//     for (var achievement in achieved) {
//       if (achievement > maxValue) maxValue = achievement;
//     }

//     // If no data, set sensible defaults
//     if (maxValue == 0) maxValue = 100.0;

//     // Add padding for better visualization
//     maxValue = maxValue * 1.2;

//     // Calculate intervals for Y axis
//     final double interval = maxValue <= 100
//         ? 20.0
//         : (maxValue / 5).ceilToDouble();

//     // Check if we have any data to show
//     final hasTargets = targets.any((t) => t > 0);
//     final hasAchievements = achieved.any((a) => a > 0);
//     final hasData = hasTargets || hasAchievements;

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white),
//           onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
//         ),
//         title: const Text(
//           "Employee Dashboard",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         actions: [
//           IconButton(
//             icon: _isRefreshing
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _isRefreshing ? null : _refreshData,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refreshData,
//         child: SingleChildScrollView(
//           controller: _scrollController,
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Consumer<AttendanceProvider>(
//             builder: (context, attendanceProvider, _) => Column(
//               children: [
//                 // Attendance Card
//                 InkWell(
//                   onTap: attendanceProvider.attendanceMarkedToday
//                       ? null
//                       : () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) =>
//                                   const EmployeeAttendancePage(cameras: []),
//                             ),
//                           );
//                         },
//                   child: Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: attendanceProvider.attendanceMarkedToday
//                           ? Colors.green.shade100
//                           : Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(color: AppColors.shadowGrey, blurRadius: 12),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: attendanceProvider.attendanceMarkedToday
//                                 ? Colors.green
//                                 : GlobalColors.primaryBlue,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Iconsax.calendar_1,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 attendanceProvider.attendanceMarkedToday
//                                     ? "Attendance Marked"
//                                     : "Mark Attendance",
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 15,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 attendanceProvider.attendanceMarkedToday
//                                     ? "Already marked for today"
//                                     : "Tap to mark now",
//                                 style: const TextStyle(
//                                   color: GlobalColors.textGrey,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Icon(
//                           attendanceProvider.attendanceMarkedToday
//                               ? Icons.check_circle
//                               : Icons.arrow_forward_ios,
//                           color: attendanceProvider.attendanceMarkedToday
//                               ? Colors.green
//                               : GlobalColors.primaryBlue,
//                           size: 16,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 28),

//                 // Orders Overview
//                 const Text(
//                   "Orders Overview",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const TotalOrdersPage(),
//                             ),
//                           );
//                         },
//                         borderRadius: BorderRadius.circular(16),
//                         child: _summary(
//                           "Total",
//                           context.watch<OrderProvider>().totalOrders.toString(),
//                           Iconsax.shopping_cart,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const PendingOrdersPage(),
//                             ),
//                           );
//                         },
//                         borderRadius: BorderRadius.circular(16),
//                         child: _summary(
//                           "Pending",
//                           context
//                               .watch<OrderProvider>()
//                               .pendingOrders
//                               .toString(),
//                           Iconsax.timer,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const CompletedOrdersPage(),
//                             ),
//                           );
//                         },
//                         borderRadius: BorderRadius.circular(16),
//                         child: _summary(
//                           "Completed",
//                           context
//                               .watch<OrderProvider>()
//                               .completedOrders
//                               .toString(),
//                           Iconsax.tick_circle,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 28),

//                 // Performance Chart Section
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: GlobalColors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(color: AppColors.shadowGrey, blurRadius: 12),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             "Performance vs Target",
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: GlobalColors.primaryBlue.withOpacity(
//                                     0.1,
//                                   ),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   DateTime.now().year.toString(),
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: GlobalColors.primaryBlue,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
                      

//                       // Error message
//                       if (_loadError != null)
//                         Container(
//                           margin: const EdgeInsets.only(top: 12),
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.red.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.red.shade200),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.error,
//                                 color: Colors.red,
//                                 size: 16,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   _loadError!,
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.red,
//                                   ),
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.refresh, size: 16),
//                                 onPressed: _initializeAndLoadData,
//                               ),
//                             ],
//                           ),
//                         ),

//                       // Data status indicator
//                       if (!hasData)
//                         Container(
//                           margin: const EdgeInsets.only(top: 12),
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.blue.shade200),
//                           ),
//                           child: Column(
//                             children: [
//                               const Icon(
//                                 Icons.info,
//                                 color: Colors.blue,
//                                 size: 32,
//                               ),
//                               const SizedBox(height: 8),
//                               const Text(
//                                 "No Performance Data",
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 hasTargets
//                                     ? "Complete some orders to see your achievements"
//                                     : "Ask your manager to assign targets for ${DateTime.now().year}",
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                               const SizedBox(height: 12),
//                               ElevatedButton.icon(
//                                 onPressed: _initializeAndLoadData,
//                                 icon: const Icon(Icons.refresh, size: 16),
//                                 label: const Text('Reload Data'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue,
//                                   foregroundColor: Colors.white,
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 8,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                       // Current month summary - ALWAYS SHOW
//                       Padding(
//                         padding: const EdgeInsets.only(top: 12),
//                         child: Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.grey.shade200),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: [
//                               _buildCurrentMonthStat(
//                                 "Current ",
//                                 monthLabels[DateTime.now().month - 1],
//                                 GlobalColors.primaryBlue,
//                               ),
//                               _buildCurrentMonthStat(
//                                 "Target",
//                                 "${targets[DateTime.now().month - 1].toStringAsFixed(1)} T",
//                                 Colors.grey.shade700,
//                               ),
//                               _buildCurrentMonthStat(
//                                 "Achieved",
//                                 "${achieved[DateTime.now().month - 1].toStringAsFixed(1)} T",
//                                 achieved[DateTime.now().month - 1] >=
//                                         targets[DateTime.now().month - 1]
//                                     ? Colors.green
//                                     : GlobalColors.primaryBlue,
//                               ),
//                               _buildCurrentMonthStat(
//                                 targets[DateTime.now().month - 1] > 0
//                                     ? "${((achieved[DateTime.now().month - 1] / targets[DateTime.now().month - 1]) * 100).toStringAsFixed(0)}%"
//                                     : "N/A",
//                                 "Progress",
//                                 targets[DateTime.now().month - 1] > 0 &&
//                                         achieved[DateTime.now().month - 1] >=
//                                             targets[DateTime.now().month - 1]
//                                     ? Colors.green
//                                     : Colors.orange,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 12),

//                       // Chart Container - ALWAYS RENDER, even if empty
//                       Container(
//                         height: 320,
//                         decoration: BoxDecoration(
//                           border: Border.all(
//                             color: Colors.grey.shade300,
//                             width: 1,
//                           ),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           children: [
//                             // Chart Title
//                             Container(
//                               padding: const EdgeInsets.symmetric(vertical: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade50,
//                                 border: Border(
//                                   bottom: BorderSide(
//                                     color: Colors.grey.shade300,
//                                   ),
//                                 ),
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   hasData
//                                       ? "Monthly Targets vs Achievements"
//                                       : "Performance Chart",
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey.shade600,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Expanded(
//                               child: Scrollbar(
//                                 controller: _scrollController,
//                                 child: SingleChildScrollView(
//                                   scrollDirection: Axis.horizontal,
//                                   child: SizedBox(
//                                     width: 420,
//                                     height: 290,
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(12.0),
//                                       child: hasData
//                                           ? BarChart(
//                                               _buildBarChartData(
//                                                 targets,
//                                                 achieved,
//                                                 maxValue,
//                                                 interval,
//                                               ),
//                                             )
//                                           : Center(
//                                               child: Column(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment.center,
//                                                 children: [
//                                                   Icon(
//                                                     Icons.bar_chart,
//                                                     size: 48,
//                                                     color: Colors.grey.shade300,
//                                                   ),
//                                                   const SizedBox(height: 12),
//                                                   Text(
//                                                     "Loading performance data...",
//                                                     style: TextStyle(
//                                                       color:
//                                                           Colors.grey.shade400,
//                                                       fontSize: 14,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       // Legend - Only show if we have data
//                       if (hasData) ...[
//                         const SizedBox(height: 16),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             _buildLegendItem(Colors.grey.shade400, "Target"),
//                             const SizedBox(width: 20),
//                             _buildLegendItem(
//                               GlobalColors.primaryBlue,
//                               "Achieved",
//                             ),
//                             const SizedBox(width: 20),
//                             _buildLegendItem(Colors.green, "Target Achieved"),
//                           ],
//                         ),
//                       ],

//                       // Year Summary - Only show if we have data
//                       if (hasData) ...[
//                         const SizedBox(height: 16),
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.grey.shade200),
//                           ),
//                           child: Column(
//                             children: [
//                               Text(
//                                 "Year ${DateTime.now().year} Summary",
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                               const SizedBox(height: 12),
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceAround,
//                                 children: [
//                                   _buildYearSummaryStat(
//                                     "Total Target",
//                                     "${targets.fold(0.0, (sum, element) => sum + element).toStringAsFixed(1)} T",
//                                     Colors.grey.shade700,
//                                   ),
//                                   _buildYearSummaryStat(
//                                     "Total Achieved",
//                                     "${achieved.fold(0.0, (sum, element) => sum + element).toStringAsFixed(1)} T",
//                                     GlobalColors.primaryBlue,
//                                   ),
//                                   _buildYearSummaryStat(
//                                     "Overall Progress",
//                                     targets.fold(
//                                               0.0,
//                                               (sum, element) => sum + element,
//                                             ) >
//                                             0
//                                         ? "${((achieved.fold(0.0, (sum, element) => sum + element) / targets.fold(0.0, (sum, element) => sum + element)) * 100).toStringAsFixed(1)}%"
//                                         : "0%",
//                                     targets.fold(
//                                                   0.0,
//                                                   (sum, element) =>
//                                                       sum + element,
//                                                 ) >
//                                                 0 &&
//                                             (achieved.fold(
//                                                       0.0,
//                                                       (sum, element) =>
//                                                           sum + element,
//                                                     ) /
//                                                     targets.fold(
//                                                       0.0,
//                                                       (sum, element) =>
//                                                           sum + element,
//                                                     )) >=
//                                                 1
//                                         ? Colors.green
//                                         : Colors.orange,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
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

//   BarChartData _buildBarChartData(
//     List<double> targets,
//     List<double> achieved,
//     double maxValue,
//     double interval,
//   ) {
//     return BarChartData(
//       alignment: BarChartAlignment.center,
//       groupsSpace: 12,
//       minY: 0,
//       maxY: maxValue,
//       barTouchData: BarTouchData(
//         enabled: true,
//         touchTooltipData: BarTouchTooltipData(
//           tooltipBorder: BorderSide(color: Colors.grey.shade300),
//           tooltipRoundedRadius: 8,
//           tooltipMargin: 10,
//           getTooltipItem: (group, groupIndex, rod, rodIndex) {
//             final month = monthLabels[group.x];
//             final targetVal = targets[group.x];
//             final achievedVal = achieved[group.x];
//             final progress = targetVal > 0
//                 ? (achievedVal / targetVal) * 100
//                 : 0;

//             String tooltipText = "📅 $month ${DateTime.now().year}\n";
//             tooltipText += "━━━━━━━━━━━━━━━━━━━━\n";
//             tooltipText += "🎯 Target: ${targetVal.toStringAsFixed(1)} T\n";
//             tooltipText += "📈 Achieved: ${achievedVal.toStringAsFixed(1)} T\n";

//             if (targetVal > 0) {
//               tooltipText += "📊 Progress: ${progress.toStringAsFixed(1)}%";

//               if (progress >= 100) {
//                 tooltipText += " 🎉 Target Achieved!";
//               } else if (progress >= 70) {
//                 tooltipText += " 🔥 Great Progress!";
//               } else if (progress >= 30) {
//                 tooltipText += " ⚡ Good Progress";
//               } else if (progress > 0) {
//                 tooltipText += " 📈 Getting Started";
//               }
//             } else {
//               tooltipText += "ℹ️ No target assigned";
//             }

//             return BarTooltipItem(
//               tooltipText,
//               const TextStyle(
//                 fontSize: 12,
//                 color: Colors.black,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.left,
//             );
//           },
//         ),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 40,
//             interval: interval,
//             getTitlesWidget: (value, meta) {
//               return Padding(
//                 padding: const EdgeInsets.only(right: 8),
//                 child: Text(
//                   "${value.toInt()} T",
//                   style: const TextStyle(fontSize: 10, color: Colors.grey),
//                 ),
//               );
//             },
//           ),
//         ),
//         rightTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             getTitlesWidget: (value, meta) {
//               final index = value.toInt();
//               if (index >= 0 && index < monthLabels.length) {
//                 final isCurrentMonth = index == DateTime.now().month - 1;
//                 return Padding(
//                   padding: const EdgeInsets.only(top: 4),
//                   child: Text(
//                     monthLabels[index],
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: isCurrentMonth
//                           ? GlobalColors.primaryBlue
//                           : Colors.grey,
//                       fontWeight: isCurrentMonth
//                           ? FontWeight.w600
//                           : FontWeight.w500,
//                     ),
//                   ),
//                 );
//               }
//               return const SizedBox();
//             },
//           ),
//         ),
//       ),
//       gridData: FlGridData(
//         show: true,
//         drawHorizontalLine: true,
//         drawVerticalLine: false,
//         horizontalInterval: interval,
//         getDrawingHorizontalLine: (value) {
//           return FlLine(color: Colors.grey.shade200, strokeWidth: 0.5);
//         },
//       ),
//       borderData: FlBorderData(
//         show: true,
//         border: Border.all(color: Colors.grey.shade300, width: 0.5),
//       ),
//       barGroups: List.generate(12, (index) {
//         final target = targets[index];
//         final achievedValue = achieved[index];
//         final isTargetAchieved = target > 0 && achievedValue >= target;

//         return BarChartGroupData(
//           x: index,
//           groupVertically: true,
//           barRods: [
//             // Target bar (grey)
//             BarChartRodData(
//               toY: target,
//               width: 14,
//               color: Colors.grey.shade400,
//               borderRadius: BorderRadius.circular(2),
//             ),
//             // Achieved bar (blue or green if target achieved)
//             BarChartRodData(
//               toY: achievedValue,
//               width: 10,
//               color: isTargetAchieved ? Colors.green : GlobalColors.primaryBlue,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ],
//         );
//       }),
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
//             style: const TextStyle(color: GlobalColors.textGrey, fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCurrentMonthStat(String value, String label, Color color) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w700,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
//       ],
//     );
//   }

//   Widget _buildYearSummaryStat(String label, String value, Color color) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 11,
//             color: Colors.grey,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.w700,
//             color: color,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLegendItem(Color color, String text) {
//     return Row(
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(
//           text,
//           style: const TextStyle(
//             fontSize: 11,
//             color: Colors.grey,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
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
// import 'package:mega_pro/providers/emp_mar_target_provider.dart';
// import 'package:mega_pro/providers/emp_order_provider.dart';
// import 'package:mega_pro/providers/emp_provider.dart';
// import 'package:provider/provider.dart';

// class EmployeeDashboard extends StatefulWidget {
//   final Map<String, dynamic> userData;

//   const EmployeeDashboard({
//     super.key,
//     required this.userData,
//   });

//   @override
//   State<EmployeeDashboard> createState() => _EmployeeDashboardState();
// }

// class _EmployeeDashboardState extends State<EmployeeDashboard> {
//   int _selectedIndex = 0;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

//   // Define your routes
//   final List<String> _routeNames = [
//     '/home',
//     '/create-order',
//     '/recent-orders',
//     '/profile',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: AppColors.scaffoldBg,
//       drawer: _buildDrawer(context),
//       body: Navigator(
//         key: _navigatorKey,
//         initialRoute: '/home',
//         onGenerateRoute: (RouteSettings settings) {
//           return MaterialPageRoute(
//             builder: (context) {
//               return _buildPageForRoute(settings.name ?? '/home');
//             },
//             settings: settings,
//           );
//         },
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         selectedItemColor: GlobalColors.primaryBlue,
//         unselectedItemColor: GlobalColors.textGrey,
//         type: BottomNavigationBarType.fixed,
//         onTap: (index) {
//           if (_selectedIndex != index) {
//             setState(() {
//               _selectedIndex = index;
//             });
//             // Navigate to the route
//             _navigatorKey.currentState?.pushReplacementNamed(_routeNames[index]);
//           }
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Iconsax.home), label: "Home"),
//           BottomNavigationBarItem(icon: Icon(Iconsax.add_square), label: "Create"),
//           BottomNavigationBarItem(
//               icon: Icon(Iconsax.receipt_item), label: "Orders"),
//           BottomNavigationBarItem(icon: Icon(Iconsax.user), label: "Profile"),
//         ],
//       ),
//     );
//   }

//   Widget _buildPageForRoute(String routeName) {
//     switch (routeName) {
//       case '/home':
//         return _DashboardHome(scaffoldKey: _scaffoldKey);
//       case '/create-order':
//         return const CattleFeedOrderScreen();
//       case '/recent-orders':
//         return const RecentOrdersScreen();
//       case '/profile':
//         return const EmployeeProfileDashboard();
//       default:
//         return _DashboardHome(scaffoldKey: _scaffoldKey);
//     }
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
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold)),
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
//               MaterialPageRoute(
//                   builder: (_) => const CompletedOrdersPage()),
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

//   Widget _drawerTile(IconData icon, String title, VoidCallback onTap,
//       {bool danger = false}) {
//     return ListTile(
//       leading: Icon(icon,
//           color:
//               danger ? GlobalColors.danger : GlobalColors.primaryBlue),
//       title: Text(title,
//           style: TextStyle(
//               color:
//                   danger ? GlobalColors.danger : GlobalColors.black)),
//       onTap: onTap,
//     );
//   }
// }

// /* ================= DASHBOARD HOME ================= */

// class _DashboardHome extends StatefulWidget {
//   final GlobalKey<ScaffoldState> scaffoldKey;
//   const _DashboardHome({required this.scaffoldKey});

//   @override
//   State<_DashboardHome> createState() => __DashboardHomeState();
// }

// class __DashboardHomeState extends State<_DashboardHome> {
//   final ScrollController _scrollController = ScrollController();

//   late List<String> months;
//   late List<String> monthLabels;
//   bool _isRefreshing = false;
//   String? _loadError;
//   bool _isInitialized = false;
//   bool _isDataLoading = false;

//   @override
//   void initState() {
//     super.initState();

//     final now = DateTime.now();
//     months = List.generate(
//       12,
//       (i) => '${now.year}-${(i + 1).toString().padLeft(2, '0')}',
//     );

//     monthLabels = const [
//       'Jan','Feb','Mar','Apr','May','Jun',
//       'Jul','Aug','Sep','Oct','Nov','Dec'
//     ];

//     // Load data immediately
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeAndLoadData();
//     });
//   }

//   Future<void> _initializeAndLoadData() async {
//     if (_isInitialized) return;
    
//     setState(() {
//       _isDataLoading = true;
//       _loadError = null;
//     });

//     try {
//       // First load employee profile if not loaded
//       await context.read<EmployeeProvider>().loadEmployeeProfile();
      
//       // Load all data concurrently
//       await Future.wait([
//         _loadTargetData(),
//         context.read<OrderProvider>().fetchOrderCounts(),
//         context.read<AttendanceProvider>().checkTodayAttendance(),
//       ]);
      
//       setState(() {
//         _isInitialized = true;
//       });
//     } catch (e) {
//       print('❌ Error initializing dashboard: $e');
//       setState(() {
//         _loadError = 'Failed to load data: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isDataLoading = false;
//       });
//     }
//   }

//   Future<void> _loadTargetData() async {
//     final empProvider = context.read<EmployeeProvider>();
//     final targetProvider = context.read<TargetProvider>();
    
//     final empId = empProvider.profile?['emp_id']?.toString();
//     if (empId != null && empId.isNotEmpty) {
//       print('🔄 Loading target data for employee: $empId');
      
//       try {
//         await targetProvider.loadTargetData(empId);
        
//         // Debug: Print loaded data
//         final targets = targetProvider.getMonthlyTargets(empId, months);
//         final achieved = targetProvider.getMonthlyAchieved(empId, months);
        
//         print('📊 === DASHBOARD DATA LOADED ===');
//         for (int i = 0; i < months.length; i++) {
//           if (targets[i] > 0 || achieved[i] > 0) {
//             print('${monthLabels[i]}: Target=${targets[i]} T, Achieved=${achieved[i]} T');
//           }
//         }
        
//       } catch (e) {
//         print('❌ Failed to load target data: $e');
//         throw e; // Re-throw to be caught by parent
//       }
//     } else {
//       throw Exception('No employee ID found. Please check your profile.');
//     }
//   }

//   Future<void> _refreshData() async {
//     if (_isRefreshing) return;
    
//     setState(() {
//       _isRefreshing = true;
//       _loadError = null;
//     });
    
//     try {
//       await Future.wait([
//         _loadTargetData(),
//         context.read<OrderProvider>().fetchOrderCounts(),
//         context.read<AttendanceProvider>().checkTodayAttendance(),
//       ]);
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Data refreshed successfully'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );
      
//       setState(() {});
//     } catch (e) {
//       print('❌ Error refreshing data: $e');
//       setState(() {
//         _loadError = 'Refresh failed: ${e.toString()}';
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Refresh failed: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isRefreshing = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final empProvider = context.watch<EmployeeProvider>();
//     final targetProvider = context.watch<TargetProvider>();

//     // Show loading screen if data is still loading
//     if (_isDataLoading) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Loading dashboard...'),
//           ],
//         ),
//       );
//     }

//     final empId = empProvider.profile?['emp_id']?.toString() ?? '';

//     // Get target and achieved data
//     final targets = targetProvider.getMonthlyTargets(empId, months);
//     final achieved = targetProvider.getMonthlyAchieved(empId, months);
    
//     // Calculate max value for scaling
//     double maxValue = 0;
//     for (var target in targets) {
//       if (target > maxValue) maxValue = target;
//     }
//     for (var achievement in achieved) {
//       if (achievement > maxValue) maxValue = achievement;
//     }
    
//     // If no data, set sensible defaults
//     if (maxValue == 0) maxValue = 100.0;
    
//     // Add padding for better visualization
//     maxValue = maxValue * 1.2;
    
//     // Calculate intervals for Y axis
//     final double interval = maxValue <= 100 ? 20.0 : (maxValue / 5).ceilToDouble();

//     // Check if we have any data to show
//     final hasTargets = targets.any((t) => t > 0);
//     final hasAchievements = achieved.any((a) => a > 0);
//     final hasData = hasTargets || hasAchievements;

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white),
//           onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
//         ),
//         title: const Text("Employee Dashboard",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//         actions: [
//           IconButton(
//             icon: _isRefreshing 
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _isRefreshing ? null : _refreshData,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refreshData,
//         child: SingleChildScrollView(
//           controller: _scrollController,
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Consumer<AttendanceProvider>(
//             builder: (context, attendanceProvider, _) => Column(
//               children: [
//                 // Attendance Card
//                 InkWell(
//                   onTap: attendanceProvider.attendanceMarkedToday
//                       ? null
//                       : () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const EmployeeAttendancePage(cameras: []),
//                             ),
//                           );
//                         },
//                   child: Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: attendanceProvider.attendanceMarkedToday
//                           ? Colors.green.shade100
//                           : Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: attendanceProvider.attendanceMarkedToday
//                                 ? Colors.green
//                                 : GlobalColors.primaryBlue,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Iconsax.calendar_1,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 attendanceProvider.attendanceMarkedToday
//                                     ? "Attendance Marked"
//                                     : "Mark Attendance",
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 15,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 attendanceProvider.attendanceMarkedToday
//                                     ? "Already marked for today"
//                                     : "Tap to mark now",
//                                 style: const TextStyle(
//                                   color: GlobalColors.textGrey,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Icon(
//                           attendanceProvider.attendanceMarkedToday
//                               ? Icons.check_circle
//                               : Icons.arrow_forward_ios,
//                           color: attendanceProvider.attendanceMarkedToday
//                               ? Colors.green
//                               : GlobalColors.primaryBlue,
//                           size: 16,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 28),
                
//                 // Orders Overview
//                 const Text(
//                   "Orders Overview",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (_) => const TotalOrdersPage()),
//                           );
//                         },
//                         borderRadius: BorderRadius.circular(16),
//                         child: _summary(
//                           "Total",
//                           context.watch<OrderProvider>().totalOrders.toString(),
//                           Iconsax.shopping_cart,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (_) => const PendingOrdersPage()),
//                           );
//                         },
//                         borderRadius: BorderRadius.circular(16),
//                         child: _summary(
//                           "Pending",
//                           context.watch<OrderProvider>().pendingOrders.toString(),
//                           Iconsax.timer,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (_) => const CompletedOrdersPage()),
//                           );
//                         },
//                         borderRadius: BorderRadius.circular(16),
//                         child: _summary(
//                           "Completed",
//                           context.watch<OrderProvider>().completedOrders.toString(),
//                           Iconsax.tick_circle,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 28),
                
//                 // Performance Chart Section
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: GlobalColors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(color: AppColors.shadowGrey, blurRadius: 12)
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             "Performance vs Target",
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                           ),
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: GlobalColors.primaryBlue.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   DateTime.now().year.toString(),
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: GlobalColors.primaryBlue,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 6),
//                       const Text(
//                         "Monthly comparison in Tons (Jan-Dec)",
//                         style: TextStyle(
//                           color: GlobalColors.textGrey,
//                           fontSize: 12,
//                         ),
//                       ),
                      
//                       // Error message
//                       if (_loadError != null)
//                         Container(
//                           margin: const EdgeInsets.only(top: 12),
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.red.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.red.shade200),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.error, color: Colors.red, size: 16),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   _loadError!,
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.red,
//                                   ),
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.refresh, size: 16),
//                                 onPressed: _initializeAndLoadData,
//                               ),
//                             ],
//                           ),
//                         ),
                      
//                       // Data status indicator
//                       if (!hasData)
//                         Container(
//                           margin: const EdgeInsets.only(top: 12),
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.blue.shade200),
//                           ),
//                           child: Column(
//                             children: [
//                               const Icon(Icons.info, color: Colors.blue, size: 32),
//                               const SizedBox(height: 8),
//                               const Text(
//                                 "No Performance Data",
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 hasTargets
//                                     ? "Complete some orders to see your achievements"
//                                     : "Ask your manager to assign targets for ${DateTime.now().year}",
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                               const SizedBox(height: 12),
//                               ElevatedButton.icon(
//                                 onPressed: _initializeAndLoadData,
//                                 icon: const Icon(Icons.refresh, size: 16),
//                                 label: const Text('Reload Data'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue,
//                                   foregroundColor: Colors.white,
//                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
                      
//                       // Current month summary - ALWAYS SHOW
//                       Padding(
//                         padding: const EdgeInsets.only(top: 12),
//                         child: Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.grey.shade200),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: [
//                               _buildCurrentMonthStat(
//                                 "Current Month",
//                                 monthLabels[DateTime.now().month - 1],
//                                 GlobalColors.primaryBlue,
//                               ),
//                               _buildCurrentMonthStat(
//                                 "Target",
//                                 "${targets[DateTime.now().month - 1].toStringAsFixed(1)} T",
//                                 Colors.grey.shade700,
//                               ),
//                               _buildCurrentMonthStat(
//                                 "Achieved",
//                                 "${achieved[DateTime.now().month - 1].toStringAsFixed(1)} T",
//                                 achieved[DateTime.now().month - 1] >= targets[DateTime.now().month - 1]
//                                     ? Colors.green
//                                     : GlobalColors.primaryBlue,
//                               ),
//                               _buildCurrentMonthStat(
//                                 targets[DateTime.now().month - 1] > 0
//                                     ? "${((achieved[DateTime.now().month - 1] / targets[DateTime.now().month - 1]) * 100).toStringAsFixed(0)}%"
//                                     : "N/A",
//                                 "Progress",
//                                 targets[DateTime.now().month - 1] > 0 && 
//                                 achieved[DateTime.now().month - 1] >= targets[DateTime.now().month - 1]
//                                     ? Colors.green
//                                     : Colors.orange,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
                      
//                       const SizedBox(height: 12),
                      
//                       // Chart Container - ALWAYS RENDER, even if empty
//                       Container(
//                         height: 320,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade300, width: 1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           children: [
//                             // Chart Title
//                             Container(
//                               padding: const EdgeInsets.symmetric(vertical: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade50,
//                                 border: Border(
//                                   bottom: BorderSide(color: Colors.grey.shade300),
//                                 ),
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   hasData 
//                                       ? "Monthly Targets vs Achievements"
//                                       : "Performance Chart",
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey.shade600,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Expanded(
//                               child: Scrollbar(
//                                 controller: _scrollController,
//                                 child: SingleChildScrollView(
//                                   scrollDirection: Axis.horizontal,
//                                   child: SizedBox(
//                                     width: 420, 
//                                     height: 290,
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(12.0),
//                                       child: hasData 
//                                           ? BarChart(
//                                               _buildBarChartData(targets, achieved, maxValue, interval),
//                                             )
//                                           : Center(
//                                               child: Column(
//                                                 mainAxisAlignment: MainAxisAlignment.center,
//                                                 children: [
//                                                   Icon(
//                                                     Icons.bar_chart,
//                                                     size: 48,
//                                                     color: Colors.grey.shade300,
//                                                   ),
//                                                   const SizedBox(height: 12),
//                                                   Text(
//                                                     "Loading performance data...",
//                                                     style: TextStyle(
//                                                       color: Colors.grey.shade400,
//                                                       fontSize: 14,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
                      
//                       // Legend - Only show if we have data
//                       if (hasData) ...[
//                         const SizedBox(height: 16),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             _buildLegendItem(Colors.grey.shade400, "Target"),
//                             const SizedBox(width: 20),
//                             _buildLegendItem(GlobalColors.primaryBlue, "Achieved"),
//                             const SizedBox(width: 20),
//                             _buildLegendItem(Colors.green, "Target Achieved"),
//                           ],
//                         ),
//                       ],
                      
//                       // Year Summary - Only show if we have data
//                       if (hasData) ...[
//                         const SizedBox(height: 16),
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.grey.shade200),
//                           ),
//                           child: Column(
//                             children: [
//                               Text(
//                                 "Year ${DateTime.now().year} Summary",
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                               const SizedBox(height: 12),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                                 children: [
//                                   _buildYearSummaryStat(
//                                     "Total Target",
//                                     "${targets.fold(0.0, (sum, element) => sum + element).toStringAsFixed(1)} T",
//                                     Colors.grey.shade700,
//                                   ),
//                                   _buildYearSummaryStat(
//                                     "Total Achieved",
//                                     "${achieved.fold(0.0, (sum, element) => sum + element).toStringAsFixed(1)} T",
//                                     GlobalColors.primaryBlue,
//                                   ),
//                                   _buildYearSummaryStat(
//                                     "Overall Progress",
//                                     targets.fold(0.0, (sum, element) => sum + element) > 0
//                                         ? "${((achieved.fold(0.0, (sum, element) => sum + element) / targets.fold(0.0, (sum, element) => sum + element)) * 100).toStringAsFixed(1)}%"
//                                         : "0%",
//                                     targets.fold(0.0, (sum, element) => sum + element) > 0 &&
//                                     (achieved.fold(0.0, (sum, element) => sum + element) / 
//                                      targets.fold(0.0, (sum, element) => sum + element)) >= 1
//                                         ? Colors.green
//                                         : Colors.orange,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
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

//   BarChartData _buildBarChartData(List<double> targets, List<double> achieved, double maxValue, double interval) {
//     return BarChartData(
//       alignment: BarChartAlignment.center,
//       groupsSpace: 12,
//       minY: 0,
//       maxY: maxValue,
//       barTouchData: BarTouchData(
//         enabled: true,
//         touchTooltipData: BarTouchTooltipData(
//           tooltipBorder: BorderSide(color: Colors.grey.shade300),
//           tooltipRoundedRadius: 8,
//           tooltipMargin: 10,
//           getTooltipItem: (group, groupIndex, rod, rodIndex) {
//             final month = monthLabels[group.x];
//             final targetVal = targets[group.x];
//             final achievedVal = achieved[group.x];
//             final progress = targetVal > 0 
//                 ? (achievedVal / targetVal) * 100 
//                 : 0;
            
//             String tooltipText = "📅 $month ${DateTime.now().year}\n";
//             tooltipText += "━━━━━━━━━━━━━━━━━━━━\n";
//             tooltipText += "🎯 Target: ${targetVal.toStringAsFixed(1)} T\n";
//             tooltipText += "📈 Achieved: ${achievedVal.toStringAsFixed(1)} T\n";
            
//             if (targetVal > 0) {
//               tooltipText += "📊 Progress: ${progress.toStringAsFixed(1)}%";
              
//               if (progress >= 100) {
//                 tooltipText += " 🎉 Target Achieved!";
//               } else if (progress >= 70) {
//                 tooltipText += " 🔥 Great Progress!";
//               } else if (progress >= 30) {
//                 tooltipText += " ⚡ Good Progress";
//               } else if (progress > 0) {
//                 tooltipText += " 📈 Getting Started";
//               }
//             } else {
//               tooltipText += "ℹ️ No target assigned";
//             }
            
//             return BarTooltipItem(
//               tooltipText,
//               const TextStyle(
//                 fontSize: 12,
//                 color: Colors.black,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.left,
//             );
//           },
//         ),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 40,
//             interval: interval,
//             getTitlesWidget: (value, meta) {
//               return Padding(
//                 padding: const EdgeInsets.only(right: 8),
//                 child: Text(
//                   "${value.toInt()} T",
//                   style: const TextStyle(
//                     fontSize: 10,
//                     color: Colors.grey,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//         rightTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//         topTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             getTitlesWidget: (value, meta) {
//               final index = value.toInt();
//               if (index >= 0 && index < monthLabels.length) {
//                 final isCurrentMonth = index == DateTime.now().month - 1;
//                 return Padding(
//                   padding: const EdgeInsets.only(top: 4),
//                   child: Text(
//                     monthLabels[index],
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: isCurrentMonth ? GlobalColors.primaryBlue : Colors.grey,
//                       fontWeight: isCurrentMonth ? FontWeight.w600 : FontWeight.w500,
//                     ),
//                   ),
//                 );
//               }
//               return const SizedBox();
//             },
//           ),
//         ),
//       ),
//       gridData: FlGridData(
//         show: true,
//         drawHorizontalLine: true,
//         drawVerticalLine: false,
//         horizontalInterval: interval,
//         getDrawingHorizontalLine: (value) {
//           return FlLine(
//             color: Colors.grey.shade200,
//             strokeWidth: 0.5,
//           );
//         },
//       ),
//       borderData: FlBorderData(
//         show: true,
//         border: Border.all(
//           color: Colors.grey.shade300,
//           width: 0.5,
//         ),
//       ),
//       barGroups: List.generate(12, (index) {
//         final target = targets[index];
//         final achievedValue = achieved[index];
//         final isTargetAchieved = target > 0 && achievedValue >= target;
        
//         return BarChartGroupData(
//           x: index,
//           groupVertically: true,
//           barRods: [
//             // Target bar (grey)
//             BarChartRodData(
//               toY: target,
//               width: 14,
//               color: Colors.grey.shade400,
//               borderRadius: BorderRadius.circular(2),
//             ),
//             // Achieved bar (blue or green if target achieved)
//             BarChartRodData(
//               toY: achievedValue,
//               width: 10,
//               color: isTargetAchieved ? Colors.green : GlobalColors.primaryBlue,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ],
//         );
//       }),
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

//   Widget _buildCurrentMonthStat(String value, String label, Color color) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w700,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 10,
//             color: Colors.grey,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildYearSummaryStat(String label, String value, Color color) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 11,
//             color: Colors.grey,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.w700,
//             color: color,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLegendItem(Color color, String text) {
//     return Row(
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(
//           text,
//           style: const TextStyle(
//             fontSize: 11,
//             color: Colors.grey,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
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
// import 'package:mega_pro/providers/emp_mar_target_provider.dart';
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


// class _DashboardHome extends StatefulWidget {
//   final GlobalKey<ScaffoldState> scaffoldKey;

//   const _DashboardHome({required this.scaffoldKey});

//   @override
//   State<_DashboardHome> createState() => __DashboardHomeState();
// }

// class __DashboardHomeState extends State<_DashboardHome> {
//   final ScrollController _scrollController = ScrollController();
//   late List<String> months;
//   late List<String> monthLabels;

//   @override
//   void initState() {
//     super.initState();
    
//     // Generate months for current year (Jan-Dec)
//     final now = DateTime.now();
//     months = List.generate(12, (index) {
//       final month = index + 1; // Months 1-12
//       return '${now.year}-${month.toString().padLeft(2, '0')}';
//     });
    
//     monthLabels = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
//                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadTargetData();
//     });
//   }

//   Future<void> _loadTargetData() async {
//     final empProvider = context.read<EmployeeProvider>();
//     final targetProvider = context.read<TargetProvider>();
    
//     final empId = empProvider.profile?['emp_id']?.toString();
//     if (empId != null && empId.isNotEmpty) {
//       await targetProvider.loadTargetData(empId);
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final empProvider = context.watch<EmployeeProvider>();
//     final targetProvider = context.watch<TargetProvider>();

//     if (empProvider.loading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     final empId = empProvider.profile?['emp_id']?.toString() ?? '';

//     // Get target and achieved data
//     final targets = targetProvider.getMonthlyTargets(empId, months);
//     final achieved = targetProvider.getMonthlyAchieved(empId, months);
    
//     // FIXED: Always use 0-100 T scale for vertical axis
//     final double maxY = 100.0;
//     final double interval = 20.0; // Fixed interval for 0-100 scale

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white),
//           onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
//         ),
//         title: const Text("Employee Dashboard",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//       ),
//       body: SingleChildScrollView(
//         controller: _scrollController,
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
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           "Performance vs Target",
//                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                         ),
//                         if (empId.isNotEmpty)
//                           IconButton(
//                             icon: Icon(Icons.refresh, 
//                                 color: GlobalColors.primaryBlue, size: 20),
//                             onPressed: _loadTargetData,
//                             tooltip: 'Refresh Targets',
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       "Monthly comparison in Tons (Jan-Dec)",
//                       style: const TextStyle(
//                         color: GlobalColors.textGrey,
//                         fontSize: 12,
//                       ),
//                     ),
                    
//                     // Current month target info
//                     if (targets.isNotEmpty)
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 8),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 12,
//                               height: 12,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade400,
//                                 borderRadius: BorderRadius.circular(2),
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               "Target: ${targets.last.toStringAsFixed(1)} T",
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                             Container(
//                               width: 12,
//                               height: 12,
//                               decoration: BoxDecoration(
//                                 color: GlobalColors.primaryBlue,
//                                 borderRadius: BorderRadius.circular(2),
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               "Achieved: ${achieved.last.toStringAsFixed(1)} T",
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: GlobalColors.primaryBlue,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
                    
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       height: 290,
//                       child: Scrollbar(
//                         controller: _scrollController,
//                         child: SingleChildScrollView(
//                           scrollDirection: Axis.horizontal,
//                           child: SizedBox(
//                             width: 400, 
//                             height: 290,
//                             child: Padding(
//                               padding: const EdgeInsets.only(right: 20),
//                               child: BarChart(
//                                 BarChartData(
//                                   alignment: BarChartAlignment.center,
//                                   groupsSpace: 12,
//                                   minY: 0,
//                                   maxY: maxY, 
//                                   barTouchData: BarTouchData(
//                                     enabled: true,
//                                     touchTooltipData: BarTouchTooltipData(
//                                       tooltipBorder: BorderSide(color: Colors.grey.shade300),
//                                       tooltipRoundedRadius: 8,
//                                       getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                                         final month = monthLabels[group.x];
//                                         final targetVal = targets[group.x];
//                                         final achievedVal = achieved[group.x];
                                        
//                                         String tooltipText = "$month\n";
//                                         tooltipText += "Target: ${targetVal.toStringAsFixed(1)} T\n";
//                                         tooltipText += "Achieved: ${achievedVal.toStringAsFixed(1)} T";
                                        
//                                         if (targetVal > 0) {
//                                           final percentage = (achievedVal / targetVal * 100);
//                                           tooltipText += "\nCompletion: ${percentage.toStringAsFixed(1)}%";
//                                         }
                                        
//                                         return BarTooltipItem(
//                                           tooltipText,
//                                           const TextStyle(
//                                             fontSize: 12,
//                                             color: Colors.black,
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                   titlesData: FlTitlesData(
//                                     show: true,
//                                     leftTitles: AxisTitles(
//                                       sideTitles: SideTitles(
//                                         showTitles: true,
//                                         reservedSize: 40,
//                                         interval: interval, // Fixed at 20
//                                         getTitlesWidget: (value, meta) {
//                                           return Padding(
//                                             padding: const EdgeInsets.only(right: 8),
//                                             child: Text(
//                                               "${value.toInt()} T",
//                                               style: const TextStyle(
//                                                 fontSize: 10,
//                                                 color: Colors.grey,
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                     rightTitles: const AxisTitles(
//                                       sideTitles: SideTitles(showTitles: false),
//                                     ),
//                                     topTitles: const AxisTitles(
//                                       sideTitles: SideTitles(showTitles: false),
//                                     ),
//                                     bottomTitles: AxisTitles(
//                                       sideTitles: SideTitles(
//                                         showTitles: true,
//                                         reservedSize: 30,
//                                         getTitlesWidget: (value, meta) {
//                                           final index = value.toInt();
//                                           if (index >= 0 && index < monthLabels.length) {
//                                             return Padding(
//                                               padding: const EdgeInsets.only(top: 4),
//                                               child: Text(
//                                                 monthLabels[index],
//                                                 style: const TextStyle(
//                                                   fontSize: 11,
//                                                   color: Colors.grey,
//                                                   fontWeight: FontWeight.w500,
//                                                 ),
//                                               ),
//                                             );
//                                           }
//                                           return const SizedBox();
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                   gridData: FlGridData(
//                                     show: true,
//                                     drawHorizontalLine: true,
//                                     drawVerticalLine: false,
//                                     horizontalInterval: interval, // Fixed at 20
//                                     getDrawingHorizontalLine: (value) {
//                                       return FlLine(
//                                         color: Colors.grey.shade200,
//                                         strokeWidth: 0.5,
//                                       );
//                                     },
//                                   ),
//                                   borderData: FlBorderData(
//                                     show: true,
//                                     border: Border.all(
//                                       color: Colors.grey.shade300,
//                                       width: 0.5,
//                                     ),
//                                   ),
//                                   barGroups: List.generate(12, (index) {
//                                     return BarChartGroupData(
//                                       x: index,
//                                       groupVertically: true,
//                                       barRods: [
//                                         BarChartRodData(
//                                           toY: targets[index] > maxY ? maxY : targets[index], // Cap at 100
//                                           width: 14,
//                                           color: Colors.grey.shade400,
//                                           borderRadius: BorderRadius.circular(2),
//                                         ),
//                                         BarChartRodData(
//                                           toY: achieved[index] > maxY ? maxY : achieved[index], // Cap at 100
//                                           width: 10,
//                                           color: GlobalColors.primaryBlue,
//                                           borderRadius: BorderRadius.circular(2),
//                                         ),
//                                       ],
//                                     );
//                                   }),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
                    
//                     // Legend
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               width: 12,
//                               height: 12,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade400,
//                                 borderRadius: BorderRadius.circular(2),
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             const Text(
//                               "Target",
//                               style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(width: 20),
//                         Row(
//                           children: [
//                             Container(
//                               width: 12,
//                               height: 12,
//                               decoration: BoxDecoration(
//                                 color: GlobalColors.primaryBlue,
//                                 borderRadius: BorderRadius.circular(2),
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             const Text(
//                               "Achieved",
//                               style: TextStyle(fontSize: 12, color: GlobalColors.primaryBlue, fontWeight: FontWeight.w500),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
                    
//                     // Summary statistics
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey.shade200),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           _buildStatCard(
//                             "Current Target",
//                             "${targets.last.toStringAsFixed(1)} T",
//                             Colors.grey.shade700,
//                           ),
//                           _buildStatCard(
//                             "Current Achieved",
//                             "${achieved.last.toStringAsFixed(1)} T",
//                             GlobalColors.primaryBlue,
//                           ),
//                           _buildStatCard(
//                             "Completion",
//                             targets.last > 0 
//                                 ? "${(achieved.last / targets.last * 100).toStringAsFixed(1)}%"
//                                 : "0%",
//                             targets.last > 0 && (achieved.last / targets.last * 100) >= 100
//                                 ? Colors.green
//                                 : Colors.orange,
//                           ),
//                         ],
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

//   Widget _buildStatCard(String title, String value, Color color) {
//     return Column(
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 11,
//             color: Colors.grey,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: color,
//           ),
//         ),
//       ],
//     );
//   }
// }








//without database connection

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



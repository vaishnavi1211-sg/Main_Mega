import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mega_pro/marketing/mar_employees.dart';
import 'package:mega_pro/marketing/mar_order.dart';
import 'package:mega_pro/marketing/mar_profile.dart';
import 'package:mega_pro/marketing/mar_reporting.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/services/mar_target_assigning_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketingManagerDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const MarketingManagerDashboard({super.key, required this.userData});

  @override
  State<MarketingManagerDashboard> createState() =>
      _MarketingManagerDashboardState();
}

class _MarketingManagerDashboardState extends State<MarketingManagerDashboard> {
  int _currentIndex = 0;
  final supabase = Supabase.instance.client;
  StreamSubscription? _targetsSubscription;
  
  // Pages for bottom navigation
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages with userData
    _pages = [
      DashboardContent(userData: widget.userData),
      const EmployeeDetailPage(),
      const CattleFeedOrderScreen(),
      const ReportingPage(),
      MarketingProfilePage(userData: widget.userData),
    ];
  }

  @override
  void dispose() {
    _targetsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex == 0) {
          return await _showExitConfirmation(context);
        } else {
          setState(() => _currentIndex = 0);
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: GlobalColors.background,
        appBar: _currentIndex == 0 
            ? _buildDashboardAppBar() 
            : _buildStandardAppBar(_currentIndex),
        body: _pages[_currentIndex],
        bottomNavigationBar: _buildBottomNavigationBar(),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
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
                  
                  Text("Are you sure you want to exit?", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800])),
                  const SizedBox(height: 8),
                  Text("Any unsaved changes may be lost", style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
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

  AppBar _buildDashboardAppBar() {
    return AppBar(
      backgroundColor: GlobalColors.primaryBlue,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Marketing Dashboard",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      //centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      
    );
  }

  AppBar _buildStandardAppBar(int index) {
    return AppBar(
      backgroundColor: GlobalColors.primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => setState(() => _currentIndex = 0),
      ),
      title: Text(_getAppBarTitle(index), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.dashboard, "Dashboard"),
              _buildNavItem(1, Icons.people_alt, "Team"),
              _buildNavItem(2, Icons.shopping_cart, "Orders"),
              _buildNavItem(3, Icons.analytics, "Reports"),
              _buildNavItem(4, Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _currentIndex == index ? GlobalColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _currentIndex == index ? GlobalColors.primaryBlue : Colors.grey[600], size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: _currentIndex == index ? FontWeight.w600 : FontWeight.normal,
              color: _currentIndex == index ? GlobalColors.primaryBlue : Colors.grey[600],
            )),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return "Marketing Dashboard";
      case 1: return "Team Management";
      case 2: return "Order Management";
      case 3: return "Reporting";
      case 4: return "My Profile";
      default: return "Marketing Dashboard";
    }
  }
}

// Dashboard Content Widget
class DashboardContent extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DashboardContent({super.key, required this.userData});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final MarketingTargetService _targetService = MarketingTargetService();
  final supabase = Supabase.instance.client;
  
  // Sales data for line chart (in Tons)
  final Map<String, List<Map<String, dynamic>>> _districtTalukaData = {
    "Kolhapur": [
      {"taluka": "Karvir", "sales": 220, "target": 250},
      {"taluka": "Panhala", "sales": 160, "target": 180},
      {"taluka": "Shirol", "sales": 140, "target": 150},
      {"taluka": "Hatkanangale", "sales": 110, "target": 120},
      {"taluka": "Kagal", "sales": 180, "target": 200},
      {"taluka": "Shahuwadi", "sales": 95, "target": 100},
      {"taluka": "Ajara", "sales": 75, "target": 90},
      {"taluka": "Gadhinglaj", "sales": 205, "target": 220},
      {"taluka": "Chandgad", "sales": 130, "target": 140},
      {"taluka": "Radhanagari", "sales": 120, "target": 130},
      {"taluka": "Jat", "sales": 90, "target": 100},
      {"taluka": "Bhudargad", "sales": 150, "target": 160},
    ],
  };

  final String _selectedDistrict = "Kolhapur";
  final Color themePrimary = GlobalColors.primaryBlue;
  
  // Target variables
  Map<String, dynamic>? _currentTargetData;
  Map<String, dynamic>? _teamPerformanceData;
  bool _isLoadingTarget = true;
  bool _isLoadingTeam = true;
  DateTime _currentMonth = DateTime.now();
  String? _managerId;
  StreamSubscription? _targetSubscription;
  StreamSubscription? _teamSubscription;
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _initializeManagerId();
  }

  @override
  void dispose() {
    _targetSubscription?.cancel();
    _teamSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeManagerId() async {
    try {
      print('=== INITIALIZING MANAGER DASHBOARD ===');
      
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        setState(() => _isLoadingTarget = false);
        return;
      }
      
      print('👤 Auth User ID: ${user.id}');
      
      // Try to get manager ID
      String? managerId;
      
      // 1. Try from userData
      if (widget.userData['id'] != null) {
        managerId = widget.userData['id'].toString();
      } else if (widget.userData['profile_id'] != null) {
        managerId = widget.userData['profile_id'].toString();
      } else if (widget.userData['emp_profile_id'] != null) {
        managerId = widget.userData['emp_profile_id'].toString();
      }
      
      // 2. Query emp_profile if not found
      if (managerId == null) {
        final profileData = await supabase
            .from('emp_profile')
            .select('id, emp_id, full_name, role')
            .eq('user_id', user.id)
            .maybeSingle();
            
        if (profileData != null && profileData['id'] != null) {
          managerId = profileData['id'].toString();
        }
      }
      
      if (managerId != null) {
        setState(() => _managerId = managerId);
        await _loadCurrentTarget(managerId);
        await _loadTeamPerformance(managerId);
        _setupRealtimeSubscriptions(managerId);
      } else {
        setState(() => _isLoadingTarget = false);
      }
      
    } catch (e) {
      print('❌ Error initializing manager ID: $e');
      setState(() => _isLoadingTarget = false);
    }
  }

  void _setupRealtimeSubscriptions(String managerId) {
    // Subscribe to manager target changes
    _targetSubscription = supabase
        .channel('manager-targets-$managerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'own_marketing_targets',
          callback: (payload) {
            if (payload.newRecord['manager_id'] == managerId) {
              _loadCurrentTarget(managerId);
            }
          },
        )
        .subscribe() as StreamSubscription?;

    // Subscribe to employee targets (for team aggregation)
    _teamSubscription = supabase
        .channel('employee-targets-$managerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'marketing_targets',
          callback: (payload) {
            _loadTeamPerformance(managerId);
          },
        )
        .subscribe() as StreamSubscription?;

    // Subscribe to orders for real-time achievement updates
    _ordersSubscription = supabase
        .channel('orders-$managerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            _loadCurrentTarget(managerId);
            _loadTeamPerformance(managerId);
          },
        )
        .subscribe() as StreamSubscription?;
  }

  Future<void> _loadCurrentTarget(String managerId) async {
    try {
      final targetData = await _targetService.getManagerTarget(
        managerId: managerId,
        month: _currentMonth,
      );

      if (targetData != null) {
        setState(() {
          _currentTargetData = targetData;
          _isLoadingTarget = false;
        });
      } else {
        setState(() {
          _currentTargetData = null;
          _isLoadingTarget = false;
        });
      }
    } catch (e) {
      print('❌ Error loading target: $e');
      setState(() => _isLoadingTarget = false);
    }
  }

  Future<void> _loadTeamPerformance(String managerId) async {
    try {
      setState(() => _isLoadingTeam = true);
      
      // Get all employees under this manager
      final employees = await supabase
          .from('emp_profile')
          .select('id, full_name, role')
          .eq('reporting_to', managerId)
          .eq('role', 'Marketing Executive');

      if (employees.isEmpty) {
        setState(() {
          _teamPerformanceData = null;
          _isLoadingTeam = false;
        });
        return;
      }

      // Get current month in string format
      final currentMonthStr = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-01';
      
      // Get targets for all employees
      final targets = await supabase
          .from('marketing_targets')
          .select('*')
          .inFilter('marketing_executive_id', employees.map((e) => e['id'].toString()).toList())
          .eq('target_month', currentMonthStr);

      // Get orders for all employees this month
      final orders = await supabase
          .from('orders')
          .select('id, amount, order_date, created_by')
          .inFilter('created_by', employees.map((e) => e['id'].toString()).toList())
          .gte('order_date', '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-01')
          .lt('order_date', 
              '${_currentMonth.month == 12 ? _currentMonth.year + 1 : _currentMonth.year}-'
              '${_currentMonth.month == 12 ? '01' : (_currentMonth.month + 1).toString().padLeft(2, '0')}-01');

      // Calculate team totals
      int totalRevenueTarget = 0;
      int totalOrderTarget = 0;
      int totalAchievedRevenue = 0;
      int totalAchievedOrders = orders.length;
      double totalProgress = 0;
      int activeEmployees = 0;

      for (var employee in employees) {
        final employeeTargets = targets.where((t) => t['marketing_executive_id'] == employee['id']).toList();
        final employeeOrders = orders.where((o) => o['created_by'] == employee['id']).toList();
        
        if (employeeTargets.isNotEmpty) {
          final target = employeeTargets.first;
          totalRevenueTarget += ((target['revenue_target'] ?? 0) as num).toInt();
          totalOrderTarget += ((target['order_target'] ?? 0) as num).toInt();
          totalAchievedRevenue += employeeOrders.fold(0, (sum, order) => sum + ((order['amount'] as int?) ?? 0));
          totalProgress += (employeeOrders.length / (target['order_target'] ?? 1)).clamp(0.0, 1.0);
          activeEmployees++;
        }
      }
      setState(() {
        _teamPerformanceData = {
          'totalRevenueTarget': totalRevenueTarget,
          'totalOrderTarget': totalOrderTarget,
          'totalAchievedRevenue': totalAchievedRevenue,
          'totalAchievedOrders': totalAchievedOrders,
          'averageProgress': activeEmployees > 0 ? totalProgress / activeEmployees : 0,
          'activeEmployees': activeEmployees,
          'totalEmployees': employees.length,
          'topPerformers': _getTopPerformers(employees, targets, orders),
        };
        _isLoadingTeam = false;
      });

    } catch (e) {
      print('❌ Error loading team performance: $e');
      setState(() => _isLoadingTeam = false);
    }
  }

  List<Map<String, dynamic>> _getTopPerformers(
    List<Map<String, dynamic>> employees,
    List<Map<String, dynamic>> targets,
    List<Map<String, dynamic>> orders,
  ) {
    final performers = <Map<String, dynamic>>[];

    for (var employee in employees) {
      final employeeTargets = targets.where((t) => t['marketing_executive_id'] == employee['id']).toList();
      final employeeOrders = orders.where((o) => o['created_by'] == employee['id']).toList();
      
      if (employeeTargets.isNotEmpty) {
        final target = employeeTargets.first;
        final achievedRevenue = employeeOrders.fold<int>(0, (sum, order) => sum + ((order['amount'] as int?) ?? 0));
        final revenueProgress = target['revenue_target'] > 0 
            ? achievedRevenue / target['revenue_target'] 
            : 0.0;
        final orderProgress = target['order_target'] > 0 
            ? employeeOrders.length / target['order_target'] 
            : 0.0;
        final overallProgress = (revenueProgress + orderProgress) / 2;

        performers.add({
          'id': employee['id'],
          'name': employee['full_name'],
          'revenueProgress': revenueProgress,
          'orderProgress': orderProgress,
          'overallProgress': overallProgress,
          'achievedRevenue': achievedRevenue,
          'achievedOrders': employeeOrders.length,
        });
      }
    }

    performers.sort((a, b) => b['overallProgress'].compareTo(a['overallProgress']));
    return performers.take(3).toList();
  }

  // Line Chart Widget
  Widget _buildChart(List<Map<String, dynamic>> talukas) {
    final chartWidth = talukas.length * 80.0;
    final chartHeight = 250.0;
    
    return SizedBox(
      height: chartHeight,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: chartWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getMaxY(talukas) / 5,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              int i = value.toInt();
                              if (i < 0 || i >= talukas.length) return const SizedBox();
                              
                              return Container(
                                width: 75,
                                margin: const EdgeInsets.only(top: 8),
                                child: Transform.rotate(
                                  angle: -0.4,
                                  child: Text(
                                    talukas[i]['taluka'].toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            interval: _getMaxY(talukas) / 5,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      minX: 0,
                      maxX: talukas.isNotEmpty ? (talukas.length - 1).toDouble() : 0,
                      minY: 0,
                      maxY: _getMaxY(talukas),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(talukas.length, (i) => 
                            FlSpot(i.toDouble(), talukas[i]['sales'].toDouble())
                          ),
                          isCurved: true,
                          color: themePrimary,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => 
                              FlDotCirclePainter(
                                radius: 3,
                                color: themePrimary,
                                strokeWidth: 1.5,
                                strokeColor: Colors.white,
                              ),
                          ),
                          belowBarData: BarAreaData(
                            show: true, 
                            color: themePrimary.withOpacity(0.08),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                themePrimary.withOpacity(0.3),
                                themePrimary.withOpacity(0.05),
                              ],
                            ),
                          ),
                        )
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              final taluka = talukas[spot.x.toInt()];
                              return LineTooltipItem(
                                '${taluka['taluka']}\n${taluka['sales']} T',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 4,
            width: 100,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> talukas) {
    if (talukas.isEmpty) return 100.0;
    
    final maxSales = talukas
        .map((e) => (e['sales'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    
    return (maxSales / 50).ceil() * 50 * 1.1;
  }

  double _getTotalSales() {
    final talukaList = _districtTalukaData[_selectedDistrict] ?? [];
    return talukaList.fold(0.0, (sum, item) => sum + (item['sales'] as num).toDouble());
  }

  Widget _buildAssignedTargetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: _isLoadingTarget
          ? _buildLoadingState()
          : _currentTargetData == null
              ? _buildNoTargetState()
              : _buildTargetState(_currentTargetData!),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const CircularProgressIndicator(color: GlobalColors.primaryBlue),
            const SizedBox(height: 16),
            Text("Loading target data...", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTargetState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Monthly Target", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange.withOpacity(0.8), Colors.orange.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  const Text("Not Assigned", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(Icons.tablet, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text("No target assigned for ${DateFormat('MMMM yyyy').format(_currentMonth)}", 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text("Contact your supervisor for target assignment", 
                style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetState(Map<String, dynamic> targetData) {
    final revenueTarget = targetData['revenue_target'] ?? 0;
    final orderTarget = targetData['order_target'] ?? 0;
    final achievedRevenue = targetData['achieved_revenue'] ?? 0;
    final achievedOrders = targetData['achieved_orders'] ?? 0;
    final revenueProgress = revenueTarget > 0 ? achievedRevenue / revenueTarget : 0.0;
    final orderProgress = orderTarget > 0 ? achievedOrders / orderTarget : 0.0;
    final revenuePercentage = (revenueProgress * 100).toInt();
    final orderPercentage = (orderProgress * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Your Monthly Target", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GlobalColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: GlobalColors.primaryBlue),
                    const SizedBox(width: 6),
                    Text(DateFormat('MMM yyyy').format(_currentMonth), 
                      style: TextStyle(color: GlobalColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Revenue Target
        _buildMetricCard(
          title: "Revenue Target",
          icon: Icons.currency_rupee,
          current: achievedRevenue,
          target: revenueTarget,
          percentage: revenuePercentage,
          prefix: "₹",
          progress: revenueProgress,
        ),
        const SizedBox(height: 16),
        
        // Orders Target
        _buildMetricCard(
          title: "Order Target",
          icon: Icons.shopping_cart,
          current: achievedOrders,
          target: orderTarget,
          percentage: orderPercentage,
          prefix: "#",
          progress: orderProgress,
        ),

        // Real-time indicator
        if (targetData['last_updated'] != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.update, size: 14, color: Colors.green[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Live Updates Active", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green[700])),
                      const SizedBox(height: 2),
                      Text("Targets update automatically", style: TextStyle(fontSize: 10, color: Colors.green[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text("LIVE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.green[700])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Last Updated
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.update, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text("Last Updated", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[600])),
              ]),
              Text(targetData['last_updated'] != null 
                  ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(targetData['last_updated']))
                  : DateFormat('dd MMM, hh:mm a').format(DateTime.now()), 
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required int current,
    required int target,
    required int percentage,
    required String prefix,
    required double progress,
  }) {
    final isCompleted = percentage >= 100;
    final remaining = target - current;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey[300]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.withOpacity(0.1) : GlobalColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: isCompleted ? Colors.green : GlobalColors.primaryBlue),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isCompleted ? Colors.green : Colors.grey[800])),
                    const SizedBox(height: 2),
                    Text(DateFormat('MMM yyyy').format(_currentMonth), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.1) : GlobalColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("$percentage%", style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, 
                  color: isCompleted ? Colors.green : GlobalColors.primaryBlue,
                )),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Current vs Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Achieved", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text("$prefix$current", style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, 
                    color: isCompleted ? Colors.green : GlobalColors.primaryBlue,
                  )),
                  const SizedBox(width: 4),
                  Text("/ $prefix$target", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ]),
              ]),
              
              // Progress Indicator
              SizedBox(
                width: 100,
                child: Column(children: [
                  Stack(children: [
                    Container(height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3))),
                    Container(
                      height: 6,
                      width: 100 * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green : GlobalColors.primaryBlue,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text("$percentage% Complete", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ]),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Status and Remaining
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Status", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(isCompleted ? "Target Achieved 🎉" : "In Progress", 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isCompleted ? Colors.green : GlobalColors.primaryBlue)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text("Remaining", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text("$prefix$remaining", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPerformanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: _isLoadingTeam
          ? Center(child: const CircularProgressIndicator(color: GlobalColors.primaryBlue))
          : _teamPerformanceData == null
              ? _buildNoTeamState()
              : _buildTeamState(_teamPerformanceData!),
    );
  }

  Widget _buildNoTeamState() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Team Performance", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text("No Team", style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Column(
            children: [
              Icon(Icons.group_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text("No team members assigned", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text("Add marketing executives to your team", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamState(Map<String, dynamic> teamData) {
    final totalRevenue = teamData['totalAchievedRevenue'] ?? 0;
    final totalOrders = teamData['totalAchievedOrders'] ?? 0;
    final avgProgress = ((teamData['averageProgress'] ?? 0) * 100).toInt();
    final activeEmployees = teamData['activeEmployees'] ?? 0;
    final totalEmployees = teamData['totalEmployees'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Team Performance", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GlobalColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group, size: 14, color: GlobalColors.primaryBlue),
                  const SizedBox(width: 6),
                  Text("$activeEmployees/$totalEmployees Active", style: TextStyle(color: GlobalColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Team Metrics
        Row(
          children: [
            Expanded(
              child: _buildTeamMetricCard(
                title: "Total Revenue",
                value: "₹${totalRevenue.toStringAsFixed(0)}",
                icon: Icons.currency_rupee,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTeamMetricCard(
                title: "Total Orders",
                value: "$totalOrders",
                icon: Icons.shopping_cart,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTeamMetricCard(
                title: "Avg. Progress",
                value: "$avgProgress%",
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTeamMetricCard(
                title: "Team Size",
                value: "$totalEmployees",
                icon: Icons.people,
                color: Colors.purple,
              ),
            ),
          ],
        ),

        // Top Performers
        if ((teamData['topPerformers'] as List).isNotEmpty) ...[
          const SizedBox(height: 20),
          Text("Top Performers", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          const SizedBox(height: 12),
          Column(
            children: List.generate((teamData['topPerformers'] as List).length, (index) {
              final performer = (teamData['topPerformers'] as List)[index];
              final progress = (performer['overallProgress'] * 100).toInt();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getRankColor(index),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(performer['name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text("${performer['achievedOrders']} orders • ₹${performer['achievedRevenue']}", 
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getProgressColor(progress),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text("$progress%", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],

        // Real-time indicator
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.sync, size: 14, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Team performance updates in real-time", 
                  style: TextStyle(fontSize: 12, color: Colors.blue[700])),
              ),
              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue[600]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, 
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0: return Colors.amber[700]!;
      case 1: return Colors.grey[500]!;
      case 2: return Colors.orange[700]!;
      default: return Colors.blue;
    }
  }

  Color _getProgressColor(int progress) {
    if (progress >= 90) return Colors.green;
    if (progress >= 70) return Colors.blue;
    if (progress >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final talukaList = _districtTalukaData[_selectedDistrict] ?? [];

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              

              // Total Sales Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[600]!,
                      Colors.blue[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total District Sales",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${_getTotalSales().toInt()} T",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Across ${talukaList.length} Talukas",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sales Trend Chart
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sales Trend by Taluka",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: GlobalColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: GlobalColors.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedDistrict,
                                style: TextStyle(
                                  color: GlobalColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    talukaList.isNotEmpty
                        ? _buildChart(talukaList)
                        : SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bar_chart,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No Sales Data Available",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swipe_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Swipe horizontally to view all talukas",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Assigned Target Card
              _buildAssignedTargetCard(),
              
              // Team Performance Card
              _buildTeamPerformanceCard(),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_managerId != null) {
                          setState(() {
                            _isLoadingTarget = true;
                            _isLoadingTeam = true;
                          });
                          _loadCurrentTarget(_managerId!);
                          _loadTeamPerformance(_managerId!);
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Refresh All"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to team management
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployeeDetailPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.group_add),
                      label: const Text("Manage Team"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: GlobalColors.primaryBlue),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Information Card
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Real-time Updates", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                          const SizedBox(height: 2),
                          Text("Targets and team performance update automatically", 
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}






// import 'package:flutter/material.dart';
// import 'package:mega_pro/marketing/mar_employees.dart';
// import 'package:mega_pro/marketing/mar_order.dart';
// import 'package:mega_pro/marketing/mar_profile.dart';
// import 'package:mega_pro/marketing/mar_reporting.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/models/mar_manager_model.dart';
// import 'package:mega_pro/services/mar_target_assigning_services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class MarketingManagerDashboard extends StatefulWidget {
//   final Map<String, dynamic> userData;
  
//   const MarketingManagerDashboard({super.key, required this.userData});

//   @override
//   State<MarketingManagerDashboard> createState() =>
//       _MarketingManagerDashboardState();
// }

// class _MarketingManagerDashboardState extends State<MarketingManagerDashboard> {
//   int _currentIndex = 0;
//   final supabase = Supabase.instance.client;
  
//   // Pages for bottom navigation
//   late final List<Widget> _pages;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize pages with userData
//     _pages = [
//       DashboardContent(userData: widget.userData),
//       const EmployeeDetailPage(),
//       const CattleFeedOrderScreen(),
//       const ReportingPage(),
//       MarketingProfilePage(userData: widget.userData),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: _currentIndex == 0 
//           ? _buildDashboardAppBar() 
//           : _buildStandardAppBar(_currentIndex),
//       body: _pages[_currentIndex],
//       bottomNavigationBar: _buildBottomNavigationBar(),
//     );
//   }

//   AppBar _buildDashboardAppBar() {
//     return AppBar(
//       backgroundColor: GlobalColors.primaryBlue,
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Marketing Dashboard",
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               color: Colors.white,
//               fontSize: 18,
//             ),
//           ),
          
//         ],
//       ),
//       centerTitle: false,
//       iconTheme: const IconThemeData(color: Colors.white),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.notifications_none),
//           onPressed: () {},
//           tooltip: 'Notifications',
//         ),
//         const SizedBox(width: 8),
//       ],
//     );
//   }

//   AppBar _buildStandardAppBar(int index) {
//     return AppBar(
//       backgroundColor: GlobalColors.primaryBlue,
//       title: Text(
//         _getAppBarTitle(index),
//         style: GoogleFonts.poppins(
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//         ),
//       ),
//      // centerTitle: true,
//       iconTheme: const IconThemeData(color: Colors.white),
//     );
//   }

//   Widget _buildBottomNavigationBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         top: false,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildNavItem(0, Icons.dashboard, "Dashboard"),
//               _buildNavItem(1, Icons.people_alt, "Team"),
//               _buildNavItem(2, Icons.shopping_cart, "Orders"),
//               _buildNavItem(3, Icons.analytics, "Reports"),
//               _buildNavItem(4, Icons.person, "Profile"),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(int index, IconData icon, String label) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _currentIndex = index;
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: _currentIndex == index
//               ? GlobalColors.primaryBlue.withOpacity(0.1)
//               : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: _currentIndex == index
//                   ? GlobalColors.primaryBlue
//                   : Colors.grey[600],
//               size: 22,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: _currentIndex == index
//                     ? FontWeight.w600
//                     : FontWeight.normal,
//                 color: _currentIndex == index
//                     ? GlobalColors.primaryBlue
//                     : Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getAppBarTitle(int index) {
//     switch (index) {
//       case 0:
//         return "Marketing Dashboard";
//       case 1:
//         return "Team Management";
//       case 2:
//         return "Order Management";
//       case 3:
//         return "Reporting";
//       case 4:
//         return "My Profile";
//       default:
//         return "Marketing Dashboard";
//     }
//   }
// }

// // Dashboard Content Widget
// class DashboardContent extends StatefulWidget {
//   final Map<String, dynamic> userData;
  
//   const DashboardContent({super.key, required this.userData});

//   @override
//   State<DashboardContent> createState() => _DashboardContentState();
// }

// class _DashboardContentState extends State<DashboardContent> {
//   final MarketingTargetService _targetService = MarketingTargetService();
//   final supabase = Supabase.instance.client;
  
//   // Sales data in Tons (T)
//   final Map<String, List<Map<String, dynamic>>> _districtTalukaData = {
//     "Kolhapur": [
//       {"taluka": "Karvir", "sales": 220, "target": 250},
//       {"taluka": "Panhala", "sales": 160, "target": 180},
//       {"taluka": "Shirol", "sales": 140, "target": 150},
//       {"taluka": "Hatkanangale", "sales": 110, "target": 120},
//       {"taluka": "Kagal", "sales": 180, "target": 200},
//       {"taluka": "Shahuwadi", "sales": 95, "target": 100},
//       {"taluka": "Ajara", "sales": 75, "target": 90},
//       {"taluka": "Gadhinglaj", "sales": 205, "target": 220},
//       {"taluka": "Chandgad", "sales": 130, "target": 140},
//       {"taluka": "Radhanagari", "sales": 120, "target": 130},
//       {"taluka": "Jat", "sales": 90, "target": 100},
//       {"taluka": "Bhudargad", "sales": 150, "target": 160},
//     ],
//   };

//   final String _selectedDistrict = "Kolhapur";
//   final Color themePrimary = GlobalColors.primaryBlue;
  
//   // Target variables
//   MarketingTarget? _currentTarget;
//   bool _isLoadingTarget = true;
//   DateTime _currentMonth = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _initializeManagerId();
//   }

//   Future<void> _initializeManagerId() async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         debugPrint('❌ No user logged in');
//         setState(() => _isLoadingTarget = false);
//         return;
//       }

//       String? managerId;
      
//       if (widget.userData['profile_id'] != null) {
//         managerId = widget.userData['profile_id'].toString();
//       }
//       else if (widget.userData['id'] != null) {
//         managerId = widget.userData['id'].toString();
//       }
//       else {
//         final profileData = await supabase
//             .from('emp_profile')
//             .select('id')
//             .eq('user_id', user.id)
//             .single()
//             .catchError((e) => null);
            
//         if (profileData['id'] != null) {
//           managerId = profileData['id'].toString();
//         }
//       }

//       if (managerId != null) {
//         await _loadCurrentTarget(managerId);
//       } else {
//         debugPrint('❌ Could not find manager ID');
//         setState(() => _isLoadingTarget = false);
//       }
//     } catch (e) {
//       debugPrint('❌ Error initializing manager ID: $e');
//       setState(() => _isLoadingTarget = false);
//     }
//   }

//   Future<void> _loadCurrentTarget(String managerId) async {
//     try {
//       final target = await _targetService.getManagerTarget(
//         managerId: managerId,
//         month: _currentMonth,
//       );

//       setState(() {
//         _currentTarget = target;
//         _isLoadingTarget = false;
//       });
//     } catch (e) {
//       debugPrint('❌ Error loading target: $e');
//       setState(() => _isLoadingTarget = false);
//     }
//   }

//   Widget _buildChart(List<Map<String, dynamic>> talukas) {
//     final chartWidth = talukas.length * 80.0;
//     final chartHeight = 250.0;
    
//     return SizedBox(
//       height: chartHeight,
//       child: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               physics: const BouncingScrollPhysics(),
//               child: SizedBox(
//                 width: chartWidth,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//                   child: LineChart(
//                     LineChartData(
//                       gridData: FlGridData(
//                         show: true,
//                         drawHorizontalLine: true,
//                         drawVerticalLine: false,
//                         horizontalInterval: _getMaxY(talukas) / 5,
//                         getDrawingHorizontalLine: (value) => FlLine(
//                           color: Colors.grey.withOpacity(0.2),
//                           strokeWidth: 1,
//                         ),
//                       ),
//                       titlesData: FlTitlesData(
//                         show: true,
//                         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                         bottomTitles: AxisTitles(
//                           sideTitles: SideTitles(
//                             showTitles: true,
//                             reservedSize: 40,
//                             interval: 1,
//                             getTitlesWidget: (value, meta) {
//                               int i = value.toInt();
//                               if (i < 0 || i >= talukas.length) return const SizedBox();
                              
//                               return Container(
//                                 width: 75,
//                                 margin: const EdgeInsets.only(top: 8),
//                                 child: Transform.rotate(
//                                   angle: -0.4,
//                                   child: Text(
//                                     talukas[i]['taluka'].toString(),
//                                     style: const TextStyle(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                     textAlign: TextAlign.center,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         leftTitles: AxisTitles(
//                           sideTitles: SideTitles(
//                             showTitles: true,
//                             reservedSize: 35,
//                             interval: _getMaxY(talukas) / 5,
//                             getTitlesWidget: (value, meta) {
//                               return Padding(
//                                 padding: const EdgeInsets.only(right: 8),
//                                 child: Text(
//                                   value.toInt().toString(),
//                                   style: const TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ),
//                       borderData: FlBorderData(
//                         show: true,
//                         border: Border.all(
//                           color: Colors.grey.withOpacity(0.3),
//                           width: 1,
//                         ),
//                       ),
//                       minX: 0,
//                       maxX: talukas.isNotEmpty ? (talukas.length - 1).toDouble() : 0,
//                       minY: 0,
//                       maxY: _getMaxY(talukas),
//                       lineBarsData: [
//                         LineChartBarData(
//                           spots: List.generate(talukas.length, (i) => 
//                             FlSpot(i.toDouble(), talukas[i]['sales'].toDouble())
//                           ),
//                           isCurved: true,
//                           color: themePrimary,
//                           barWidth: 3,
//                           dotData: FlDotData(
//                             show: true,
//                             getDotPainter: (spot, percent, barData, index) => 
//                               FlDotCirclePainter(
//                                 radius: 3,
//                                 color: themePrimary,
//                                 strokeWidth: 1.5,
//                                 strokeColor: Colors.white,
//                               ),
//                           ),
//                           belowBarData: BarAreaData(
//                             show: true, 
//                             color: themePrimary.withOpacity(0.08),
//                             gradient: LinearGradient(
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                               colors: [
//                                 themePrimary.withOpacity(0.3),
//                                 themePrimary.withOpacity(0.05),
//                               ],
//                             ),
//                           ),
//                         )
//                       ],
//                       lineTouchData: LineTouchData(
//                         touchTooltipData: LineTouchTooltipData(
//                           getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
//                           getTooltipItems: (List<LineBarSpot> touchedSpots) {
//                             return touchedSpots.map((spot) {
//                               final taluka = talukas[spot.x.toInt()];
//                               return LineTooltipItem(
//                                 '${taluka['taluka']}\n${taluka['sales']} T',
//                                 const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                 ),
//                               );
//                             }).toList();
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Container(
//             height: 4,
//             width: 100,
//             margin: const EdgeInsets.only(bottom: 8),
//             decoration: BoxDecoration(
//               color: Colors.grey.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   double _getMaxY(List<Map<String, dynamic>> talukas) {
//     if (talukas.isEmpty) return 100.0;
    
//     final maxSales = talukas
//         .map((e) => (e['sales'] as num).toDouble())
//         .reduce((a, b) => a > b ? a : b);
    
//     return (maxSales / 50).ceil() * 50 * 1.1;
//   }

//   // FIXED: Simplified Assigned Target Card
//   Widget _buildAssignedTargetCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 15,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: _isLoadingTarget
//           ? _buildLoadingState()
//           : _currentTarget == null
//               ? _buildNoTargetState()
//               : _buildTargetState(_currentTarget!),
//     );
//   }

//   Widget _buildLoadingState() {
//     return const Center(
//       child: Padding(
//         padding: EdgeInsets.symmetric(vertical: 32),
//         child: CircularProgressIndicator(
//           color: GlobalColors.primaryBlue,
//         ),
//       ),
//     );
//   }

//   Widget _buildNoTargetState() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               "Current Month Target",
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[800],
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.orange.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.info_outline,
//                     size: 12,
//                     color: Colors.orange[700],
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     "Not Assigned",
//                     style: TextStyle(
//                       color: Colors.orange[700],
//                       fontWeight: FontWeight.w600,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),
//         Column(
//           children: [
//             Icon(
//               Icons.tablet,
//               size: 48,
//               color: Colors.grey[400],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               "No target assigned for ${DateFormat('MMMM yyyy').format(_currentMonth)}",
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Contact your supervisor for target assignment",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[500],
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildTargetState(MarketingTarget target) {
//     final revenueProgress = target.revenueTarget > 0 
//         ? target.achievedRevenue / target.revenueTarget 
//         : 0.0;
    
//     final orderProgress = target.orderTarget > 0 
//         ? target.achievedOrders / target.orderTarget 
//         : 0.0;

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               "Current Month Target",
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[800],
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: GlobalColors.primaryBlue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.calendar_today,
//                     size: 14,
//                     color: GlobalColors.primaryBlue,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     DateFormat('MMM yyyy').format(_currentMonth),
//                     style: TextStyle(
//                       color: GlobalColors.primaryBlue,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // Target Metrics
//         Row(
//           children: [
//             Expanded(
//               child: _buildCompactTargetMetric(
//                 title: "Revenue",
//                 current: target.achievedRevenue,
//                 target: target.revenueTarget,
//                 prefix: "₹",
//                 progress: revenueProgress,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _buildCompactTargetMetric(
//                 title: "Orders",
//                 current: target.achievedOrders,
//                 target: target.orderTarget,
//                 prefix: "#",
//                 progress: orderProgress,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // Progress Indicators
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildCompactProgressBar(
//               label: "Revenue Progress",
//               value: revenueProgress,
//               current: target.achievedRevenue,
//               total: target.revenueTarget,
//             ),
//             const SizedBox(height: 12),
//             _buildCompactProgressBar(
//               label: "Orders Progress",
//               value: orderProgress,
//               current: target.achievedOrders,
//               total: target.orderTarget,
//             ),
//           ],
//         ),

//         // Remarks (if any)
//         if (target.remarks != null && target.remarks!.isNotEmpty) ...[
//           const SizedBox(height: 16),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.grey[200]!),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.message,
//                       size: 14,
//                       color: Colors.grey[600],
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       "Remarks",
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   target.remarks!,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ],

//         // Last Updated
//         const SizedBox(height: 12),
//         Align(
//           alignment: Alignment.centerRight,
//           child: Text(
//             "Updated: ${DateFormat('dd MMM, hh:mm a').format(DateTime.now())}",
//             style: TextStyle(
//               fontSize: 10,
//               color: Colors.grey[500],
//               fontStyle: FontStyle.italic,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCompactTargetMetric({
//     required String title,
//     required int current,
//     required int target,
//     required String prefix,
//     required double progress,
//   }) {
//     final percentage = (progress * 100).toInt();
//     Color getColor() {
//       if (progress >= 1.0) return Colors.green;
//       if (progress >= 0.75) return Colors.orange;
//       return Colors.red;
//     }

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: getColor().withOpacity(0.05),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: getColor().withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 6),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Flexible(
//                 child: Text(
//                   "$prefix${current.toStringAsFixed(0)}",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: getColor(),
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 "/$prefix$target",
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Container(
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(2),
//             ),
//             child: FractionallySizedBox(
//               widthFactor: progress.clamp(0.0, 1.0),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: getColor(),
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "$percentage%",
//                 style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.w600,
//                   color: getColor(),
//                 ),
//               ),
//               Text(
//                 "${target - current} left",
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: Colors.grey[500],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCompactProgressBar({
//     required String label,
//     required double value,
//     required int current,
//     required int total,
//   }) {
//     final percentage = (value * 100).toInt();
//     final color = value >= 1.0 ? Colors.green : 
//                   value >= 0.75 ? Colors.orange : Colors.red;
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[700],
//               ),
//             ),
//             Text(
//               "$percentage%",
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Container(
//           height: 6,
//           decoration: BoxDecoration(
//             color: Colors.grey[200],
//             borderRadius: BorderRadius.circular(3),
//           ),
//           child: FractionallySizedBox(
//             widthFactor: value.clamp(0.0, 1.0),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: BorderRadius.circular(3),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               "$current of $total",
//               style: TextStyle(
//                 fontSize: 10,
//                 color: Colors.grey[500],
//               ),
//             ),
//             Text(
//               "${total - current} remaining",
//               style: TextStyle(
//                 fontSize: 10,
//                 color: Colors.grey[500],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   double _getTotalSales() {
//     final talukaList = _districtTalukaData[_selectedDistrict] ?? [];
//     return talukaList.fold(0.0, (sum, item) => sum + (item['sales'] as num).toDouble());
//   }

//   @override
//   Widget build(BuildContext context) {
//     final talukaList = _districtTalukaData[_selectedDistrict] ?? [];

//     return SafeArea(
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             physics: const BouncingScrollPhysics(),
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 minHeight: constraints.maxHeight,
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Total Sales Card
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: [
//                             GlobalColors.primaryBlue,
//                             Colors.blue[700]!,
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: GlobalColors.primaryBlue.withOpacity(0.3),
//                             blurRadius: 15,
//                             offset: const Offset(0, 5),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "Total Sales",
//                                   style: GoogleFonts.poppins(
//                                     color: Colors.white.withOpacity(0.9),
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   "${_getTotalSales().toInt()} T",
//                                   style: GoogleFonts.poppins(
//                                     color: Colors.white,
//                                     fontSize: 28,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   "Across ${talukaList.length} Talukas",
//                                   style: GoogleFonts.poppins(
//                                     color: Colors.white.withOpacity(0.8),
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             width: 80,
//                             height: 80,
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: const Icon(
//                               Icons.trending_up,
//                               color: Colors.white,
//                               size: 40,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),

//                     // Sales Trend Chart
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.08),
//                             blurRadius: 15,
//                             offset: const Offset(0, 6),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Sales Trend by Taluka",
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.grey[800],
//                                 ),
//                               ),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                                 decoration: BoxDecoration(
//                                   color: GlobalColors.primaryBlue.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(20),
//                                 ),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Icon(
//                                       Icons.location_on,
//                                       size: 14,
//                                       color: GlobalColors.primaryBlue,
//                                     ),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       _selectedDistrict,
//                                       style: TextStyle(
//                                         color: GlobalColors.primaryBlue,
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
                          
//                           talukaList.isNotEmpty
//                               ? _buildChart(talukaList)
//                               : SizedBox(
//                                   height: 200,
//                                   child: Center(
//                                     child: Column(
//                                       mainAxisAlignment: MainAxisAlignment.center,
//                                       children: [
//                                         Icon(
//                                           Icons.bar_chart,
//                                           size: 48,
//                                           color: Colors.grey[400],
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Text(
//                                           "No Sales Data Available",
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color: Colors.grey[600],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
                          
//                           Padding(
//                             padding: const EdgeInsets.only(top: 8),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Icons.swipe_rounded,
//                                   size: 14,
//                                   color: Colors.grey[500],
//                                 ),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   "Swipe horizontally to view all talukas",
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     color: Colors.grey[600],
//                                     fontStyle: FontStyle.italic,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),

//                     // Assigned Target Card
//                     _buildAssignedTargetCard(),
                    
//                     // Add bottom padding to prevent overflow
//                     SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:mega_pro/marketing/mar_employees.dart';
// import 'package:mega_pro/marketing/mar_order.dart';
// import 'package:mega_pro/marketing/mar_profile.dart';
// import 'package:mega_pro/marketing/mar_reporting.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fl_chart/fl_chart.dart';

// class MarketingManagerDashboard extends StatefulWidget {
//   const MarketingManagerDashboard({super.key, required Map userData});

//   @override
//   State<MarketingManagerDashboard> createState() =>
//       _MarketingManagerDashboardState();
// }

// class _MarketingManagerDashboardState extends State<MarketingManagerDashboard> {
//   int _currentIndex = 0;
  
//   // Pages for bottom navigation
//   final List<Widget> _pages = [
//     const DashboardContent(),
//     const EmployeeDetailPage(),
//     const CattleFeedOrderScreen(),
//     const ReportingPage(),
//     const MarketingProfilePage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: _currentIndex == 0 
//           ? _buildDashboardAppBar() 
//           : _buildStandardAppBar(_currentIndex),
//       body: _pages[_currentIndex],
//       bottomNavigationBar: _buildBottomNavigationBar(),
//     );
//   }

//   AppBar _buildDashboardAppBar() {
//     return AppBar(
//       backgroundColor: GlobalColors.primaryBlue,
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Marketing Dashboard",
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               color: Colors.white,
//               fontSize: 18,
//             ),
//           ),
//         ],
//       ),
//       centerTitle: false,
//       iconTheme: const IconThemeData(color: Colors.white),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.notifications_none),
//           onPressed: () {},
//           tooltip: 'Notifications',
//         ),
//         const SizedBox(width: 8),
//       ],
//     );
//   }

//   AppBar _buildStandardAppBar(int index) {
//     return AppBar(
//       backgroundColor: GlobalColors.primaryBlue,
//       title: Text(
//         _getAppBarTitle(index),
//         style: GoogleFonts.poppins(
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//         ),
//       ),
//       centerTitle: true,
//       iconTheme: const IconThemeData(color: Colors.white),
//     );
//   }

//   Widget _buildBottomNavigationBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildNavItem(0, Icons.dashboard, "Dashboard"),
//               _buildNavItem(1, Icons.people_alt, "Team"),
//               _buildNavItem(2, Icons.shopping_cart, "Orders"),
//               _buildNavItem(3, Icons.analytics, "Reports"),
//               _buildNavItem(4, Icons.person, "Profile"),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(int index, IconData icon, String label) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _currentIndex = index;
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: _currentIndex == index
//               ? GlobalColors.primaryBlue.withOpacity(0.1)
//               : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: _currentIndex == index
//                   ? GlobalColors.primaryBlue
//                   : Colors.grey[600],
//               size: 22,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: _currentIndex == index
//                     ? FontWeight.w600
//                     : FontWeight.normal,
//                 color: _currentIndex == index
//                     ? GlobalColors.primaryBlue
//                     : Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getAppBarTitle(int index) {
//     switch (index) {
//       case 0:
//         return "Marketing Dashboard";
//       case 1:
//         return "Team Management";
//       case 2:
//         return "Order Management";
//       case 3:
//         return "Reporting";
//       case 4:
//         return "My Profile";
//       default:
//         return "Marketing Dashboard";
//     }
//   }
// }

// // Dashboard Content Widget
// class DashboardContent extends StatefulWidget {
//   const DashboardContent({super.key});

//   @override
//   State<DashboardContent> createState() => _DashboardContentState();
// }

// class _DashboardContentState extends State<DashboardContent> {
//   // Sales data in Tons (T)
//   final Map<String, List<Map<String, dynamic>>> _districtTalukaData = {
//     "Kolhapur": [
//       {"taluka": "Karvir", "sales": 220, "target": 250},
//       {"taluka": "Panhala", "sales": 160, "target": 180},
//       {"taluka": "Shirol", "sales": 140, "target": 150},
//       {"taluka": "Hatkanangale", "sales": 110, "target": 120},
//       {"taluka": "Kagal", "sales": 180, "target": 200},
//       {"taluka": "Shahuwadi", "sales": 95, "target": 100},
//       {"taluka": "Ajara", "sales": 75, "target": 90},
//       {"taluka": "Gadhinglaj", "sales": 205, "target": 220},
//       {"taluka": "Chandgad", "sales": 130, "target": 140},
//       {"taluka": "Radhanagari", "sales": 120, "target": 130},
//       {"taluka": "Jat", "sales": 90, "target": 100},
//       {"taluka": "Bhudargad", "sales": 150, "target": 160},
//     ],
//   };

//   final String _selectedDistrict = "Kolhapur";
//   final Color themePrimary = GlobalColors.primaryBlue;

//   double _getTotalSales() {
//     final talukas = _districtTalukaData[_selectedDistrict] ?? [];
//     return talukas.fold<double>(0, (sum, e) => sum + (e['sales'] as num).toDouble());
//   }

//   Widget _buildChart(List<Map<String, dynamic>> talukas) {
//     // Calculate required width based on number of data points
//     final chartWidth = talukas.length * 80.0;
//     final chartHeight = 250.0;
    
//     return Container(
//       height: chartHeight,
//       decoration: BoxDecoration(
//         color: Colors.white, 
//         borderRadius: BorderRadius.circular(20)
//       ),
//       child: Column(
//         children: [
//           // Chart Area with horizontal scroll
//           Expanded(
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               physics: const BouncingScrollPhysics(),
//               child: Container(
//                 width: chartWidth,
//                 padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//                 child: LineChart(
//                   LineChartData(
//                     gridData: FlGridData(
//                       show: true,
//                       drawHorizontalLine: true,
//                       drawVerticalLine: false,
//                       horizontalInterval: _getMaxY(talukas) / 5,
//                       getDrawingHorizontalLine: (value) => FlLine(
//                         color: Colors.grey.withOpacity(0.2),
//                         strokeWidth: 1,
//                       ),
//                     ),
//                     titlesData: FlTitlesData(
//                       show: true,
//                       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                       rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 40,
//                           interval: 1,
//                           getTitlesWidget: (value, meta) {
//                             int i = value.toInt();
//                             if (i < 0 || i >= talukas.length) return const SizedBox();
                            
//                             return Container(
//                               width: 75,
//                               margin: const EdgeInsets.only(top: 8),
//                               child: Transform.rotate(
//                                 angle: -0.4, // Rotate labels slightly for better fit
//                                 child: Text(
//                                   talukas[i]['taluka'].toString(),
//                                   style: const TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       leftTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 35,
//                           interval: _getMaxY(talukas) / 5,
//                           getTitlesWidget: (value, meta) {
//                             return Padding(
//                               padding: const EdgeInsets.only(right: 8),
//                               child: Text(
//                                 value.toInt().toString(),
//                                 style: const TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                     borderData: FlBorderData(
//                       show: true,
//                       border: Border.all(
//                         color: Colors.grey.withOpacity(0.3),
//                         width: 1,
//                       ),
//                     ),
//                     minX: 0,
//                     maxX: talukas.length > 0 ? (talukas.length - 1).toDouble() : 0,
//                     minY: 0,
//                     maxY: _getMaxY(talukas),
//                     lineBarsData: [
//                       LineChartBarData(
//                         spots: List.generate(talukas.length, (i) => 
//                           FlSpot(i.toDouble(), talukas[i]['sales'].toDouble())
//                         ),
//                         isCurved: true,
//                         color: themePrimary,
//                         barWidth: 3,
//                         dotData: FlDotData(
//                           show: true,
//                           getDotPainter: (spot, percent, barData, index) => 
//                             FlDotCirclePainter(
//                               radius: 3,
//                               color: themePrimary,
//                               strokeWidth: 1.5,
//                               strokeColor: Colors.white,
//                             ),
//                         ),
//                         belowBarData: BarAreaData(
//                           show: true, 
//                           color: themePrimary.withOpacity(0.08),
//                           gradient: LinearGradient(
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                             colors: [
//                               themePrimary.withOpacity(0.3),
//                               themePrimary.withOpacity(0.05),
//                             ],
//                           ),
//                         ),
//                       )
//                     ],
//                     lineTouchData: LineTouchData(
//                       touchTooltipData: LineTouchTooltipData(
//                         getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
//                         getTooltipItems: (List<LineBarSpot> touchedSpots) {
//                           return touchedSpots.map((spot) {
//                             final taluka = talukas[spot.x.toInt()];
//                             return LineTooltipItem(
//                               '${taluka['taluka']}\n${taluka['sales']} T',
//                               const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 12,
//                               ),
//                             );
//                           }).toList();
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
          
//           // Scroll indicator
//           Container(
//             height: 4,
//             width: 100,
//             margin: const EdgeInsets.only(bottom: 8),
//             decoration: BoxDecoration(
//               color: Colors.grey.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   double _getMaxY(List<Map<String, dynamic>> talukas) {
//     if (talukas.isEmpty) return 100.0;
    
//     final maxSales = talukas
//         .map((e) => (e['sales'] as num).toDouble())
//         .reduce((a, b) => a > b ? a : b);
    
//     // Round up to nearest 50
//     return (maxSales / 50).ceil() * 50 * 1.1;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final talukaList = _districtTalukaData[_selectedDistrict] ?? [];

//     return SafeArea(
//       child: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Performance Overview Card
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       GlobalColors.primaryBlue,
//                       Colors.blue[700]!,
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: GlobalColors.primaryBlue.withOpacity(0.3),
//                       blurRadius: 15,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Total Sales",
//                             style: GoogleFonts.poppins(
//                               color: Colors.white.withOpacity(0.9),
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             "${_getTotalSales().toInt()} T",
//                             style: GoogleFonts.poppins(
//                               color: Colors.white,
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             "Across ${talukaList.length} Talukas",
//                             style: GoogleFonts.poppins(
//                               color: Colors.white.withOpacity(0.8),
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Icon(
//                         Icons.trending_up,
//                         color: Colors.white,
//                         size: 40,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Chart Container
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.08),
//                       blurRadius: 15,
//                       offset: const Offset(0, 6),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Chart Header
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "Sales Trend by Taluka",
//                           style: GoogleFonts.poppins(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: GlobalColors.primaryBlue.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.location_on,
//                                 size: 14,
//                                 color: GlobalColors.primaryBlue,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 _selectedDistrict,
//                                 style: TextStyle(
//                                   color: GlobalColors.primaryBlue,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Chart Legend
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: [
//                         _buildLegendItem(GlobalColors.primaryBlue, "Sales Trend"),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     // Line Chart
//                     talukaList.isNotEmpty
//                         ? _buildChart(talukaList)
//                         : SizedBox(
//                             height: 300,
//                             child: Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.bar_chart,
//                                     size: 48,
//                                     color: Colors.grey[400],
//                                   ),
//                                   const SizedBox(height: 12),
//                                   Text(
//                                     "No Sales Data Available",
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
                    
//                     // Chart Explanation
//                     Padding(
//                       padding: const EdgeInsets.only(top: 16),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.swipe_rounded,
//                             size: 14,
//                             color: Colors.grey[500],
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             "Swipe horizontally to view all talukas",
//                             style: TextStyle(
//                               fontSize: 11,
//                               color: Colors.grey[600],
//                               fontStyle: FontStyle.italic,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLegendItem(Color color, String text) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
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
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[700],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
// }







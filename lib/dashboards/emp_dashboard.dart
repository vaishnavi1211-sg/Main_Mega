import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EmployeeDashboard({super.key, required this.userData});

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
    
    _pages = [
      _DashboardHome(scaffoldKey: _scaffoldKey),
      const CattleFeedOrderScreen(),
      const RecentOrdersScreen(),
      const EmployeeProfileDashboard(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Load employee profile when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final empProvider = context.read<EmployeeProvider>();
      if (empProvider.profile == null) {
        empProvider.loadProfile();
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        } else {
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: GlobalColors.primaryBlue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _drawerTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color iconColor = GlobalColors.primaryBlue,
    Color textColor = GlobalColors.black,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    
    // Get the current employee profile
    final emp = employeeProvider.profile;
    
    // Extract user role and name from profile
    final userName = emp?['full_name']?.toString() ?? 'Loading...';
    final userRole = emp?['position']?.toString() ?? 
                     emp?['role']?.toString() ?? 
                     'Employee';
    final userDistrict = emp?['district']?.toString() ?? 'Not Assigned';
    
    // Determine role-based menu items
    final bool isAdmin = userRole.toLowerCase().contains('admin');
    
    print('👤 Drawer User: $userName, Role: $userRole');

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            decoration: const BoxDecoration(
              color: GlobalColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      backgroundImage: emp?['profile_image'] != null
                          ? NetworkImage(emp!['profile_image'])
                          : null,
                      child: emp?['profile_image'] == null
                          ? Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'E',
                              style: TextStyle(
                                color: GlobalColors.primaryBlue,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              userRole,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 10,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  userDistrict,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Current Date & Time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Attendance Section (for all users)
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    'ATTENDANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (!attendanceProvider.attendanceMarkedToday)
                  _drawerTile(
                    Iconsax.calendar_1, 
                    "Mark Attendance", 
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmployeeAttendancePage(cameras: []),
                        ),
                      );
                    },
                    iconColor: GlobalColors.primaryBlue,
                  ),
                _drawerTile(
                  Icons.calendar_month, 
                  "Attendance History", 
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AttendanceHistoryPage()),
                    );
                  },
                ),

                const Divider(height: 20),

                // Orders Section
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    'ORDERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                _drawerTile(
                  Iconsax.receipt_item, 
                  "All Orders", 
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TotalOrdersPage()),
                    );
                  },
                ),
                _drawerTile(
                  Iconsax.timer, 
                  "Pending Orders", 
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PendingOrdersPage()),
                    );
                  },
                ),
                _drawerTile(
                  Iconsax.tick_circle, 
                  "Completed Orders", 
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CompletedOrdersPage()),
                    );
                  },
                ),

                

                // Admin Section (only for admins)
                if (isAdmin) ...[
                  const Divider(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _drawerTile(
                    Icons.settings, 
                    "Settings", 
                    () {
                      Navigator.pop(context);
                      _showComingSoon(context, 'Settings');
                    },
                  ),
                  _drawerTile(
                    Icons.admin_panel_settings, 
                    "User Management", 
                    () {
                      Navigator.pop(context);
                      _showComingSoon(context, 'User Management');
                    },
                  ),
                ],

                const Divider(height: 20),

                // Profile Section (for all users)
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                _drawerTile(
                  Iconsax.user, 
                  "My Profile", 
                  () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedIndex = 3;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Logout button
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: _drawerTile(
              Iconsax.logout, 
              "Logout", 
              () async {
                // Confirm logout
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  // Sign out from Supabase
                  await Supabase.instance.client.auth.signOut();
                  // Clear providers
                  context.read<EmployeeProvider>().clearProfile();
                  context.read<AttendanceProvider>().resetAttendance();
                  // Navigate to login screen
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  }
                }
              }, 
              iconColor: Colors.red,
              textColor: Colors.red,
            ),
          ),
        ],
      ),
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
  bool _isDataLoading = true;
  
  // Store data locally
  List<double> _targets = List.filled(12, 0.0);
  List<double> _achieved = List.filled(12, 0.0);
  
  // Store employee info
  String? _employeeDistrict;
  String? _employeeId;
  
  // Add listeners for real-time updates
  RealtimeChannel? _ordersChannel;
  Timer? _pollingTimer;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    months = List.generate(
      12,
      (i) => '${now.year}-${(i + 1).toString().padLeft(2, '0')}',
    );

    monthLabels = const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    // Load data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadData();
    });
  }

  @override
  void dispose() {
    // Clean up real-time channel
    _ordersChannel?.unsubscribe();
    _pollingTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAndLoadData() async {
    print('🔄 Initializing and loading dashboard data...');
    
    setState(() {
      _isDataLoading = true;
      _loadError = null;
    });

    try {
      // Load employee profile first
      final empProvider = context.read<EmployeeProvider>();
      if (empProvider.profile == null) {
        print('📝 Loading employee profile...');
        await empProvider.loadProfile();
      }

      // Get employee ID
      final profile = empProvider.profile;
      if (profile == null) {
        throw Exception('Employee profile not loaded');
      }

      // Extract employee ID
      _employeeId = profile['emp_id']?.toString() ??
                     profile['employee_id']?.toString() ??
                     profile['id']?.toString() ??
                     profile['user_id']?.toString();

      print('👤 Extracted Employee ID: $_employeeId');
      
      if (_employeeId == null || _employeeId!.isEmpty) {
        throw Exception('No employee ID found in profile');
      }

      // Get employee district
      await _getEmployeeDistrict(_employeeId!);

      // Load target data
      print('🎯 Loading target data...');
      await _loadTargetData(_employeeId!);

      // Load completed orders data from provider (ONLY completed orders)
      print('📦 Loading COMPLETED orders data from provider for employee $_employeeId...');
      await _loadCompletedOrdersFromProvider(_employeeId!);

      // Set up real-time subscriptions for completed orders only
      _setupRealtimeSubscriptions(_employeeId!);

      // Load attendance
      print('📅 Checking attendance...');
      await context.read<AttendanceProvider>().checkTodayAttendance();

      print('✅ Dashboard data loaded successfully!');

    } catch (e) {
      print('❌ Error initializing dashboard: $e');
      setState(() {
        _loadError = 'Failed to load data: ${e.toString().split('\n').first}';
      });
    } finally {
      setState(() {
        _isDataLoading = false;
      });
    }
  }

  Future<void> _loadCompletedOrdersFromProvider(String empId) async {
    try {
      final orderProvider = context.read<OrderProvider>();
      final now = DateTime.now();
      
      // Use the provider's method to get monthly completed orders
      // This method already filters by employee_id AND status = 'completed'
      final monthlyCompleted = await orderProvider.getMonthlyCompletedOrders(now.year);
      
      setState(() {
        _achieved = List.from(monthlyCompleted); // Update achieved from completed orders only
      });

      print('📦 COMPLETED orders by month from provider for employee $empId: $_achieved');
      
      // Print monthly summary for debugging
      for (int i = 0; i < months.length; i++) {
        final target = _targets[i];
        final achieved = _achieved[i];
        if (target > 0 || achieved > 0) {
          final progress = target > 0 ? (achieved / target) * 100 : (achieved > 0 ? double.infinity : 0);
          print('${monthLabels[i]}: Target=${target}T, Completed=${achieved}T, Progress=${progress.isFinite ? progress.toStringAsFixed(1) : '∞'}%');
        }
      }
    } catch (e) {
      print('❌ Error loading completed orders from provider: $e');
    }
  }

  void _setupRealtimeSubscriptions(String empId) {
    try {
      final supabase = Supabase.instance.client;
      
      // Create a channel for real-time updates
      _ordersChannel = supabase.channel('dashboard_orders_channel_$empId');
      
      // Listen for changes in the orders table
      _ordersChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'emp_mar_orders',
            callback: (payload) {
              print('🔄 Real-time update received for orders table');
              print('📊 Update type: ${payload.eventType}');
              
              // Check if this update is relevant to our employee and involves completed status
              final newRecord = payload.newRecord;
              final oldRecord = payload.oldRecord;
              
              bool shouldRefresh = false;
              
              // For INSERT events
              if (payload.eventType == 'INSERT') {
                final orderEmployeeId = newRecord['employee_id']?.toString();
                final orderStatus = newRecord['status']?.toString();
                
                // Only refresh if it's a completed order for this employee
                if (orderEmployeeId == empId && orderStatus == 'completed') {
                  shouldRefresh = true;
                  print('✅ New COMPLETED order detected for employee $empId - refreshing data');
                }
              }
              // For UPDATE events
              else if (payload.eventType == 'UPDATE') {
                final orderEmployeeId = newRecord['employee_id']?.toString();
                final newStatus = newRecord['status']?.toString();
                final oldStatus = oldRecord['status']?.toString();
                
                // Refresh if status changed TO completed for this employee
                if (orderEmployeeId == empId && 
                    newStatus == 'completed' && 
                    oldStatus != 'completed') {
                  shouldRefresh = true;
                  print('✅ Order marked as COMPLETED for employee $empId - refreshing data');
                }
                // Also refresh if status changed FROM completed (order no longer counts)
                else if (orderEmployeeId == empId && 
                         oldStatus == 'completed' && 
                         newStatus != 'completed') {
                  shouldRefresh = true;
                  print('✅ Order removed from COMPLETED for employee $empId - refreshing data');
                }
              }
              // For DELETE events
              else if (payload.eventType == 'DELETE') {
                final orderEmployeeId = oldRecord['employee_id']?.toString();
                final orderStatus = oldRecord['status']?.toString();
                
                // Refresh if a completed order was deleted
                if (orderEmployeeId == empId && orderStatus == 'completed') {
                  shouldRefresh = true;
                  print('✅ COMPLETED order deleted for employee $empId - refreshing data');
                }
              }
              
              if (shouldRefresh) {
                // Debounce refresh to avoid multiple rapid updates
                _debouncedRefresh(empId);
              }
            },
          )
          .subscribe(
            (status, [error]) {
              if (status == 'SUBSCRIBED') {
                print('✅ Successfully subscribed to real-time updates for employee $empId');
              } else if (status == 'CHANNEL_ERROR') {
                print('❌ Channel error: $error');
                // Fallback to polling
                _setupPollingFallback(empId);
              } else if (status == 'TIMED_OUT') {
                print('⚠️ Channel timed out');
                _setupPollingFallback(empId);
              }
            },
          );
      
    } catch (e) {
      print('❌ Error setting up real-time: $e');
      print('⚠️ Falling back to polling');
      _setupPollingFallback(empId);
    }
  }

  void _debouncedRefresh(String empId) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Set new timer
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _refreshCompletedOrdersData(empId);
    });
  }

  void _setupPollingFallback(String empId) {
    print('🔄 Setting up polling fallback (every 30 seconds) for employee $empId...');
    
    // Cancel existing timer
    _pollingTimer?.cancel();
    
    // Set up new polling timer
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isDataLoading && !_isRefreshing) {
        print('🔄 Polling for completed orders updates...');
        _refreshCompletedOrdersData(empId);
      }
    });
  }

  Future<void> _refreshCompletedOrdersData(String empId) async {
    if (_isRefreshing) return;
    
    print('🔄 Refreshing COMPLETED orders data in real-time for employee $empId...');
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // First, refresh order counts in provider (this updates all order counts)
      await context.read<OrderProvider>().fetchOrderCounts();
      
      // Then reload monthly completed orders (this specifically gets completed orders)
      await _loadCompletedOrdersFromProvider(empId);
      
      print('✅ Completed orders data refreshed successfully');
      
    } catch (e) {
      print('❌ Error refreshing completed orders data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _getEmployeeDistrict(String empId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Query employee profile to get district
      final response = await supabase
          .from('emp_profiles')
          .select('district, assigned_district, location, area')
          .eq('employee_id', empId)
          .maybeSingle();
      
      if (response != null) {
        _employeeDistrict = response['district'] ?? 
                           response['assigned_district'] ?? 
                           response['location'] ??
                           response['area'];
        print('📍 Employee District: $_employeeDistrict');
      } else {
        print('⚠️ No profile found for employee');
      }
    } catch (e) {
      print('❌ Error getting employee district: $e');
    }
  }

  Future<void> _loadTargetData(String empId) async {
    final targetProvider = context.read<TargetProvider>();
    
    print('🎯 Loading target data for employee ID: $empId');

    try {
      await targetProvider.loadTargetData(empId);

      // Get and store target data locally
      final targets = targetProvider.getMonthlyTargets(empId, months);
      
      // Store locally
      setState(() {
        _targets = targets;
      });

      print('📊 Target data loaded: $_targets');
      
    } catch (e) {
      print('❌ Failed to load target data: $e');
      setState(() {
        _targets = List.filled(12, 0.0);
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    print('🔄 Manual refresh triggered...');
    
    setState(() {
      _isRefreshing = true;
      _loadError = null;
    });

    try {
      final empProvider = context.read<EmployeeProvider>();
      
      // Reload profile first
      await empProvider.loadProfile();
      
      // Get employee ID
      final profile = empProvider.profile;
      if (profile == null) {
        throw Exception('Employee profile not loaded');
      }

      String? empId = profile['emp_id']?.toString() ??
                     profile['employee_id']?.toString() ??
                     profile['id']?.toString() ??
                     profile['user_id']?.toString();

      if (empId == null || empId.isEmpty) {
        throw Exception('No employee ID found');
      }

      // Get fresh district info
      await _getEmployeeDistrict(empId);
      
      // Refresh order provider (this will fetch latest counts and orders)
      await context.read<OrderProvider>().refresh();
      
      // Load all data - ensuring completed orders are fetched
      await Future.wait([
        _loadTargetData(empId),
        _loadCompletedOrdersFromProvider(empId),
        context.read<AttendanceProvider>().checkTodayAttendance(),
      ]);

      print('✅ Data refreshed successfully!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      print('❌ Error refreshing data: $e');
      setState(() {
        _loadError = 'Refresh failed: ${e.toString().split('\n').first}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Refresh failed: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current month index
    final currentMonthIndex = DateTime.now().month - 1;
    final currentTarget = _targets[currentMonthIndex];
    final currentAchieved = _achieved[currentMonthIndex];
    final currentProgress = currentTarget > 0 
        ? (currentAchieved / currentTarget) * 100 
        : (currentAchieved > 0 ? double.infinity : 0);
    final isTargetAchieved = currentTarget > 0 && currentAchieved >= currentTarget;

    // Show loading screen if data is still loading initially
    if (_isDataLoading) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(GlobalColors.primaryBlue),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading dashboard...',
                style: TextStyle(
                  color: GlobalColors.primaryBlue,
                  fontSize: 16,
                ),
              ),
              if (_employeeDistrict != null) ...[
                const SizedBox(height: 10),
                Text(
                  'District: $_employeeDistrict',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
              if (_loadError != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      );
    }

    // Check if we have data to show
    final hasData = _targets.any((t) => t > 0) || _achieved.any((a) => a > 0);
    
    // Calculate max value for chart - ensure at least 200 for proper Y-axis display
    double maxValue = 0;
    if (hasData) {
      for (var target in _targets) {
        if (target > maxValue) maxValue = target;
      }
      for (var achievement in _achieved) {
        if (achievement > maxValue) maxValue = achievement;
      }
      // Add 20% padding but ensure minimum of 200
      maxValue = (maxValue * 1.2).ceilToDouble();
      if (maxValue < 200) maxValue = 200;
    } else {
      maxValue = 200.0; // Default max of 200 when no data
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
        color: GlobalColors.primaryBlue,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Consumer2<AttendanceProvider, OrderProvider>(
            builder: (context, attendanceProvider, orderProvider, _) => Column(
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

                // Orders Overview with real-time counts
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
                          orderProvider.totalOrders.toString(),
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
                          orderProvider.pendingOrders.toString(),
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
                          orderProvider.completedOrders.toString(),
                          Iconsax.tick_circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Current Month Progress
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                          Text(
                            "Current Month Progress",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: GlobalColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              monthLabels[currentMonthIndex],
                              style: TextStyle(
                                fontSize: 12,
                                color: GlobalColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Progress section - Using ONLY completed orders for achieved
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Target: ${currentTarget.toStringAsFixed(1)} T",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: currentTarget > 0 ? Colors.grey : Colors.orange,
                                  fontWeight: currentTarget > 0 ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Completed: ${currentAchieved.toStringAsFixed(1)} T",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: GlobalColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Stack(
                              children: [
                                Container(
                                  height: 10,
                                  color: Colors.grey.shade200,
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: 10,
                                  width: MediaQuery.of(context).size.width * 
                                      (currentTarget > 0 
                                          ? (currentAchieved / currentTarget).clamp(0.0, 1.0)
                                          : (currentAchieved > 0 ? 1.0 : 0.0)),
                                  decoration: BoxDecoration(
                                    color: isTargetAchieved ? Colors.green : GlobalColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentProgress.isInfinite 
                                    ? "No Target Set" 
                                    : currentProgress > 1000 
                                        ? ">1000%" 
                                        : "${currentProgress.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isTargetAchieved
                                      ? Colors.green
                                      : GlobalColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isTargetAchieved)
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Target Achieved! ",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              else if (currentTarget > 0 && currentAchieved > 0)
                                Text(
                                  "${(currentTarget - currentAchieved).toStringAsFixed(1)} T remaining",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else if (currentAchieved > 0 && currentTarget == 0)
                                const Text(
                                  "No target set",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: GlobalColors.primaryBlue.withOpacity(0.1),
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

                      const SizedBox(height: 12),

                      // IMPROVED Chart Container with better UI
                      Container(
                        height: 340,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Chart Header with improved styling
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    hasData
                                        ? "Monthly Targets vs Completed Orders "
                                        : "Performance Chart",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Scrollable chart area
                            Expanded(
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                thickness: 6,
                                radius: const Radius.circular(10),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _scrollController,
                                  child: Container(
                                    width: 800,
                                    height: 280,
                                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                                    child: BarChart(
                                      _buildSideBySideBarChartData(
                                        maxValue,
                                        hasData,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Horizontal scroll indicator
                            Container(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chevron_left,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Scroll horizontally',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // FIXED Legend with better styling - now visible
                      if (hasData) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(Colors.grey.shade400, "Target"),
                              const SizedBox(width: 20),
                              _buildLegendItem(GlobalColors.primaryBlue, "Completed"),
                              const SizedBox(width: 20),
                              _buildLegendItem(Colors.green, "Target Achieved"),
                            ],
                          ),
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
                                    "Total Completed",
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
                                        : _achieved.fold(0.0, (sum, element) => sum + element) > 0
                                            ? "100%+"
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

  // IMPROVED SIDE-BY-SIDE BAR CHART with better UI - FIXED VERSION
  BarChartData _buildSideBySideBarChartData(
    double maxValue,
    bool hasData,
  ) {
    // Force a fixed max value of at least 200 to show 0-200 range
    final double chartMaxValue = maxValue < 200 ? 200 : maxValue;
    
    // Fixed interval of 20 units for cleaner look
    final double interval = 20.0;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      groupsSpace: 24,
      maxY: chartMaxValue,
      minY: 0,
      baselineY: 0,
      
      // Improved bar styling
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String title;
            Color textColor;
            if (rodIndex == 0) {
              title = 'Target';
              textColor = Colors.grey.shade300;
            } else {
              title = 'Completed';
              textColor = Colors.white;
            }
            return BarTooltipItem(
              '$title\n${rod.toY.toStringAsFixed(1)} T',
              TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
      
      // Enhanced titles styling
      titlesData: FlTitlesData(
        show: true,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            interval: interval,
            getTitlesWidget: (value, meta) {
              // Only show multiples of 20
              if (value % 20 == 0 && value <= chartMaxValue) {
                return Container(
                  padding: const EdgeInsets.only(right: 8),
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${value.toInt()}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }
              return const SizedBox();
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
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < monthLabels.length) {
                final isCurrentMonth = index == DateTime.now().month - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: isCurrentMonth
                        ? BoxDecoration(
                            color: GlobalColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          )
                        : null,
                    child: Text(
                      monthLabels[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrentMonth
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isCurrentMonth
                            ? GlobalColors.primaryBlue
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      
      // Improved grid styling
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 0.8,
            dashArray: [5, 3],
          );
        },
      ),
      
      // Enhanced border styling
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          top: BorderSide(color: Colors.grey.shade100, width: 0),
          right: BorderSide(color: Colors.grey.shade100, width: 0),
        ),
      ),
      
      // FIXED bar groups - both bars properly displayed
      barGroups: List.generate(12, (index) {
        final target = _targets[index];
        final achievedValue = _achieved[index];
        final isTargetAchieved = target > 0 && achievedValue >= target;

        return BarChartGroupData(
          x: index,
          barRods: [
            // Target bar (grey) - LEFT SIDE
            BarChartRodData(
              toY: target,
              width: 14,
              color: Colors.grey.shade400,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            // Completed bar (blue or green) - RIGHT SIDE
            BarChartRodData(
              toY: achievedValue,
              width: 14,
              color: isTargetAchieved ? Colors.green : GlobalColors.primaryBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
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
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}



















// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:iconsax_flutter/iconsax_flutter.dart';
// import 'package:intl/intl.dart';
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
// import 'package:supabase_flutter/supabase_flutter.dart';

// class EmployeeDashboard extends StatefulWidget {
//   final Map<String, dynamic> userData;

//   const EmployeeDashboard({super.key, required this.userData});

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
    
//     _pages = [
//       _DashboardHome(scaffoldKey: _scaffoldKey),
//       const CattleFeedOrderScreen(),
//       const RecentOrdersScreen(),
//       const EmployeeProfileDashboard(),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Load employee profile when dashboard opens
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final empProvider = context.read<EmployeeProvider>();
//       if (empProvider.profile == null) {
//         empProvider.loadProfile();
//       }
//     });

//     return WillPopScope(
//       onWillPop: () async {
//         if (_selectedIndex != 0) {
//           setState(() {
//             _selectedIndex = 0;
//           });
//           return false;
//         } else {
//           bool? shouldExit = await showDialog<bool>(
//             context: context,
//             builder: (context) => _buildExitDialog(context),
//           );
//           return shouldExit ?? false;
//         }
//       },
//       child: Scaffold(
//         key: _scaffoldKey,
//         backgroundColor: AppColors.scaffoldBg,
//         drawer: _buildDrawer(context),
//         body: IndexedStack(
//           index: _selectedIndex,
//           children: _pages,
//         ),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           selectedItemColor: GlobalColors.primaryBlue,
//           unselectedItemColor: GlobalColors.textGrey,
//           type: BottomNavigationBarType.fixed,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
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
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       backgroundColor: Colors.transparent,
//       content: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 20,
//               spreadRadius: 2,
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [GlobalColors.primaryBlue, Colors.blue[700]!],
//                 ),
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: Row(
//                 children: [                  
//                   Expanded(
//                     child: Text(
//                       "Exit App?",
//                       style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   Text("Are you sure you want to exit?", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800])),
//                   const SizedBox(height: 28),
//                 ],
//               ),
//             ),
            
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
//                 border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () => Navigator.of(context).pop(false),
//                       label: const Text("Cancel"),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.grey[700],
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         side: BorderSide(color: Colors.grey[400]!),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => Navigator.of(context).pop(true),
//                       label: const Text("Exit"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: GlobalColors.primaryBlue,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         elevation: 0,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Drawer _buildDrawer(BuildContext context) {
//     final employeeProvider = context.watch<EmployeeProvider>();
//     final attendanceProvider = context.watch<AttendanceProvider>();
    
//     // Get the current employee profile
//     final emp = employeeProvider.profile;
//     final currentUser = Supabase.instance.client.auth.currentUser;
    
//     return Drawer(
//       child: Column(
//         children: [
//           // Drawer Header
//           Container(
//             padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
//             decoration: const BoxDecoration(
//               color: GlobalColors.primaryBlue,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(18),
//                 bottomRight: Radius.circular(18),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 28,
//                       backgroundColor: Colors.white,
//                       child: Icon(
//                         Icons.person,
//                         color: GlobalColors.primaryBlue,
//                         size: 30,
//                       ),
//                     ),
//                     const SizedBox(width: 14),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             emp?['full_name'] ?? 'Loading...',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             emp?['position'] ?? 'Employee',
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             currentUser?.email ?? 'No email',
//                             style: const TextStyle(
//                               color: Colors.white60,
//                               fontSize: 10,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 // Current Date & Time
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         DateFormat('dd MMM yyyy').format(DateTime.now()),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                         ),
//                       ),
//                       Text(
//                         DateFormat('hh:mm a').format(DateTime.now()),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           Expanded(
//             child: ListView(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               children: [
//                 // Only show "Mark Attendance" if NOT already marked today
//                 if (!attendanceProvider.attendanceMarkedToday)
//                   _drawerTile(Iconsax.calendar_1, "Mark Attendance", () {
//                     Navigator.pop(context);
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const EmployeeAttendancePage(cameras: []),
//                       ),
//                     );
//                   }),
                
//                 _drawerTile(Icons.calendar_month, "Attendance History", () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const AttendanceHistoryPage()),
//                   );
//                 }),
//                 _drawerTile(Iconsax.receipt_item, "Total Orders", () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const TotalOrdersPage()),
//                   );
//                 }),
//                 _drawerTile(Iconsax.timer, "Pending Orders", () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const PendingOrdersPage()),
//                   );
//                 }),
//                 _drawerTile(Iconsax.tick_circle, "Completed Orders", () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const CompletedOrdersPage()),
//                   );
//                 }),
                
//                 // Profile navigation
//                 _drawerTile(Iconsax.user, "My Profile", () {
//                   Navigator.pop(context);
//                   setState(() {
//                     _selectedIndex = 3;
//                   });
//                 }),
//               ],
//             ),
//           ),
          
//           // Logout button
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: _drawerTile(Iconsax.logout, "Logout", () async {
//               // Confirm logout
//               final confirmed = await showDialog<bool>(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   title: const Text('Logout'),
//                   content: const Text('Are you sure you want to logout?'),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context, false),
//                       child: const Text('Cancel'),
//                     ),
//                     TextButton(
//                       onPressed: () => Navigator.pop(context, true),
//                       child: const Text('Logout', style: TextStyle(color: Colors.red)),
//                     ),
//                   ],
//                 ),
//               );
              
//               if (confirmed == true) {
//                 // Sign out from Supabase
//                 await Supabase.instance.client.auth.signOut();
//                 // Clear providers
//                 context.read<EmployeeProvider>().clearProfile();
//                 context.read<AttendanceProvider>().resetAttendance();
//                 // Navigate to login screen
//                 Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
//               }
//             }, danger: true),
//           ),
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
//         color: danger ? Colors.red : GlobalColors.primaryBlue,
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: danger ? Colors.red : GlobalColors.black,
//           fontWeight: FontWeight.w500,
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
//   bool _isDataLoading = true;
  
//   // Store data locally
//   List<double> _targets = List.filled(12, 0.0);
//   List<double> _achieved = List.filled(12, 0.0);
//   List<double> _completedOrders = List.filled(12, 0.0);
  
//   // Store district info
//   String? _employeeDistrict;
  
//   // Add listeners for real-time updates
//   RealtimeChannel? _ordersChannel;
//   Timer? _pollingTimer;

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

//   @override
//   void dispose() {
//     // Clean up real-time channel
//     _ordersChannel?.unsubscribe();
//     _pollingTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _initializeAndLoadData() async {
//     print('🔄 Initializing and loading dashboard data...');
    
//     setState(() {
//       _isDataLoading = true;
//       _loadError = null;
//     });

//     try {
//       // Load employee profile first
//       final empProvider = context.read<EmployeeProvider>();
//       if (empProvider.profile == null) {
//         print('📝 Loading employee profile...');
//         await empProvider.loadProfile();
//       }

//       // Get employee ID
//       final profile = empProvider.profile;
//       if (profile == null) {
//         throw Exception('Employee profile not loaded');
//       }

//       // Extract employee ID
//       String? empId = profile['emp_id']?.toString() ??
//                      profile['employee_id']?.toString() ??
//                      profile['id']?.toString() ??
//                      profile['user_id']?.toString();

//       print('👤 Extracted Employee ID: $empId');
      
//       if (empId == null || empId.isEmpty) {
//         throw Exception('No employee ID found in profile');
//       }

//       // Load target data
//       print('🎯 Loading target data...');
//       await _loadTargetData(empId);

//       // Get employee district first
//       await _getEmployeeDistrict(empId);

//       // Load completed orders data from district
//       print('📦 Loading completed orders data from district: $_employeeDistrict');
//       await _loadCompletedOrdersData(empId);

//       // Set up real-time subscriptions
//       _setupRealtimeSubscriptions(empId);

//       // Load attendance
//       print('📅 Checking attendance...');
//       await context.read<AttendanceProvider>().checkTodayAttendance();

//       print('✅ Dashboard data loaded successfully!');

//     } catch (e) {
//       print('❌ Error initializing dashboard: $e');
//       setState(() {
//         _loadError = 'Failed to load data: ${e.toString().split('\n').first}';
//       });
//     } finally {
//       setState(() {
//         _isDataLoading = false;
//       });
//     }
//   }

//   void _setupRealtimeSubscriptions(String empId) {
//     try {
//       final supabase = Supabase.instance.client;
      
//       // Create a channel for real-time updates
//       _ordersChannel = supabase.channel('dashboard_orders_channel_$empId');
      
//       // Listen for changes in the orders table
//       _ordersChannel!
//           .onPostgresChanges(
//             event: PostgresChangeEvent.all,
//             schema: 'public',
//             table: 'emp_mar_orders',
//             callback: (payload) {
//               print('🔄 Real-time update received for orders table');
//               print('📊 Update type: ${payload.eventType}');
//               print('📊 New record: ${payload.newRecord}');
//               print('📊 Old record: ${payload.oldRecord}');
              
//               // Check if this update is relevant to our employee/district
//               final newRecord = payload.newRecord;
//               final oldRecord = payload.oldRecord;
              
//               bool shouldRefresh = false;
              
//               // For INSERT events
//               if (payload.eventType == 'INSERT') {
//                 final orderDistrict = newRecord['district'] ?? newRecord['assigned_district'];
//                 final orderStatus = newRecord['status'];
                
//                 if (orderStatus == 'completed' && 
//                     (orderDistrict == _employeeDistrict || 
//                      newRecord['employee_id'] == empId)) {
//                   shouldRefresh = true;
//                   print('✅ Relevant INSERT detected - refreshing data');
//                 }
//               }
//               // For UPDATE events
//               else if (payload.eventType == 'UPDATE') {
//                 final newDistrict = newRecord['district'] ?? newRecord['assigned_district'];
//                 final oldDistrict = oldRecord['district'] ?? oldRecord['assigned_district'];
//                 final newStatus = newRecord['status'];
//                 final oldStatus = oldRecord['status'];
                
//                 // Refresh if status changed to completed or district changed
//                 if ((newStatus == 'completed' && oldStatus != 'completed') ||
//                     (newDistrict == _employeeDistrict && oldDistrict != _employeeDistrict) ||
//                     (newRecord['employee_id'] == empId)) {
//                   shouldRefresh = true;
//                   print('✅ Relevant UPDATE detected - refreshing data');
//                 }
//               }
//               // For DELETE events
//               else if (payload.eventType == 'DELETE') {
//                 final deletedDistrict = oldRecord['district'] ?? oldRecord['assigned_district'];
                
//                 if (deletedDistrict == _employeeDistrict || 
//                     oldRecord['employee_id'] == empId) {
//                   shouldRefresh = true;
//                   print('✅ Relevant DELETE detected - refreshing data');
//                 }
//               }
              
//               if (shouldRefresh) {
//                 // Debounce refresh to avoid multiple rapid updates
//                 _debouncedRefresh(empId);
//               }
//             },
//           )
//           .subscribe(
//             (status, [error]) {
//               if (status == 'SUBSCRIBED') {
//                 print('✅ Successfully subscribed to real-time updates');
//               } else if (status == 'CHANNEL_ERROR') {
//                 print('❌ Channel error: $error');
//                 // Fallback to polling
//                 _setupPollingFallback(empId);
//               } else if (status == 'TIMED_OUT') {
//                 print('⚠️ Channel timed out');
//                 _setupPollingFallback(empId);
//               }
//             },
//           );
      
//     } catch (e) {
//       print('❌ Error setting up real-time: $e');
//       print('⚠️ Falling back to polling');
//       _setupPollingFallback(empId);
//     }
//   }

//   Timer? _debounceTimer;
//   void _debouncedRefresh(String empId) {
//     // Cancel previous timer
//     _debounceTimer?.cancel();
    
//     // Set new timer
//     _debounceTimer = Timer(const Duration(seconds: 1), () {
//       _refreshOrdersData(empId);
//     });
//   }

//   void _setupPollingFallback(String empId) {
//     print('🔄 Setting up polling fallback (every 30 seconds)...');
    
//     // Cancel existing timer
//     _pollingTimer?.cancel();
    
//     // Set up new polling timer
//     _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (!_isDataLoading && !_isRefreshing) {
//         print('🔄 Polling for updates...');
//         _refreshOrdersData(empId);
//       }
//     });
//   }

//   Future<void> _refreshOrdersData(String empId) async {
//     if (_isRefreshing) return;
    
//     print('🔄 Refreshing orders data in real-time...');
//     await _loadCompletedOrdersData(empId);
    
//     // Show a subtle notification
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Data updated at ${DateFormat('hh:mm:ss a').format(DateTime.now())}'),
//         duration: const Duration(seconds: 2),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   Future<void> _getEmployeeDistrict(String empId) async {
//     try {
//       final supabase = Supabase.instance.client;
      
//       // Query employee profile to get district
//       final response = await supabase
//           .from('emp_profiles')
//           .select('district, assigned_district, location, area')
//           .eq('employee_id', empId)
//           .maybeSingle();
      
//       if (response != null) {
//         _employeeDistrict = response['district'] ?? 
//                            response['assigned_district'] ?? 
//                            response['location'] ??
//                            response['area'];
//         print('📍 Employee District: $_employeeDistrict');
//       } else {
//         print('⚠️ No profile found for employee');
//       }
//     } catch (e) {
//       print('❌ Error getting employee district: $e');
//     }
//   }

//   Future<void> _loadTargetData(String empId) async {
//     final targetProvider = context.read<TargetProvider>();
    
//     print('🎯 Loading target data for employee ID: $empId');

//     try {
//       await targetProvider.loadTargetData(empId);

//       // Get and store target data locally
//       final targets = targetProvider.getMonthlyTargets(empId, months);
      
//       // Store locally - initialize achieved as 0 for now
//       setState(() {
//         _targets = targets;
//         // Don't reset achieved here - it will be updated from orders
//       });

//       print('📊 Target data loaded:');
//       print('Targets: $_targets');
      
//     } catch (e) {
//       print('❌ Failed to load target data: $e');
//       setState(() {
//         _targets = List.filled(12, 0.0);
//       });
//     }
//   }

//   Future<void> _loadCompletedOrdersData(String empId) async {
//     try {
//       print('📦 Loading completed orders for employee ID: $empId');
      
//       final supabase = Supabase.instance.client;
//       final now = DateTime.now();
      
//       List<dynamic> orders;
      
//       if (_employeeDistrict == null || _employeeDistrict!.isEmpty) {
//         print('⚠️ No district found, fetching all orders for employee');
        
//         // Fallback: fetch all completed orders for employee
//         orders = await supabase
//             .from('emp_mar_orders')
//             .select('id, employee_id, bags, status, created_at, total_price, district')
//             .eq('employee_id', empId)
//             .eq('status', 'completed')
//             .gte('created_at', '${now.year}-01-01')
//             .lte('created_at', '${now.year}-12-31')
//             .order('created_at', ascending: true);
//       } else {
//         // Fetch completed orders from employee's district
//         print('🔍 Fetching orders from district: $_employeeDistrict');
        
//         orders = await supabase
//             .from('emp_mar_orders')
//             .select('id, employee_id, bags, status, created_at, total_price, district, assigned_district')
//             .or('district.eq.$_employeeDistrict,assigned_district.eq.$_employeeDistrict')
//             .eq('status', 'completed')
//             .gte('created_at', '${now.year}-01-01')
//             .lte('created_at', '${now.year}-12-31')
//             .order('created_at', ascending: true);
//       }
      
//       print('📦 Found ${orders.length} completed orders');
      
//       // Process orders and calculate achieved
//       await _processOrders(orders, now.year);
      
//     } catch (e) {
//       print('❌ Error loading completed orders: $e');
//       setState(() {
//         _completedOrders = List.filled(12, 0.0);
//         _achieved = List.filled(12, 0.0);
//       });
//     }
//   }

//   Future<void> _processOrders(List<dynamic> orders, int year) async {
//     // Reset completed orders
//     final completedByMonth = List<double>.filled(12, 0.0);
    
//     for (var order in orders) {
//       final orderDateStr = order['created_at']?.toString();
//       if (orderDateStr != null) {
//         try {
//           final orderDate = DateTime.parse(orderDateStr);
          
//           // Check if order is from the correct year
//           if (orderDate.year != year) {
//             continue;
//           }
          
//           final monthIndex = orderDate.month - 1;
//           if (monthIndex >= 0 && monthIndex < 12) {
//             // Get number of bags completed
//             final bags = (order['bags'] as num?)?.toDouble() ?? 0.0;
//             completedByMonth[monthIndex] += bags;
//           }
//         } catch (e) {
//           print('⚠️ Error parsing order date: $e');
//         }
//       }
//     }
    
//     setState(() {
//       _completedOrders = completedByMonth;
//       // Update achieved from completed orders
//       _achieved = List.from(completedByMonth);
//     });

//     print('📦 Completed orders by month: $_completedOrders');
//     print('📈 Achieved from orders: $_achieved');
    
//     // Print monthly summary for debugging
//     for (int i = 0; i < months.length; i++) {
//       final target = _targets[i];
//       final achieved = _achieved[i];
//       if (target > 0 || achieved > 0) {
//         final progress = target > 0 ? (achieved / target) * 100 : 0;
//         print('${monthLabels[i]}: Target=${target}T, Achieved=${achieved}T, Progress=${progress.toStringAsFixed(1)}%');
//       }
//     }
//   }

//   Future<void> _refreshData() async {
//     if (_isRefreshing) return;

//     print('🔄 Manual refresh triggered...');
    
//     setState(() {
//       _isRefreshing = true;
//       _loadError = null;
//     });

//     try {
//       final empProvider = context.read<EmployeeProvider>();
      
//       // Reload profile first
//       await empProvider.loadProfile();
      
//       // Get employee ID
//       final profile = empProvider.profile;
//       if (profile == null) {
//         throw Exception('Employee profile not loaded');
//       }

//       String? empId = profile['emp_id']?.toString() ??
//                      profile['employee_id']?.toString() ??
//                      profile['id']?.toString() ??
//                      profile['user_id']?.toString();

//       if (empId == null || empId.isEmpty) {
//         throw Exception('No employee ID found');
//       }

//       // Get fresh district info
//       await _getEmployeeDistrict(empId);
      
//       // Load all data
//       await Future.wait([
//         _loadTargetData(empId),
//         _loadCompletedOrdersData(empId),
//         context.read<AttendanceProvider>().checkTodayAttendance(),
//       ]);

//       print('✅ Data refreshed successfully!');
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Data refreshed successfully'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );

//     } catch (e) {
//       print('❌ Error refreshing data: $e');
//       setState(() {
//         _loadError = 'Refresh failed: ${e.toString().split('\n').first}';
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Refresh failed: ${e.toString().split('\n').first}'),
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
//     // Get current month index
//     final currentMonthIndex = DateTime.now().month - 1;
//     final currentTarget = _targets[currentMonthIndex];
//     final currentAchieved = _achieved[currentMonthIndex];
//     final currentProgress = currentTarget > 0 
//         ? (currentAchieved / currentTarget) * 100 
//         : (currentAchieved > 0 ? double.infinity : 0);

//     // Show loading screen if data is still loading initially
//     if (_isDataLoading) {
//       return Scaffold(
//         backgroundColor: AppColors.scaffoldBg,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(GlobalColors.primaryBlue),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 'Loading dashboard...',
//                 style: TextStyle(
//                   color: GlobalColors.primaryBlue,
//                   fontSize: 16,
//                 ),
//               ),
//               if (_employeeDistrict != null) ...[
//                 const SizedBox(height: 10),
//                 Text(
//                   'District: $_employeeDistrict',
//                   style: const TextStyle(
//                     color: Colors.grey,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//               if (_loadError != null) ...[
//                 const SizedBox(height: 10),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 40),
//                   child: Text(
//                     _loadError!,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       color: Colors.red,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ]
//             ],
//           ),
//         ),
//       );
//     }

//     // Check if we have data to show
//     final hasData = _targets.any((t) => t > 0) || _achieved.any((a) => a > 0);
    
//     // Calculate max value for chart
//     double maxValue = 0;
//     if (hasData) {
//       for (var target in _targets) {
//         if (target > maxValue) maxValue = target;
//       }
//       for (var achievement in _achieved) {
//         if (achievement > maxValue) maxValue = achievement;
//       }
//       maxValue = maxValue * 1.2;
//     } else {
//       maxValue = 100.0;
//     }

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

//                 // Current Month Progress
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
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
//                           Text(
//                             "Current Month Progress",
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: GlobalColors.primaryBlue.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               monthLabels[currentMonthIndex],
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: GlobalColors.primaryBlue,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
                      
//                       // Progress section
//                       Column(
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Target: ${currentTarget.toStringAsFixed(1)} T",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: currentTarget > 0 ? Colors.grey : Colors.orange,
//                                   fontWeight: currentTarget > 0 ? FontWeight.normal : FontWeight.w600,
//                                 ),
//                               ),
//                               Text(
//                                 "Achieved: ${currentAchieved.toStringAsFixed(1)} T",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: GlobalColors.primaryBlue,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           LinearProgressIndicator(
//                             value: currentTarget > 0 
//                                 ? (currentAchieved / currentTarget).clamp(0.0, 1.0)
//                                 : (currentAchieved > 0 ? 1.0 : 0.0),
//                             backgroundColor: Colors.grey.shade200,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               currentProgress >= 100 
//                                   ? Colors.green
//                                   : GlobalColors.primaryBlue,
//                             ),
//                             minHeight: 10,
//                             borderRadius: BorderRadius.circular(5),
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 currentProgress.isInfinite 
//                                     ? "No Target Set" 
//                                     : currentProgress > 1000 
//                                         ? ">1000%" 
//                                         : "${currentProgress.toStringAsFixed(1)}%",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: currentProgress >= 100
//                                       ? Colors.green
//                                       : GlobalColors.primaryBlue,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               if (currentProgress >= 100 && currentTarget > 0)
//                                 Row(
//                                   children: [
//                                     Icon(Icons.check_circle, color: Colors.green, size: 14),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       "Target Achieved",
//                                       style: TextStyle(
//                                         fontSize: 11,
//                                         color: Colors.green,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 )
//                               else if (currentTarget > 0 && currentAchieved > 0)
//                                 Text(
//                                   "${(currentTarget - currentAchieved).toStringAsFixed(1)} T remaining",
//                                   style: const TextStyle(
//                                     fontSize: 11,
//                                     color: Colors.orange,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
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
//                                 onPressed: _refreshData,
//                               ),
//                             ],
//                           ),
//                         ),

//                       const SizedBox(height: 12),

//                       // Chart Container (EXACTLY AS YOU REQUESTED)
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
//                                       child: BarChart(
//                                         _buildBarChartData(
//                                           maxValue,
//                                           hasData,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       // Legend - Only show if we have data
                      // if (hasData) ...[
                      //   const SizedBox(height: 16),
                      //   Row(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: [
                      //       _buildLegendItem(Colors.grey.shade400, "Target"),
                      //       const SizedBox(width: 20),
                      //       _buildLegendItem(
                      //         GlobalColors.primaryBlue,
                      //         "Achieved",
                      //       ),
                      //       const SizedBox(width: 20),
                      //       _buildLegendItem(Colors.green, "Target Achieved"),
                      //     ],
                      //   ),
                      // ],

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
//                                     "${_targets.fold(0.0, (sum, element) => sum + element).toStringAsFixed(1)} T",
//                                     Colors.grey.shade700,
//                                   ),
//                                   _buildYearSummaryStat(
//                                     "Total Achieved",
//                                     "${_achieved.fold(0.0, (sum, element) => sum + element).toStringAsFixed(1)} T",
//                                     GlobalColors.primaryBlue,
//                                   ),
//                                   _buildYearSummaryStat(
//                                     "Overall Progress",
//                                     _targets.fold(
//                                               0.0,
//                                               (sum, element) => sum + element,
//                                             ) >
//                                             0
//                                         ? "${((_achieved.fold(0.0, (sum, element) => sum + element) / _targets.fold(0.0, (sum, element) => sum + element)) * 100).toStringAsFixed(1)}%"
//                                         : "0%",
//                                     _targets.fold(
//                                                   0.0,
//                                                   (sum, element) =>
//                                                       sum + element,
//                                                 ) >
//                                                 0 &&
//                                             (_achieved.fold(
//                                                       0.0,
//                                                       (sum, element) =>
//                                                           sum + element,
//                                                     ) /
//                                                     _targets.fold(
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

// BarChartData _buildBarChartData(
//   double maxValue,
//   bool hasData,
// ) {
//   // Calculate interval based on max value
//   final double interval = maxValue <= 100
//       ? 20.0
//       : (maxValue / 5).ceilToDouble();

//   return BarChartData(
//     alignment: BarChartAlignment.center,
//     groupsSpace: 12,
//     minY: 0,
//     maxY: maxValue,
//     barTouchData: BarTouchData(
//       enabled: false, // Disable touch interactions including tooltips
//     ),
//     titlesData: FlTitlesData(
//       show: true,
//       leftTitles: AxisTitles(
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 40,
//           interval: interval,
//           getTitlesWidget: (value, meta) {
//             return Padding(
//               padding: const EdgeInsets.only(right: 8),
//               child: Text(
//                 "${value.toInt()} T",
//                 style: const TextStyle(fontSize: 10, color: Colors.grey),
//               ),
//             );
//           },
//         ),
//       ),
//       rightTitles: const AxisTitles(
//         sideTitles: SideTitles(showTitles: false),
//       ),
//       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       bottomTitles: AxisTitles(
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 30,
//           getTitlesWidget: (value, meta) {
//             final index = value.toInt();
//             if (index >= 0 && index < monthLabels.length) {
//               final isCurrentMonth = index == DateTime.now().month - 1;
//               return Padding(
//                 padding: const EdgeInsets.only(top: 4),
//                 child: Text(
//                   monthLabels[index],
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: isCurrentMonth
//                         ? GlobalColors.primaryBlue
//                         : Colors.grey,
//                     fontWeight: isCurrentMonth
//                         ? FontWeight.w600
//                         : FontWeight.w500,
//                   ),
//                 ),
//               );
//             }
//             return const SizedBox();
//           },
//         ),
//       ),
//     ),
//     gridData: FlGridData(
//       show: true,
//       drawHorizontalLine: true,
//       drawVerticalLine: false,
//       horizontalInterval: interval,
//       getDrawingHorizontalLine: (value) {
//         return FlLine(color: Colors.grey.shade200, strokeWidth: 0.5);
//       },
//     ),
//     borderData: FlBorderData(
//       show: true,
//       border: Border.all(color: Colors.grey.shade300, width: 0.5),
//     ),
//     barGroups: List.generate(12, (index) {
//       final target = _targets[index];
//       final achievedValue = _achieved[index];
//       final isTargetAchieved = target > 0 && achievedValue >= target;

//       return BarChartGroupData(
//         x: index,
//         groupVertically: true,
//         barRods: [
//           // Target bar (grey) - always show even if 0
//           BarChartRodData(
//             toY: target,
//             width: 14,
//             color: Colors.grey.shade400,
//             borderRadius: BorderRadius.circular(2),
//           ),
//           // Achieved bar (blue or green if target achieved)
//           BarChartRodData(
//             toY: achievedValue,
//             width: 10,
//             color: isTargetAchieved ? Colors.green : GlobalColors.primaryBlue,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ],
//       );
//     }),
//   );
// }
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
  
//   late final List<Widget> _pages;

//   @override
//   void initState() {
//     super.initState();
    
//     _pages = [
//       _DashboardHome(scaffoldKey: _scaffoldKey),
//       const CattleFeedOrderScreen(),
//       const RecentOrdersScreen(),
//       const EmployeeProfileDashboard(),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ignore: deprecated_member_use
//     return WillPopScope(
//       onWillPop: () async {
//         if (_selectedIndex != 0) {
//           setState(() {
//             _selectedIndex = 0;
//           });
//           return false;
//         } else {
//           bool? shouldExit = await showDialog<bool>(
//             context: context,
//             builder: (context) => _buildExitDialog(context),
//           );
//           return shouldExit ?? false;
//         }
//       },
//       child: Scaffold(
//         key: _scaffoldKey,
//         backgroundColor: AppColors.scaffoldBg,
//         drawer: _buildDrawer(context),
//         body: IndexedStack(
//           index: _selectedIndex,
//           children: _pages,
//         ),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           selectedItemColor: GlobalColors.primaryBlue,
//           unselectedItemColor: GlobalColors.textGrey,
//           type: BottomNavigationBarType.fixed,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
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
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       backgroundColor: Colors.transparent,
//       content: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               // ignore: deprecated_member_use
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 20,
//               spreadRadius: 2,
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [GlobalColors.primaryBlue, Colors.blue[700]!],
//                 ),
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: Row(
//                 children: [                  
//                   Expanded(
//                     child: Text(
//                       "Exit App?",
//                       style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   Text("Are you sure you want to exit?", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800])),
//                   const SizedBox(height: 28),
//                 ],
//               ),
//             ),
            
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
//                 border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () => Navigator.of(context).pop(false),
//                       label: const Text("Cancel"),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.grey[700],
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         side: BorderSide(color: Colors.grey[400]!),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => Navigator.of(context).pop(true),
//                       label: const Text("Exit"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: GlobalColors.primaryBlue,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         elevation: 0,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Drawer _buildDrawer(BuildContext context) {
//     final emp = context.watch<EmployeeProvider>().profile;
//     final attendanceProvider = context.watch<AttendanceProvider>();

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
          
//           // Only show "Mark Attendance" if NOT already marked today
//           if (!attendanceProvider.attendanceMarkedToday)
//             _drawerTile(Iconsax.calendar_1, "Mark Attendance", () {
//               Navigator.pop(context);
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const EmployeeAttendancePage(cameras: []),
//                 ),
//               );
//             }),
          
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
          
//           // Profile navigation
//           _drawerTile(Iconsax.user, "My Profile", () {
//             Navigator.pop(context);
//             setState(() {
//               _selectedIndex = 3;
//             });
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
  
//   // Store data locally to prevent reloading
//   List<double> _targets = List.filled(12, 0.0);
//   List<double> _achieved = List.filled(12, 0.0);

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
//     if (_isInitialized && !_isRefreshing) return;

//     setState(() {
//       if (!_isInitialized) _isDataLoading = true;
//       _loadError = null;
//     });

//     try {
//       // Only load employee profile if not already loaded
//       final empProvider = context.read<EmployeeProvider>();
//       if (empProvider.profile == null) {
//         await empProvider.loadEmployeeProfile();
//       }

//       final empId = empProvider.profile?['emp_id']?.toString();

//       if (empId == null || empId.isEmpty) {
//         throw Exception('No employee ID found. Please check your profile.');
//       }

//       // Load all data concurrently
//       await Future.wait([
//         _loadTargetData(empId),
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

//   Future<void> _loadTargetData(String empId) async {
//     final targetProvider = context.read<TargetProvider>();
    
//     print('🔄 Loading target data for employee: $empId');

//     try {
//       await targetProvider.loadTargetData(empId);

//       // Get and store data locally
//       final targets = targetProvider.getMonthlyTargets(empId, months);
//       final achieved = targetProvider.getMonthlyAchieved(empId, months);
      
//       // Store locally to prevent reloading
//       setState(() {
//         _targets = targets;
//         _achieved = achieved;
//       });

//       print('📊 === TARGET DATA LOADED ===');
//       print('Targets: $_targets');
//       print('Achieved: $_achieved');
      
//       for (int i = 0; i < months.length; i++) {
//         print('${monthLabels[i]}: Target=${_targets[i]} T, Achieved=${_achieved[i]} T');
//       }
//     } catch (e) {
//       print('❌ Failed to load target data: $e');
//       rethrow;
//     }
//   }

//   Future<void> _refreshData() async {
//     if (_isRefreshing) return;

//     setState(() {
//       _isRefreshing = true;
//       _loadError = null;
//     });

//     try {
//       final empProvider = context.read<EmployeeProvider>();
//       final empId = empProvider.profile?['emp_id']?.toString();
      
//       if (empId == null || empId.isEmpty) {
//         throw Exception('No employee ID found');
//       }

//       await Future.wait([
//         _loadTargetData(empId),
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

//     // Check if we have any data to show
//     final hasTargets = _targets.any((t) => t > 0);
//     final hasAchievements = _achieved.any((a) => a > 0);
//     final hasData = hasTargets || hasAchievements;

//     // Calculate max value for scaling
//     double maxValue = 0;
//     if (hasData) {
//       for (var target in _targets) {
//         if (target > maxValue) maxValue = target;
//       }
//       for (var achievement in _achieved) {
//         if (achievement > maxValue) maxValue = achievement;
//       }
//       // Add padding for better visualization
//       maxValue = maxValue * 1.2;
//     } else {
//       maxValue = 100.0; // Default value for empty chart
//     }

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
//                                 onPressed: _refreshData,
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
//                                 monthLabels[DateTime.now().month - 1],
//                                 "Current Month",
//                                 GlobalColors.primaryBlue,
//                               ),
//                               _buildCurrentMonthStat(
//                                 "${_targets[DateTime.now().month - 1].toStringAsFixed(1)} T",
//                                 "Target",
//                                 Colors.grey.shade700,
//                               ),
//                               _buildCurrentMonthStat(
//                                 "${_achieved[DateTime.now().month - 1].toStringAsFixed(1)} T",
//                                 "Achieved",
//                                 _achieved[DateTime.now().month - 1] >=
//                                         _targets[DateTime.now().month - 1]
//                                     ? Colors.green
//                                     : GlobalColors.primaryBlue,
//                               ),
//                               _buildCurrentMonthStat(
//                                 _targets[DateTime.now().month - 1] > 0
//                                     ? "${((_achieved[DateTime.now().month - 1] / _targets[DateTime.now().month - 1]) * 100).toStringAsFixed(0)}%"
//                                     : "N/A",
//                                 "Progress",
//                                 _targets[DateTime.now().month - 1] > 0 &&
//                                         _achieved[DateTime.now().month - 1] >=
//                                             _targets[DateTime.now().month - 1]
//                                     ? Colors.green
//                                     : Colors.orange,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 12),

//                       // Chart Container
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
//                                       child: BarChart(
//                                         _buildBarChartData(
//                                           maxValue,
//                                           hasData,
//                                         ),
//                                       ),
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
//                                     "${_targets.fold(0.0, (sum, element) => sum + element).toStringAsFixed(1)} T",
//                                     Colors.grey.shade700,
//                                   ),
//                                   _buildYearSummaryStat(
//                                     "Total Achieved",
//                                     "${_achieved.fold(0.0, (sum, element) => sum + element).toStringAsFixed(1)} T",
//                                     GlobalColors.primaryBlue,
//                                   ),
//                                   _buildYearSummaryStat(
//                                     "Overall Progress",
//                                     _targets.fold(
//                                               0.0,
//                                               (sum, element) => sum + element,
//                                             ) >
//                                             0
//                                         ? "${((_achieved.fold(0.0, (sum, element) => sum + element) / _targets.fold(0.0, (sum, element) => sum + element)) * 100).toStringAsFixed(1)}%"
//                                         : "0%",
//                                     _targets.fold(
//                                                   0.0,
//                                                   (sum, element) =>
//                                                       sum + element,
//                                                 ) >
//                                                 0 &&
//                                             (_achieved.fold(
//                                                       0.0,
//                                                       (sum, element) =>
//                                                           sum + element,
//                                                     ) /
//                                                     _targets.fold(
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
//     double maxValue,
//     bool hasData,
//   ) {
//     // Calculate interval based on max value
//     final double interval = maxValue <= 100
//         ? 20.0
//         : (maxValue / 5).ceilToDouble();

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
//             final targetVal = _targets[group.x];
//             final achievedVal = _achieved[group.x];
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
//         final target = _targets[index];
//         final achievedValue = _achieved[index];
//         final isTargetAchieved = target > 0 && achievedValue >= target;

//         return BarChartGroupData(
//           x: index,
//           groupVertically: true,
//           barRods: [
//             // Target bar (grey) - always show even if 0
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












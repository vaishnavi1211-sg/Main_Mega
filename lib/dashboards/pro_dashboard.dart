import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mega_pro/production/pro_inventory_page.dart';
import 'package:mega_pro/production/pro_orders_from_emp_mar_page.dart';
import 'package:mega_pro/production/pro_profilePage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductionDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProductionDashboard({super.key, required this.userData});

  @override
  State<ProductionDashboard> createState() => _ProductionDashboardState();
}

class _ProductionDashboardState extends State<ProductionDashboard> {
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Define routes
  final List<String> _routeNames = [
    '/dashboard',
    '/inventory',
    '/orders',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle Android back button
        if (_navigatorKey.currentState?.canPop() ?? false) {
          _navigatorKey.currentState?.pop();
          return false;
        } else if (_currentIndex != 0) {
          // If not on dashboard, go to dashboard
          setState(() => _currentIndex = 0);
          _navigatorKey.currentState?.pushReplacementNamed('/dashboard');
          return false;
        } else {
          // If on dashboard, show exit dialog
          _showExitDialog(context);
          return false;
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: GlobalColors.white,
        body: Navigator(
          key: _navigatorKey,
          initialRoute: '/dashboard',
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute(
              builder: (context) {
                return _buildPageForRoute(settings.name ?? '/dashboard');
              },
              settings: settings,
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildPageForRoute(String routeName) {
    switch (routeName) {
      case '/dashboard':
        return DashboardContent(
          scaffoldKey: _scaffoldKey,
          userData: widget.userData,
        );
      case '/inventory':
        return const ProInventoryManager();
      case '/orders':
        return ProductionOrdersPage(
          productionProfile: const {}, 
          onDataChanged: () {},
        );
      case '/profile':
        return const ProductionProfilePage();
      default:
        return DashboardContent(
          scaffoldKey: _scaffoldKey,
          userData: widget.userData,
        );
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.dashboard, "Dashboard"),
              _buildNavItem(1, Icons.inventory_2, "Inventory"),
              _buildNavItem(2, Icons.assignment, "Orders"),
              _buildNavItem(3, Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
          _navigatorKey.currentState?.pushReplacementNamed(_routeNames[index]);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _currentIndex == index
              ? GlobalColors.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _currentIndex == index
                  ? GlobalColors.primaryBlue
                  : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: _currentIndex == index
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: _currentIndex == index
                    ? GlobalColors.primaryBlue
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Exit App?",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to exit?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Exit app
                          // SystemNavigator.pop(); // For Android
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Exit",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dashboard Content with real-time updates
class DashboardContent extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Map<String, dynamic> userData;
  
  const DashboardContent({
    super.key,
    required this.scaffoldKey,
    required this.userData,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> _inventoryData = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  
  // Real-time metrics
  double _todayProduction = 0.0;
  double _productionTarget = 120.0;
  int _activeMachines = 0;
  int _totalMachines = 15;
  double _qualityRate = 0.0;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _startRealtimeUpdates();
  }

  void _startRealtimeUpdates() {
    // Update every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchAllData();
    });
  }

  Future<void> _fetchAllData() async {
    try {
      await Future.wait([
        _fetchInventoryData(),
        _fetchProductionMetrics(),
        _fetchMachineStatus(),
      ]);
      
      if (mounted) {
        setState(() {
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  Future<void> _fetchInventoryData() async {
    try {
      final response = await _supabase
          .from('inventory')
          .select('*')
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _inventoryData.clear();
          _inventoryData.addAll(List<Map<String, dynamic>>.from(response));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProductionMetrics() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Fetch today's production
      final productionResponse = await _supabase
          .from('production_logs')
          .select('SUM(quantity) as total_quantity')
          .eq('date', today)
          .single()
          .catchError((_) => {'total_quantity': 0});
      
      // Fetch today's target
      final targetResponse = await _supabase
          .from('production_targets')
          .select('target_amount')
          .eq('date', today)
          .single()
          .catchError((_) => {'target_amount': 120.0});
      
      if (mounted) {
        setState(() {
          _todayProduction = (productionResponse['total_quantity'] ?? 0).toDouble();
          _productionTarget = (targetResponse['target_amount'] ?? 120.0).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Error fetching production metrics: $e');
    }
  }

  Future<void> _fetchMachineStatus() async {
    try {
      final response = await _supabase
          .from('machines')
          .select('status')
          .eq('is_active', true);
      
      if (mounted) {
        setState(() {
          _activeMachines = response.where((m) => m['status'] == 'running').length;
          _totalMachines = response.length;
          
          // Simulate quality rate (replace with actual API call)
          final random = Random();
          _qualityRate = 95.0 + random.nextDouble() * 5.0;
          _qualityRate = double.parse(_qualityRate.toStringAsFixed(1));
        });
      }
    } catch (e) {
      debugPrint('Error fetching machine status: $e');
    }
  }

  void _showRefreshSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Refreshing data...'),
        backgroundColor: GlobalColors.primaryBlue,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.white,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Production Dashboard",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            if (_lastUpdated != null)
              Text(
                "Updated: ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchAllData();
              _showRefreshSnackBar(context);
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _showExitDialog(context),
            tooltip: 'Exit App',
          ),
        ],
      ),
      body: _DashboardBody(
        inventoryData: _inventoryData,
        isLoading: _isLoading,
        todayProduction: _todayProduction,
        productionTarget: _productionTarget,
        activeMachines: _activeMachines,
        totalMachines: _totalMachines,
        qualityRate: _qualityRate,
        onRefresh: () {
          _fetchAllData();
          _showRefreshSnackBar(context);
        },
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.exit_to_app,
                  size: 40,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  "Exit Application?",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to exit?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text("CANCEL"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // SystemNavigator.pop(); // For Android exit
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("EXIT"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dashboard Body Widget
class _DashboardBody extends StatelessWidget {
  final List<Map<String, dynamic>> inventoryData;
  final bool isLoading;
  final double todayProduction;
  final double productionTarget;
  final int activeMachines;
  final int totalMachines;
  final double qualityRate;
  final VoidCallback onRefresh;

  const _DashboardBody({
    required this.inventoryData,
    required this.isLoading,
    required this.todayProduction,
    required this.productionTarget,
    required this.activeMachines,
    required this.totalMachines,
    required this.qualityRate,
    required this.onRefresh,
  });

  Widget _buildProductionMetrics() {
    final progress = productionTarget > 0 ? todayProduction / productionTarget : 0;
    final isTargetAchieved = todayProduction >= productionTarget;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GlobalColors.primaryBlue,
            Colors.blue[700]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: GlobalColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Production",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${todayProduction.toStringAsFixed(1)} MT",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress > 1 ? 1.0 : progress.toDouble(),
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isTargetAchieved ? Colors.green : Colors.amber,
                      ),
                    ),
                    Text(
                      "${(progress * 100).toStringAsFixed(0)}%",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        "Target: ${productionTarget.toStringAsFixed(1)} MT",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                onPressed: onRefresh,
                tooltip: 'Refresh Production',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                "Raw Material Status",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigation handled by bottom nav
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GlobalColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "View All",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: GlobalColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: GlobalColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isLoading)
            Container(
              height: 200,
              child: const Center(
                child: CircularProgressIndicator(color: GlobalColors.primaryBlue),
              ),
            )
          else if (inventoryData.isEmpty)
            Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No inventory data",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: inventoryData.take(4).map((item) {
                final stock = (item['stock'] ?? 0).toDouble();
                final reorder = (item['reorder_level'] ?? 100).toDouble();
                final isLow = stock < reorder;
                final percentage = reorder > 0 ? (stock / reorder) : 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['name']?.toString() ?? 'Unknown Material',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLow
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$stock MT",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLow ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: percentage > 1 ? 1.0 : percentage,
                                backgroundColor: Colors.grey[200],
                                color: isLow ? Colors.red : Colors.green,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${(percentage * 100).toStringAsFixed(0)}%",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (isLow)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Below reorder level ($reorder MT)",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Stats",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _statCard(
                "Active Machines",
                "$activeMachines/$totalMachines",
                Icons.settings,
                Colors.blue,
              ),
              _statCard(
                "Quality Rate",
                "${qualityRate.toStringAsFixed(1)}%",
                Icons.verified,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductionMetrics(),
              const SizedBox(height: 20),
              
              _buildInventoryStatus(),
              const SizedBox(height: 20),
              
              _buildQuickStats(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}




















// import 'package:flutter/material.dart';
// import 'package:mega_pro/production/pro_inventory_page.dart';
// import 'package:mega_pro/production/pro_orders_page.dart';
// import 'package:mega_pro/production/pro_profilePage.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';

// class ProductionDashboard extends StatefulWidget {
//   const ProductionDashboard({super.key, required Map userData});

//   @override
//   State<ProductionDashboard> createState() => _ProductionDashboardState();
// }

// class _ProductionDashboardState extends State<ProductionDashboard> {
//   int _currentIndex = 0;
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: GlobalColors.white,
//       body: _buildBody(),
//       bottomNavigationBar: _buildBottomNavigationBar(),
//     );
//   }

//   Widget _buildBody() {
//     switch (_currentIndex) {
//       case 0:
//         return const DashboardContent();
//       case 1:
//         return const ProInventoryManager();
//       case 2:
//         return ProductionOrdersPage(productionProfile: const {}, onDataChanged: () {  },);
//       case 3:
//         return const ProductionProfilePage();
//       default:
//         return const DashboardContent();
//     }
//   }

//   Widget _buildBottomNavigationBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             // ignore: deprecated_member_use
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
//               _buildNavItem(1, Icons.inventory_2, "Inventory"),
//               _buildNavItem(2, Icons.assignment, "Orders"),
//               _buildNavItem(3, Icons.person, "Profile"),
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
// }

// class DashboardContent extends StatelessWidget {
//   const DashboardContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: GlobalColors.white,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Production Dashboard",
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//                 fontSize: 20,
//               ),
//             ),
            
//           ],
//         ),
//         centerTitle: false,
//         iconTheme: const IconThemeData(color: Colors.white),
        
//       ),
//       body: const DashboardBody(),
//     );
//   }
// }

// // Dashboard Body Widget
// class DashboardBody extends StatefulWidget {
//   const DashboardBody({super.key});

//   @override
//   State<DashboardBody> createState() => _DashboardBodyState();
// }

// class _DashboardBodyState extends State<DashboardBody> {
//   final SupabaseClient supabase = Supabase.instance.client;
//   List<Map<String, dynamic>> _inventoryData = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchInventoryData();
//   }

//   Future<void> _fetchInventoryData() async {
//     try {
//       final response = await supabase
//           .from('inventory')
//           .select('*')
//           .order('name', ascending: true);

//       setState(() {
//         _inventoryData = List<Map<String, dynamic>>.from(response);
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching inventory: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Widget _buildProductionMetrics() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             GlobalColors.primaryBlue,
//             Colors.blue[700]!,
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: GlobalColors.primaryBlue.withOpacity(0.3),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Today's Production",
//                   style: GoogleFonts.poppins(
//                     color: Colors.white.withOpacity(0.9),
//                     fontSize: 14,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "125.0 MT",
//                   style: GoogleFonts.poppins(
//                     color: Colors.white,
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         // ignore: deprecated_member_use
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.flag, size: 12, color: Colors.white),
//                           const SizedBox(width: 4),
//                           Text(
//                             "Target: 120 MT",
//                             style: GoogleFonts.poppins(
//                               color: Colors.white,
//                               fontSize: 11,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 8),                    
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(
//               Icons.factory,
//               color: Colors.white,
//               size: 40,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInventoryStatus() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "Raw Material Status",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[800],
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () {
//                   // Navigate to inventory page
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: GlobalColors.primaryBlue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Row(
//                     children: [
//                       Text(
//                         "View All",
//                         style: GoogleFonts.poppins(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                           color: GlobalColors.primaryBlue,
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       Icon(
//                         Icons.arrow_forward_ios,
//                         size: 10,
//                         color: GlobalColors.primaryBlue,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           if (_isLoading)
//             Container(
//               height: 200,
//               child: const Center(
//                 child: CircularProgressIndicator(color: GlobalColors.primaryBlue),
//               ),
//             )
//           else if (_inventoryData.isEmpty)
//             Container(
//               height: 200,
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.inventory_2_outlined,
//                       size: 48,
//                       color: Colors.grey[400],
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       "No inventory data",
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           else
//             Column(
//               children: _inventoryData.take(4).map((item) {
//                 final stock = (item['stock'] ?? 0).toDouble();
//                 final reorder = (item['reorder_level'] ?? 100).toDouble();
//                 final isLow = stock < reorder;
//                 final percentage = reorder > 0 ? (stock / reorder) : 0;

//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 10),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(
//                       color: Colors.grey[200]!,
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               item['name']?.toString() ?? 'Unknown Material',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.grey[800],
//                               ),
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: isLow
//                                   ? Colors.red.withOpacity(0.1)
//                                   : Colors.green.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: Text(
//                               "$stock MT",
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                                 color: isLow ? Colors.red : Colors.green,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(10),
//                               child: LinearProgressIndicator(
//                                 value: percentage > 1 ? 1.0 : percentage,
//                                 backgroundColor: Colors.grey[200],
//                                 color: isLow ? Colors.red : Colors.green,
//                                 minHeight: 6,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Text(
//                             "${(percentage * 100).toStringAsFixed(0)}%",
//                             style: GoogleFonts.poppins(
//                               fontSize: 11,
//                               color: Colors.grey[600],
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (isLow)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.warning_amber_rounded,
//                                 size: 14,
//                                 color: Colors.red,
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 "Below reorder level ($reorder MT)",
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 11,
//                                   color: Colors.red,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickStats() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Quick Stats",
//             style: GoogleFonts.poppins(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[800],
//             ),
//           ),
//           const SizedBox(height: 16),
//           GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 2,
//             crossAxisSpacing: 12,
//             mainAxisSpacing: 12,
//             childAspectRatio: 1.3,
//             children: [
//               _statCard(
//                 "Active Machines",
//                 "12/15",
//                 Icons.settings,
//                 Colors.blue,
//               ),
//               _statCard(
//                 "Quality Rate",
//                 "98.5%",
//                 Icons.verified,
//                 Colors.green,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _statCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 20, color: color),
//           const SizedBox(height: 8),
//           Text(
//             title,
//             style: GoogleFonts.poppins(
//               fontSize: 11,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: GoogleFonts.poppins(
//               fontSize: 16,
//               fontWeight: FontWeight.w700,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildProductionMetrics(),
//               const SizedBox(height: 20),
              
//               _buildInventoryStatus(),
//               const SizedBox(height: 20),
              
//               _buildQuickStats(),
//               const SizedBox(height: 32),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:iconsax_flutter/iconsax_flutter.dart';
// import 'package:mega_pro/production/pro_home_dash.dart';
// import 'package:mega_pro/production/pro_profilePage.dart';
// import 'package:mega_pro/production/stats_manager.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/production/pro_inventory_page.dart';
// import 'package:mega_pro/production/pro_orders_page.dart';

// class ProductionDashboard extends StatefulWidget {
//   final Map<String, dynamic> userData;
  
//   const ProductionDashboard({super.key, required this.userData});

//   @override
//   State<ProductionDashboard> createState() => _ProductionDashboardState();
// }

// class _ProductionDashboardState extends State<ProductionDashboard> {
//   final supabase = Supabase.instance.client;
//   int _selectedIndex = 0;
  
//   // Production manager profile data
//   Map<String, dynamic> _productionProfile = {};
//   bool _isLoadingProfile = true;

//   // Bottom navigation pages
//   late List<Widget> _pages;

//   @override
//   void initState() {
//     super.initState();
//     _loadProductionProfile();
//   }

//   Future<void> _loadProductionProfile() async {
//     try {
//       final user = supabase.auth.currentUser;
//       if (user != null) {
//         final profileResponse = await supabase
//             .from('emp_profile')
//             .select('''
//               id, emp_id, full_name, email, phone, position, 
//               branch, department, role, status, created_at,
//               profile_image, salary, address
//             ''')
//             .eq('user_id', user.id)
//             .maybeSingle();

//         if (profileResponse != null) {
//           setState(() {
//             _productionProfile = profileResponse;
//           });
//         } else {
//           // Create default profile from userData
//           setState(() {
//             _productionProfile = {
//               'full_name': widget.userData['full_name'] ?? 'Production Manager',
//               'email': widget.userData['email'] ?? '',
//               'emp_id': 'PM${DateTime.now().millisecondsSinceEpoch % 10000}',
//               'position': 'Production Manager',
//               'department': 'Production',
//               'status': 'Active',
//               'profile_image': null,
//             };
//           });
//         }
//       }
//     } catch (e) {
//       print('Error loading production profile: $e');
//     } finally {
//       setState(() {
//         _isLoadingProfile = false;
//       });
//       // Initialize stats and pages after profile loads
//        StatsManager.refreshStats();
//       _initializePages();
//     }
//   }

//   // Initialize pages method
//   void _initializePages() {
//     _pages = [
//       DashboardHome(
//         pendingOrdersCount: StatsManager.pendingOrders,
//         lowStockItems: StatsManager.lowStockItems,
//         onRefresh: () async {
//            StatsManager.refreshStats();
//           setState(() {}); // Trigger rebuild
//         },
//       ),
//       InventoryPage(
//         productionProfile: _productionProfile,
//         onDataChanged: () async {
//            StatsManager.refreshStats();
//           setState(() {}); // Trigger rebuild
//         },
//       ),
//       ProductionOrdersPage(
//         productionProfile: _productionProfile,
//         onDataChanged: () async {
//            StatsManager.refreshStats();
//           setState(() {}); // Trigger rebuild
//         },
//       ),
//       ProductionProfilePage(
//         productionProfile: _productionProfile,
//         onProfileUpdated: _loadProductionProfile,
//       ),
//     ];
    
//     // Ensure setState is called to update the UI
//     if (mounted) {
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoadingProfile || _pages.isEmpty) {
//       return Scaffold(
//         backgroundColor: GlobalColors.white,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(color: GlobalColors.primaryBlue),
//               const SizedBox(height: 16),
//               Text(
//                 'Loading Production Dashboard...',
//                 style: TextStyle(
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: GlobalColors.white,
//       appBar: _selectedIndex == 0
//           ? AppBar(
//               backgroundColor: GlobalColors.primaryBlue,
//               elevation: 0,
//               title: Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 16,
//                     backgroundColor: Colors.white,
//                     child: Text(
//                       _productionProfile['full_name']?[0] ?? 'P',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: GlobalColors.primaryBlue,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Production Dashboard',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       Text(
//                         'Welcome, ${_productionProfile['full_name']?.split(' ').first ?? 'Manager'}',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.white.withOpacity(0.8),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               actions: [
//                 IconButton(
//                   icon: const Icon(Iconsax.notification, color: Colors.white),
//                   onPressed: () {
//                     setState(() => _selectedIndex = 2);
//                   },
//                 ),
//               ],
//             )
//           : null,
//       body: _selectedIndex < _pages.length ? _pages[_selectedIndex] : const SizedBox(),
//       bottomNavigationBar: _buildBottomNavigationBar(),
//     );
//   }

//   Widget _buildBottomNavigationBar() {
//     return Container(
//       decoration: BoxDecoration(
//         border: Border(
//           top: BorderSide(color: Colors.grey.shade200, width: 1),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         backgroundColor: Colors.white,
//         selectedItemColor: GlobalColors.primaryBlue,
//         unselectedItemColor: Colors.grey.shade600,
//         showUnselectedLabels: true,
//         selectedLabelStyle: const TextStyle(
//           fontWeight: FontWeight.w500,
//           fontSize: 11,
//         ),
//         unselectedLabelStyle: const TextStyle(
//           fontWeight: FontWeight.w400,
//           fontSize: 11,
//         ),
//         type: BottomNavigationBarType.fixed,
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(_selectedIndex == 0 ? Iconsax.home_2 : Iconsax.home_2),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(_selectedIndex == 1 ? Iconsax.box_2 : Iconsax.box),
//             label: 'Inventory',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(_selectedIndex == 2 ? Iconsax.receipt_2 : Iconsax.receipt),
//             label: 'Orders',
//           ),
//           BottomNavigationBarItem(
//             icon: _buildProfileIcon(),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileIcon() {
//     final hasProfileImage = _productionProfile['profile_image'] != null;

//     return Container(
//       width: 24,
//       height: 24,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: _selectedIndex == 3
//             ? Border.all(color: GlobalColors.primaryBlue, width: 2)
//             : null,
//       ),
//       child: CircleAvatar(
//         radius: 10,
//         backgroundColor: _selectedIndex == 3
//             ? GlobalColors.primaryBlue.withOpacity(0.1)
//             : Colors.grey.shade100,
//         backgroundImage: hasProfileImage
//             ? NetworkImage(_productionProfile['profile_image'].toString())
//             : null,
//         child: !hasProfileImage
//             ? Icon(
//                 Iconsax.profile_circle,
//                 size: 20,
//                 color: _selectedIndex == 3 
//                     ? GlobalColors.primaryBlue 
//                     : Colors.grey.shade600,
//               )
//             : null,
//       ),
//     );
//   }
// }
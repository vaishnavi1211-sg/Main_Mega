import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mega_pro/production/pro_inventory_page.dart';
import 'package:mega_pro/production/pro_orders_from_emp_mar_page.dart';
import 'package:mega_pro/production/pro_profilePage.dart';
import 'package:mega_pro/production/pro_raw_material_entry_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mega_pro/providers/pro_orders_provider.dart';

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
        if (_navigatorKey.currentState?.canPop() ?? false) {
          _navigatorKey.currentState?.pop();
          return false;
        } else if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          _navigatorKey.currentState?.pushReplacementNamed('/dashboard');
          return false;
        } else {
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
        return ChangeNotifierProvider<ProductionOrdersProvider>(
          create: (_) => ProductionOrdersProvider(),
          child: DashboardContent(
            scaffoldKey: _scaffoldKey,
            userData: widget.userData,
          ),
        );
      case '/inventory':
        return const ProInventoryManager();
      case '/orders':
        return ChangeNotifierProvider<ProductionOrdersProvider>(
          create: (_) => ProductionOrdersProvider(),
          child: ProductionOrdersPage(
            productionProfile: const {}, 
            onDataChanged: () {},
          ),
        );
      case '/profile':
        return const ProductionProfilePage();
      default:
        return ChangeNotifierProvider<ProductionOrdersProvider>(
          create: (_) => ProductionOrdersProvider(),
          child: DashboardContent(
            scaffoldKey: _scaffoldKey,
            userData: widget.userData,
          ),
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
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Exit the app?",
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
                          _logoutAndGoToMainPage(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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

  void _logoutAndGoToMainPage(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacementNamed(context, '/');
  }
}

// Enhanced Dashboard Content with Profit Calculation
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
  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _recentOrders = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  
  // Real-time metrics
  double _todayProduction = 0.0;
  double _productionTarget = 120.0;
  int _activeMachines = 0;
  int _totalMachines = 15;
  double _qualityRate = 0.0;
  DateTime? _lastUpdated;
  
  // Profit Calculation Variables
  double _totalRawMaterialCost = 0.0;
  double _totalRevenue = 0.0;
  double _totalProfit = 0.0;
  double _profitMargin = 0.0;
  
  // Raw Material Usage
  Map<String, double> _rawMaterialUsage = {};
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _startRealtimeUpdates();
  }

  void _startRealtimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchAllData();
    });
  }

  Future<void> _fetchAllData() async {
    try {
      await Future.wait([
        _fetchInventoryData(),
        _fetchProducts(),
        _fetchProductionMetrics(),
        _fetchMachineStatus(),
        _fetchRecentOrders(),
        _calculateProfitMetrics(),
      ]);
      
      if (mounted) {
        setState(() {
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchInventoryData() async {
    try {
      final response = await _supabase
          .from('pro_inventory')
          .select('*')
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _inventoryData.clear();
          _inventoryData.addAll(List<Map<String, dynamic>>.from(response));
        });
      }
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _supabase
          .from('pro_products')
          .select('*')
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _products.clear();
          _products.addAll(List<Map<String, dynamic>>.from(response));
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  // ENHANCED PROFIT CALCULATION METHOD
  Future<void> _calculateProfitMetrics() async {
    try {
      final today = DateTime.now();
      final monthStart = DateTime(today.year, today.month, 1);
      
      double totalRevenue = 0.0;
      Map<String, double> rawMaterialCosts = {};

      // METHOD 1: Get revenue from Provider (primary method)
      try {
        final ordersProvider = context.read<ProductionOrdersProvider>();
        final completedOrders = ordersProvider.orders
            .where((order) => order.status.toLowerCase() == 'completed')
            .toList();
        
        debugPrint('Found ${completedOrders.length} completed orders from provider');
        
        // Sum revenue for current month
        for (var order in completedOrders) {
          if (order.createdAt.isAfter(monthStart) && order.createdAt.isBefore(today.add(const Duration(days: 1)))) {
            totalRevenue += order.totalPrice;
            debugPrint('Added order revenue: ₹${order.totalPrice} - Date: ${order.createdAt}');
          }
        }
        
        debugPrint('Total revenue from provider: ₹$totalRevenue');
      } catch (e) {
        debugPrint('Error accessing provider for revenue: $e');
        
        // METHOD 2: Fallback to Supabase
        final monthStartStr = "${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-01";
        final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

        final revenueResponse = await _supabase
            .from('emp_mar_orders')
            .select('total_price, created_at')
            .eq('status', 'completed')
            .gte('created_at', monthStartStr)
            .lte('created_at', todayStr);

        for (var order in revenueResponse) {
          totalRevenue += (order['total_price'] ?? 0).toDouble();
        }
        
        debugPrint('Total revenue from Supabase: ₹$totalRevenue');
      }

      // Get raw material usage cost for this month
      final monthStartStr = "${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-01";
      final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final materialResponse = await _supabase
          .from('pro_raw_material_usage')
          .select('total_cost, raw_material_id, pro_inventory!inner(name)')
          .gte('usage_date', monthStartStr)
          .lte('usage_date', todayStr);

      double totalRawMaterialCost = 0.0;

      for (var usage in materialResponse) {
        final cost = (usage['total_cost'] ?? 0).toDouble();
        totalRawMaterialCost += cost;
        
        final inventoryData = usage['pro_inventory'] as Map<String, dynamic>?;
        final materialName = inventoryData?['name']?.toString() ?? 'Unknown Material';
        
        rawMaterialCosts[materialName] = (rawMaterialCosts[materialName] ?? 0) + cost;
      }

      debugPrint('Total raw material cost: ₹$totalRawMaterialCost');
      debugPrint('Raw material breakdown: $rawMaterialCosts');

      // Calculate profit
      double totalProfit = totalRevenue - totalRawMaterialCost;
      double profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

      if (mounted) {
        setState(() {
          _totalRevenue = totalRevenue;
          _totalRawMaterialCost = totalRawMaterialCost;
          _totalProfit = totalProfit;
          _profitMargin = profitMargin;
          _rawMaterialUsage = rawMaterialCosts;
        });
        
        debugPrint('Profit Calculation Complete:');
        debugPrint('  Revenue: ₹$_totalRevenue');
        debugPrint('  Material Cost: ₹$_totalRawMaterialCost');
        debugPrint('  Profit: ₹$_totalProfit');
        debugPrint('  Margin: ${_profitMargin.toStringAsFixed(2)}%');
      }
    } catch (e) {
      debugPrint('Profit calculation error: $e');
    }
  }

  // GET MONTHLY STATISTICS
  Future<Map<String, dynamic>> getMonthlyStatistics() async {
    final today = DateTime.now();
    final monthStart = DateTime(today.year, today.month, 1);
    final monthStartStr = "${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-01";
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    Map<String, dynamic> stats = {
      'revenue': 0.0,
      'material_cost': 0.0,
      'profit': 0.0,
      'margin': 0.0,
      'order_count': 0,
    };

    try {
      // Get revenue from completed orders
      final ordersProvider = context.read<ProductionOrdersProvider>();
      final completedOrders = ordersProvider.orders
          .where((order) => order.status.toLowerCase() == 'completed')
          .toList();
      
      int orderCount = 0;
      double revenue = 0.0;
      
      for (var order in completedOrders) {
        if (order.createdAt.isAfter(monthStart) && order.createdAt.isBefore(today.add(const Duration(days: 1)))) {
          revenue += order.totalPrice;
          orderCount++;
        }
      }
      
      stats['revenue'] = revenue;
      stats['order_count'] = orderCount;

      // Get raw material costs
      final materialResponse = await _supabase
          .from('pro_raw_material_usage')
          .select('total_cost')
          .gte('usage_date', monthStartStr)
          .lte('usage_date', todayStr);

      double materialCost = 0.0;
      for (var usage in materialResponse) {
        materialCost += (usage['total_cost'] ?? 0).toDouble();
      }
      
      stats['material_cost'] = materialCost;
      stats['profit'] = revenue - materialCost;
      stats['margin'] = revenue > 0 ? ((revenue - materialCost) / revenue) * 100 : 0;

    } catch (e) {
      debugPrint('Error getting monthly statistics: $e');
    }
    
    return stats;
  }

  Future<void> _fetchProductionMetrics() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final productionResponse = await _supabase
          .from('pro_production_logs')
          .select('SUM(quantity_produced) as total_quantity')
          .eq('production_date', today)
          .single()
          .catchError((_) => {'total_quantity': 0});
      
      final targetResponse = await _supabase
          .from('pro_production_targets')
          .select('target_quantity')
          .eq('start_date', today)
          .single()
          .catchError((_) => {'target_quantity': 120});
      
      if (mounted) {
        setState(() {
          _todayProduction = (productionResponse['total_quantity'] ?? 0).toDouble();
          _productionTarget = (targetResponse['target_quantity'] ?? 120).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Error fetching production metrics: $e');
    }
  }

  Future<void> _fetchMachineStatus() async {
    try {
      final response = await _supabase
          .from('pro_machines')
          .select('status')
          .eq('is_active', true);
      
      if (mounted) {
        setState(() {
          _activeMachines = response.where((m) => m['status'] == 'running').length;
          _totalMachines = response.length;
          _qualityRate = 95.0 + (DateTime.now().millisecond % 100) * 0.05;
          _qualityRate = double.parse(_qualityRate.toStringAsFixed(1));
        });
      }
    } catch (e) {
      debugPrint('Error fetching machine status: $e');
    }
  }

  Future<void> _fetchRecentOrders() async {
    try {
      final response = await _supabase
          .from('emp_mar_orders')
          .select('*')
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _recentOrders.clear();
          _recentOrders.addAll(List<Map<String, dynamic>>.from(response));
        });
      }
    } catch (e) {
      debugPrint('Error fetching recent orders: $e');
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
            icon: const Icon(Icons.analytics),
            onPressed: () async {
              _showRefreshSnackBar(context);
              await _calculateProfitMetrics();
              final stats = await getMonthlyStatistics();
              _showMonthlyStatsDialog(context, stats);
            },
            tooltip: 'View Monthly Stats',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchAllData();
              _showRefreshSnackBar(context);
            },
            tooltip: 'Refresh All Data',
          ),
          
          
        ],
      ),
      body: _DashboardBody(
        inventoryData: _inventoryData,
        products: _products,
        recentOrders: _recentOrders,
        isLoading: _isLoading,
        todayProduction: _todayProduction,
        productionTarget: _productionTarget,
        activeMachines: _activeMachines,
        totalMachines: _totalMachines,
        qualityRate: _qualityRate,
        totalRevenue: _totalRevenue,
        totalRawMaterialCost: _totalRawMaterialCost,
        totalProfit: _totalProfit,
        profitMargin: _profitMargin,
        rawMaterialUsage: _rawMaterialUsage,
        currencyFormat: _currencyFormat,
        onRefresh: () {
          _fetchAllData();
          _showRefreshSnackBar(context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProRawMaterialEntryPage(),
            ),
          );
        },
        backgroundColor: GlobalColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Record Raw Material Usage',
      ),
    );
  }

  void _showMonthlyStatsDialog(BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Monthly Statistics',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statItem('Total Revenue', '₹${stats['revenue'].toStringAsFixed(2)}', Colors.green),
              _statItem('Raw Material Cost', '₹${stats['material_cost'].toStringAsFixed(2)}', Colors.orange),
              _statItem('Net Profit', '₹${stats['profit'].toStringAsFixed(2)}', 
                  (stats['profit'] as double) >= 0 ? Colors.green : Colors.red),
              _statItem('Profit Margin', '${stats['margin'].toStringAsFixed(2)}%', 
                  (stats['margin'] as double) >= 20 ? Colors.green : Colors.orange),
              _statItem('Completed Orders', stats['order_count'].toString(), Colors.blue),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


}

// Enhanced Dashboard Body Widget with Profit Calculation
class _DashboardBody extends StatelessWidget {
  final List<Map<String, dynamic>> inventoryData;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> recentOrders;
  final bool isLoading;
  final double todayProduction;
  final double productionTarget;
  final int activeMachines;
  final int totalMachines;
  final double qualityRate;
  final double totalRevenue;
  final double totalRawMaterialCost;
  final double totalProfit;
  final double profitMargin;
  final Map<String, double> rawMaterialUsage;
  final NumberFormat currencyFormat;
  final VoidCallback onRefresh;

  const _DashboardBody({
    required this.inventoryData,
    required this.products,
    required this.recentOrders,
    required this.isLoading,
    required this.todayProduction,
    required this.productionTarget,
    required this.activeMachines,
    required this.totalMachines,
    required this.qualityRate,
    required this.totalRevenue,
    required this.totalRawMaterialCost,
    required this.totalProfit,
    required this.profitMargin,
    required this.rawMaterialUsage,
    required this.currencyFormat,
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
                      "${todayProduction.toStringAsFixed(0)} Bags",
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
                        "Target: ${productionTarget.toStringAsFixed(0)} Bags",
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

  Widget _buildProfitMetrics() {
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
                "Monthly Profit & Loss",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  DateFormat('MMM yyyy').format(DateTime.now()),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Revenue
          _profitRow(
            "Total Revenue",
            currencyFormat.format(totalRevenue),
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 12),
          
          // Raw Material Cost
          _profitRow(
            "Raw Material Cost",
            currencyFormat.format(totalRawMaterialCost),
            Icons.inventory,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          
          // Profit
          _profitRow(
            "Net Profit",
            currencyFormat.format(totalProfit),
            Icons.account_balance_wallet,
            totalProfit >= 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 12),
          
          // Profit Margin
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: profitMargin >= 20 
                  ? Colors.green.withOpacity(0.1)
                  : profitMargin >= 10
                      ? Colors.amber.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: profitMargin >= 20 
                    ? Colors.green.withOpacity(0.3)
                    : profitMargin >= 10
                        ? Colors.amber.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      profitMargin >= 20 
                          ? Icons.trending_up
                          : profitMargin >= 10
                              ? Icons.trending_flat
                              : Icons.trending_down,
                      size: 18,
                      color: profitMargin >= 20 
                          ? Colors.green
                          : profitMargin >= 10
                              ? Colors.amber
                              : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Profit Margin",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  "${profitMargin.toStringAsFixed(1)}%",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: profitMargin >= 20 
                        ? Colors.green
                        : profitMargin >= 10
                            ? Colors.amber
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profitRow(String title, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRawMaterialCosts() {
    if (rawMaterialUsage.isEmpty) {
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
                  "Raw Material Costs",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // This would navigate to raw material entry page
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
                          "Add Usage",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: GlobalColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.add,
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
            Container(
              height: 100,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No raw material usage data",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap 'Add Usage' button to start recording",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final sortedMaterials = rawMaterialUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                "Top Raw Material Costs",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                "This Month",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedMaterials.take(5).map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Text(
                    currencyFormat.format(entry.value),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
                onTap: () {},
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
                              "${stock.toStringAsFixed(0)} ${item['unit'] ?? 'kg'}",
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
                                "Below reorder level (${reorder.toStringAsFixed(0)} ${item['unit'] ?? 'kg'})",
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
              _statCard(
                "Products",
                "${products.length}",
                Icons.category,
                Colors.purple,
              ),
              _statCard(
                "Monthly Orders",
                "${recentOrders.length}",
                Icons.shopping_cart,
                Colors.orange,
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
              
              _buildProfitMetrics(),
              const SizedBox(height: 20),
              
              _buildRawMaterialCosts(),
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












//profir does not working code


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:mega_pro/production/pro_inventory_page.dart';
// import 'package:mega_pro/production/pro_orders_from_emp_mar_page.dart';
// import 'package:mega_pro/production/pro_profilePage.dart';
// import 'package:mega_pro/production/pro_raw_material_entry_page.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';

// class ProductionDashboard extends StatefulWidget {
//   final Map<String, dynamic> userData;

//   const ProductionDashboard({super.key, required this.userData});

//   @override
//   State<ProductionDashboard> createState() => _ProductionDashboardState();
// }

// class _ProductionDashboardState extends State<ProductionDashboard> {
//   int _currentIndex = 0;
//   final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
//   // Define routes
//   final List<String> _routeNames = [
//     '/dashboard',
//     '/inventory',
//     '/orders',
//     '/profile',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         if (_navigatorKey.currentState?.canPop() ?? false) {
//           _navigatorKey.currentState?.pop();
//           return false;
//         } else if (_currentIndex != 0) {
//           setState(() => _currentIndex = 0);
//           _navigatorKey.currentState?.pushReplacementNamed('/dashboard');
//           return false;
//         } else {
//           _showExitDialog(context);
//           return false;
//         }
//       },
//       child: Scaffold(
//         key: _scaffoldKey,
//         backgroundColor: GlobalColors.white,
//         body: Navigator(
//           key: _navigatorKey,
//           initialRoute: '/dashboard',
//           onGenerateRoute: (RouteSettings settings) {
//             return MaterialPageRoute(
//               builder: (context) {
//                 return _buildPageForRoute(settings.name ?? '/dashboard');
//               },
//               settings: settings,
//             );
//           },
//         ),
//         bottomNavigationBar: _buildBottomNavigationBar(),
//       ),
//     );
//   }

//   Widget _buildPageForRoute(String routeName) {
//     switch (routeName) {
//       case '/dashboard':
//         return DashboardContent(
//           scaffoldKey: _scaffoldKey,
//           userData: widget.userData,
//         );
//       case '/inventory':
//         return const ProInventoryManager();
//       case '/orders':
//         return ProductionOrdersPage(
//           productionProfile: const {}, 
//           onDataChanged: () {},
//         );
//       case '/profile':
//         return const ProductionProfilePage();
//       default:
//         return DashboardContent(
//           scaffoldKey: _scaffoldKey,
//           userData: widget.userData,
//         );
//     }
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
//         if (_currentIndex != index) {
//           setState(() {
//             _currentIndex = index;
//           });
//           _navigatorKey.currentState?.pushReplacementNamed(_routeNames[index]);
//         }
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
//                   : Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showExitDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierColor: Colors.black38,
//       builder: (context) {
//         return Dialog(
//           insetPadding: const EdgeInsets.symmetric(horizontal: 24),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           backgroundColor: Colors.white,
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: Colors.red.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.exit_to_app,
//                     color: Colors.red,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   "Log Out?",
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Are you sure you want to log out?",
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           side: BorderSide(color: Colors.grey[300]!),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: Text(
//                           "Cancel",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           _logoutAndGoToMainPage(context);
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: Text(
//                           "Log Out",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w500,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _logoutAndGoToMainPage(BuildContext context) {
//     Navigator.of(context).popUntil((route) => route.isFirst);
//     Navigator.pushReplacementNamed(context, '/');
//   }
// }

// // Enhanced Dashboard Content with Profit Calculation
// class DashboardContent extends StatefulWidget {
//   final GlobalKey<ScaffoldState> scaffoldKey;
//   final Map<String, dynamic> userData;
  
//   const DashboardContent({
//     super.key,
//     required this.scaffoldKey,
//     required this.userData,
//   });

//   @override
//   State<DashboardContent> createState() => _DashboardContentState();
// }

// class _DashboardContentState extends State<DashboardContent> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//   final List<Map<String, dynamic>> _inventoryData = [];
//   final List<Map<String, dynamic>> _products = [];
//   final List<Map<String, dynamic>> _recentOrders = [];
//   bool _isLoading = true;
//   Timer? _refreshTimer;
  
//   // Real-time metrics
//   double _todayProduction = 0.0;
//   double _productionTarget = 120.0;
//   int _activeMachines = 0;
//   int _totalMachines = 15;
//   double _qualityRate = 0.0;
//   DateTime? _lastUpdated;
  
//   // Profit Calculation Variables
//   double _totalRawMaterialCost = 0.0;
//   double _totalRevenue = 0.0;
//   double _totalProfit = 0.0;
//   double _profitMargin = 0.0;
  
//   // Raw Material Usage
//   Map<String, double> _rawMaterialUsage = {};
//   final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

//   @override
//   void initState() {
//     super.initState();
//     _fetchAllData();
//     _startRealtimeUpdates();
//   }

//   void _startRealtimeUpdates() {
//     _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       _fetchAllData();
//     });
//   }

//   Future<void> _fetchAllData() async {
//     try {
//       await Future.wait([
//         _fetchInventoryData(),
//         _fetchProducts(),
//         _fetchProductionMetrics(),
//         _fetchMachineStatus(),
//         _fetchRecentOrders(),
//         _calculateProfitMetrics(),
//       ]);
      
//       if (mounted) {
//         setState(() {
//           _lastUpdated = DateTime.now();
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching data: $e');
//     }
//   }

//   Future<void> _fetchInventoryData() async {
//     try {
//       final response = await _supabase
//           .from('pro_inventory')
//           .select('*')
//           .order('name', ascending: true);

//       if (mounted) {
//         setState(() {
//           _inventoryData.clear();
//           _inventoryData.addAll(List<Map<String, dynamic>>.from(response));
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching inventory: $e');
//     }
//   }

//   Future<void> _fetchProducts() async {
//     try {
//       final response = await _supabase
//           .from('pro_products')
//           .select('*')
//           .order('name', ascending: true);

//       if (mounted) {
//         setState(() {
//           _products.clear();
//           _products.addAll(List<Map<String, dynamic>>.from(response));
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching products: $e');
//     }
//   }

//   // NEW PROFIT CALCULATION METHOD
//   Future<void> _calculateProfitMetrics() async {
//     try {
//       final today = DateTime.now();
//       final monthStart = DateTime(today.year, today.month, 1);
      
//       // Format dates
//       final monthStartStr = "${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-01";
//       final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

//       // Get monthly revenue from completed orders
//       final revenueResponse = await _supabase
//           .from('pro_orders')
//           .select('total_amount')
//           .eq('status', 'completed')
//           .gte('order_date', monthStartStr)
//           .lte('order_date', todayStr);

//       double totalRevenue = 0.0;
//       for (var order in revenueResponse) {
//         totalRevenue += (order['total_amount'] ?? 0).toDouble();
//       }

//       // Get raw material usage cost for this month
//       final materialResponse = await _supabase
//           .from('pro_raw_material_usage')
//           .select('quantity_used, pro_inventory!inner(price_per_unit)')
//           .gte('usage_date', monthStartStr)
//           .lte('usage_date', todayStr);

//       double totalRawMaterialCost = 0.0;
//       Map<String, double> rawMaterialCosts = {};

//       for (var usage in materialResponse) {
//         final quantity = (usage['quantity_used'] ?? 0).toDouble();
//         final inventoryData = usage['pro_inventory'] as Map<String, dynamic>?;
        
//         if (inventoryData != null && inventoryData.isNotEmpty) {
//           final price = (inventoryData['price_per_unit'] ?? 0).toDouble();
//           final cost = quantity * price;
//           totalRawMaterialCost += cost;
          
//           // Track individual material costs if needed
//           final materialId = usage['raw_material_id']?.toString() ?? 'unknown';
//           rawMaterialCosts[materialId] = (rawMaterialCosts[materialId] ?? 0) + cost;
//         }
//       }

//       // Calculate profit
//       double totalProfit = totalRevenue - totalRawMaterialCost;
//       double profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

//       if (mounted) {
//         setState(() {
//           _totalRevenue = totalRevenue;
//           _totalRawMaterialCost = totalRawMaterialCost;
//           _totalProfit = totalProfit;
//           _profitMargin = profitMargin;
//           _rawMaterialUsage = rawMaterialCosts;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Profit calculation error: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchProductionMetrics() async {
//     try {
//       final today = DateTime.now().toIso8601String().split('T')[0];
      
//       final productionResponse = await _supabase
//           .from('pro_production_logs')
//           .select('SUM(quantity_produced) as total_quantity')
//           .eq('production_date', today)
//           .single()
//           .catchError((_) => {'total_quantity': 0});
      
//       final targetResponse = await _supabase
//           .from('pro_production_targets')
//           .select('target_quantity')
//           .eq('start_date', today)
//           .single()
//           .catchError((_) => {'target_quantity': 120});
      
//       if (mounted) {
//         setState(() {
//           _todayProduction = (productionResponse['total_quantity'] ?? 0).toDouble();
//           _productionTarget = (targetResponse['target_quantity'] ?? 120).toDouble();
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching production metrics: $e');
//     }
//   }

//   Future<void> _fetchMachineStatus() async {
//     try {
//       final response = await _supabase
//           .from('pro_machines')
//           .select('status')
//           .eq('is_active', true);
      
//       if (mounted) {
//         setState(() {
//           _activeMachines = response.where((m) => m['status'] == 'running').length;
//           _totalMachines = response.length;
//           _qualityRate = 95.0 + (DateTime.now().millisecond % 100) * 0.05;
//           _qualityRate = double.parse(_qualityRate.toStringAsFixed(1));
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching machine status: $e');
//     }
//   }

//   Future<void> _fetchRecentOrders() async {
//     try {
//       final response = await _supabase
//           .from('pro_orders')
//           .select('*')
//           .eq('status', 'completed')
//           .order('order_date', ascending: false)
//           .limit(5);

//       if (mounted) {
//         setState(() {
//           _recentOrders.clear();
//           _recentOrders.addAll(List<Map<String, dynamic>>.from(response));
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching recent orders: $e');
//     }
//   }

//   void _showRefreshSnackBar(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text('Refreshing data...'),
//         backgroundColor: GlobalColors.primaryBlue,
//         duration: const Duration(seconds: 1),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _refreshTimer?.cancel();
//     super.dispose();
//   }

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
//             const SizedBox(height: 2),
//             if (_lastUpdated != null)
//               Text(
//                 "Updated: ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}",
//                 style: GoogleFonts.poppins(
//                   fontSize: 11,
//                   color: Colors.white.withOpacity(0.8),
//                 ),
//               ),
//           ],
//         ),
//         centerTitle: false,
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.menu),
//           onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
//         ),
//         actions: [
//           // ADD RAW MATERIAL ENTRY BUTTON
//           IconButton(
//             icon: const Icon(Icons.add_chart),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => _RawMaterialEntryPage(),
//                 ),
//               );
//             },
//             tooltip: 'Record Raw Material Usage',
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               _fetchAllData();
//               _showRefreshSnackBar(context);
//             },
//             tooltip: 'Refresh Data',
//           ),
//           IconButton(
//             icon: const Icon(Icons.exit_to_app),
//             onPressed: () => _showLogoutDialog(context),
//             tooltip: 'Log Out',
//           ),
//         ],
//       ),
//       body: _DashboardBody(
//         inventoryData: _inventoryData,
//         products: _products,
//         recentOrders: _recentOrders,
//         isLoading: _isLoading,
//         todayProduction: _todayProduction,
//         productionTarget: _productionTarget,
//         activeMachines: _activeMachines,
//         totalMachines: _totalMachines,
//         qualityRate: _qualityRate,
//         totalRevenue: _totalRevenue,
//         totalRawMaterialCost: _totalRawMaterialCost,
//         totalProfit: _totalProfit,
//         profitMargin: _profitMargin,
//         rawMaterialUsage: _rawMaterialUsage,
//         currencyFormat: _currencyFormat,
//         onRefresh: () {
//           _fetchAllData();
//           _showRefreshSnackBar(context);
//         },
//       ),
//       // ADD FLOATING ACTION BUTTON FOR QUICK ACCESS
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => ProRawMaterialEntryPage(),
//             ),
//           );
//         },
//         backgroundColor: GlobalColors.primaryBlue,
//         child: const Icon(Icons.add, color: Colors.white),
//         tooltip: 'Record Raw Material Usage',
//       ),
//     );
//   }

//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierColor: Colors.black38,
//       builder: (context) {
//         return Dialog(
//           insetPadding: const EdgeInsets.symmetric(horizontal: 24),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           backgroundColor: Colors.white,
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: Colors.red.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.exit_to_app,
//                     color: Colors.red,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   "Log Out?",
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Are you sure you want to log out?",
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           side: BorderSide(color: Colors.grey[300]!),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: Text(
//                           "Cancel",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           _logoutAndGoToMainPage(context);
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: Text(
//                           "Log Out",
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w500,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _logoutAndGoToMainPage(BuildContext context) {
//     Navigator.of(context).popUntil((route) => route.isFirst);
//     Navigator.pushReplacementNamed(context, '/');
//   }
// }

// // ============================================================
// // RAW MATERIAL ENTRY PAGE (Added as inner class for simplicity)
// // ============================================================

// class _RawMaterialEntryPage extends StatefulWidget {
//   @override
//   State<_RawMaterialEntryPage> createState() => __RawMaterialEntryPageState();
// }

// class __RawMaterialEntryPageState extends State<_RawMaterialEntryPage> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//   final _formKey = GlobalKey<FormState>();
  
//   List<Map<String, dynamic>> _rawMaterials = [];
//   List<Map<String, dynamic>> _products = [];
//   bool _isLoading = false;
  
//   // Form fields
//   String? _selectedMaterialId;
//   String? _selectedProductId;
//   TextEditingController _quantityController = TextEditingController();
//   TextEditingController _batchController = TextEditingController();
//   TextEditingController _notesController = TextEditingController();
//   DateTime _selectedDate = DateTime.now();
  
//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//     _batchController.text = "BATCH-${DateFormat('yyMMdd').format(DateTime.now())}";
//   }
  
//   Future<void> _fetchData() async {
//     try {
//       setState(() => _isLoading = true);
      
//       await Future.wait([
//         _fetchRawMaterials(),
//         _fetchProducts(),
//       ]);
//     } catch (e) {
//       debugPrint('Error fetching data: $e');
//       _showErrorSnackBar('Failed to load data');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
  
//   Future<void> _fetchRawMaterials() async {
//     try {
//       final response = await _supabase
//           .from('pro_inventory')
//           .select('id, name, stock, unit, price_per_unit')
//           .order('name');
      
//       setState(() {
//         _rawMaterials = List<Map<String, dynamic>>.from(response);
//       });
//     } catch (e) {
//       debugPrint('Error fetching raw materials: $e');
//     }
//   }
  
//   Future<void> _fetchProducts() async {
//     try {
//       final response = await _supabase
//           .from('pro_products')
//           .select('id, name, weight, unit')
//           .order('name');
      
//       setState(() {
//         _products = List<Map<String, dynamic>>.from(response);
//       });
//     } catch (e) {
//       debugPrint('Error fetching products: $e');
//     }
//   }
  
//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) return;
    
//     if (_selectedMaterialId == null) {
//       _showErrorSnackBar('Please select a raw material');
//       return;
//     }
    
//     final quantity = double.tryParse(_quantityController.text);
//     if (quantity == null || quantity <= 0) {
//       _showErrorSnackBar('Please enter a valid quantity');
//       return;
//     }
    
//     try {
//       setState(() => _isLoading = true);
      
//       // 1. Insert raw material usage record
//       await _supabase.from('pro_raw_material_usage').insert({
//         'raw_material_id': _selectedMaterialId,
//         'product_id': _selectedProductId,
//         'quantity_used': quantity,
//         'usage_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
//         'batch_number': _batchController.text.isNotEmpty ? _batchController.text : null,
//         'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
//       });
      
//       // 2. Update inventory stock (reduce stock)
//       final material = _rawMaterials.firstWhere(
//         (m) => m['id'].toString() == _selectedMaterialId,
//         orElse: () => {},
//       );
      
//       if (material.isNotEmpty) {
//         final currentStock = (material['stock'] ?? 0).toDouble();
//         final newStock = currentStock - quantity;
        
//         await _supabase
//             .from('pro_inventory')
//             .update({'stock': newStock})
//             .eq('id', _selectedMaterialId as Object);
//       }
      
//       // 3. Show success message
//       _showSuccessSnackBar('Raw material usage recorded successfully!');
      
//       // 4. Reset form
//       _formKey.currentState!.reset();
//       _selectedMaterialId = null;
//       _selectedProductId = null;
//       _quantityController.clear();
//       _batchController.text = "BATCH-${DateFormat('yyMMdd').format(DateTime.now())}";
//       _notesController.clear();
//       _selectedDate = DateTime.now();
      
//       // 5. Refresh data
//       _fetchData();
      
//     } catch (e) {
//       debugPrint('Error submitting form: $e');
//       _showErrorSnackBar('Failed to save data: ${e.toString()}');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
  
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
  
//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
  
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() => _selectedDate = picked);
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Record Raw Material Usage',
//           style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: GlobalColors.primaryBlue,
//         foregroundColor: Colors.white,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Date Selection
//                     InkWell(
//                       onTap: () => _selectDate(context),
//                       child: Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[50],
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.grey[300]!),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Usage Date',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   DateFormat('dd MMM yyyy').format(_selectedDate),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Icon(Icons.calendar_today, color: GlobalColors.primaryBlue),
//                           ],
//                         ),
//                       ),
//                     ),
                    
//                     const SizedBox(height: 20),
                    
//                     // Raw Material Dropdown
//                     Text(
//                       'Raw Material *',
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: DropdownButtonFormField<String>(
//                         value: _selectedMaterialId,
//                         decoration: const InputDecoration(
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                         ),
//                         hint: Text(
//                           'Select Raw Material',
//                           style: GoogleFonts.poppins(color: Colors.grey[600]),
//                         ),
//                         items: _rawMaterials.map((material) {
//                           final currentStock = (material['stock'] ?? 0).toDouble();
//                           final unit = material['unit'] ?? 'kg';
//                           final price = (material['price_per_unit'] ?? 0).toDouble();
                          
//                           return DropdownMenuItem(
//                             value: material['id'].toString(),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   material['name'] ?? 'Unknown',
//                                   style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                                 ),
//                                 Text(
//                                   'Stock: ${currentStock.toStringAsFixed(0)} $unit • ₹$price/$unit',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() => _selectedMaterialId = value);
//                         },
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please select a raw material';
//                           }
//                           return null;
//                         },
//                       ),
//                     ),
                    
//                     const SizedBox(height: 20),
                    
//                     // Product Dropdown (Optional)
//                     Text(
//                       'Product (Optional)',
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: DropdownButtonFormField<String>(
//                         value: _selectedProductId,
//                         decoration: const InputDecoration(
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                         ),
//                         hint: Text(
//                           'Select Product (Optional)',
//                           style: GoogleFonts.poppins(color: Colors.grey[600]),
//                         ),
//                         items: [
//                           DropdownMenuItem(
//                             value: null,
//                             child: Text(
//                               'Not linked to product',
//                               style: GoogleFonts.poppins(color: Colors.grey[600]),
//                             ),
//                           ),
//                           ..._products.map((product) {
//                             return DropdownMenuItem(
//                               value: product['id'].toString(),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     product['name'] ?? 'Unknown',
//                                     style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                                   ),
//                                   Text(
//                                     '${product['weight']} ${product['unit']}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 12,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }),
//                         ],
//                         onChanged: (value) {
//                           setState(() => _selectedProductId = value);
//                         },
//                       ),
//                     ),
                    
//                     const SizedBox(height: 20),
                    
//                     // Quantity Input
//                     TextFormField(
//                       controller: _quantityController,
//                       decoration: InputDecoration(
//                         labelText: 'Quantity Used *',
//                         labelStyle: GoogleFonts.poppins(),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         prefixIcon: Icon(Icons.scale, color: GlobalColors.primaryBlue),
//                         suffixText: _getUnitForSelectedMaterial(),
//                       ),
//                       keyboardType: TextInputType.number,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter quantity';
//                         }
//                         final quantity = double.tryParse(value);
//                         if (quantity == null || quantity <= 0) {
//                           return 'Enter valid quantity';
//                         }
//                         return null;
//                       },
//                     ),
                    
//                     const SizedBox(height: 20),
                    
//                     // Batch Number
//                     TextFormField(
//                       controller: _batchController,
//                       decoration: InputDecoration(
//                         labelText: 'Batch Number',
//                         labelStyle: GoogleFonts.poppins(),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         prefixIcon: Icon(Icons.qr_code, color: GlobalColors.primaryBlue),
//                       ),
//                     ),
                    
//                     const SizedBox(height: 20),
                    
//                     // Notes
//                     TextFormField(
//                       controller: _notesController,
//                       decoration: InputDecoration(
//                         labelText: 'Notes (Optional)',
//                         labelStyle: GoogleFonts.poppins(),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         prefixIcon: Icon(Icons.note, color: GlobalColors.primaryBlue),
//                       ),
//                       maxLines: 3,
//                     ),
                    
//                     const SizedBox(height: 30),
                    
//                     // Submit Button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _submitForm,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: GlobalColors.primaryBlue,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: _isLoading
//                             ? const CircularProgressIndicator(color: Colors.white)
//                             : Text(
//                                 'Record Usage',
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                       ),
//                     ),
                    
//                     const SizedBox(height: 20),
                    
//                     // Information Card
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: GlobalColors.primaryBlue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: GlobalColors.primaryBlue.withOpacity(0.3)),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(Icons.info, color: GlobalColors.primaryBlue),
//                               const SizedBox(width: 8),
//                               Text(
//                                 'Important Notes',
//                                 style: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.w600,
//                                   color: GlobalColors.primaryBlue,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '• Recording raw material usage will automatically deduct from inventory stock\n'
//                             '• This data is used for accurate profit calculation\n'
//                             '• Make sure to record usage daily for accurate reports',
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
  
//   String _getUnitForSelectedMaterial() {
//     if (_selectedMaterialId == null) return 'kg';
//     final material = _rawMaterials.firstWhere(
//       (m) => m['id'].toString() == _selectedMaterialId,
//       orElse: () => {'unit': 'kg'},
//     );
//     return material['unit'] ?? 'kg';
//   }
  
//   @override
//   void dispose() {
//     _quantityController.dispose();
//     _batchController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }
// }

// // Enhanced Dashboard Body Widget with Profit Calculation
// class _DashboardBody extends StatelessWidget {
//   final List<Map<String, dynamic>> inventoryData;
//   final List<Map<String, dynamic>> products;
//   final List<Map<String, dynamic>> recentOrders;
//   final bool isLoading;
//   final double todayProduction;
//   final double productionTarget;
//   final int activeMachines;
//   final int totalMachines;
//   final double qualityRate;
//   final double totalRevenue;
//   final double totalRawMaterialCost;
//   final double totalProfit;
//   final double profitMargin;
//   final Map<String, double> rawMaterialUsage;
//   final NumberFormat currencyFormat;
//   final VoidCallback onRefresh;

//   const _DashboardBody({
//     required this.inventoryData,
//     required this.products,
//     required this.recentOrders,
//     required this.isLoading,
//     required this.todayProduction,
//     required this.productionTarget,
//     required this.activeMachines,
//     required this.totalMachines,
//     required this.qualityRate,
//     required this.totalRevenue,
//     required this.totalRawMaterialCost,
//     required this.totalProfit,
//     required this.profitMargin,
//     required this.rawMaterialUsage,
//     required this.currencyFormat,
//     required this.onRefresh,
//   });

//   Widget _buildProductionMetrics() {
//     final progress = productionTarget > 0 ? todayProduction / productionTarget : 0;
//     final isTargetAchieved = todayProduction >= productionTarget;
    
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
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Today's Production",
//                       style: GoogleFonts.poppins(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       "${todayProduction.toStringAsFixed(0)} Bags",
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     CircularProgressIndicator(
//                       value: progress > 1 ? 1.0 : progress.toDouble(),
//                       strokeWidth: 6,
//                       backgroundColor: Colors.white.withOpacity(0.3),
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         isTargetAchieved ? Colors.green : Colors.amber,
//                       ),
//                     ),
//                     Text(
//                       "${(progress * 100).toStringAsFixed(0)}%",
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.flag, size: 14, color: Colors.white),
//                       const SizedBox(width: 6),
//                       Text(
//                         "Target: ${productionTarget.toStringAsFixed(0)} Bags",
//                         style: GoogleFonts.poppins(
//                           color: Colors.white,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               IconButton(
//                 icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
//                 onPressed: onRefresh,
//                 tooltip: 'Refresh Production',
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfitMetrics() {
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
//                 "Monthly Profit & Loss",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[800],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Text(
//                   "This Month",
//                   style: GoogleFonts.poppins(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
          
//           // Revenue
//           _profitRow(
//             "Total Revenue",
//             currencyFormat.format(totalRevenue),
//             Icons.trending_up,
//             Colors.green,
//           ),
//           const SizedBox(height: 12),
          
//           // Raw Material Cost
//           _profitRow(
//             "Raw Material Cost",
//             currencyFormat.format(totalRawMaterialCost),
//             Icons.inventory,
//             Colors.orange,
//           ),
//           const SizedBox(height: 12),
          
//           // Profit
//           _profitRow(
//             "Net Profit",
//             currencyFormat.format(totalProfit),
//             Icons.account_balance_wallet,
//             totalProfit >= 0 ? Colors.green : Colors.red,
//           ),
//           const SizedBox(height: 12),
          
//           // Profit Margin
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: profitMargin >= 20 
//                   ? Colors.green.withOpacity(0.1)
//                   : profitMargin >= 10
//                       ? Colors.amber.withOpacity(0.1)
//                       : Colors.red.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: profitMargin >= 20 
//                     ? Colors.green.withOpacity(0.3)
//                     : profitMargin >= 10
//                         ? Colors.amber.withOpacity(0.3)
//                         : Colors.red.withOpacity(0.3),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       profitMargin >= 20 
//                           ? Icons.trending_up
//                           : profitMargin >= 10
//                               ? Icons.trending_flat
//                               : Icons.trending_down,
//                       size: 18,
//                       color: profitMargin >= 20 
//                           ? Colors.green
//                           : profitMargin >= 10
//                               ? Colors.amber
//                               : Colors.red,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       "Profit Margin",
//                       style: GoogleFonts.poppins(
//                         fontSize: 13,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                   ],
//                 ),
//                 Text(
//                   "${profitMargin.toStringAsFixed(1)}%",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                     color: profitMargin >= 20 
//                         ? Colors.green
//                         : profitMargin >= 10
//                             ? Colors.amber
//                             : Colors.red,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _profitRow(String title, String value, IconData icon, Color color) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(icon, size: 18, color: color),
//             ),
//             const SizedBox(width: 12),
//             Text(
//               title,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ],
//         ),
//         Text(
//           value,
//           style: GoogleFonts.poppins(
//             fontSize: 16,
//             fontWeight: FontWeight.w700,
//             color: color,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRawMaterialCosts() {
//     if (rawMaterialUsage.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "Raw Material Costs",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     // This would navigate to raw material entry page
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: GlobalColors.primaryBlue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Row(
//                       children: [
//                         Text(
//                           "Add Usage",
//                           style: GoogleFonts.poppins(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             color: GlobalColors.primaryBlue,
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         Icon(
//                           Icons.add,
//                           size: 10,
//                           color: GlobalColors.primaryBlue,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Container(
//               height: 100,
//               alignment: Alignment.center,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.analytics_outlined,
//                     size: 40,
//                     color: Colors.grey[400],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     "No raw material usage data",
//                     style: GoogleFonts.poppins(
//                       color: Colors.grey[500],
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     "Tap 'Add Usage' button to start recording",
//                     style: GoogleFonts.poppins(
//                       fontSize: 12,
//                       color: Colors.grey[400],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     final sortedMaterials = rawMaterialUsage.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

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
//                 "Top Raw Material Costs",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[800],
//                 ),
//               ),
//               Text(
//                 "This Month",
//                 style: GoogleFonts.poppins(
//                   fontSize: 11,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           ...sortedMaterials.take(5).map((entry) {
//             // Find material name
//             String materialName = 'Unknown Material';
//             for (var item in inventoryData) {
//               if (item['id'].toString() == entry.key) {
//                 materialName = item['name']?.toString() ?? 'Unknown Material';
//                 break;
//               }
//             }
            
//             return Container(
//               margin: const EdgeInsets.only(bottom: 10),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       materialName,
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                   ),
//                   Text(
//                     currencyFormat.format(entry.value),
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.orange,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
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
//                 onTap: () {},
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

//           if (isLoading)
//             Container(
//               height: 200,
//               child: const Center(
//                 child: CircularProgressIndicator(color: GlobalColors.primaryBlue),
//               ),
//             )
//           else if (inventoryData.isEmpty)
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
//               children: inventoryData.take(4).map((item) {
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
//                               "${stock.toStringAsFixed(0)} ${item['unit'] ?? 'kg'}",
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
//                                 "Below reorder level (${reorder.toStringAsFixed(0)} ${item['unit'] ?? 'kg'})",
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
//                 "$activeMachines/$totalMachines",
//                 Icons.settings,
//                 Colors.blue,
//               ),
//               _statCard(
//                 "Quality Rate",
//                 "${qualityRate.toStringAsFixed(1)}%",
//                 Icons.verified,
//                 Colors.green,
//               ),
//               _statCard(
//                 "Products",
//                 "${products.length}",
//                 Icons.category,
//                 Colors.purple,
//               ),
//               _statCard(
//                 "Monthly Orders",
//                 "${recentOrders.length}",
//                 Icons.shopping_cart,
//                 Colors.orange,
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
              
//               _buildProfitMetrics(),
//               const SizedBox(height: 20),
              
//               _buildRawMaterialCosts(),
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














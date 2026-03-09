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
import 'package:mega_pro/providers/pro_inventory_provider.dart';

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

  void _navigateToPage(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _navigatorKey.currentState?.pushReplacementNamed(_routeNames[index]);
    }
    // Close drawer if open
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (_navigatorKey.currentState?.canPop() ?? false) {
          _navigatorKey.currentState?.pop();
          return false;
        } else if (_currentIndex != 0) {
          _navigateToPage(0);
          return false;
        } else {
          _showExitDialog(context);
          return false;
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: GlobalColors.white,
        drawer: _buildDrawer(),
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

  Widget _buildDrawer() {
    final userData = widget.userData;
    final userName = userData['name'] ?? userData['employee_name'] ?? 'Production User';
    final userRole = userData['role'] ?? userData['designation'] ?? 'Production Manager';
    final userEmail = userData['email'] ?? 'production@mega-pro.com';
    
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header with user info
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            decoration: BoxDecoration(
              color: GlobalColors.primaryBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: GlobalColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: GlobalColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              userRole,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, size: 16, color: Colors.white.withOpacity(0.8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userEmail,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDrawerItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  selectedIcon: Icons.dashboard,
                ),
                _buildDrawerItem(
                  index: 1,
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  selectedIcon: Icons.inventory_2,
                ),
                _buildDrawerItem(
                  index: 2,
                  icon: Icons.assignment_outlined,
                  label: 'Orders',
                  selectedIcon: Icons.assignment,
                ),
                _buildDrawerItem(
                  index: 3,
                  icon: Icons.person_outline,
                  label: 'Profile',
                  selectedIcon: Icons.person,
                ),
                
                const Divider(height: 32, thickness: 1),
                
                // Additional Items
                _buildDrawerItem(
                  index: -1,
                  icon: Icons.inventory,
                  label: 'Raw Material Entry',
                  selectedIcon: Icons.inventory,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProRawMaterialEntryPage(),
                      ),
                    );
                  },
                ),
                
                _buildDrawerItem(
                  index: -2,
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  selectedIcon: Icons.analytics,
                  onTap: () {
                    Navigator.pop(context);
                    _showAnalyticsDialog();
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Settings and Support Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'SUPPORT',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                
                _buildDrawerItem(
                  index: -3,
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  selectedIcon: Icons.help,
                  onTap: () {
                    Navigator.pop(context);
                    _showHelpDialog();
                  },
                ),
                
                _buildDrawerItem(
                  index: -4,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  selectedIcon: Icons.settings,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon...')),
                    );
                  },
                ),
                
                const Divider(height: 32, thickness: 1),
                
                // Logout Button
                _buildDrawerItem(
                  index: -5,
                  icon: Icons.logout,
                  label: 'Logout',
                  selectedIcon: Icons.logout,
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Version Info
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required IconData icon,
    required String label,
    required IconData selectedIcon,
    VoidCallback? onTap,
    Color? color,
  }) {
    final isSelected = index >= 0 && _currentIndex == index;
    final itemColor = color ?? (isSelected ? GlobalColors.primaryBlue : Colors.grey[700]);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? GlobalColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: itemColor,
          size: 22,
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: itemColor,
        ),
      ),
      selected: isSelected,
      selectedTileColor: GlobalColors.primaryBlue.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onTap: onTap ?? () => _navigateToPage(index),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Detailed analytics will be available soon.\n\nTrack production metrics, efficiency, and performance in real-time.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Help & Support', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactItem(Icons.email, 'support@mega-pro.in'),
            const SizedBox(height: 12),
            _buildContactItem(Icons.phone, '+91 1234567890'),
            const SizedBox(height: 12),
            _buildContactItem(Icons.access_time, '24/7 Support Available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: GlobalColors.primaryBlue),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.poppins(fontSize: 13)),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logoutAndGoToMainPage(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Logout', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildPageForRoute(String routeName) {
    switch (routeName) {
      case '/dashboard':
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<ProductionOrdersProvider>(
              create: (_) => ProductionOrdersProvider(),
            ),
            ChangeNotifierProvider<InventoryProvider>(
              create: (_) => InventoryProvider(),
            ),
          ],
          child: DashboardContent(
            scaffoldKey: _scaffoldKey,
            userData: widget.userData,
          ),
        );
      case '/inventory':
        return ChangeNotifierProvider<InventoryProvider>(
          create: (_) => InventoryProvider(),
          child: const ProInventoryManager(),
        );
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
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<ProductionOrdersProvider>(
              create: (_) => ProductionOrdersProvider(),
            ),
            ChangeNotifierProvider<InventoryProvider>(
              create: (_) => InventoryProvider(),
            ),
          ],
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
              _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, "Dashboard"),
              _buildNavItem(1, Icons.inventory_2_outlined, Icons.inventory_2, "Inventory"),
              _buildNavItem(2, Icons.assignment_outlined, Icons.assignment, "Orders"),
              _buildNavItem(3, Icons.person_outline, Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    return GestureDetector(
      onTap: () => _navigateToPage(index),
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
              _currentIndex == index ? selectedIcon : icon,
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

  void _logoutAndGoToMainPage(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacementNamed(context, '/');
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
                    // ignore: deprecated_member_use
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
}

// Enhanced Dashboard Content with Real-time Profit Calculation
// Enhanced Dashboard Content with Real-time Profit Calculation
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
  double _qualityRate = 0.0;
  DateTime? _lastUpdated;
  
  // Profit Calculation Variables
  double _totalRawMaterialCost = 0.0;
  double _totalRevenue = 0.0;
  double _totalProfit = 0.0;
  double _profitMargin = 0.0;
  
  // Raw Material Usage
  Map<String, double> _rawMaterialUsage = {};
  
  // Total Bags from Inventory
  double _totalInventoryBags = 0.0;
  
  // Realtime subscriptions
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _materialUsageSubscription;
  StreamSubscription? _inventorySubscription;
  
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Delay initial load to ensure providers are ready
    Future.delayed(const Duration(milliseconds: 100), () {
      _fetchAllData();
    });
    _startRealtimeUpdates();
    _setupRealtimeSubscriptions();
  }

  void _startRealtimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _fetchAllData();
      }
    });
  }

  void _setupRealtimeSubscriptions() {
    print('🔔 Setting up real-time financial data subscriptions...');
    
    try {
      // Subscribe to order changes (affects revenue)
      _ordersSubscription = _supabase
          .from('emp_mar_orders')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> updates) {
            print('🔄 Orders changed (${updates.length} updates), updating profit metrics...');
            _handleRealtimeUpdate('orders');
          }, onError: (error) {
            print('❌ Orders subscription error: $error');
          });

      // Subscribe to raw material usage changes (affects costs)
      _materialUsageSubscription = _supabase
          .from('pro_raw_material_usage')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> updates) {
            print('🔄 Material usage changed (${updates.length} updates), updating profit metrics...');
            _handleRealtimeUpdate('material_usage');
          }, onError: (error) {
            print('❌ Material usage subscription error: $error');
          });

      // Subscribe to inventory changes (affects available stock)
      _inventorySubscription = _supabase
          .from('production_products')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> updates) {
            print('🔄 Inventory changed (${updates.length} updates), updating...');
            _handleRealtimeUpdate('inventory');
          }, onError: (error) {
            print('❌ Inventory subscription error: $error');
          });

      print('✅ All real-time subscriptions established');
    } catch (e) {
      print('❌ Failed to setup real-time subscriptions: $e');
    }
  }

  Future<void> _handleRealtimeUpdate(String updateType) async {
    if (!mounted) return;
    
    print('🔄 Handling realtime update for: $updateType');
    
    try {
      switch (updateType) {
        case 'orders':
          // Only refresh revenue-related data
          await Future.wait([
            _calculateProfitMetrics(),
            _fetchRecentOrders(),
          ]);
          break;
          
        case 'material_usage':
          // Only refresh cost-related data
          await _calculateProfitMetrics();
          break;
          
        case 'inventory':
          // Only refresh inventory-related data
          await Future.wait([
            _fetchTotalInventoryBags(),
            _fetchInventoryData(),
            _fetchProducts(),
          ]);
          break;
          
        default:
          await _fetchAllData();
      }
      
      if (mounted) {
        setState(() {
          _lastUpdated = DateTime.now();
        });
      }
      
      debugPrint('✅ Realtime update processed for: $updateType at ${_lastUpdated}');
    } catch (e) {
      debugPrint('❌ Error handling realtime update: $e');
    }
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Run all fetches in parallel for better performance
      await Future.wait([
        _fetchInventoryData(),
        _fetchProducts(),
        _fetchProductionMetrics(),
        _fetchMachineStatus(),
        _fetchRecentOrders(),
        _fetchTotalInventoryBags(),
        _calculateProfitMetrics(),
      ]);
      
      if (mounted) {
        setState(() {
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });
        
        debugPrint('✅ All data fetched successfully at ${_lastUpdated}');
        debugPrint('📦 Total bags: $_totalInventoryBags');
        debugPrint('💰 Revenue: $_totalRevenue');
        debugPrint('💸 Material Cost: $_totalRawMaterialCost');
        debugPrint('📈 Profit: $_totalProfit');
      }
    } catch (e) {
      debugPrint('❌ Error fetching data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTotalInventoryBags() async {
    try {
      // Direct database query for total bags
      final response = await _supabase
          .from('production_products')
          .select('bags')
          .eq('is_active', true);

      double totalBags = 0.0;
      for (var item in response) {
        totalBags += (item['bags'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          _totalInventoryBags = totalBags;
        });
      }
      
      debugPrint('📊 Direct DB query - Total bags: $totalBags');
    } catch (e) {
      debugPrint('Error fetching total bags: $e');
      if (mounted) {
        setState(() {
          _totalInventoryBags = 0.0;
        });
      }
    }
  }

  Future<void> _fetchInventoryData() async {
    try {
      final response = await _supabase
          .from('production_products')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _inventoryData.clear();
          _inventoryData.addAll(List<Map<String, dynamic>>.from(response));
        });
      }
      
      debugPrint('📦 Inventory data fetched: ${_inventoryData.length} items');
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _supabase
          .from('production_products')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _products.clear();
          _products.addAll(List<Map<String, dynamic>>.from(response));
        });
      }
      
      debugPrint('📋 Products fetched: ${_products.length} items');
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  Future<void> _calculateProfitMetrics() async {
    try {
      final today = DateTime.now();
      final monthStart = DateTime(today.year, today.month, 1);
      
      double totalRevenue = 0.0;
      double totalRawMaterialCost = 0.0;
      Map<String, double> rawMaterialCosts = {};

      final monthStartStr = "${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-01";
      final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      debugPrint('📊 Calculating profit metrics for period: $monthStartStr to $todayStr');

      final revenueResponse = await _supabase
          .from('emp_mar_orders')
          .select('total_price')
          .eq('status', 'completed')
          .gte('created_at', monthStartStr)
          .lte('created_at', todayStr);

      for (var order in revenueResponse) {
        totalRevenue += (order['total_price'] ?? 0).toDouble();
      }
      
      debugPrint('💰 Revenue fetched: ₹$totalRevenue');

      // Get raw material usage cost for this month
      final materialResponse = await _supabase
          .from('pro_raw_material_usage')
          .select('total_cost, raw_material_id, pro_inventory!inner(name)')
          .gte('usage_date', monthStartStr)
          .lte('usage_date', todayStr);

      for (var usage in materialResponse) {
        final cost = (usage['total_cost'] ?? 0).toDouble();
        totalRawMaterialCost += cost;
        
        final inventoryData = usage['pro_inventory'] as Map<String, dynamic>?;
        final materialName = inventoryData?['name']?.toString() ?? 'Unknown Material';
        
        rawMaterialCosts[materialName] = (rawMaterialCosts[materialName] ?? 0) + cost;
      }

      debugPrint('💰 Material cost fetched: ₹$totalRawMaterialCost');

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
        
        debugPrint('✅ Profit Calculation Complete:');
        debugPrint('  Revenue: ₹$_totalRevenue');
        debugPrint('  Material Cost: ₹$_totalRawMaterialCost');
        debugPrint('  Profit: ₹$_totalProfit');
        debugPrint('  Margin: ${_profitMargin.toStringAsFixed(2)}%');
      }
    } catch (e) {
      debugPrint('❌ Profit calculation error: $e');
      if (mounted) {
        // Set default values on error
        setState(() {
          _totalRevenue = 0.0;
          _totalRawMaterialCost = 0.0;
          _totalProfit = 0.0;
          _profitMargin = 0.0;
          _rawMaterialUsage = {};
        });
      }
    }
  }

  Future<void> _fetchProductionMetrics() async {
    try {
      
      
      
      if (mounted) {
        setState(() {
        });
      }
    } catch (e) {
      debugPrint('Error fetching production metrics: $e');
    }
  }

  Future<void> _fetchMachineStatus() async {
    try {
      
      if (mounted) {
        setState(() {
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
    _ordersSubscription?.cancel();
    _materialUsageSubscription?.cancel();
    _inventorySubscription?.cancel();
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
                "Updated: ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}:${_lastUpdated!.second.toString().padLeft(2, '0')}",
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
            tooltip: 'Refresh All Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: GlobalColors.primaryBlue,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchAllData();
                _showRefreshSnackBar(context);
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInventorySummary(),
                      const SizedBox(height: 20),
                      
                      _buildProfitMetrics(),
                      const SizedBox(height: 20),
                      
                      _buildRawMaterialCosts(),
                      const SizedBox(height: 20),
                      
                      _buildInventoryStatus(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProRawMaterialEntryPage(),
            ),
          ).then((_) {
            // Refresh data when returning from raw material entry
            _fetchAllData();
          });
        },
        backgroundColor: GlobalColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Record Raw Material Usage',
      ),
    );
  }

  // Moved all the _build methods here so they can access the state variables directly
  Widget _buildInventorySummary() {
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
                "Inventory Summary",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),             
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Bags",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _totalInventoryBags.toStringAsFixed(0),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "in inventory",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    size: 32,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Based on ${_products.length} products in inventory",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
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
            _currencyFormat.format(_totalRevenue),
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 12),
          
          // Raw Material Cost
          _profitRow(
            "Raw Material Cost",
            _currencyFormat.format(_totalRawMaterialCost),
            Icons.inventory,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          
          // Profit
          _profitRow(
            "Net Profit",
            _currencyFormat.format(_totalProfit),
            Icons.account_balance_wallet,
            _totalProfit >= 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 12),
          
          // Profit Margin
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _profitMargin >= 20 
                  ? Colors.green.withOpacity(0.1)
                  : _profitMargin >= 10
                      ? Colors.amber.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _profitMargin >= 20 
                    ? Colors.green.withOpacity(0.3)
                    : _profitMargin >= 10
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
                      _profitMargin >= 20 
                          ? Icons.trending_up
                          : _profitMargin >= 10
                              ? Icons.trending_flat
                              : Icons.trending_down,
                      size: 18,
                      color: _profitMargin >= 20 
                          ? Colors.green
                          : _profitMargin >= 10
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
                  "${_profitMargin.toStringAsFixed(1)}%",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _profitMargin >= 20 
                        ? Colors.green
                        : _profitMargin >= 10
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
    if (_rawMaterialUsage.isEmpty) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProRawMaterialEntryPage(),
                      ),
                    ).then((_) {
                      _fetchAllData();
                    });
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

    final sortedMaterials = _rawMaterialUsage.entries.toList()
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
                    _currencyFormat.format(entry.value),
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
              
            ],
          ),
          const SizedBox(height: 12),

          if (_inventoryData.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
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
            )
          else
            Column(
              children: _inventoryData.take(4).map((item) {
                final stock = (item['bags'] ?? 0).toDouble();
                final reorder = (item['min_bags_stock'] ?? 10).toDouble();
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
                              "${stock.toStringAsFixed(0)} bags",
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
                                "Below reorder level (${reorder.toStringAsFixed(0)} bags)",
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
}





















//refresh issue


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
// import 'package:provider/provider.dart';
// import 'package:mega_pro/providers/pro_orders_provider.dart';
// import 'package:mega_pro/providers/pro_inventory_provider.dart';

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

//   void _navigateToPage(int index) {
//     if (_currentIndex != index) {
//       setState(() {
//         _currentIndex = index;
//       });
//       _navigatorKey.currentState?.pushReplacementNamed(_routeNames[index]);
//     }
//     // Close drawer if open
//     _scaffoldKey.currentState?.closeDrawer();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ignore: deprecated_member_use
//     return WillPopScope(
//       onWillPop: () async {
//         if (_navigatorKey.currentState?.canPop() ?? false) {
//           _navigatorKey.currentState?.pop();
//           return false;
//         } else if (_currentIndex != 0) {
//           _navigateToPage(0);
//           return false;
//         } else {
//           _showExitDialog(context);
//           return false;
//         }
//       },
//       child: Scaffold(
//         key: _scaffoldKey,
//         backgroundColor: GlobalColors.white,
//         drawer: _buildDrawer(),
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

//   Widget _buildDrawer() {
//     final userData = widget.userData;
//     final userName = userData['name'] ?? userData['employee_name'] ?? 'Production User';
//     final userRole = userData['role'] ?? userData['designation'] ?? 'Production Manager';
//     final userEmail = userData['email'] ?? 'production@mega-pro.com';
    
//     return Drawer(
//       backgroundColor: Colors.white,
//       width: MediaQuery.of(context).size.width * 0.75,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.only(
//           topRight: Radius.circular(20),
//           bottomRight: Radius.circular(20),
//         ),
//       ),
//       child: Column(
//         children: [
//           // Header with user info
//           Container(
//             padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
//             decoration: BoxDecoration(
//               color: GlobalColors.primaryBlue,
//               borderRadius: const BorderRadius.only(
//                 bottomLeft: Radius.circular(20),
//                 bottomRight: Radius.circular(20),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: GlobalColors.primaryBlue.withOpacity(0.3),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       width: 60,
//                       height: 60,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                       ),
//                       child: Center(
//                         child: Text(
//                           userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
//                           style: GoogleFonts.poppins(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: GlobalColors.primaryBlue,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             userName,
//                             style: GoogleFonts.poppins(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               userRole,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.email_outlined, size: 16, color: Colors.white.withOpacity(0.8)),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           userEmail,
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             color: Colors.white.withOpacity(0.9),
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // Navigation Menu Items
//           Expanded(
//             child: ListView(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               children: [
//                 _buildDrawerItem(
//                   index: 0,
//                   icon: Icons.dashboard_outlined,
//                   label: 'Dashboard',
//                   selectedIcon: Icons.dashboard,
//                 ),
//                 _buildDrawerItem(
//                   index: 1,
//                   icon: Icons.inventory_2_outlined,
//                   label: 'Inventory',
//                   selectedIcon: Icons.inventory_2,
//                 ),
//                 _buildDrawerItem(
//                   index: 2,
//                   icon: Icons.assignment_outlined,
//                   label: 'Orders',
//                   selectedIcon: Icons.assignment,
//                 ),
//                 _buildDrawerItem(
//                   index: 3,
//                   icon: Icons.person_outline,
//                   label: 'Profile',
//                   selectedIcon: Icons.person,
//                 ),
                
//                 const Divider(height: 32, thickness: 1),
                
//                 // Additional Items
//                 _buildDrawerItem(
//                   index: -1,
//                   icon: Icons.inventory,
//                   label: 'Raw Material Entry',
//                   selectedIcon: Icons.inventory,
//                   onTap: () {
//                     Navigator.pop(context);
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const ProRawMaterialEntryPage(),
//                       ),
//                     );
//                   },
//                 ),
                
//                 _buildDrawerItem(
//                   index: -2,
//                   icon: Icons.analytics_outlined,
//                   label: 'Analytics',
//                   selectedIcon: Icons.analytics,
//                   onTap: () {
//                     Navigator.pop(context);
//                     _showAnalyticsDialog();
//                   },
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 // Settings and Support Section
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                   child: Text(
//                     'SUPPORT',
//                     style: GoogleFonts.poppins(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[500],
//                     ),
//                   ),
//                 ),
                
//                 _buildDrawerItem(
//                   index: -3,
//                   icon: Icons.help_outline,
//                   label: 'Help & Support',
//                   selectedIcon: Icons.help,
//                   onTap: () {
//                     Navigator.pop(context);
//                     _showHelpDialog();
//                   },
//                 ),
                
//                 _buildDrawerItem(
//                   index: -4,
//                   icon: Icons.settings_outlined,
//                   label: 'Settings',
//                   selectedIcon: Icons.settings,
//                   onTap: () {
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Settings coming soon...')),
//                     );
//                   },
//                 ),
                
//                 const Divider(height: 32, thickness: 1),
                
//                 // Logout Button
//                 _buildDrawerItem(
//                   index: -5,
//                   icon: Icons.logout,
//                   label: 'Logout',
//                   selectedIcon: Icons.logout,
//                   color: Colors.red,
//                   onTap: () {
//                     Navigator.pop(context);
//                     _showLogoutDialog();
//                   },
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 // Version Info
//                 Center(
//                   child: Text(
//                     'Version 1.0.0',
//                     style: GoogleFonts.poppins(
//                       fontSize: 11,
//                       color: Colors.grey[400],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required int index,
//     required IconData icon,
//     required String label,
//     required IconData selectedIcon,
//     VoidCallback? onTap,
//     Color? color,
//   }) {
//     final isSelected = index >= 0 && _currentIndex == index;
//     final itemColor = color ?? (isSelected ? GlobalColors.primaryBlue : Colors.grey[700]);
    
//     return ListTile(
//       leading: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: isSelected ? GlobalColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Icon(
//           isSelected ? selectedIcon : icon,
//           color: itemColor,
//           size: 22,
//         ),
//       ),
//       title: Text(
//         label,
//         style: GoogleFonts.poppins(
//           fontSize: 14,
//           fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//           color: itemColor,
//         ),
//       ),
//       selected: isSelected,
//       selectedTileColor: GlobalColors.primaryBlue.withOpacity(0.05),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       onTap: onTap ?? () => _navigateToPage(index),
//     );
//   }

//   void _showAnalyticsDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text('Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
//         content: Text(
//           'Detailed analytics will be available soon.\n\nTrack production metrics, efficiency, and performance in real-time.',
//           style: GoogleFonts.poppins(fontSize: 14),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('OK', style: GoogleFonts.poppins()),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showHelpDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text('Help & Support', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildContactItem(Icons.email, 'support@mega-pro.in'),
//             const SizedBox(height: 12),
//             _buildContactItem(Icons.phone, '+91 1234567890'),
//             const SizedBox(height: 12),
//             _buildContactItem(Icons.access_time, '24/7 Support Available'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close', style: GoogleFonts.poppins()),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContactItem(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: GlobalColors.primaryBlue),
//         const SizedBox(width: 12),
//         Text(text, style: GoogleFonts.poppins(fontSize: 13)),
//       ],
//     );
//   }

//   void _showLogoutDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
//         content: Text(
//           'Are you sure you want to logout?',
//           style: GoogleFonts.poppins(fontSize: 14),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel', style: GoogleFonts.poppins()),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _logoutAndGoToMainPage(context);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//             child: Text('Logout', style: GoogleFonts.poppins()),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPageForRoute(String routeName) {
//     switch (routeName) {
//       case '/dashboard':
//         return MultiProvider(
//           providers: [
//             ChangeNotifierProvider<ProductionOrdersProvider>(
//               create: (_) => ProductionOrdersProvider(),
//             ),
//             ChangeNotifierProvider<InventoryProvider>(
//               create: (_) => InventoryProvider(),
//             ),
//           ],
//           child: DashboardContent(
//             scaffoldKey: _scaffoldKey,
//             userData: widget.userData,
//           ),
//         );
//       case '/inventory':
//         return ChangeNotifierProvider<InventoryProvider>(
//           create: (_) => InventoryProvider(),
//           child: const ProInventoryManager(),
//         );
//       case '/orders':
//         return ChangeNotifierProvider<ProductionOrdersProvider>(
//           create: (_) => ProductionOrdersProvider(),
//           child: ProductionOrdersPage(
//             productionProfile: const {}, 
//             onDataChanged: () {},
//           ),
//         );
//       case '/profile':
//         return const ProductionProfilePage();
//       default:
//         return MultiProvider(
//           providers: [
//             ChangeNotifierProvider<ProductionOrdersProvider>(
//               create: (_) => ProductionOrdersProvider(),
//             ),
//             ChangeNotifierProvider<InventoryProvider>(
//               create: (_) => InventoryProvider(),
//             ),
//           ],
//           child: DashboardContent(
//             scaffoldKey: _scaffoldKey,
//             userData: widget.userData,
//           ),
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
//               _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, "Dashboard"),
//               _buildNavItem(1, Icons.inventory_2_outlined, Icons.inventory_2, "Inventory"),
//               _buildNavItem(2, Icons.assignment_outlined, Icons.assignment, "Orders"),
//               _buildNavItem(3, Icons.person_outline, Icons.person, "Profile"),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
//     return GestureDetector(
//       onTap: () => _navigateToPage(index),
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
//               _currentIndex == index ? selectedIcon : icon,
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

//   void _logoutAndGoToMainPage(BuildContext context) {
//     Navigator.of(context).popUntil((route) => route.isFirst);
//     Navigator.pushReplacementNamed(context, '/');
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
//                     // ignore: deprecated_member_use
//                     color: Colors.blue.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.exit_to_app,
//                     color: Colors.blue,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   "Exit the app?",
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Are you sure you want to exit?",
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
//                           backgroundColor: Colors.blue,
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: Text(
//                           "Exit",
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
// }

// // Enhanced Dashboard Content with Real-time Profit Calculation
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
  
//   // Total Bags from Inventory
//   double _totalInventoryBags = 0.0;
  
//   // Realtime subscriptions
//   StreamSubscription? _ordersSubscription;
//   StreamSubscription? _materialUsageSubscription;
//   StreamSubscription? _inventorySubscription;
  
//   final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

//   @override
//   void initState() {
//     super.initState();
//     // Delay initial load to ensure providers are ready
//     Future.delayed(const Duration(milliseconds: 100), () {
//       _fetchAllData();
//     });
//     _startRealtimeUpdates();
//     _setupRealtimeSubscriptions();
//   }

//   void _startRealtimeUpdates() {
//     _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       if (mounted) {
//         _fetchAllData();
//       }
//     });
//   }

//   void _setupRealtimeSubscriptions() {
//     print('🔔 Setting up real-time financial data subscriptions...');
    
//     try {
//       // Subscribe to order changes (affects revenue)
//       _ordersSubscription = _supabase
//           .from('emp_mar_orders')
//           .stream(primaryKey: ['id'])
//           .listen((List<Map<String, dynamic>> updates) {
//             print('🔄 Orders changed (${updates.length} updates), updating profit metrics...');
//             _handleRealtimeUpdate('orders');
//           }, onError: (error) {
//             print('❌ Orders subscription error: $error');
//           });

//       // Subscribe to raw material usage changes (affects costs)
//       _materialUsageSubscription = _supabase
//           .from('pro_raw_material_usage')
//           .stream(primaryKey: ['id'])
//           .listen((List<Map<String, dynamic>> updates) {
//             print('🔄 Material usage changed (${updates.length} updates), updating profit metrics...');
//             _handleRealtimeUpdate('material_usage');
//           }, onError: (error) {
//             print('❌ Material usage subscription error: $error');
//           });

//       // Subscribe to inventory changes (affects available stock)
//       _inventorySubscription = _supabase
//           .from('production_products')
//           .stream(primaryKey: ['id'])
//           .listen((List<Map<String, dynamic>> updates) {
//             print('🔄 Inventory changed (${updates.length} updates), updating...');
//             _handleRealtimeUpdate('inventory');
//           }, onError: (error) {
//             print('❌ Inventory subscription error: $error');
//           });

//       print('✅ All real-time subscriptions established');
//     } catch (e) {
//       print('❌ Failed to setup real-time subscriptions: $e');
//     }
//   }

//   Future<void> _handleRealtimeUpdate(String updateType) async {
//     if (!mounted) return;
    
//     print('🔄 Handling realtime update for: $updateType');
    
//     try {
//       switch (updateType) {
//         case 'orders':
//           // Only refresh revenue-related data
//           await Future.wait([
//             _calculateProfitMetrics(),
//             _fetchRecentOrders(),
//           ]);
//           break;
          
//         case 'material_usage':
//           // Only refresh cost-related data
//           await _calculateProfitMetrics();
//           break;
          
//         case 'inventory':
//           // Only refresh inventory-related data
//           await Future.wait([
//             _fetchTotalInventoryBags(),
//             _fetchInventoryData(),
//             _fetchProducts(),
//           ]);
//           break;
          
//         default:
//           await _fetchAllData();
//       }
      
//       if (mounted) {
//         setState(() {
//           _lastUpdated = DateTime.now();
//         });
//       }
      
//       debugPrint('✅ Realtime update processed for: $updateType at ${_lastUpdated}');
//     } catch (e) {
//       debugPrint('❌ Error handling realtime update: $e');
//     }
//   }

//   Future<void> _fetchAllData() async {
//     if (!mounted) return;
    
//     try {
//       if (mounted) {
//         setState(() {
//           _isLoading = true;
//         });
//       }

//       // Run all fetches in parallel for better performance
//       await Future.wait([
//         _fetchInventoryData(),
//         _fetchProducts(),
//         _fetchProductionMetrics(),
//         _fetchMachineStatus(),
//         _fetchRecentOrders(),
//         _fetchTotalInventoryBags(),
//         _calculateProfitMetrics(),
//       ]);
      
//       if (mounted) {
//         setState(() {
//           _lastUpdated = DateTime.now();
//           _isLoading = false;
//         });
        
//         debugPrint('✅ All data fetched successfully at ${_lastUpdated}');
//         debugPrint('📦 Total bags: $_totalInventoryBags');
//         debugPrint('💰 Revenue: $_totalRevenue');
//         debugPrint('💸 Material Cost: $_totalRawMaterialCost');
//         debugPrint('📈 Profit: $_totalProfit');
//       }
//     } catch (e) {
//       debugPrint('❌ Error fetching data: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTotalInventoryBags() async {
//     try {
//       // Direct database query for total bags
//       final response = await _supabase
//           .from('production_products')
//           .select('bags')
//           .eq('is_active', true);

//       double totalBags = 0.0;
//       for (var item in response) {
//         totalBags += (item['bags'] ?? 0).toDouble();
//       }

//       if (mounted) {
//         setState(() {
//           _totalInventoryBags = totalBags;
//         });
//       }
      
//       debugPrint('📊 Direct DB query - Total bags: $totalBags');
//     } catch (e) {
//       debugPrint('Error fetching total bags: $e');
//       if (mounted) {
//         setState(() {
//           _totalInventoryBags = 0.0;
//         });
//       }
//     }
//   }

//   Future<void> _fetchInventoryData() async {
//     try {
//       final response = await _supabase
//           .from('production_products')
//           .select('*')
//           .eq('is_active', true)
//           .order('name', ascending: true);

//       if (mounted) {
//         setState(() {
//           _inventoryData.clear();
//           _inventoryData.addAll(List<Map<String, dynamic>>.from(response));
//         });
//       }
      
//       debugPrint('📦 Inventory data fetched: ${_inventoryData.length} items');
//     } catch (e) {
//       debugPrint('Error fetching inventory: $e');
//     }
//   }

//   Future<void> _fetchProducts() async {
//     try {
//       final response = await _supabase
//           .from('production_products')
//           .select('*')
//           .eq('is_active', true)
//           .order('name', ascending: true);

//       if (mounted) {
//         setState(() {
//           _products.clear();
//           _products.addAll(List<Map<String, dynamic>>.from(response));
//         });
//       }
      
//       debugPrint('📋 Products fetched: ${_products.length} items');
//     } catch (e) {
//       debugPrint('Error fetching products: $e');
//     }
//   }

//   Future<void> _calculateProfitMetrics() async {
//     try {
//       final today = DateTime.now();
//       final monthStart = DateTime(today.year, today.month, 1);
      
//       double totalRevenue = 0.0;
//       double totalRawMaterialCost = 0.0;
//       Map<String, double> rawMaterialCosts = {};

//       final monthStartStr = "${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-01";
//       final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

//       debugPrint('📊 Calculating profit metrics for period: $monthStartStr to $todayStr');

//       final revenueResponse = await _supabase
//           .from('emp_mar_orders')
//           .select('total_price')
//           .eq('status', 'completed')
//           .gte('created_at', monthStartStr)
//           .lte('created_at', todayStr);

//       for (var order in revenueResponse) {
//         totalRevenue += (order['total_price'] ?? 0).toDouble();
//       }
      
//       debugPrint('💰 Revenue fetched: ₹$totalRevenue');

//       // Get raw material usage cost for this month
//       final materialResponse = await _supabase
//           .from('pro_raw_material_usage')
//           .select('total_cost, raw_material_id, pro_inventory!inner(name)')
//           .gte('usage_date', monthStartStr)
//           .lte('usage_date', todayStr);

//       for (var usage in materialResponse) {
//         final cost = (usage['total_cost'] ?? 0).toDouble();
//         totalRawMaterialCost += cost;
        
//         final inventoryData = usage['pro_inventory'] as Map<String, dynamic>?;
//         final materialName = inventoryData?['name']?.toString() ?? 'Unknown Material';
        
//         rawMaterialCosts[materialName] = (rawMaterialCosts[materialName] ?? 0) + cost;
//       }

//       debugPrint('💰 Material cost fetched: ₹$totalRawMaterialCost');

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
//         });
        
//         debugPrint('✅ Profit Calculation Complete:');
//         debugPrint('  Revenue: ₹$_totalRevenue');
//         debugPrint('  Material Cost: ₹$_totalRawMaterialCost');
//         debugPrint('  Profit: ₹$_totalProfit');
//         debugPrint('  Margin: ${_profitMargin.toStringAsFixed(2)}%');
//       }
//     } catch (e) {
//       debugPrint('❌ Profit calculation error: $e');
//       if (mounted) {
//         // Set default values on error
//         setState(() {
//           _totalRevenue = 0.0;
//           _totalRawMaterialCost = 0.0;
//           _totalProfit = 0.0;
//           _profitMargin = 0.0;
//           _rawMaterialUsage = {};
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
//           .from('emp_mar_orders')
//           .select('*')
//           .eq('status', 'completed')
//           .order('created_at', ascending: false)
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
//     _ordersSubscription?.cancel();
//     _materialUsageSubscription?.cancel();
//     _inventorySubscription?.cancel();
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
//                 "Updated: ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}:${_lastUpdated!.second.toString().padLeft(2, '0')}",
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
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               _fetchAllData();
//               _showRefreshSnackBar(context);
//             },
//             tooltip: 'Refresh All Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(
//               child: CircularProgressIndicator(
//                 color: GlobalColors.primaryBlue,
//               ),
//             )
//           : RefreshIndicator(
//               onRefresh: () async {
//                 await _fetchAllData();
//                 _showRefreshSnackBar(context);
//               },
//               child: _DashboardBody(
//                 inventoryData: _inventoryData,
//                 products: _products,
//                 recentOrders: _recentOrders,
//                 isLoading: _isLoading,
//                 todayProduction: _todayProduction,
//                 productionTarget: _productionTarget,
//                 activeMachines: _activeMachines,
//                 totalMachines: _totalMachines,
//                 qualityRate: _qualityRate,
//                 totalRevenue: _totalRevenue,
//                 totalRawMaterialCost: _totalRawMaterialCost,
//                 totalProfit: _totalProfit,
//                 profitMargin: _profitMargin,
//                 rawMaterialUsage: _rawMaterialUsage,
//                 totalInventoryBags: _totalInventoryBags,
//                 currencyFormat: _currencyFormat,
//                 onRefresh: () {
//                   _fetchAllData();
//                   _showRefreshSnackBar(context);
//                 },
//               ),
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const ProRawMaterialEntryPage(),
//             ),
//           );
//         },
//         backgroundColor: GlobalColors.primaryBlue,
//         child: const Icon(Icons.add, color: Colors.white),
//         tooltip: 'Record Raw Material Usage',
//       ),
//     );
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
//   final double totalInventoryBags;
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
//     required this.totalInventoryBags,
//     required this.currencyFormat,
//     required this.onRefresh,
//   });

//   Widget _buildInventorySummary() {
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
//                 "Inventory Summary",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[800],
//                 ),
//               ),             
//             ],
//           ),
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.blue.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.blue.withOpacity(0.1)),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Total Bags",
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       totalInventoryBags.toStringAsFixed(0),
//                       style: GoogleFonts.poppins(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       "in inventory",
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         color: Colors.grey[500],
//                       ),
//                     ),
//                   ],
//                 ),
//                 Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(
//                     Icons.inventory_2,
//                     size: 32,
//                     color: Colors.blue,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.green.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.green.withOpacity(0.1)),
//             ),
//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.info_outline,
//                   size: 16,
//                   color: Colors.green,
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     "Based on ${products.length} products in inventory",
//                     style: GoogleFonts.poppins(
//                       fontSize: 12,
//                       color: Colors.green,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
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
//                   DateFormat('MMM yyyy').format(DateTime.now()),
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
//                     // Navigate to raw material entry page
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
//                       entry.key,
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
              
//             ],
//           ),
//           const SizedBox(height: 12),

//           if (inventoryData.isEmpty)
//             Container(
//               height: 200,
//               alignment: Alignment.center,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.inventory_2_outlined,
//                     size: 48,
//                     color: Colors.grey[400],
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     "No inventory data",
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           else
//             Column(
//               children: inventoryData.take(4).map((item) {
//                 final stock = (item['bags'] ?? 0).toDouble();
//                 final reorder = (item['min_bags_stock'] ?? 10).toDouble();
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
//                               "${stock.toStringAsFixed(0)} bags",
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
//                                 "Below reorder level (${reorder.toStringAsFixed(0)} bags)",
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
//               _buildInventorySummary(),
//               const SizedBox(height: 20),
              
//               _buildProfitMetrics(),
//               const SizedBox(height: 20),
              
//               _buildRawMaterialCosts(),
//               const SizedBox(height: 20),
              
//               _buildInventoryStatus(),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
















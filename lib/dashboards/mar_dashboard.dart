
//not real time except for target changes, order changes are not real time, need to refresh to see changes

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mega_pro/marketing/mar_emp_performnace.dart';
import 'package:mega_pro/marketing/mar_emp_target.dart';
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
    _pages = [
      DashboardContent(userData: widget.userData),
      const EmployeeDetailPage(),
      const CattleFeedOrderScreen(),
      const MarketingManagerAttendancePage(),
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
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.group),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DistrictTeamMembersPage(),
              ),
            );
          },
        ),
      ],
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

class _DashboardContentState extends State<DashboardContent> with WidgetsBindingObserver {
  final MarketingTargetService _targetService = MarketingTargetService();
  final supabase = Supabase.instance.client;
  
  // District-Taluka mapping data
  final Map<String, List<String>> _districtTalukaData = {
    "Ahmednagar": [
      "Ahmednagar", "Akole", "Jamkhed", "Karjat", "Kopargaon",
      "Nagar", "Nevasa", "Parner", "Pathardi", "Rahata",
      "Rahuri", "Sangamner", "Shrigonda", "Shrirampur"
    ],
    "Akola": [
      "Akola", "Balapur", "Barshitakli", "Murtizapur", "Telhara", "Akot"
    ],
    "Amravati": [
      "Amravati", "Anjangaon", "Chandur Bazar", "Chandur Railway",
      "Daryapur", "Dharni", "Morshi", "Nandgaon Khandeshwar",
      "Achalpur", "Warud"
    ],
    "Aurangabad": [
      "Aurangabad City", "Aurangabad Rural", "Kannad", "Khultabad",
      "Sillod", "Paithan", "Gangapur", "Vaijapur"
    ],
    "Beed": [
      "Beed", "Ashti", "Kaij", "Georai", "Majalgaon", "Parli",
      "Ambajogai", "Shirur", "Wadwani"
    ],
    "Bhandara": [
      "Bhandara", "Tumsar", "Sakoli", "Mohadi", "Pauni"
    ],
    "Buldhana": [
      "Buldhana", "Chikhli", "Deulgaon Raja", "Khamgaon", "Mehkar",
      "Nandura", "Malkapur", "Jalgaon Jamod", "Sindkhed Raja"
    ],
    "Chandrapur": [
      "Chandrapur", "Ballarpur", "Bhadravati", "Chimur", "Nagbhid",
      "Rajura", "Warora"
    ],
    "Dhule": [
      "Dhule", "Shirpur", "Sakri", "Sindkheda", "Dondaicha"
    ],
    "Gadchiroli": [
      "Gadchiroli", "Aheri", "Chamorshi", "Etapalli", "Rajura", "Armori"
    ],
    "Gondiya": [
      "Gondiya", "Amgaon", "Deori", "Salekasa", "Tirora"
    ],
    "Hingoli": [
      "Hingoli", "Kalamnuri", "Basmath", "Sengaon"
    ],
    "Jalgaon": [
      "Jalgaon", "Amalner", "Chopda", "Dharangaon", "Erandol",
      "Pachora", "Parola", "Bhusawal", "Raver"
    ],
    "Jalna": [
      "Jalna", "Bhokardan", "Badnapur", "Partur", "Ghansawangi", "Ambad"
    ],
    "Kolhapur": [
      "Karvir", "Panhala", "Shirol", "Hatkanangale", "Kagal", 
      "Shahuwadi", "Ajara", "Gadhinglaj", "Chandgad", "Radhanagari",
      "Jat", "Bhudargad"
    ],
    "Latur": [
      "Latur", "Ausa", "Ahmedpur", "Udgir", "Nilanga", "Renapur", "Chakur"
    ],
    "Mumbai City": [
      "Mumbai City"
    ],
    "Mumbai Suburban": [
      "Andheri", "Borivali", "Kurla", "Mulund", "Bandra"
    ],
    "Nagpur": [
      "Nagpur", "Hingna", "Parseoni", "Kalmeshwar", "Umred", "Kuhi", "Savner"
    ],
    "Nanded": [
      "Nanded", "Deglur", "Biloli", "Bhokar", "Mukhed", "Loha", "Ardhapur", "Umri"
    ],
    "Nandurbar": [
      "Nandurbar", "Nawapur", "Shahada", "Taloda", "Akkalkuwa"
    ],
    "Nashik": [
      "Nashik", "Dindori", "Igatpuri", "Niphad", "Sinnar", "Yeola",
      "Trimbakeshwar", "Baglan", "Chandwad"
    ],
    "Osmanabad": [
      "Osmanabad", "Tuljapur", "Paranda", "Lohara", "Ausa", "Kalamb"
    ],
    "Palghar": [
      "Palghar", "Dahanu", "Talasari", "Umbergaon", "Vikramgad", "Jawhar", "Mokhada"
    ],
    "Parbhani": [
      "Parbhani", "Gangakhed", "Purna", "Selu", "Pathri"
    ],
    "Pune": [
      "Pune", "Haveli", "Maval", "Mulshi", "Khed (Ravet)", "Baramati",
      "Daund", "Indapur", "Junnar", "Shirur", "Bhor"
    ],
    "Raigad": [
      "Alibag", "Karjat", "Khalapur", "Mahad", "Mangaon", "Mhasala", "Panvel", "Pen", "Roha"
    ],
    "Ratnagiri": [
      "Ratnagiri", "Chiplun", "Khed", "Guhagar", "Lanja", "Sangameshwar"
    ],
    "Sangli": [
      "Sangli", "Miraj", "Tasgaon", "Jat", "Kavathe Mahankal", "Palus"
    ],
    "Satara": [
      "Satara", "Karad", "Wai", "Khandala", "Patan", "Wai", "Phaltan", "Man"
    ],
    "Sindhudurg": [
      "Sindhudurg", "Kankavli", "Malvan", "Vengurla", "Sawantwadi"
    ],
    "Solapur": [
      "Solapur", "Akkalkot", "Barshi", "Mangalwedha", "Pandharpur", "Madha", "Karmala", "Sangola"
    ],
    "Thane": [
      "Thane", "Bhiwandi", "Kalyan", "Ulhasnagar", "Ambarnath", "Shahapur", "Murbad", "Wada", "Jawahar"
    ],
    "Wardha": [
      "Wardha", "Deoli", "Arvi"
    ],
    "Washim": [
      "Washim", "Mangrulpir", "Karanja"
    ],
    "Yavatmal": [
      "Yavatmal", "Umarkhed", "Darwha", "Pusad", "Ghatanji", "Kalamb"
    ],
  };

  // Sales data storage
  Map<String, Map<String, double>> _talukaSalesData = {}; // district -> taluka -> sales in tons
  Map<String, List<Map<String, dynamic>>> _chartData = {}; // district -> list of taluka data for chart
  double _totalDistrictSales = 0.0;
  
  final Color themePrimary = GlobalColors.primaryBlue;
  
  // Target variables
  Map<String, dynamic>? _currentTargetData;
  bool _isLoadingTarget = true;
  bool _isLoadingSales = true;
  bool _isRefreshing = false;
  DateTime _currentMonth = DateTime.now();
  String? _managerId;
  String _selectedDistrict = "";
  String? _managerName;
  
  // Real-time subscriptions
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _targetChannel;
  Timer? _pollingTimer;
  Timer? _debounceTimer;
  Timer? _autoRefreshTimer;
  
  // Track last update
  DateTime _lastDataUpdate = DateTime.now();
  static const Duration autoRefreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDashboard();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed - refreshing dashboard data');
      _refreshData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ordersChannel?.unsubscribe();
    _targetChannel?.unsubscribe();
    _pollingTimer?.cancel();
    _debounceTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    try {
      print('=== INITIALIZING MANAGER DASHBOARD (REAL-TIME) ===');
      
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        setState(() {
          _isLoadingTarget = false;
          _isLoadingSales = false;
        });
        return;
      }
      
      print('👤 Auth User ID: ${user.id}');
      
      // Get manager profile from emp_profile table
      final profileData = await supabase
          .from('emp_profile')
          .select('id, emp_id, full_name, role, district, position')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (profileData == null) {
        print('❌ No profile found for user');
        setState(() {
          _isLoadingTarget = false;
          _isLoadingSales = false;
        });
        return;
      }
      
      print('✅ Manager Profile Found: ${profileData['full_name']}');
      print('   District: ${profileData['district']}');
      
      final managerId = profileData['id'].toString();
      final district = profileData['district']?.toString();
      final managerName = profileData['full_name']?.toString();
      
      if (managerId.isEmpty) {
        print('❌ Manager ID is empty');
        setState(() {
          _isLoadingTarget = false;
          _isLoadingSales = false;
        });
        return;
      }
      
      setState(() {
        _managerId = managerId;
        _selectedDistrict = district ?? "";
        _managerName = managerName;
      });
      
      // Initialize chart data structure
      _initializeChartData();
      
      // Load initial data
      await Future.wait([
        _loadCurrentTarget(managerId),
        _loadSalesData(),
      ]);
      
      // Setup real-time subscriptions
      _setupRealtimeSubscriptions(managerId);
      _setupAutoRefresh();
      
    } catch (e) {
      print('❌ Error initializing dashboard: $e');
      setState(() {
        _isLoadingTarget = false;
        _isLoadingSales = false;
      });
    }
  }

  void _setupAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(autoRefreshInterval, (timer) {
      if (mounted && !_isRefreshing && !_isLoadingSales) {
        print('🔄 Auto-refresh triggered (${autoRefreshInterval.inSeconds}s interval)');
        _refreshData(silent: true);
      }
    });
  }

  void _initializeChartData() {
    if (_selectedDistrict.isNotEmpty && _districtTalukaData.containsKey(_selectedDistrict)) {
      final talukas = _districtTalukaData[_selectedDistrict]!;
      
      _chartData[_selectedDistrict] = talukas.map((taluka) {
        return {
          "taluka": taluka,
          "sales": 0.0,
        };
      }).toList();
      
      print('✅ Initialized chart data for $_selectedDistrict with ${talukas.length} talukas');
    } else {
      _chartData[_selectedDistrict] = [];
    }
  }

  void _setupRealtimeSubscriptions(String managerId) {
    try {
      // Subscribe to order changes for real-time sales updates
      _ordersChannel = supabase.channel('manager-orders-$managerId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'emp_mar_orders',
            callback: (payload) {
              _handleOrderChange(payload);
            },
          )
          .subscribe((status, [error]) {
            if (status == 'SUBSCRIBED') {
              print('✅ Orders channel subscribed for manager $managerId');
            } else if (status == 'CHANNEL_ERROR') {
              print('❌ Orders channel error: $error');
              _setupPollingFallback();
            }
          });

      // Subscribe to manager target changes
      _targetChannel = supabase.channel('manager-targets-$managerId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'own_marketing_targets',
            callback: (payload) {
              if (payload.newRecord['manager_id'] == managerId) {
                _debouncedTargetRefresh(managerId);
              }
            },
          )
          .subscribe((status, [error]) {
            if (status == 'SUBSCRIBED') {
              print('✅ Target channel subscribed for manager $managerId');
            }
          });

    } catch (e) {
      print('❌ Error setting up real-time: $e');
      _setupPollingFallback();
    }
  }

  void _setupPollingFallback() {
    print('🔄 Setting up polling fallback (every 30 seconds)...');
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isRefreshing && !_isLoadingSales) {
        print('🔄 Polling for updates...');
        _refreshData(silent: true);
      }
    });
  }

  void _debouncedTargetRefresh(String managerId) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _loadCurrentTarget(managerId);
    });
  }

  void _handleOrderChange(PostgresChangePayload payload) {
    print('🔄 Order change detected: ${payload.eventType}');
    
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;
    
    // Check if order belongs to manager's district
    final orderDistrict = newRecord['district']?.toString() ?? oldRecord['district']?.toString();
    if (orderDistrict != _selectedDistrict) return;
    
    bool shouldRefresh = false;
    
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final status = newRecord['status']?.toString().toLowerCase() ?? '';
        if (_isCompletedStatus(status)) {
          shouldRefresh = true;
          print('✅ New completed order detected');
        }
        break;
        
      case PostgresChangeEvent.update:
        final newStatus = newRecord['status']?.toString().toLowerCase() ?? '';
        final oldStatus = oldRecord['status']?.toString().toLowerCase() ?? '';
        
        if (_isCompletedStatus(newStatus) && !_isCompletedStatus(oldStatus)) {
          shouldRefresh = true;
          print('✅ Order marked as completed');
        } else if (!_isCompletedStatus(newStatus) && _isCompletedStatus(oldStatus)) {
          shouldRefresh = true;
          print('✅ Order removed from completed');
        }
        break;
        
      case PostgresChangeEvent.delete:
        final oldStatus = oldRecord['status']?.toString().toLowerCase() ?? '';
        if (_isCompletedStatus(oldStatus)) {
          shouldRefresh = true;
          print('✅ Completed order deleted');
        }
        break;
      case PostgresChangeEvent.all:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
    
    if (shouldRefresh) {
      _debouncedRefresh();
    }
  }

  bool _isCompletedStatus(String status) {
    return status == 'completed' || status == 'delivered' || status == 'dispatched';
  }

  void _debouncedRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _refreshData(silent: true);
    });
  }

  Future<void> _loadSalesData() async {
    try {
      setState(() => _isLoadingSales = true);
      
      if (_selectedDistrict.isEmpty) {
        print('⚠️ No district selected for sales data');
        setState(() => _isLoadingSales = false);
        return;
      }
      
      print('📊 Loading sales data for district: $_selectedDistrict');
      
      _talukaSalesData[_selectedDistrict] = {};
      _totalDistrictSales = 0.0;
      
      // Get current month range
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      
      // Get all orders for the district this month
      final allOrders = await supabase
          .from('emp_mar_orders')
          .select('id, taluka, total_weight, weight_unit, status, created_at, total_price, district')
          .eq('district', _selectedDistrict)
          .gte('created_at', firstDayOfMonth.toIso8601String())
          .lte('created_at', lastDayOfMonth.toIso8601String());
      
      print('📦 Found ${allOrders.length} orders for district $_selectedDistrict');
      
      int completedOrdersCount = 0;
      
      for (var order in allOrders) {
        final status = order['status']?.toString().toLowerCase() ?? '';
        if (!_isCompletedStatus(status)) continue;
        
        completedOrdersCount++;
        
        final taluka = order['taluka']?.toString();
        if (taluka == null || taluka.isEmpty) continue;
        
        double weightInTons = _calculateWeightInTons(order);
        
        _talukaSalesData[_selectedDistrict]![taluka] = 
            (_talukaSalesData[_selectedDistrict]![taluka] ?? 0) + weightInTons;
        _totalDistrictSales += weightInTons;
      }
      
      print('✅ Processed $completedOrdersCount completed orders');
      print('💰 Total district sales: ${_totalDistrictSales.toStringAsFixed(2)} T');
      
      // Update chart data
      if (_chartData.containsKey(_selectedDistrict)) {
        final updatedTalukas = _chartData[_selectedDistrict]!.map((talukaData) {
          final talukaName = talukaData['taluka'].toString();
          final sales = _talukaSalesData[_selectedDistrict]?[talukaName] ?? 0.0;
          return {
            ...talukaData,
            "sales": sales,
          };
        }).toList();
        
        setState(() {
          _chartData[_selectedDistrict] = updatedTalukas;
          _isLoadingSales = false;
          _lastDataUpdate = DateTime.now();
        });
      }
      
    } catch (e) {
      print('❌ Error loading sales data: $e');
      setState(() => _isLoadingSales = false);
    }
  }

  double _calculateWeightInTons(Map<String, dynamic> order) {
    double weightInKg = 0.0;
    final weightUnit = order['weight_unit']?.toString() ?? 'kg';
    final totalWeight = (order['total_weight'] as num?)?.toDouble() ?? 0.0;
    
    if (weightUnit == 'kg') {
      weightInKg = totalWeight;
    } else if (weightUnit == 'g') {
      weightInKg = totalWeight / 1000;
    } else if (weightUnit == 'ton') {
      weightInKg = totalWeight * 1000;
    }
    
    return weightInKg / 1000; // Convert to tons
  }

  Future<void> _loadCurrentTarget(String managerId) async {
    try {
      final targetData = await _targetService.getManagerTarget(
        managerId: managerId,
        month: _currentMonth,
      );

      setState(() {
        _currentTargetData = targetData;
        _isLoadingTarget = false;
      });
      
    } catch (e) {
      print('❌ Error loading target: $e');
      setState(() => _isLoadingTarget = false);
    }
  }

  Future<void> _refreshData({bool silent = false}) async {
    if (_isRefreshing) return;
    
    print('🔄 ${silent ? 'Silent' : 'Manual'} refresh triggered...');
    
    if (!silent) {
      setState(() => _isRefreshing = true);
    }

    try {
      if (_managerId != null) {
        await Future.wait([
          _loadCurrentTarget(_managerId!),
          _loadSalesData(),
        ]);
      }
      
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dashboard updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error refreshing data: $e');
    } finally {
      if (!silent && mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  // Chart Widget
  Widget _buildChart(List<Map<String, dynamic>> talukas) {
    if (talukas.isEmpty || _isLoadingSales) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoadingSales 
                  ? CircularProgressIndicator(color: themePrimary)
                  : Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                _isLoadingSales ? "Loading sales data..." : "No sales data available",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    
    final chartWidth = talukas.length * 80.0;
    final chartHeight = 250.0;
    final maxY = _getMaxY(talukas);
    
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
                        horizontalInterval: maxY / 5,
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
                            interval: maxY / 5,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  "${value.toInt()} T",
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
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(talukas.length, (i) => 
                            FlSpot(i.toDouble(), (talukas[i]['sales'] as num).toDouble())
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
                                '${taluka['taluka']}\n${taluka['sales'].toStringAsFixed(2)} T',
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
    if (talukas.isEmpty) return 10.0;
    
    final maxSales = talukas
        .map((e) => (e['sales'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    
    return ((maxSales / 5).ceil() * 5 * 1.1).clamp(10.0, 1000.0);
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
              Icon(Icons.table_restaurant, size: 48, color: Colors.grey[400]),
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
    final revenueTarget = (targetData['revenue_target'] ?? 0).toDouble();
    final orderTarget = (targetData['order_target'] ?? 0).toDouble();
    final achievedRevenue = (targetData['achieved_revenue'] ?? 0).toDouble();
    final achievedOrders = (targetData['achieved_orders'] ?? 0).toDouble();
    
    final revenueProgress = revenueTarget > 0 ? achievedRevenue / revenueTarget : 0.0;
    final orderProgress = orderTarget > 0 ? achievedOrders / orderTarget : 0.0;
    final revenuePercentage = (revenueProgress * 100).toInt();
    final orderPercentage = (orderProgress * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with live indicator
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Your Monthly Target", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
              
            ],
          ),
        ),

        // Revenue Target with Progress Bar
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
        
        // Orders Target with Progress Bar
        _buildMetricCard(
          title: "Order Target",
          icon: Icons.shopping_cart,
          current: achievedOrders,
          target: orderTarget,
          percentage: orderPercentage,
          prefix: "#",
          progress: orderProgress,
        ),

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
              Text(
                DateFormat('dd MMM, hh:mm:ss a').format(_lastDataUpdate), 
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required double current,
    required double target,
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
                  Text("$prefix${current.toStringAsFixed(0)}", style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, 
                    color: isCompleted ? Colors.green : GlobalColors.primaryBlue,
                  )),
                  const SizedBox(width: 4),
                  Text("/ $prefix${target.toStringAsFixed(0)}", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ]),
              ]),
              
              // Progress Bar
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
                  Text(remaining > 0 ? "$prefix${remaining.toStringAsFixed(0)}" : "₹0", 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final talukaList = _chartData[_selectedDistrict] ?? [];
    
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _refreshData(silent: false),
        color: GlobalColors.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome and District Info Card
                if (_managerName != null || _selectedDistrict.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
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
                        if (_managerName != null) ...[
                          Text(
                            "Welcome, ${_managerName!}",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        
                        if (_selectedDistrict.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: GlobalColors.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "District: $_selectedDistrict",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Managing ${talukaList.length} Talukas",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
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
                                    Text(
                                      'Auto-refresh every 30s',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange[100]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, size: 20, color: Colors.orange[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "No district assigned. Please contact administrator.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Total Sales Card with real-time data
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        GlobalColors.primaryBlue,
                        GlobalColors.primaryBlue.withOpacity(0.8),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Total District Sales",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_isLoadingSales)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${_totalDistrictSales.toStringAsFixed(2)} T",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedDistrict.isNotEmpty
                                  ? "Across ${talukaList.length} Talukas in $_selectedDistrict"
                                  : "Select a district to view sales",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Live updates from completed orders",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
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
                        child: _isLoadingSales
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Icon(
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
                                  _selectedDistrict.isNotEmpty ? _selectedDistrict : "No District",
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
                      
                      if (_selectedDistrict.isEmpty) ...[
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No district assigned",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Please contact administrator to assign a district",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        _buildChart(talukaList),
                        
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Assigned Target Card
                _buildAssignedTargetCard(),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}  












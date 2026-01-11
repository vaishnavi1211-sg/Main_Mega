import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:mega_pro/models/own_revenue_model.dart';
import 'package:mega_pro/services/supabase_services.dart';

class DashboardProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  DashboardData _dashboardData = DashboardData.empty();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _revenueChartData = [];
  
  List<DistrictRevenueData> _districtRevenueData = [];
  bool _isLoadingDistrictData = false;
  
  // Cache management
  DateTime? _lastDistrictFetchTime;
  static const Duration _districtCacheDuration = Duration(minutes: 2);
  
  // Add these two properties
  bool _isFirstLoad = true;
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _employeesSubscription;

  DashboardData get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get revenueChartData => _revenueChartData;
  
  List<DistrictRevenueData> get districtRevenueData => _districtRevenueData;
  bool get isLoadingDistrictData => _isLoadingDistrictData;
  
  // Cache check
  bool get shouldRefreshDistrictFromCache => 
      _lastDistrictFetchTime != null && 
      DateTime.now().difference(_lastDistrictFetchTime!) < _districtCacheDuration;

  DashboardProvider() {
    // Don't call async directly in constructor
    Future.microtask(() => _init());
  }

  Future<void> _init() async {
    try {
      if (_isFirstLoad) {
        _isFirstLoad = false;
        // Load critical data first, then rest in background
        await _loadCriticalData();
        _setupRealtimeListeners();
        
        // Load district data in background with cache check
        if (!shouldRefreshDistrictFromCache) {
          unawaited(loadDistrictRevenueData());
        }
      }
    } catch (e) {
      _error = 'Initialization error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCriticalData() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Load dashboard data and chart data in parallel
      await Future.wait([
        _fetchDashboardData(),
        _fetchChartData(),
      ]);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load critical data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final data = await _supabaseService.getDashboardData();
      _dashboardData = data;
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      // Use empty data as fallback
      _dashboardData = DashboardData.empty();
    }
  }

  Future<void> _fetchChartData() async {
    try {
      _revenueChartData = await _supabaseService.getRevenueChartData();
    } catch (e) {
      debugPrint('Error fetching chart: $e');
      _revenueChartData = []; // Set empty as fallback
    }
  }

  Future<void> loadDistrictRevenueData() async {
    if (_isLoadingDistrictData) return;
    
    try {
      _isLoadingDistrictData = true;
      notifyListeners();

      // Try to get real data from Supabase
      try {
        _districtRevenueData = await _supabaseService.getDistrictRevenueData();
        _lastDistrictFetchTime = DateTime.now();
      } catch (e) {
        debugPrint('Real district data error: $e');
        // Fallback to mock data if real data fails
        _districtRevenueData = await _getMockDistrictData();
      }
      
      _isLoadingDistrictData = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDistrictData = false;
      debugPrint('District data loading error: $e');
      // Ensure we have some data even if both methods fail
      if (_districtRevenueData.isEmpty) {
        _districtRevenueData = await _getMockDistrictData();
      }
      notifyListeners();
    }
  }

  // Fallback mock data (only used when Supabase fails)
  Future<List<DistrictRevenueData>> _getMockDistrictData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      DistrictRevenueData(
        district: 'Kolhapur',
        branch: 'Main Branch',
        revenue: 450000,
        orders: 120,
        growth: 12.5,
        topProducts: ['Product A', 'Product B', 'Product C'],
      ),
      DistrictRevenueData(
        district: 'Pune',
        branch: 'City Branch',
        revenue: 620000,
        orders: 180,
        growth: 8.3,
        topProducts: ['Product X', 'Product Y'],
      ),
      DistrictRevenueData(
        district: 'Satara',
        branch: 'Satara Branch',
        revenue: 280000,
        orders: 85,
        growth: 15.2,
        topProducts: ['Product Z'],
      ),
      DistrictRevenueData(
        district: 'Sangli',
        branch: 'Sangli Branch',
        revenue: 320000,
        orders: 95,
        growth: 5.7,
        topProducts: ['Product A', 'Product D'],
      ),
    ];
  }

  void _setupRealtimeListeners() {
    // Cancel existing subscriptions
    _ordersSubscription?.cancel();
    _employeesSubscription?.cancel();

    _ordersSubscription = _supabaseService.getOrdersStream().listen((orders) {
      debugPrint('Orders updated, refreshing data...');
      // Debounce refresh to prevent multiple rapid updates
      _debounceRefresh();
    }, onError: (error) {
      debugPrint('Order stream error: $error');
      // Try to reconnect after delay
      Future.delayed(const Duration(seconds: 5), () {
        if (_ordersSubscription?.isPaused ?? true) {
          _setupRealtimeListeners();
        }
      });
    });

    _employeesSubscription = _supabaseService.getEmployeesStream().listen((employees) {
      debugPrint('Employees updated, refreshing data...');
      _debounceRefresh();
    }, onError: (error) {
      debugPrint('Employee stream error: $error');
      Future.delayed(const Duration(seconds: 5), () {
        if (_employeesSubscription?.isPaused ?? true) {
          _setupRealtimeListeners();
        }
      });
    });
  }

  // Debounce to prevent multiple rapid refreshes
  Timer? _refreshTimer;
  void _debounceRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 2), () {
      _silentRefresh();
      // Also refresh district data when orders/employees update
      if (!_isLoadingDistrictData) {
        unawaited(loadDistrictRevenueData());
      }
    });
  }

  Future<void> _silentRefresh() async {
    try {
      await Future.wait([
        _fetchDashboardData(),
        _fetchChartData(),
      ]);
      notifyListeners();
    } catch (e) {
      debugPrint('Silent refresh error: $e');
    }
  }

  Future<void> refresh() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await Future.wait([
        _fetchDashboardData(),
        _fetchChartData(),
        loadDistrictRevenueData(),
      ]);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Refresh failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Separate refresh for district data only
  Future<void> refreshDistrictData() async {
    await loadDistrictRevenueData();
  }

  // Force refresh ignoring cache
  Future<void> forceRefreshDistrictData() async {
    _lastDistrictFetchTime = null;
    await loadDistrictRevenueData();
  }

  // Statistics getters for easy access
  double get totalDistrictRevenue {
    return _districtRevenueData.fold(0.0, (sum, district) => sum + district.revenue);
  }

  int get totalDistrictOrders {
    return _districtRevenueData.fold(0, (sum, district) => sum + district.orders);
  }

  // Clear error if needed
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _employeesSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}




// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:mega_pro/models/own_revenue_model.dart';
// import 'package:mega_pro/services/supabase_services.dart';

// class DashboardProvider with ChangeNotifier {
//   final SupabaseService _supabaseService = SupabaseService();
  
//   DashboardData _dashboardData = DashboardData.empty();
//   bool _isLoading = true;
//   String? _error;
//   List<Map<String, dynamic>> _revenueChartData = [];
  
//   List<DistrictRevenueData> _districtRevenueData = [];
//   bool _isLoadingDistrictData = false;
  
//   // Add these two properties
//   bool _isFirstLoad = true;
//   StreamSubscription? _ordersSubscription;
//   StreamSubscription? _employeesSubscription;

//   DashboardData get dashboardData => _dashboardData;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   List<Map<String, dynamic>> get revenueChartData => _revenueChartData;
  
//   List<DistrictRevenueData> get districtRevenueData => _districtRevenueData;
//   bool get isLoadingDistrictData => _isLoadingDistrictData;

//   DashboardProvider() {
//     // Don't call async directly in constructor
//     Future.microtask(() => _init());
//   }

//   Future<void> _init() async {
//     try {
//       if (_isFirstLoad) {
//         _isFirstLoad = false;
//         // Load critical data first, then rest in background
//         await _loadCriticalData();
//         _setupRealtimeListeners();
        
//         // Load district data in background
//         unawaited(loadDistrictRevenueData());
//       }
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _loadCriticalData() async {
//     try {
//       _isLoading = true;
//       notifyListeners();
      
//       // Load dashboard data and chart data
//       await Future.wait([
//         _fetchDashboardData(),
//         _fetchChartData(),
//       ]);
      
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _fetchDashboardData() async {
//     try {
//       final data = await _supabaseService.getDashboardData();
//       _dashboardData = data;
//     } catch (e) {
//       // Keep existing data if possible
//       debugPrint('Error fetching dashboard: $e');
//       // Don't throw, just use empty data
//     }
//   }

//   Future<void> _fetchChartData() async {
//     try {
//       _revenueChartData = await _supabaseService.getRevenueChartData();
//     } catch (e) {
//       debugPrint('Error fetching chart: $e');
//       _revenueChartData = []; // Set empty instead of throwing
//     }
//   }

//   Future<void> loadDistrictRevenueData() async {
//     if (_isLoadingDistrictData) return;
    
//     try {
//       _isLoadingDistrictData = true;
//       notifyListeners();

//       // Call your Supabase service to get district revenue data
//       // Example: _districtRevenueData = await _supabaseService.getDistrictRevenueData();
      
//       // For now, create mock data for testing
//       await Future.delayed(const Duration(seconds: 1));
      
//       _districtRevenueData = [
//         DistrictRevenueData(
//           district: 'Kolhapur',
//           branch: 'Main Branch',
//           revenue: 450000,
//           orders: 120,
//           growth: 12.5,
//           topProducts: ['Product A', 'Product B', 'Product C'],
//         ),
//         DistrictRevenueData(
//           district: 'Pune',
//           branch: 'City Branch',
//           revenue: 620000,
//           orders: 180,
//           growth: 8.3,
//           topProducts: ['Product X', 'Product Y'],
//         ),
//         DistrictRevenueData(
//           district: 'Satara',
//           branch: 'Satara Branch',
//           revenue: 280000,
//           orders: 85,
//           growth: 15.2,
//           topProducts: ['Product Z'],
//         ),
//         DistrictRevenueData(
//           district: 'Sangli',
//           branch: 'Sangli Branch',
//           revenue: 320000,
//           orders: 95,
//           growth: 5.7,
//           topProducts: ['Product A', 'Product D'],
//         ),
//       ];
      
//       _isLoadingDistrictData = false;
//       notifyListeners();
//     } catch (e) {
//       _isLoadingDistrictData = false;
//       debugPrint('District data error: $e');
//       // Don't set error for district data to avoid breaking main UI
//       notifyListeners();
//     }
//   }

//   void _setupRealtimeListeners() {
//     // Cancel existing subscriptions
//     _ordersSubscription?.cancel();
//     _employeesSubscription?.cancel();

//     _ordersSubscription = _supabaseService.getOrdersStream().listen((orders) {
//       debugPrint('Orders updated, refreshing data...');
//       // Debounce refresh
//       Timer(const Duration(seconds: 2), () {
//         _silentRefresh();
//       });
//     }, onError: (error) {
//       debugPrint('Order stream error: $error');
//     });

//     _employeesSubscription = _supabaseService.getEmployeesStream().listen((employees) {
//       debugPrint('Employees updated, refreshing data...');
//       Timer(const Duration(seconds: 2), () {
//         _silentRefresh();
//       });
//     }, onError: (error) {
//       debugPrint('Employee stream error: $error');
//     });
//   }

//   Future<void> _silentRefresh() async {
//     try {
//       await Future.wait([
//         _fetchDashboardData(),
//         _fetchChartData(),
//       ]);
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Silent refresh error: $e');
//     }
//   }

//   Future<void> refresh() async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();

//       await Future.wait([
//         _fetchDashboardData(),
//         _fetchChartData(),
//         loadDistrictRevenueData(),
//       ]);
      
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   @override
//   void dispose() {
//     _ordersSubscription?.cancel();
//     _employeesSubscription?.cancel();
//     super.dispose();
//   }
// }









// // lib/providers/dashboard_provider.dart
// import 'package:flutter/foundation.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:mega_pro/models/own_revenue_model.dart'; // Add this import
// import 'package:mega_pro/services/supabase_services.dart';

// class DashboardProvider with ChangeNotifier {
//   final SupabaseService _supabaseService = SupabaseService();
  
//   DashboardData _dashboardData = DashboardData.empty();
//   bool _isLoading = true;
//   String? _error;
//   List<Map<String, dynamic>> _revenueChartData = [];
  
//   // Add these properties for district revenue
//   List<DistrictRevenueData> _districtRevenueData = [];
//   bool _isLoadingDistrictData = false;

//   DashboardData get dashboardData => _dashboardData;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   List<Map<String, dynamic>> get revenueChartData => _revenueChartData;
  
//   // Add these getters
//   List<DistrictRevenueData> get districtRevenueData => _districtRevenueData;
//   bool get isLoadingDistrictData => _isLoadingDistrictData;

//   DashboardProvider() {
//     _init();
//   }

//   Future<void> _init() async {
//     try {
      
//       await loadDistrictRevenueData(); // Load district data on init
//       _setupRealtimeListeners();
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // ... existing fetchDashboardData and fetchChartData methods ...

//   Future<void> loadDistrictRevenueData() async {
//     try {
//       _isLoadingDistrictData = true;
//       notifyListeners();

//       // Call your Supabase service to get district revenue data
//       // Example: _districtRevenueData = await _supabaseService.getDistrictRevenueData();
      
//       // For now, create mock data for testing
//       await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
//       _districtRevenueData = [
//         DistrictRevenueData(
//           district: 'Kolhapur',
//           branch: 'Main Branch',
//           revenue: 450000,
//           orders: 120,
//           growth: 12.5,
//           topProducts: ['Product A', 'Product B', 'Product C'],
//         ),
//         DistrictRevenueData(
//           district: 'Pune',
//           branch: 'City Branch',
//           revenue: 620000,
//           orders: 180,
//           growth: 8.3,
//           topProducts: ['Product X', 'Product Y'],
//         ),
//         DistrictRevenueData(
//           district: 'Satara',
//           branch: 'Satara Branch',
//           revenue: 280000,
//           orders: 85,
//           growth: 15.2,
//           topProducts: ['Product Z'],
//         ),
//         DistrictRevenueData(
//           district: 'Sangli',
//           branch: 'Sangli Branch',
//           revenue: 320000,
//           orders: 95,
//           growth: 5.7,
//           topProducts: ['Product A', 'Product D'],
//         ),
//       ];
      
//       _isLoadingDistrictData = false;
//       notifyListeners();
//     } catch (e) {
//       _isLoadingDistrictData = false;
//       _error = 'Failed to load district data: $e';
//       notifyListeners();
//     }
//   }

//   void _setupRealtimeListeners() {
//     _supabaseService.getOrdersStream().listen((orders) {
//       debugPrint('Orders updated, fetching new dashboard data...');
      
//       loadDistrictRevenueData(); // Also reload district data
//     }, onError: (error) {
//       debugPrint('Order stream error: $error');
//     });

//     _supabaseService.getEmployeesStream().listen((employees) {
//       debugPrint('Employees updated, fetching new dashboard data...');
//     }, onError: (error) {
//       debugPrint('Employee stream error: $error');
//     });
//   }

//   void refresh() {
    
//     loadDistrictRevenueData();
//   }
// }
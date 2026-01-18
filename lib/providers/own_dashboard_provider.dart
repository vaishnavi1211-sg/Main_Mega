import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:mega_pro/services/supabase_services.dart';

class DashboardProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  DashboardData _dashboardData = DashboardData.empty();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _revenueChartData = [];
  List<Map<String, dynamic>> _profitChartData = [];
  
  // Real-time streams
  StreamSubscription<Map<String, dynamic>>? _profitMetricsSubscription;
  StreamSubscription<List<dynamic>>? _ordersSubscription;
  StreamSubscription<List<dynamic>>? _employeesSubscription;
  StreamSubscription<List<dynamic>>? _materialUsageSubscription;
  StreamSubscription<Map<String, dynamic>>? _productionSubscription;
  
  Timer? _autoRefreshTimer;
  Timer? _debounceTimer;
  DateTime? _lastUpdate;
  bool _isRefreshing = false;

  // District revenue data
  List<DistrictRevenueData> _districtRevenueData = [];
  bool _isLoadingDistrictData = false;

  DashboardData get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get revenueChartData => _revenueChartData;
  List<Map<String, dynamic>> get profitChartData => _profitChartData;
  DateTime? get lastUpdate => _lastUpdate;
  bool get isRefreshing => _isRefreshing;
  
  List<DistrictRevenueData> get districtRevenueData => _districtRevenueData;
  bool get isLoadingDistrictData => _isLoadingDistrictData;

  DashboardProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _loadInitialData();
      _setupRealTimeListeners();
      _startAutoRefresh();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Initialization failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _fetchDashboardData(),
        _fetchChartData(),
        _fetchProfitChartData(),
      ]);
      
      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Load initial data error: $e');
      // Use fallback data or empty data
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      _dashboardData = await _supabaseService.getDashboardData();
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      // Keep existing data or use empty
    }
  }

  Future<void> _fetchChartData() async {
    try {
      _revenueChartData = await _supabaseService.getRevenueChartData();
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      _revenueChartData = [];
    }
  }

  Future<void> _fetchProfitChartData() async {
    try {
      _profitChartData = await _supabaseService.getProfitChartData();
    } catch (e) {
      debugPrint('Error fetching profit chart data: $e');
      _profitChartData = [];
    }
  }

  Future<void> loadDistrictRevenueData() async {
    if (_isLoadingDistrictData) return;
    
    try {
      _isLoadingDistrictData = true;
      notifyListeners();

      _districtRevenueData = await _supabaseService.getDistrictRevenueData();
      
      _isLoadingDistrictData = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDistrictData = false;
      debugPrint('District data loading error: $e');
      notifyListeners();
    }
  }

  void _setupRealTimeListeners() {
    // Listen for profit metrics updates
    _profitMetricsSubscription = _supabaseService.getProfitMetricsStream().listen(
      (metrics) {
        _updateDashboardWithProfitMetrics(metrics);
      },
      onError: (error) {
        debugPrint('Profit metrics stream error: $error');
        _reconnectProfitStream();
      },
    );

    // Listen for order changes
    _ordersSubscription = _supabaseService.getOrdersStream().listen(
      (orders) {
        _handleOrderUpdate();
      },
      onError: (error) {
        debugPrint('Orders stream error: $error');
        _reconnectOrdersStream();
      },
    );

    // Listen for employee changes
    _employeesSubscription = _supabaseService.getEmployeesStream().listen(
      (employees) {
        _handleEmployeeUpdate();
      },
      onError: (error) {
        debugPrint('Employees stream error: $error');
        _reconnectEmployeesStream();
      },
    );

    // Listen for raw material usage changes
    _materialUsageSubscription = _supabaseService.getRawMaterialUsageStream().listen(
      (usage) {
        _handleMaterialUsageUpdate();
      },
      onError: (error) {
        debugPrint('Material usage stream error: $error');
        _reconnectMaterialStream();
      },
    );

    // Listen for production updates - Fixed version
    _productionSubscription = _supabaseService.getProductionStream().listen(
      (productionData) {
        _updateProductionMetrics(productionData);
      },
      onError: (error) {
        debugPrint('Production logs stream error: $error');
        _reconnectProductionStream();
      },
    );
  }

  void _updateDashboardWithProfitMetrics(Map<String, dynamic> metrics) {
    _dashboardData = _dashboardData.copyWith(
      totalRevenue: metrics['totalRevenue'] as double,
      totalRawMaterialCost: metrics['totalRawMaterialCost'] as double,
      totalProfit: metrics['totalProfit'] as double,
      profitMargin: metrics['profitMargin'] as double,
      materialCostBreakdown: metrics['materialCostBreakdown'] as Map<String, double>,
      productionToday: metrics['productionToday'] as double,
      productionTarget: metrics['productionTarget'] as double,
      completedOrdersThisMonth: metrics['completedOrdersThisMonth'] as int,
    );
    
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  void _updateProductionMetrics(Map<String, dynamic> productionData) {
    _dashboardData = _dashboardData.copyWith(
      productionToday: productionData['productionToday'] as double,
    );
    
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  void _handleOrderUpdate() {
    _debounceRefresh();
    // Log activity
    _supabaseService.logActivity(
      activityType: 'order_updated',
      description: 'Orders data updated in real-time',
    );
  }

  void _handleEmployeeUpdate() {
    _debounceRefresh();
  }

  void _handleMaterialUsageUpdate() {
    _debounceRefresh();
  }

  void _debounceRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _silentRefresh();
    });
  }

  Future<void> _silentRefresh() async {
    if (_isRefreshing) return;
    
    try {
      _isRefreshing = true;
      
      await Future.wait([
        _fetchDashboardData(),
        _fetchChartData(),
        _fetchProfitChartData(),
      ]);
      
      _lastUpdate = DateTime.now();
      _isRefreshing = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Silent refresh error: $e');
      _isRefreshing = false;
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _silentRefresh();
    });
  }

  // Reconnection methods
  void _reconnectProfitStream() {
    Future.delayed(const Duration(seconds: 10), () {
      if (_profitMetricsSubscription?.isPaused ?? true) {
        _profitMetricsSubscription?.cancel();
        _setupRealTimeListeners();
      }
    });
  }

  void _reconnectOrdersStream() {
    Future.delayed(const Duration(seconds: 10), () {
      if (_ordersSubscription?.isPaused ?? true) {
        _ordersSubscription?.cancel();
        _setupRealTimeListeners();
      }
    });
  }

  void _reconnectEmployeesStream() {
    Future.delayed(const Duration(seconds: 10), () {
      if (_employeesSubscription?.isPaused ?? true) {
        _employeesSubscription?.cancel();
        _setupRealTimeListeners();
      }
    });
  }

  void _reconnectMaterialStream() {
    Future.delayed(const Duration(seconds: 10), () {
      if (_materialUsageSubscription?.isPaused ?? true) {
        _materialUsageSubscription?.cancel();
        _setupRealTimeListeners();
      }
    });
  }

  void _reconnectProductionStream() {
    Future.delayed(const Duration(seconds: 10), () {
      if (_productionSubscription?.isPaused ?? true) {
        _productionSubscription?.cancel();
        _setupRealTimeListeners();
      }
    });
  }

  Future<void> refresh() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await Future.wait([
        _fetchDashboardData(),
        _fetchChartData(),
        _fetchProfitChartData(),
      ]);

      _lastUpdate = DateTime.now();
      _isLoading = false;
      
      // Log refresh activity
      _supabaseService.logActivity(
        activityType: 'dashboard_refresh',
        description: 'Dashboard manually refreshed',
      );
      
      notifyListeners();
    } catch (e) {
      _error = 'Refresh failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDistrictData() async {
    await loadDistrictRevenueData();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _profitMetricsSubscription?.cancel();
    _ordersSubscription?.cancel();
    _employeesSubscription?.cancel();
    _materialUsageSubscription?.cancel();
    _productionSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}





















// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:mega_pro/models/own_dashboard_model.dart';
// import 'package:mega_pro/services/supabase_services.dart';

// class DashboardProvider with ChangeNotifier {
//   final SupabaseService _supabaseService = SupabaseService();
  
//   DashboardData _dashboardData = DashboardData.empty();
//   bool _isLoading = true;
//   String? _error;
//   List<Map<String, dynamic>> _revenueChartData = [];
//   List<Map<String, dynamic>> _profitChartData = [];
  
//   // Real-time streams
//   StreamSubscription<Map<String, dynamic>>? _profitMetricsSubscription;
//   StreamSubscription<Map<String, dynamic>>? _productionSubscription;
//   StreamSubscription<List<dynamic>>? _ordersSubscription;
//   StreamSubscription<List<dynamic>>? _materialUsageSubscription;
  
//   Timer? _refreshTimer;
//   DateTime? _lastUpdate;

//   DashboardData get dashboardData => _dashboardData;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   List<Map<String, dynamic>> get revenueChartData => _revenueChartData;
//   List<Map<String, dynamic>> get profitChartData => _profitChartData;
//   DateTime? get lastUpdate => _lastUpdate;

//   DashboardProvider() {
//     _init();
//   }

//   Future<void> _init() async {
//     await _loadDashboardData();
//     _setupRealTimeListeners();
//     _startAutoRefresh();
//   }

//   Future<void> _loadDashboardData() async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       await Future.wait([
//         _fetchDashboardData(),
//         _fetchChartData(),
//         _fetchProfitChartData(),
//       ]);

//       _lastUpdate = DateTime.now();
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = 'Failed to load dashboard: ${e.toString()}';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _fetchDashboardData() async {
//     try {
//       _dashboardData = await _supabaseService.getDashboardData();
//     } catch (e) {
//       debugPrint('Error fetching dashboard: $e');
//       _dashboardData = DashboardData.empty();
//     }
//   }

//   Future<void> _fetchChartData() async {
//     try {
//       _revenueChartData = await _supabaseService.getRevenueChartData();
//     } catch (e) {
//       debugPrint('Error fetching chart data: $e');
//       _revenueChartData = [];
//     }
//   }

//   Future<void> _fetchProfitChartData() async {
//     try {
//       _profitChartData = await _supabaseService.getProfitChartData();
//     } catch (e) {
//       debugPrint('Error fetching profit chart data: $e');
//       _profitChartData = [];
//     }
//   }

//   void _setupRealTimeListeners() {
//     // Listen for profit metrics changes
//     _profitMetricsSubscription = _supabaseService.getProfitMetricsStream().listen(
//       (metrics) {
//         _updateDashboardWithProfitMetrics(metrics);
//       },
//       onError: (error) {
//         debugPrint('Profit metrics stream error: $error');
//         _reconnectProfitStream();
//       },
//     );

//     // Listen for production updates
//     _productionSubscription = _supabaseService.getProductionStream().listen(
//       (production) {
//         _updateProductionMetrics(production);
//       },
//       onError: (error) {
//         debugPrint('Production stream error: $error');
//         _reconnectProductionStream();
//       },
//     );

//     // Listen for order changes
//     _ordersSubscription = _supabaseService.getOrdersStream().listen(
//       (orders) {
//         _debounceRefresh();
//       },
//       onError: (error) {
//         debugPrint('Orders stream error: $error');
//         _reconnectOrdersStream();
//       },
//     );

//     // Listen for raw material usage changes
//     _materialUsageSubscription = _supabaseService.getEmployeesStream().listen(
//       (employees) {
//         _debounceRefresh();
//       },
//       onError: (error) {
//         debugPrint('Material usage stream error: $error');
//         _reconnectMaterialStream();
//       },
//     );
//   }

//   void _updateDashboardWithProfitMetrics(Map<String, dynamic> metrics) {
//     _dashboardData = _dashboardData.copyWith(
//       totalRevenue: metrics['totalRevenue'] as double,
//       totalRawMaterialCost: metrics['totalRawMaterialCost'] as double,
//       totalProfit: metrics['totalProfit'] as double,
//       profitMargin: metrics['profitMargin'] as double,
//       materialCostBreakdown: metrics['materialCostBreakdown'] as Map<String, double>,
//       productionToday: metrics['productionToday'] as double,
//       productionTarget: metrics['productionTarget'] as double,
//     );
    
//     _lastUpdate = DateTime.now();
//     notifyListeners();
//   }

//   void _updateProductionMetrics(Map<String, dynamic> production) {
//     _dashboardData = _dashboardData.copyWith(
//       productionToday: production['productionToday'] as double,
//     );
    
//     _lastUpdate = DateTime.now();
//     notifyListeners();
//   }

//   void _reconnectProfitStream() {
//     Future.delayed(const Duration(seconds: 5), () {
//       if (_profitMetricsSubscription?.isPaused ?? true) {
//         _setupRealTimeListeners();
//       }
//     });
//   }

//   void _reconnectProductionStream() {
//     Future.delayed(const Duration(seconds: 5), () {
//       if (_productionSubscription?.isPaused ?? true) {
//         _setupRealTimeListeners();
//       }
//     });
//   }

//   void _reconnectOrdersStream() {
//     Future.delayed(const Duration(seconds: 5), () {
//       if (_ordersSubscription?.isPaused ?? true) {
//         _setupRealTimeListeners();
//       }
//     });
//   }

//   void _reconnectMaterialStream() {
//     Future.delayed(const Duration(seconds: 5), () {
//       if (_materialUsageSubscription?.isPaused ?? true) {
//         _setupRealTimeListeners();
//       }
//     });
//   }

//   void _startAutoRefresh() {
//     _refreshTimer?.cancel();
//     _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
//       _silentRefresh();
//     });
//   }

//   Timer? _debounceTimer;
//   void _debounceRefresh() {
//     _debounceTimer?.cancel();
//     _debounceTimer = Timer(const Duration(seconds: 2), () {
//       _silentRefresh();
//     });
//   }

//   Future<void> _silentRefresh() async {
//     try {
//       await Future.wait([
//         _fetchDashboardData(),
//         _fetchChartData(),
//         _fetchProfitChartData(),
//       ]);
//       _lastUpdate = DateTime.now();
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
//         _fetchProfitChartData(),
//       ]);

//       _lastUpdate = DateTime.now();
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = 'Refresh failed: ${e.toString()}';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   @override
//   void dispose() {
//     _profitMetricsSubscription?.cancel();
//     _productionSubscription?.cancel();
//     _ordersSubscription?.cancel();
//     _materialUsageSubscription?.cancel();
//     _refreshTimer?.cancel();
//     _debounceTimer?.cancel();
//     super.dispose();
//   }
// }










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
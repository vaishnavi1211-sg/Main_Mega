// lib/providers/dashboard_provider.dart
import 'package:flutter/foundation.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';

import 'package:mega_pro/services/supabase_services.dart';

class DashboardProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  DashboardData _dashboardData = DashboardData.empty();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _revenueChartData = [];

  DashboardData get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get revenueChartData => _revenueChartData;

  DashboardProvider() {
    // Initialize and set up real-time listeners
    _init();
  }

  Future<void> _init() async {
    try {
      await fetchDashboardData();
      await fetchChartData();
      _setupRealtimeListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _dashboardData = await _supabaseService.getDashboardData();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchChartData() async {
    try {
      _revenueChartData = await _supabaseService.getRevenueChartData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
    }
  }

  void _setupRealtimeListeners() {
    // Listen for order changes
    _supabaseService.getOrdersStream().listen((orders) {
      debugPrint('Orders updated, fetching new dashboard data...');
      fetchDashboardData();
      fetchChartData();
    }, onError: (error) {
      debugPrint('Order stream error: $error');
    });

    // Listen for employee changes
    _supabaseService.getEmployeesStream().listen((employees) {
      debugPrint('Employees updated, fetching new dashboard data...');
      fetchDashboardData();
    }, onError: (error) {
      debugPrint('Employee stream error: $error');
    });
  }

  void refresh() {
    fetchDashboardData();
    fetchChartData();
  }
}
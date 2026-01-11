import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:mega_pro/models/own_revenue_model.dart';

class DashboardProvider extends ChangeNotifier {
  // Existing dashboard data
  DashboardData _dashboardData = DashboardData.empty();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _revenueChartData = [];
  
  // New detailed data
  List<DistrictRevenueData> _districtRevenueData = [];
  List<OrderDetail> _orderDetails = [];
  List<EmployeeDetail> _employeeDetails = [];
  List<PendingOrder> _pendingOrders = [];
  
  // Loading states for detailed data
  bool _isLoadingDistrictData = false;
  bool _isLoadingOrderDetails = false;
  bool _isLoadingEmployeeDetails = false;
  bool _isLoadingPendingOrders = false;
  
  DashboardProvider() {
    _initialize();
  }
  
  // Getters
  DashboardData get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get revenueChartData => _revenueChartData;
  
  List<DistrictRevenueData> get districtRevenueData => _districtRevenueData;
  List<OrderDetail> get orderDetails => _orderDetails;
  List<EmployeeDetail> get employeeDetails => _employeeDetails;
  List<PendingOrder> get pendingOrders => _pendingOrders;
  
  bool get isLoadingDistrictData => _isLoadingDistrictData;
  bool get isLoadingOrderDetails => _isLoadingOrderDetails;
  bool get isLoadingEmployeeDetails => _isLoadingEmployeeDetails;
  bool get isLoadingPendingOrders => _isLoadingPendingOrders;
  
  Future<void> _initialize() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate dashboard data
      _dashboardData = DashboardData(
        totalRevenue: 12500000,
        totalOrders: 4580,
        activeEmployees: 125,
        pendingOrders: 180,
        revenueGrowth: 12.5,
        orderGrowth: 8.3,
        employeeGrowth: 5.2,
        topProducts: [
          {'name': 'Cattle Feed Premium', 'sales': 1250, 'revenue': 4500000},
          {'name': 'Poultry Feed', 'sales': 980, 'revenue': 3200000},
          {'name': 'Fish Feed', 'sales': 720, 'revenue': 2800000},
        ],
        recentActivities: [
          {
            'title': 'New order received',
            'description': 'Order #ORD-2024-125 from Rajesh Farms',
            'time': '10 min ago',
            'icon': Icons.shopping_cart,
            'color': Colors.blue,
          },
          {
            'title': 'Payment received',
            'description': '₹45,000 from Kumar Dairy',
            'time': '30 min ago',
            'icon': Icons.currency_rupee,
            'color': Colors.green,
          },
        ],
      );
      
      // Simulate chart data
      _revenueChartData = [
        {'day': 'Mon', 'revenue': 1200000},
        {'day': 'Tue', 'revenue': 1500000},
        {'day': 'Wed', 'revenue': 1800000},
        {'day': 'Thu', 'revenue': 2200000},
        {'day': 'Fri', 'revenue': 1950000},
        {'day': 'Sat', 'revenue': 1400000},
        {'day': 'Sun', 'revenue': 1000000},
      ];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _initialize();
  }
  
  // New method for district revenue data
  Future<void> loadDistrictRevenueData() async {
    if (_districtRevenueData.isNotEmpty) return;
    
    _isLoadingDistrictData = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Sample data
      _districtRevenueData = [
        DistrictRevenueData(
          district: 'Kolhapur',
          branch: 'Main Branch',
          revenue: 1250000.0,
          orders: 450,
          growth: 12.5,
          topProducts: ['Cattle Feed Premium', 'Poultry Feed', 'Fish Feed'],
        ),
        DistrictRevenueData(
          district: 'Kolhapur',
          branch: 'Shirol Branch',
          revenue: 850000.0,
          orders: 320,
          growth: 8.2,
          topProducts: ['Cattle Feed Standard', 'Goat Feed', 'Supplement'],
        ),
        DistrictRevenueData(
          district: 'Pune',
          branch: 'Pune Central',
          revenue: 1950000.0,
          orders: 680,
          growth: 15.3,
          topProducts: ['Cattle Feed Premium', 'Organic Feed', 'Vitamin Mix'],
        ),
        DistrictRevenueData(
          district: 'Satara',
          branch: 'Satara Main',
          revenue: 720000.0,
          orders: 280,
          growth: 6.8,
          topProducts: ['Poultry Feed', 'Cattle Feed Standard', 'Mineral Mix'],
        ),
        DistrictRevenueData(
          district: 'Sangli',
          branch: 'Sangli Branch',
          revenue: 940000.0,
          orders: 350,
          growth: 9.7,
          topProducts: ['Fish Feed', 'Cattle Feed Premium', 'Growth Booster'],
        ),
      ];
    } catch (e) {
      print('Error loading district revenue data: $e');
    } finally {
      _isLoadingDistrictData = false;
      notifyListeners();
    }
  }
  
  // New method for order details
  Future<void> loadOrderDetails() async {
    if (_orderDetails.isNotEmpty) return;
    
    _isLoadingOrderDetails = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Sample data
      _orderDetails = [
        OrderDetail(
          id: 'ORD-2024-001',
          customerName: 'Rajesh Farms',
          status: 'completed',
          amount: 45000.0,
          date: DateTime.now().subtract(const Duration(days: 1)),
          product: 'Cattle Feed Premium',
          quantity: 50,
          branch: 'Main Branch',
          district: 'Kolhapur',
        ),
        OrderDetail(
          id: 'ORD-2024-002',
          customerName: 'Suresh Poultry',
          status: 'processing',
          amount: 32000.0,
          date: DateTime.now(),
          product: 'Poultry Feed',
          quantity: 40,
          branch: 'Shirol Branch',
          district: 'Kolhapur',
        ),
        OrderDetail(
          id: 'ORD-2024-003',
          customerName: 'Mohan Fisheries',
          status: 'completed',
          amount: 28000.0,
          date: DateTime.now().subtract(const Duration(days: 2)),
          product: 'Fish Feed',
          quantity: 35,
          branch: 'Pune Central',
          district: 'Pune',
        ),
        OrderDetail(
          id: 'ORD-2024-004',
          customerName: 'Ganesh Dairy',
          status: 'shipped',
          amount: 52000.0,
          date: DateTime.now().subtract(const Duration(days: 1)),
          product: 'Cattle Feed Standard',
          quantity: 65,
          branch: 'Satara Main',
          district: 'Satara',
        ),
        OrderDetail(
          id: 'ORD-2024-005',
          customerName: 'Vijay Farms',
          status: 'pending',
          amount: 38000.0,
          date: DateTime.now(),
          product: 'Goat Feed',
          quantity: 45,
          branch: 'Sangli Branch',
          district: 'Sangli',
        ),
      ];
    } catch (e) {
      print('Error loading order details: $e');
    } finally {
      _isLoadingOrderDetails = false;
      notifyListeners();
    }
  }
  
  // New method for employee details
  Future<void> loadEmployeeDetails() async {
    if (_employeeDetails.isNotEmpty) return;
    
    _isLoadingEmployeeDetails = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Sample data
      _employeeDetails = [
        EmployeeDetail(
          id: 'EMP-001',
          name: 'Ramesh Patil',
          position: 'Sales Manager',
          branch: 'Main Branch',
          district: 'Kolhapur',
          status: 'active',
          performance: 92.5,
          completedOrders: 125,
          revenueGenerated: 850000.0,
          joinDate: DateTime(2022, 1, 15),
        ),
        EmployeeDetail(
          id: 'EMP-002',
          name: 'Suresh Desai',
          position: 'Sales Executive',
          branch: 'Shirol Branch',
          district: 'Kolhapur',
          status: 'active',
          performance: 85.3,
          completedOrders: 98,
          revenueGenerated: 620000.0,
          joinDate: DateTime(2022, 3, 20),
        ),
        EmployeeDetail(
          id: 'EMP-003',
          name: 'Priya Sharma',
          position: 'Marketing Manager',
          branch: 'Pune Central',
          district: 'Pune',
          status: 'active',
          performance: 88.7,
          completedOrders: 145,
          revenueGenerated: 1050000.0,
          joinDate: DateTime(2021, 11, 5),
        ),
        EmployeeDetail(
          id: 'EMP-004',
          name: 'Amit Verma',
          position: 'Sales Executive',
          branch: 'Satara Main',
          district: 'Satara',
          status: 'on-leave',
          performance: 78.2,
          completedOrders: 82,
          revenueGenerated: 480000.0,
          joinDate: DateTime(2023, 2, 10),
        ),
        EmployeeDetail(
          id: 'EMP-005',
          name: 'Neha Gupta',
          position: 'Customer Support',
          branch: 'Sangli Branch',
          district: 'Sangli',
          status: 'active',
          performance: 91.0,
          completedOrders: 110,
          revenueGenerated: 720000.0,
          joinDate: DateTime(2022, 6, 15),
        ),
      ];
    } catch (e) {
      print('Error loading employee details: $e');
    } finally {
      _isLoadingEmployeeDetails = false;
      notifyListeners();
    }
  }
  
  // New method for pending orders
  Future<void> loadPendingOrders() async {
    if (_pendingOrders.isNotEmpty) return;
    
    _isLoadingPendingOrders = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Sample data
      _pendingOrders = [
        PendingOrder(
          id: 'PEND-001',
          customerName: 'Kumar Farms',
          product: 'Cattle Feed Premium',
          quantity: 60,
          amount: 54000.0,
          orderDate: DateTime.now().subtract(const Duration(days: 3)),
          branch: 'Main Branch',
          district: 'Kolhapur',
          reason: 'Payment pending',
          priority: 'high',
        ),
        PendingOrder(
          id: 'PEND-002',
          customerName: 'Shivaji Poultry',
          product: 'Poultry Feed',
          quantity: 45,
          amount: 36000.0,
          orderDate: DateTime.now().subtract(const Duration(days: 2)),
          branch: 'Shirol Branch',
          district: 'Kolhapur',
          reason: 'Stock unavailable',
          priority: 'medium',
        ),
        PendingOrder(
          id: 'PEND-003',
          customerName: 'Ocean Fisheries',
          product: 'Fish Feed',
          quantity: 30,
          amount: 24000.0,
          orderDate: DateTime.now().subtract(const Duration(days: 4)),
          branch: 'Pune Central',
          district: 'Pune',
          reason: 'Delivery address issue',
          priority: 'high',
        ),
        PendingOrder(
          id: 'PEND-004',
          customerName: 'Maharashtra Dairy',
          product: 'Cattle Feed Standard',
          quantity: 75,
          amount: 45000.0,
          orderDate: DateTime.now().subtract(const Duration(days: 1)),
          branch: 'Satara Main',
          district: 'Satara',
          reason: 'Customer verification',
          priority: 'low',
        ),
        PendingOrder(
          id: 'PEND-005',
          customerName: 'Goat Farm Sangli',
          product: 'Goat Feed',
          quantity: 40,
          amount: 32000.0,
          orderDate: DateTime.now(),
          branch: 'Sangli Branch',
          district: 'Sangli',
          reason: 'New customer approval',
          priority: 'medium',
        ),
      ];
    } catch (e) {
      print('Error loading pending orders: $e');
    } finally {
      _isLoadingPendingOrders = false;
      notifyListeners();
    }
  }
  
  // Method to refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadDistrictRevenueData(),
      loadOrderDetails(),
      loadEmployeeDetails(),
      loadPendingOrders(),
    ]);
  }
}
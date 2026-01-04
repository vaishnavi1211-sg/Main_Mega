import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

final supabase = Supabase.instance.client;

class MarTargetProvider extends ChangeNotifier {
  final Map<String, Map<String, double>> _targetData = {};
  final Map<String, Map<String, double>> _achievedData = {};

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // ================= LOAD TARGET DATA =================
  Future<void> loadTargetData(String empId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final currentYear = DateTime.now().year;

      // Generate month keys (YYYY-MM)
      final months = List.generate(
        12,
        (i) => '$currentYear-${(i + 1).toString().padLeft(2, '0')}',
      );

      final targetMap = {for (final m in months) m: 0.0};
      final achievedMap = {for (final m in months) m: 0.0};

      // ================= FETCH TARGETS =================
      try {
        final targetsResponse = await supabase
            .from('emp_mar_targets')
            .select('target_month, target_amount')
            .eq('emp_id', empId)
            .like('target_month', '$currentYear-%')
            .order('target_month');

        for (final row in targetsResponse) {
          final month = row['target_month']?.toString();
          final amount = double.tryParse(row['target_amount'].toString()) ?? 0.0;
          if (month != null && targetMap.containsKey(month)) {
            targetMap[month] = amount;
          }
        }
      } catch (e) {
        debugPrint('❌ Error fetching targets: $e');
      }

      // ================= FETCH ACHIEVED ORDERS =================
      try {
        final ordersResponse = await supabase
            .from('emp_mar_orders')
            .select('created_at, total_price, status, bags')
            .eq('employee_id', empId)
            .gte('created_at', '$currentYear-01-01T00:00:00')
            .lte('created_at', '$currentYear-12-31T23:59:59')
            .order('created_at', ascending: false);

        for (final order in ordersResponse) {
          final status = (order['status'] ?? 'pending').toString().toLowerCase();

          // Check if order is completed
          final isCompleted = status == 'completed' || 
                             status == 'delivered' ||
                             status == 'dispatched';

          if (!isCompleted) continue;

          final createdAt = order['created_at'];
          if (createdAt == null) continue;

          final date = DateTime.tryParse(createdAt.toString());
          if (date == null) continue;

          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

          // Calculate achieved value
          double achievedValue = 0.0;
          
          // Priority 1: Use total_price if available
          if (order['total_price'] != null) {
            achievedValue = double.tryParse(order['total_price'].toString()) ?? 0.0;
          } 
          // Priority 2: Calculate from bags and price (if you have price_per_bag field)
          else if (order['bags'] != null) {
            // Assuming average price per bag - you might need to adjust this
            final bags = double.tryParse(order['bags'].toString()) ?? 0.0;
            achievedValue = bags * 1000; // Example: ₹1000 per bag
          }

          if (achievedValue > 0 && achievedMap.containsKey(monthKey)) {
            achievedMap[monthKey] = achievedMap[monthKey]! + achievedValue;
          }
        }
      } catch (e) {
        debugPrint('❌ Error fetching orders: $e');
      }

      // Store the data
      _targetData[empId] = targetMap;
      _achievedData[empId] = achievedMap;

      _loading = false;
      notifyListeners();

      debugPrint('✅ Loaded target data for employee: $empId');
      debugPrint('   Targets: $targetMap');
      debugPrint('   Achieved: $achievedMap');

    } catch (e) {
      _error = e.toString();
      _loading = false;
      debugPrint('❌ Error in loadTargetData: $e');
      notifyListeners();
    }
  }

  // ================= GET TARGET FOR SPECIFIC MONTH =================
  double getTargetForMonth(String empId, String month) {
    return _targetData[empId]?[month] ?? 0.0;
  }

  // ================= GET ACHIEVED FOR SPECIFIC MONTH =================
  double getAchievedForMonth(String empId, String month) {
    return _achievedData[empId]?[month] ?? 0.0;
  }

  // ================= GET COMPLETE MONTHLY DATA =================
  Map<String, Map<String, double>> getMonthlyData(String empId) {
    final targets = _targetData[empId] ?? {};
    final achieved = _achievedData[empId] ?? {};
    
    return {
      'targets': Map<String, double>.from(targets),
      'achieved': Map<String, double>.from(achieved),
    };
  }

  // ================= GET DATA FOR CHART =================
  Map<String, List<double>> getChartData(String empId) {
    final currentYear = DateTime.now().year;
    final months = List.generate(12, (i) => i + 1);
    
    final targets = months.map((month) {
      final monthKey = '$currentYear-${month.toString().padLeft(2, '0')}';
      return getTargetForMonth(empId, monthKey);
    }).toList();
    
    final achieved = months.map((month) {
      final monthKey = '$currentYear-${month.toString().padLeft(2, '0')}';
      return getAchievedForMonth(empId, monthKey);
    }).toList();
    
    return {
      'targets': targets,
      'achieved': achieved,
    };
  }

  // ================= GET MONTH NAMES FOR DISPLAY =================
  List<String> getMonthNames() {
    return [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
  }

  // ================= GET FULL MONTH NAMES =================
  List<String> getFullMonthNames() {
    return [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
  }

  // ================= CHECK IF EMPLOYEE HAS DATA =================
  bool hasData(String empId) {
    final targetsExist = _targetData.containsKey(empId) && 
                        _targetData[empId]!.values.any((value) => value > 0);
    
    final achievedExist = _achievedData.containsKey(empId) && 
                         _achievedData[empId]!.values.any((value) => value > 0);
    
    return targetsExist || achievedExist;
  }

  // ================= GET COMPLETION PERCENTAGE =================
  double getCompletionPercentage(String empId, String month) {
    final target = getTargetForMonth(empId, month);
    final achieved = getAchievedForMonth(empId, month);
    
    if (target <= 0) return 0.0;
    
    final percentage = (achieved / target) * 100;
    return percentage.clamp(0.0, 100.0);
  }

  // ================= GET TOTAL ANNUAL TARGET =================
  double getTotalAnnualTarget(String empId) {
    if (!_targetData.containsKey(empId)) return 0.0;
    
    return _targetData[empId]!.values.fold(0.0, (sum, value) => sum + value);
  }

  // ================= GET TOTAL ANNUAL ACHIEVED =================
  double getTotalAnnualAchieved(String empId) {
    if (!_achievedData.containsKey(empId)) return 0.0;
    
    return _achievedData[empId]!.values.fold(0.0, (sum, value) => sum + value);
  }

  // ================= GET ANNUAL COMPLETION PERCENTAGE =================
  double getAnnualCompletionPercentage(String empId) {
    final totalTarget = getTotalAnnualTarget(empId);
    final totalAchieved = getTotalAnnualAchieved(empId);
    
    if (totalTarget <= 0) return 0.0;
    
    final percentage = (totalAchieved / totalTarget) * 100;
    return percentage.clamp(0.0, 100.0);
  }

  // ================= CLEAR DATA =================
  void clearData() {
    _targetData.clear();
    _achievedData.clear();
    _error = null;
    notifyListeners();
  }

  // ================= REFRESH DATA =================
  Future<void> refreshData(String empId) async {
    clearData();
    await loadTargetData(empId);
  }

  // ================= TEST DATA GENERATION =================
  void setTestData(String empId) {
    final currentYear = DateTime.now().year;
    
    // Generate random test data
    final random = Random();
    final targetMap = <String, double>{};
    final achievedMap = <String, double>{};
    
    for (int i = 1; i <= 12; i++) {
      final monthKey = '$currentYear-${i.toString().padLeft(2, '0')}';
      final target = 10000.0 + random.nextDouble() * 50000.0;
      final achieved = target * (0.3 + random.nextDouble() * 0.7);
      
      targetMap[monthKey] = double.parse(target.toStringAsFixed(2));
      achievedMap[monthKey] = double.parse(achieved.toStringAsFixed(2));
    }
    
    _targetData[empId] = targetMap;
    _achievedData[empId] = achievedMap;
    
    notifyListeners();
  }

  // ================= GET MONTHLY STATUS =================
  String getMonthlyStatus(String empId, String month) {
    final percentage = getCompletionPercentage(empId, month);
    
    if (percentage >= 100) {
      return 'Exceeded';
    } else if (percentage >= 80) {
      return 'On Track';
    } else if (percentage >= 50) {
      return 'Moderate';
    } else {
      return 'Behind';
    }
  }

  // ================= GET STATUS COLOR =================
  Color getStatusColor(String status) {
    switch (status) {
      case 'Exceeded':
        return Colors.green;
      case 'On Track':
        return Colors.blue;
      case 'Moderate':
        return Colors.orange;
      case 'Behind':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Import dart:math for Random class

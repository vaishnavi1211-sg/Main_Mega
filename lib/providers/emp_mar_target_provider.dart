import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class TargetProvider extends ChangeNotifier {
  Map<String, Map<String, double>> _targetData = {}; // emp_id -> {month -> target}
  Map<String, Map<String, double>> _achievedData = {}; // emp_id -> {month -> achieved}
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadTargetData(String empId) async {
    try {
      _loading = true;
      notifyListeners();

      print('Loading target data for employee: $empId');
      
      // Load assigned targets from emp_mar_targets table
      final targetsResponse = await supabase
          .from('emp_mar_targets')
          .select('target_amount, target_month')
          .eq('emp_id', empId)
          .order('target_month', ascending: true);

      print('Targets response: $targetsResponse');

      // Load achieved data (from orders table) - adjust this based on your orders table structure
      final ordersResponse = await supabase
          .from('orders') // Change this to your actual orders table name
          .select('total_amount, created_at, status')
          .eq('emp_id', empId)
          .eq('status', 'completed') // Adjust status field as needed
          .order('created_at', ascending: true);

      print('Orders response length: ${ordersResponse.length}');

      // Process target data
      final targetMap = <String, double>{};
      for (var target in targetsResponse) {
        final month = target['target_month'] as String;
        final amount = double.tryParse(target['target_amount'].toString()) ?? 0.0;
        targetMap[month] = amount;
      }

      // Process achieved data (sum by month)
      final achievedMap = <String, double>{};
      for (var order in ordersResponse) {
        try {
          final dateStr = order['created_at']?.toString();
          if (dateStr != null && dateStr.isNotEmpty) {
            final date = DateTime.parse(dateStr.split('T')[0]);
            final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            final amount = double.tryParse(order['total_amount'].toString()) ?? 0.0;
            
            achievedMap.update(
              monthKey,
              (value) => value + amount,
              ifAbsent: () => amount,
            );
          }
        } catch (e) {
          print('Error parsing order date: $e');
        }
      }

      print('Target map: $targetMap');
      print('Achieved map: $achievedMap');

      // Convert to tons (assuming amounts are in tons already)
      _targetData[empId] = targetMap;
      _achievedData[empId] = achievedMap;

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      print('Error loading target data: $e');
    }
  }

  Map<String, double> getTargetsForEmployee(String empId) {
    return _targetData[empId] ?? {};
  }

  Map<String, double> getAchievedForEmployee(String empId) {
    return _achievedData[empId] ?? {};
  }

  double getTargetForMonth(String empId, String month) {
    return _targetData[empId]?[month] ?? 0.0;
  }

  double getAchievedForMonth(String empId, String month) {
    return _achievedData[empId]?[month] ?? 0.0;
  }

  List<double> getMonthlyTargets(String empId, List<String> months) {
    return months.map((month) => getTargetForMonth(empId, month)).toList();
  }

  List<double> getMonthlyAchieved(String empId, List<String> months) {
    return months.map((month) => getAchievedForMonth(empId, month)).toList();
  }

  double getMaxTarget(String empId) {
    final targets = _targetData[empId]?.values.toList() ?? [];
    final achieved = _achievedData[empId]?.values.toList() ?? [];
    final allValues = [...targets, ...achieved];
    if (allValues.isEmpty) return 100.0;
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    return maxValue * 1.2; // Add 20% padding
  }

  void clearData() {
    _targetData.clear();
    _achievedData.clear();
    notifyListeners();
  }
}
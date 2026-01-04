import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class TargetProvider extends ChangeNotifier {
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

      final months = List.generate(
        12,
        (i) => '$currentYear-${(i + 1).toString().padLeft(2, '0')}',
      );

      final targetMap = {for (final m in months) m: 0.0};
      final achievedMap = {for (final m in months) m: 0.0};

      // ================= TARGETS =================
      final targetsResponse = await supabase
          .from('emp_mar_targets')
          .select('target_month, target_amount')
          .eq('emp_id', empId)
          .like('target_month', '$currentYear-%')
          .order('target_month');

      for (final row in targetsResponse) {
        final month = row['target_month']?.toString();
        final amount =
            double.tryParse(row['target_amount'].toString()) ?? 0.0;
        if (month != null && targetMap.containsKey(month)) {
          targetMap[month] = amount;
        }
      }

      // ================= ACHIEVED =================
      final ordersResponse = await supabase
          .from('cattle_feed_orders')
          .select('*')
          .eq('emp_id', empId)
          .gte('created_at', '$currentYear-01-01T00:00:00')
          .lte('created_at', '$currentYear-12-31T23:59:59');

      for (final order in ordersResponse) {
        final status = (order['order_status'] ??
                order['status'] ??
                '')
            .toString()
            .toLowerCase();

        final isCompleted = status.contains('complete') ||
            status.contains('deliver') ||
            status.contains('confirm');

        if (!isCompleted) continue;

        final createdAt = order['created_at'];
        if (createdAt == null) continue;

        final date = DateTime.tryParse(createdAt.toString());
        if (date == null) continue;

        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';

        double quantity = 0.0;

        const quantityFields = [
          'tons',
          'quantity',
          'bags',
          'order_quantity',
          'qty',
          'weight',
          'total_quantity',
        ];

        for (final field in quantityFields) {
          if (order[field] != null) {
            final val = order[field];
            quantity = val is num
                ? val.toDouble()
                : double.tryParse(val.toString()) ?? 0.0;
            if (quantity > 0) break;
          }
        }

        if (quantity > 0 && achievedMap.containsKey(monthKey)) {
          achievedMap[monthKey] =
              achievedMap[monthKey]! + quantity;
        }
      }

      _targetData[empId] = targetMap;
      _achievedData[empId] = achievedMap;

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  // ================= TEST DATA SUPPORT =================
  Map<String, List<double>> generateTestData(String empId) {
    final targets =
        List<double>.generate(12, (i) => (i + 1) * 10.0);
    final achieved =
        List<double>.generate(12, (i) => (i + 1) * 8.0);

    return {
      'targets': targets,
      'achieved': achieved,
    };
  }

  void setTestData(
    String empId,
    List<double> targets,
    List<double> achieved,
  ) {
    final currentYear = DateTime.now().year;

    _targetData[empId] = {
      for (int i = 0; i < 12; i++)
        '$currentYear-${(i + 1).toString().padLeft(2, '0')}': targets[i]
    };

    _achievedData[empId] = {
      for (int i = 0; i < 12; i++)
        '$currentYear-${(i + 1).toString().padLeft(2, '0')}': achieved[i]
    };

    notifyListeners();
  }

  

  // ================= GETTERS =================
  double getTargetForMonth(String empId, String month) =>
      _targetData[empId]?[month] ?? 0.0;

  double getAchievedForMonth(String empId, String month) =>
      _achievedData[empId]?[month] ?? 0.0;

  List<double> getMonthlyTargets(String empId, List<String> months) =>
      months.map((m) => getTargetForMonth(empId, m)).toList();

  List<double> getMonthlyAchieved(String empId, List<String> months) =>
      months.map((m) => getAchievedForMonth(empId, m)).toList();

  bool hasData(String empId) {
    final t = _targetData[empId]?.values.any((e) => e > 0) ?? false;
    final a =
        _achievedData[empId]?.values.any((e) => e > 0) ?? false;
    return t || a;
  }

  void clearData() {
    _targetData.clear();
    _achievedData.clear();
    notifyListeners();
  }
}








// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// final supabase = Supabase.instance.client;

// class TargetProvider extends ChangeNotifier {
//   Map<String, Map<String, double>> _targetData = {}; // emp_id -> {month -> target}
//   Map<String, Map<String, double>> _achievedData = {}; // emp_id -> {month -> achieved}
//   bool _loading = false;
//   String? _error;

//   bool get loading => _loading;
//   String? get error => _error;

//   Future<void> loadTargetData(String empId) async {
//     try {
//       _loading = true;
//       notifyListeners();

//       print('Loading target data for employee: $empId');
      
//       // Load assigned targets from emp_mar_targets table
//       final targetsResponse = await supabase
//           .from('emp_mar_targets')
//           .select('target_amount, target_month')
//           .eq('emp_id', empId)
//           .order('target_month', ascending: true);

//       print('Targets response: $targetsResponse');

//       // Load achieved data (from orders table) - adjust this based on your orders table structure
//       final ordersResponse = await supabase
//           .from('orders') // Change this to your actual orders table name
//           .select('total_amount, created_at, status')
//           .eq('emp_id', empId)
//           .eq('status', 'completed') // Adjust status field as needed
//           .order('created_at', ascending: true);

//       print('Orders response length: ${ordersResponse.length}');

//       // Process target data
//       final targetMap = <String, double>{};
//       for (var target in targetsResponse) {
//         final month = target['target_month'] as String;
//         final amount = double.tryParse(target['target_amount'].toString()) ?? 0.0;
//         targetMap[month] = amount;
//       }

//       // Process achieved data (sum by month)
//       final achievedMap = <String, double>{};
//       for (var order in ordersResponse) {
//         try {
//           final dateStr = order['created_at']?.toString();
//           if (dateStr != null && dateStr.isNotEmpty) {
//             final date = DateTime.parse(dateStr.split('T')[0]);
//             final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
//             final amount = double.tryParse(order['total_amount'].toString()) ?? 0.0;
            
//             achievedMap.update(
//               monthKey,
//               (value) => value + amount,
//               ifAbsent: () => amount,
//             );
//           }
//         } catch (e) {
//           print('Error parsing order date: $e');
//         }
//       }

//       print('Target map: $targetMap');
//       print('Achieved map: $achievedMap');

//       // Convert to tons (assuming amounts are in tons already)
//       _targetData[empId] = targetMap;
//       _achievedData[empId] = achievedMap;

//       _loading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _loading = false;
//       notifyListeners();
//       print('Error loading target data: $e');
//     }
//   }

//   Map<String, double> getTargetsForEmployee(String empId) {
//     return _targetData[empId] ?? {};
//   }

//   Map<String, double> getAchievedForEmployee(String empId) {
//     return _achievedData[empId] ?? {};
//   }

//   double getTargetForMonth(String empId, String month) {
//     return _targetData[empId]?[month] ?? 0.0;
//   }

//   double getAchievedForMonth(String empId, String month) {
//     return _achievedData[empId]?[month] ?? 0.0;
//   }

//   List<double> getMonthlyTargets(String empId, List<String> months) {
//     return months.map((month) => getTargetForMonth(empId, month)).toList();
//   }

//   List<double> getMonthlyAchieved(String empId, List<String> months) {
//     return months.map((month) => getAchievedForMonth(empId, month)).toList();
//   }

//   double getMaxTarget(String empId) {
//     final targets = _targetData[empId]?.values.toList() ?? [];
//     final achieved = _achievedData[empId]?.values.toList() ?? [];
//     final allValues = [...targets, ...achieved];
//     if (allValues.isEmpty) return 100.0;
//     final maxValue = allValues.reduce((a, b) => a > b ? a : b);
//     return maxValue * 1.2; // Add 20% padding
//   }

//   void clearData() {
//     _targetData.clear();
//     _achievedData.clear();
//     notifyListeners();
//   }
// }
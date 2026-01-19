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
      print('🎯 Loading target data for employee ID: $empId');
      
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

      // ================= TARGETS FROM emp_mar_targets TABLE =================
      print('🔍 Querying emp_mar_targets table...');
      try {
        final targetsResponse = await supabase
            .from('emp_mar_targets')
            .select('target_month, target_amount, emp_id, employee_name')
            .eq('emp_id', empId)
            .like('target_month', '$currentYear-%')
            .order('target_month');

        print('📊 Found ${targetsResponse.length} target records');
        
        for (final row in targetsResponse) {
          final month = row['target_month']?.toString();
          final amount = double.tryParse(row['target_amount'].toString()) ?? 0.0;
          final rowEmpId = row['emp_id']?.toString();
          
          print('   Month: $month, Target Amount: $amount, Emp ID: $rowEmpId');
          
          if (month != null && targetMap.containsKey(month)) {
            targetMap[month] = amount;
          }
        }
            } catch (e) {
        print('❌ Error querying emp_mar_targets: $e');
      }

      // ================= ACHIEVED FROM emp_mar_orders TABLE =================
      print('🔍 Calculating achieved from completed orders...');
      try {
        // First, get total weight in tons from completed orders
        final ordersResponse = await supabase
            .from('emp_mar_orders')
            .select('created_at, total_weight, bags, status, employee_id')
            .eq('status', 'completed')
            .gte('created_at', '$currentYear-01-01')
            .lte('created_at', '$currentYear-12-31');

        print('📦 Found ${ordersResponse.length} completed orders');
        
        // Group by month
        for (final order in ordersResponse) {
          final createdAt = order['created_at']?.toString();
          final totalWeight = (order['total_weight'] as num?)?.toDouble() ?? 0.0;
          final bags = (order['bags'] as num?)?.toDouble() ?? 0.0;
          
          if (createdAt != null) {
            try {
              final date = DateTime.parse(createdAt);
              final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
              
              if (achievedMap.containsKey(monthKey)) {
                // Convert weight to tons (if in kg, divide by 1000)
                double weightInTons = totalWeight;
                if (totalWeight > 1000) { // If it's in kg, convert to tons
                  weightInTons = totalWeight / 1000;
                }
                
                // Alternative: if bags is available, estimate weight (50kg per bag = 0.05 tons)
                if (weightInTons == 0 && bags > 0) {
                  weightInTons = bags * 0.05; // 50kg per bag
                }
                
                achievedMap[monthKey] = achievedMap[monthKey]! + weightInTons;
                print('     Added ${weightInTons.toStringAsFixed(2)} tons to $monthKey');
              }
            } catch (e) {
              print('     Error parsing date: $e');
            }
          }
        }
            } catch (e) {
        print('❌ Error querying emp_mar_orders: $e');
      }

      // Store the data
      _targetData[empId] = targetMap;
      _achievedData[empId] = achievedMap;

      // Debug output
      print('📊 FINAL TARGET DATA for $empId:');
      for (var month in months) {
        print('   $month: Target=${targetMap[month]} T, Achieved=${achievedMap[month]} T');
      }

      _loading = false;
      notifyListeners();
      
    } catch (e) {
      _error = 'Failed to load target data: $e';
      _loading = false;
      print('❌ Error in loadTargetData: $e');
      notifyListeners();
    }
  }

  // ================= GETTERS =================
  double getTargetForMonth(String empId, String month) {
    final value = _targetData[empId]?[month] ?? 0.0;
    return value;
  }

  double getAchievedForMonth(String empId, String month) {
    final value = _achievedData[empId]?[month] ?? 0.0;
    return value;
  }

  List<double> getMonthlyTargets(String empId, List<String> months) {
    final targets = months.map((m) => getTargetForMonth(empId, m)).toList();
    print('📊 getMonthlyTargets for $empId: $targets');
    return targets;
  }

  List<double> getMonthlyAchieved(String empId, List<String> months) {
    final achieved = months.map((m) => getAchievedForMonth(empId, m)).toList();
    print('📈 getMonthlyAchieved for $empId: $achieved');
    return achieved;
  }

  // ================= CURRENT MONTH DATA =================
  double getCurrentMonthTarget(String empId) {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return getTargetForMonth(empId, currentMonth);
  }

  double getCurrentMonthAchieved(String empId) {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return getAchievedForMonth(empId, currentMonth);
  }

  // ================= UTILITIES =================
  bool hasData(String empId) {
    final hasTargets = _targetData[empId]?.values.any((e) => e > 0) ?? false;
    final hasAchieved = _achievedData[empId]?.values.any((e) => e > 0) ?? false;
    print('📊 hasData for $empId: targets=$hasTargets, achieved=$hasAchieved');
    return hasTargets || hasAchieved;
  }

  void clearData() {
    _targetData.clear();
    _achievedData.clear();
    notifyListeners();
  }

  // ================= DEBUG =================
  void debugData(String empId) {
    print('=== TARGET PROVIDER DEBUG for $empId ===');
    print('Target Data Available: ${_targetData.containsKey(empId)}');
    print('Achieved Data Available: ${_achievedData.containsKey(empId)}');
    
    if (_targetData.containsKey(empId)) {
      print('Targets:');
      _targetData[empId]!.forEach((key, value) {
        if (value > 0) print('  $key: $value T');
      });
    }
    
    if (_achievedData.containsKey(empId)) {
      print('Achieved:');
      _achievedData[empId]!.forEach((key, value) {
        if (value > 0) print('  $key: $value T');
      });
    }
    
    print('===================================');
  }
}















//next one to this works well


// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// final supabase = Supabase.instance.client;

// class TargetProvider extends ChangeNotifier {
//   final Map<String, Map<String, double>> _targetData = {};
//   final Map<String, Map<String, double>> _achievedData = {};

//   bool _loading = false;
//   String? _error;

//   bool get loading => _loading;
//   String? get error => _error;

//   // ================= LOAD TARGET DATA =================
//   Future<void> loadTargetData(String empId) async {
//     try {
//       print('🎯 Loading target data for employee ID: $empId');
      
//       _loading = true;
//       _error = null;
//       notifyListeners();

//       final currentYear = DateTime.now().year;

//       final months = List.generate(
//         12,
//         (i) => '$currentYear-${(i + 1).toString().padLeft(2, '0')}',
//       );

//       final targetMap = {for (final m in months) m: 0.0};
//       final achievedMap = {for (final m in months) m: 0.0};

//       // ================= TARGETS FROM emp_mar_targets TABLE =================
//       print('🔍 Querying emp_mar_targets table...');
//       try {
//         final targetsResponse = await supabase
//             .from('emp_mar_targets')
//             .select('target_month, target_amount, emp_id')
//             .eq('emp_id', empId)
//             .like('target_month', '$currentYear-%')
//             .order('target_month');

//         print('📊 Found ${targetsResponse.length} target records');
        
//         for (final row in targetsResponse) {
//           final month = row['target_month']?.toString();
//           final amount = double.tryParse(row['target_amount'].toString()) ?? 0.0;
//           final rowEmpId = row['emp_id']?.toString();
          
//           print('   Month: $month, Target Amount: $amount, Emp ID: $rowEmpId');
          
//           if (month != null && targetMap.containsKey(month)) {
//             targetMap[month] = amount;
//           }
//         }
//             } catch (e) {
//         print('❌ Error querying emp_mar_targets: $e');
//         // Continue to try other sources
//       }

//       // ================= ACHIEVED FROM MULTIPLE SOURCES =================
//       print('🔍 Looking for completed orders to calculate achieved...');
      
//       // Try emp_mar_orders table first (since it exists according to your errors)
//       try {
//         print('   Checking emp_mar_orders table...');
//         final marOrdersResponse = await supabase
//             .from('emp_mar_orders')
//             .select('created_at, bags, status, employee_id')
//             .eq('employee_id', empId)
//             .eq('status', 'completed')
//             .gte('created_at', '$currentYear-01-01')
//             .lte('created_at', '$currentYear-12-31');

//         print('   Found ${marOrdersResponse.length} completed orders in emp_mar_orders');
        
//         for (final order in marOrdersResponse) {
//           final createdAt = order['created_at']?.toString();
//           final bags = (order['bags'] as num?)?.toDouble() ?? 0.0;
          
//           if (createdAt != null && bags > 0) {
//             try {
//               final date = DateTime.parse(createdAt);
//               final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
              
//               if (achievedMap.containsKey(monthKey)) {
//                 // Convert bags to tons (assuming 1 bag = 0.05 tons, adjust as needed)
//                 final tons = bags * 0.05;
//                 achievedMap[monthKey] = achievedMap[monthKey]! + tons;
//                 print('     Added $bags bags ($tons tons) to $monthKey');
//               }
//             } catch (e) {
//               print('     Error parsing date: $e');
//             }
//           }
//         }
//             } catch (e) {
//         print('❌ Error querying emp_mar_orders: $e');
//       }

//       // Try cattle_feed_orders table
//       try {
//         print('   Checking cattle_feed_orders table...');
//         // Use multiple OR conditions instead of .inFilter
//         final ordersResponse = await supabase
//             .from('cattle_feed_orders')
//             .select('created_at, bags, order_status, emp_id')
//             .eq('emp_id', empId)
//             .or('order_status.eq.completed,order_status.eq.delivered,order_status.eq.confirmed')
//             .gte('created_at', '$currentYear-01-01')
//             .lte('created_at', '$currentYear-12-31');

//         print('   Found ${ordersResponse.length} completed orders in cattle_feed_orders');
        
//         for (final order in ordersResponse) {
//           (order['order_status'] ?? '').toString().toLowerCase();
//           final createdAt = order['created_at']?.toString();
//           final bags = (order['bags'] as num?)?.toDouble() ?? 0.0;
          
//           if (createdAt != null && bags > 0) {
//             try {
//               final date = DateTime.parse(createdAt);
//               final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
              
//               if (achievedMap.containsKey(monthKey)) {
//                 // Convert bags to tons (assuming 1 bag = 0.05 tons)
//                 final tons = bags * 0.05;
//                 achievedMap[monthKey] = achievedMap[monthKey]! + tons;
//                 print('     Added $bags bags ($tons tons) from cattle_feed_orders to $monthKey');
//               }
//             } catch (e) {
//               print('     Error parsing date: $e');
//             }
//           }
//         }
//             } catch (e) {
//         print('❌ Error querying cattle_feed_orders: $e');
//       }

//       // Store the data
//       _targetData[empId] = targetMap;
//       _achievedData[empId] = achievedMap;

//       // Debug output
//       print('📊 FINAL TARGET DATA for $empId:');
//       for (var month in months) {
//         print('   $month: Target=${targetMap[month]}, Achieved=${achievedMap[month]}');
//       }

//       _loading = false;
//       notifyListeners();
      
//     } catch (e) {
//       _error = 'Failed to load target data: $e';
//       _loading = false;
//       print('❌ Error in loadTargetData: $e');
//       notifyListeners();
//     }
//   }

//   // ================= GETTERS =================
//   double getTargetForMonth(String empId, String month) {
//     final value = _targetData[empId]?[month] ?? 0.0;
//     return value;
//   }

//   double getAchievedForMonth(String empId, String month) {
//     final value = _achievedData[empId]?[month] ?? 0.0;
//     return value;
//   }

//   List<double> getMonthlyTargets(String empId, List<String> months) {
//     final targets = months.map((m) => getTargetForMonth(empId, m)).toList();
//     print('📊 getMonthlyTargets for $empId: $targets');
//     return targets;
//   }

//   List<double> getMonthlyAchieved(String empId, List<String> months) {
//     final achieved = months.map((m) => getAchievedForMonth(empId, m)).toList();
//     print('📈 getMonthlyAchieved for $empId: $achieved');
//     return achieved;
//   }

//   // ================= CURRENT MONTH DATA =================
//   double getCurrentMonthTarget(String empId) {
//     final now = DateTime.now();
//     final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
//     return getTargetForMonth(empId, currentMonth);
//   }

//   double getCurrentMonthAchieved(String empId) {
//     final now = DateTime.now();
//     final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
//     return getAchievedForMonth(empId, currentMonth);
//   }

//   // ================= TEST DATA SUPPORT =================
//   Map<String, List<double>> generateTestData(String empId) {
//     final targets = List<double>.generate(12, (i) => (i + 1) * 10.0);
//     final achieved = List<double>.generate(12, (i) => (i + 1) * 8.0);

//     return {
//       'targets': targets,
//       'achieved': achieved,
//     };
//   }

//   void setTestData(
//     String empId,
//     List<double> targets,
//     List<double> achieved,
//   ) {
//     final currentYear = DateTime.now().year;

//     _targetData[empId] = {
//       for (int i = 0; i < 12; i++)
//         '$currentYear-${(i + 1).toString().padLeft(2, '0')}': targets[i]
//     };

//     _achievedData[empId] = {
//       for (int i = 0; i < 12; i++)
//         '$currentYear-${(i + 1).toString().padLeft(2, '0')}': achieved[i]
//     };

//     notifyListeners();
//   }

//   // ================= UTILITIES =================
//   bool hasData(String empId) {
//     final hasTargets = _targetData[empId]?.values.any((e) => e > 0) ?? false;
//     final hasAchieved = _achievedData[empId]?.values.any((e) => e > 0) ?? false;
//     print('📊 hasData for $empId: targets=$hasTargets, achieved=$hasAchieved');
//     return hasTargets || hasAchieved;
//   }

//   void clearData() {
//     _targetData.clear();
//     _achievedData.clear();
//     notifyListeners();
//   }

//   // ================= DEBUG =================
//   void debugData(String empId) {
//     print('=== TARGET PROVIDER DEBUG for $empId ===');
//     print('Target Data Available: ${_targetData.containsKey(empId)}');
//     print('Achieved Data Available: ${_achievedData.containsKey(empId)}');
    
//     if (_targetData.containsKey(empId)) {
//       print('Targets:');
//       _targetData[empId]!.forEach((key, value) {
//         if (value > 0) print('  $key: $value');
//       });
//     }
    
//     if (_achievedData.containsKey(empId)) {
//       print('Achieved:');
//       _achievedData[empId]!.forEach((key, value) {
//         if (value > 0) print('  $key: $value');
//       });
//     }
    
//     print('===================================');
//   }
// }



















// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// final supabase = Supabase.instance.client;

// class TargetProvider extends ChangeNotifier {
//   final Map<String, Map<String, double>> _targetData = {};
//   final Map<String, Map<String, double>> _achievedData = {};

//   bool _loading = false;
//   String? _error;

//   bool get loading => _loading;
//   String? get error => _error;

//   // ================= LOAD TARGET DATA =================
//   Future<void> loadTargetData(String empId) async {
//     try {
//       _loading = true;
//       _error = null;
//       notifyListeners();

//       final currentYear = DateTime.now().year;

//       final months = List.generate(
//         12,
//         (i) => '$currentYear-${(i + 1).toString().padLeft(2, '0')}',
//       );

//       final targetMap = {for (final m in months) m: 0.0};
//       final achievedMap = {for (final m in months) m: 0.0};

//       // ================= TARGETS =================
//       final targetsResponse = await supabase
//           .from('emp_mar_targets')
//           .select('target_month, target_amount')
//           .eq('emp_id', empId)
//           .like('target_month', '$currentYear-%')
//           .order('target_month');

//       for (final row in targetsResponse) {
//         final month = row['target_month']?.toString();
//         final amount =
//             double.tryParse(row['target_amount'].toString()) ?? 0.0;
//         if (month != null && targetMap.containsKey(month)) {
//           targetMap[month] = amount;
//         }
//       }

//       // ================= ACHIEVED =================
//       final ordersResponse = await supabase
//           .from('cattle_feed_orders')
//           .select('*')
//           .eq('emp_id', empId)
//           .gte('created_at', '$currentYear-01-01T00:00:00')
//           .lte('created_at', '$currentYear-12-31T23:59:59');

//       for (final order in ordersResponse) {
//         final status = (order['order_status'] ??
//                 order['status'] ??
//                 '')
//             .toString()
//             .toLowerCase();

//         final isCompleted = status.contains('complete') ||
//             status.contains('deliver') ||
//             status.contains('confirm');

//         if (!isCompleted) continue;

//         final createdAt = order['created_at'];
//         if (createdAt == null) continue;

//         final date = DateTime.tryParse(createdAt.toString());
//         if (date == null) continue;

//         final monthKey =
//             '${date.year}-${date.month.toString().padLeft(2, '0')}';

//         double quantity = 0.0;

//         const quantityFields = [
//           'tons',
//           'quantity',
//           'bags',
//           'order_quantity',
//           'qty',
//           'weight',
//           'total_quantity',
//         ];

//         for (final field in quantityFields) {
//           if (order[field] != null) {
//             final val = order[field];
//             quantity = val is num
//                 ? val.toDouble()
//                 : double.tryParse(val.toString()) ?? 0.0;
//             if (quantity > 0) break;
//           }
//         }

//         if (quantity > 0 && achievedMap.containsKey(monthKey)) {
//           achievedMap[monthKey] =
//               achievedMap[monthKey]! + quantity;
//         }
//       }

//       _targetData[empId] = targetMap;
//       _achievedData[empId] = achievedMap;

//       _loading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _loading = false;
//       notifyListeners();
//     }
//   }

//   // ================= TEST DATA SUPPORT =================
//   Map<String, List<double>> generateTestData(String empId) {
//     final targets =
//         List<double>.generate(12, (i) => (i + 1) * 10.0);
//     final achieved =
//         List<double>.generate(12, (i) => (i + 1) * 8.0);

//     return {
//       'targets': targets,
//       'achieved': achieved,
//     };
//   }

//   void setTestData(
//     String empId,
//     List<double> targets,
//     List<double> achieved,
//   ) {
//     final currentYear = DateTime.now().year;

//     _targetData[empId] = {
//       for (int i = 0; i < 12; i++)
//         '$currentYear-${(i + 1).toString().padLeft(2, '0')}': targets[i]
//     };

//     _achievedData[empId] = {
//       for (int i = 0; i < 12; i++)
//         '$currentYear-${(i + 1).toString().padLeft(2, '0')}': achieved[i]
//     };

//     notifyListeners();
//   }

  

//   // ================= GETTERS =================
//   double getTargetForMonth(String empId, String month) =>
//       _targetData[empId]?[month] ?? 0.0;

//   double getAchievedForMonth(String empId, String month) =>
//       _achievedData[empId]?[month] ?? 0.0;

//   List<double> getMonthlyTargets(String empId, List<String> months) =>
//       months.map((m) => getTargetForMonth(empId, m)).toList();

//   List<double> getMonthlyAchieved(String empId, List<String> months) =>
//       months.map((m) => getAchievedForMonth(empId, m)).toList();

//   bool hasData(String empId) {
//     final t = _targetData[empId]?.values.any((e) => e > 0) ?? false;
//     final a =
//         _achievedData[empId]?.values.any((e) => e > 0) ?? false;
//     return t || a;
//   }

//   void clearData() {
//     _targetData.clear();
//     _achievedData.clear();
//     notifyListeners();
//   }
// }
















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
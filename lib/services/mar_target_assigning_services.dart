import 'package:flutter/material.dart';
import 'package:mega_pro/models/mar_manager_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketingTargetService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===================== GET MARKETING MANAGERS =====================
  Future<List<MarketingManager>> getMarketingManagers() async {
    try {
      final data = await _supabase
          .from('emp_profile')
          .select('id, emp_id, full_name, district, position, status, email, phone, branch, role')
          .eq('role', 'Marketing Manager')
          .eq('status', 'Active')
          .order('full_name');
      
      return (data as List).map((e) => MarketingManager.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getting managers: $e');
      return [];
    }
  }

  // ===================== GET AVAILABLE DISTRICTS =====================
  Future<List<String>> getAvailableDistricts() async {
    try {
      final data = await _supabase
          .from('emp_profile')
          .select('district')
          .eq('role', 'Marketing Manager')
          .eq('status', 'Active')
          .neq('district', '');

      final districts = (data as List<dynamic>)
          .map((e) => e['district'] as String?)
          .where((district) => district != null && district.isNotEmpty && district != 'null')
          .map((district) => district!.trim())
          .toSet()
          .toList();
      
      districts.sort();
      return ['All Districts', ...districts];
    } catch (e) {
      debugPrint('Error fetching districts: $e');
      return _getFallbackDistricts();
    }
  }

  List<String> _getFallbackDistricts() {
    final fallbackDistricts = [
      "Ahmednagar", "Akola", "Amravati", "Aurangabad", "Beed",
      "Bhandara", "Buldhana", "Chandrapur", "Dhule", "Gadchiroli",
      "Gondiya", "Hingoli", "Jalgaon", "Jalna", "Kolhapur",
      "Latur", "Mumbai City", "Mumbai Suburban", "Nagpur", "Nanded",
      "Nandurbar", "Nashik", "Osmanabad", "Palghar", "Parbhani",
      "Pune", "Raigad", "Ratnagiri", "Sangli", "Satara",
      "Sindhudurg", "Solapur", "Thane", "Wardha", "Washim", "Yavatmal"
    ]..sort();
    
    return ['All Districts', ...fallbackDistricts];
  }

  // ===================== ASSIGN TARGETS =====================
  Future<bool> assignTargets({
    required List<String> managerIds,
    required String district,
    required DateTime targetMonth,
    required int revenueTarget,
    required int orderTarget,
    String? remarks,
    required String branch,
  }) async {
    try {
      print('🚀 STARTING TARGET ASSIGNMENT');
      print('📋 Selected ${managerIds.length} managers');
      print('📍 District: $district');
      print('📅 Month: ${targetMonth.year}-${targetMonth.month}');
      print('💰 Revenue Target: $revenueTarget');
      print('📦 Order Target: $orderTarget');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return false;
      }
      print('👤 Current User ID: ${currentUser.id}');
      
      String targetDistrict = district;
      if (district == 'All Districts') {
        targetDistrict = 'All';
      }
      
      final monthStr = '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}-01';
      final now = DateTime.now().toIso8601String();
      
      // Method 1: Direct batch insert
      try {
        final List<Map<String, dynamic>> targets = [];
        for (final managerId in managerIds) {
          targets.add({
            'manager_id': managerId,
            'district': targetDistrict,
            'target_month': monthStr,
            'revenue_target': revenueTarget,
            'order_target': orderTarget,
            'achieved_revenue': 0,
            'achieved_orders': 0,
            'remarks': remarks,
            'assigned_by': currentUser.id,
            'assigned_at': now,
            'updated_at': now,
            'status': 'Active',
            'branch': branch,
          });
        }
        
        final response = await _supabase
            .from('own_marketing_targets')
            .insert(targets)
            .select();
        
        print('✅ SUCCESS! Inserted ${response.length} targets');
        return true;
      } catch (e) {
        print('⚠️ Method 1 failed: $e');
        
        // Method 2: One by one insert
        int successCount = 0;
        
        for (final managerId in managerIds) {
          try {
            await _supabase
                .from('own_marketing_targets')
                .upsert({
                  'manager_id': managerId,
                  'district': targetDistrict,
                  'target_month': monthStr,
                  'revenue_target': revenueTarget,
                  'order_target': orderTarget,
                  'achieved_revenue': 0,
                  'achieved_orders': 0,
                  'remarks': remarks,
                  'assigned_by': currentUser.id,
                  'assigned_at': now,
                  'updated_at': now,
                  'status': 'Active',
                  'branch': branch,
                }, onConflict: 'manager_id,target_month');
            successCount++;
            print('✓ Inserted for manager: $managerId');
          } catch (e) {
            print('✗ Failed for manager $managerId: $e');
          }
        }
        
        print('📊 Final result: $successCount/${managerIds.length} successful');
        return successCount > 0;
      }
    } catch (e, stackTrace) {
      print('💥 FATAL ERROR:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // ===================== GET RECENT TARGETS =====================
  Future<List<Map<String, dynamic>>> getRecentTargets({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('own_marketing_targets')
          .select('''
            *,
            emp_profile:manager_id(full_name, district, emp_id)
          ''')
          .order('assigned_at', ascending: false)
          .limit(limit);
      
      return (response as List).map((target) {
        final manager = target['emp_profile'] as Map<String, dynamic>?;
        return {
          'id': target['id'],
          'manager_id': target['manager_id'],
          'manager_name': manager?['full_name'] ?? 'Unknown',
          'manager_emp_id': manager?['emp_id'] ?? '',
          'district': target['district'] ?? 'Unknown',
          'target_month': target['target_month'],
          'revenue_target': target['revenue_target'] ?? 0,
          'achieved_revenue': target['achieved_revenue'] ?? 0,
          'order_target': target['order_target'] ?? 0,
          'achieved_orders': target['achieved_orders'] ?? 0,
          'assigned_at': target['assigned_at'],
          'remarks': target['remarks'],
          'status': target['status'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting recent targets: $e');
      return [];
    }
  }

  // ===================== GET MANAGER TARGET FOR SPECIFIC MONTH =====================
  Future<Map<String, dynamic>?> getManagerTarget({
    required String managerId,
    required DateTime month,
  }) async {
    try {
      final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
      
      final data = await _supabase
          .from('own_marketing_targets')
          .select('*')
          .eq('manager_id', managerId)
          .eq('target_month', monthStr)
          .maybeSingle();
      
      if (data == null) return null;
      
      return {
        'revenue_target': data['revenue_target'] ?? 0,
        'order_target': data['order_target'] ?? 0,
        'achieved_revenue': data['achieved_revenue'] ?? 0,
        'achieved_orders': data['achieved_orders'] ?? 0,
        'district': data['district'] ?? 'Unknown',
        'remarks': data['remarks'],
        'assigned_at': data['assigned_at'],
        'status': data['status'],
      };
    } catch (e) {
      debugPrint('Error getting manager target: $e');
      return null;
    }
  }

  // ===================== GET ALL PREVIOUS TARGETS FOR MANAGER =====================
  Future<List<Map<String, dynamic>>> getManagerAllTargets({
    required String managerId,
    int limit = 24, // Last 24 months by default
  }) async {
    try {
      final response = await _supabase
          .from('own_marketing_targets')
          .select('''
            *,
            emp_profile:manager_id(full_name, emp_id)
          ''')
          .eq('manager_id', managerId)
          .order('target_month', ascending: false)
          .limit(limit);

      return (response as List).map((target) {
        final manager = target['emp_profile'] as Map<String, dynamic>?;
        return {
          'id': target['id'],
          'manager_id': target['manager_id'],
          'manager_name': manager?['full_name'] ?? 'Unknown',
          'manager_emp_id': manager?['emp_id'] ?? '',
          'district': target['district'] ?? 'Unknown',
          'target_month': target['target_month'],
          'revenue_target': target['revenue_target'] ?? 0,
          'achieved_revenue': target['achieved_revenue'] ?? 0,
          'order_target': target['order_target'] ?? 0,
          'achieved_orders': target['achieved_orders'] ?? 0,
          'remarks': target['remarks'],
          'assigned_at': target['assigned_at'],
          'updated_at': target['updated_at'],
          'status': target['status'],
          'branch': target['branch'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting manager all targets: $e');
      return [];
    }
  }

  // ===================== GET TARGETS BY DATE RANGE =====================
  Future<List<Map<String, dynamic>>> getManagerTargetsByDateRange({
    required String managerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-01';
      final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-01';
      
      final response = await _supabase
          .from('own_marketing_targets')
          .select('''
            *,
            emp_profile:manager_id(full_name, emp_id)
          ''')
          .eq('manager_id', managerId)
          .gte('target_month', startStr)
          .lte('target_month', endStr)
          .order('target_month', ascending: false);

      return (response as List).map((target) {
        final manager = target['emp_profile'] as Map<String, dynamic>?;
        return {
          'id': target['id'],
          'manager_id': target['manager_id'],
          'manager_name': manager?['full_name'] ?? 'Unknown',
          'manager_emp_id': manager?['emp_id'] ?? '',
          'district': target['district'] ?? 'Unknown',
          'target_month': target['target_month'],
          'revenue_target': target['revenue_target'] ?? 0,
          'achieved_revenue': target['achieved_revenue'] ?? 0,
          'order_target': target['order_target'] ?? 0,
          'achieved_orders': target['achieved_orders'] ?? 0,
          'remarks': target['remarks'],
          'assigned_at': target['assigned_at'],
          'updated_at': target['updated_at'],
          'status': target['status'],
          'branch': target['branch'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting targets by date range: $e');
      return [];
    }
  }

  // ===================== GET TARGET SUMMARY STATISTICS =====================
  Future<Map<String, dynamic>> getTargetSummaryStatistics({
    required String managerId,
  }) async {
    try {
      final allTargets = await getManagerAllTargets(managerId: managerId);
      
      if (allTargets.isEmpty) {
        return {
          'total_targets': 0,
          'total_revenue_target': 0,
          'total_order_target': 0,
          'total_achieved_revenue': 0,
          'total_achieved_orders': 0,
          'average_revenue_completion': 0,
          'average_order_completion': 0,
          'best_month': null,
          'worst_month': null,
        };
      }
      
      int totalRevenueTarget = 0;
      int totalOrderTarget = 0;
      int totalAchievedRevenue = 0;
      int totalAchievedOrders = 0;
      Map<String, double> monthlyCompletion = {};
      
      for (final target in allTargets) {
        final revenueTarget = (target['revenue_target'] as int?) ?? 0;
        final orderTarget = (target['order_target'] as int?) ?? 0;
        final achievedRevenue = (target['achieved_revenue'] as int?) ?? 0;
        final achievedOrders = (target['achieved_orders'] as int?) ?? 0;
        final targetMonth = target['target_month']?.toString() ?? '';
        
        totalRevenueTarget += revenueTarget;
        totalOrderTarget += orderTarget;
        totalAchievedRevenue += achievedRevenue;
        totalAchievedOrders += achievedOrders;
        
        // Calculate completion percentage for this month
        if (revenueTarget > 0) {
          final completion = (achievedRevenue / revenueTarget * 100).clamp(0.0, 100.0);
          monthlyCompletion[targetMonth] = completion;
        }
      }
      
      final revenueCompletion = totalRevenueTarget > 0 
          ? (totalAchievedRevenue / totalRevenueTarget * 100).clamp(0.0, 100.0)
          : 0.0;
          
      final orderCompletion = totalOrderTarget > 0 
          ? (totalAchievedOrders / totalOrderTarget * 100).clamp(0.0, 100.0)
          : 0.0;
      
      // Find best and worst performing months
      String? bestMonth;
      String? worstMonth;
      double bestCompletion = 0.0;
      double worstCompletion = 100.0;
      
      monthlyCompletion.forEach((month, completion) {
        if (completion > bestCompletion) {
          bestCompletion = completion;
          bestMonth = month;
        }
        if (completion < worstCompletion) {
          worstCompletion = completion;
          worstMonth = month;
        }
      });
      
      return {
        'total_targets': allTargets.length,
        'total_revenue_target': totalRevenueTarget,
        'total_order_target': totalOrderTarget,
        'total_achieved_revenue': totalAchievedRevenue,
        'total_achieved_orders': totalAchievedOrders,
        'average_revenue_completion': revenueCompletion,
        'average_order_completion': orderCompletion,
        'best_month': bestMonth,
        'worst_month': worstMonth,
        'best_completion': bestCompletion,
        'worst_completion': worstCompletion,
      };
    } catch (e) {
      debugPrint('Error getting target summary: $e');
      return {
        'total_targets': 0,
        'total_revenue_target': 0,
        'total_order_target': 0,
        'total_achieved_revenue': 0,
        'total_achieved_orders': 0,
        'average_revenue_completion': 0,
        'average_order_completion': 0,
        'best_month': null,
        'worst_month': null,
      };
    }
  }

  // ===================== DEBUG MANAGER DATA =====================
  Future<void> debugManagerData() async {
    try {
      print('🔍 DEBUGGING MANAGER DATA');
      
      final managers = await getMarketingManagers();
      print('📊 Total marketing managers: ${managers.length}');
      
      if (managers.isEmpty) {
        print('❌ No marketing managers found!');
        return;
      }
      
      // Print first 3 managers
      for (var i = 0; i < managers.length && i < 3; i++) {
        final manager = managers[i];
        print('\n👤 Manager ${i + 1}:');
        print('   Name: ${manager.fullName}');
        print('   ID: ${manager.id}');
        print('   ID Type: ${manager.id.runtimeType}');
        print('   ID Length: ${manager.id.length}');
        print('   Has dashes: ${manager.id.contains('-')}');
        print('   Emp ID: ${manager.empId}');
        print('   District: ${manager.district}');
      }
      
      // Check table structure
      try {
        print('\n📋 Checking own_marketing_targets table...');
        final sample = await _supabase
            .from('own_marketing_targets')
            .select('*')
            .limit(1);
        
        if (sample.isNotEmpty) {
          print('✅ Table exists and has data');
          print('   Sample columns: ${sample[0].keys.join(', ')}');
        } else {
          print('ℹ️ Table exists but has no data');
        }
      } catch (e) {
        print('❌ Error checking table: $e');
      }
    } catch (e) {
      print('💥 Debug error: $e');
    }
  }

  // ===================== GET PRODUCT SUMMARY =====================
  Future<Map<String, dynamic>> getProductSummary() async {
    try {
      final Map<String, Map<String, dynamic>> products = {
        "मिल्क पॉवर / Milk Power": {"weight": 20, "unit": "kg", "price": 350},
        "दुध सरिता / Dugdh Sarita": {"weight": 25, "unit": "kg", "price": 450},
        "दुग्धराज / Dugdh Raj": {"weight": 30, "unit": "kg", "price": 600},
        "डायमंड संतुलित पशु आहार / Diamond Balanced Animal Feed": {"weight": 10, "unit": "kg", "price": 800},
        "मिल्क पॉवर प्लस / Milk Power Plus": {"weight": 5, "unit": "kg", "price": 1200},
        "संतुलित पशु आहार / Santulit Pashu Aahar": {"weight": 5, "unit": "kg", "price": 1200},
        "जीवन धारा / Jeevan Dhara": {"weight": 5, "unit": "kg", "price": 1200},
        "Dairy Special संतुलित पशु आहार": {"weight": 5, "unit": "kg", "price": 1200},
      };

      double totalPrice = 0;
      double totalWeight = 0;
      int minPrice = 999999;
      int maxPrice = 0;

      products.forEach((name, data) {
        final price = data['price'] as int;
        final weight = data['weight'] as int;
        
        totalPrice += price.toDouble();
        totalWeight += weight.toDouble();
        
        if (price < minPrice) minPrice = price;
        if (price > maxPrice) maxPrice = price;
      });

      final averagePricePerKg = totalWeight > 0 ? totalPrice / totalWeight : 0;

      return {
        'products': products,
        'total_products': products.length,
        'min_price': minPrice,
        'max_price': maxPrice,
        'average_price_per_kg': averagePricePerKg,
        'min_order_weight': 5,
        'max_order_weight': 1000,
      };
    } catch (e) {
      debugPrint('Error generating product summary: $e');
      return {
        'products': {},
        'total_products': 0,
        'min_price': 0,
        'max_price': 0,
        'average_price_per_kg': 0,
        'min_order_weight': 5,
        'max_order_weight': 1000,
      };
    }
  }

  // ===================== UPDATE TARGET PROGRESS =====================
  Future<bool> updateTargetProgress({
    required String targetId,
    required int revenueAchieved,
    required int ordersAchieved,
  }) async {
    try {
      await _supabase
          .from('own_marketing_targets')
          .update({
            'achieved_revenue': revenueAchieved,
            'achieved_orders': ordersAchieved,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', targetId);

      return true;
    } catch (e) {
      debugPrint('Error updating target progress: $e');
      return false;
    }
  }

  // ===================== DELETE TARGET =====================
  Future<bool> deleteTarget(String targetId) async {
    try {
      await _supabase
          .from('own_marketing_targets')
          .delete()
          .eq('id', targetId);
      return true;
    } catch (e) {
      debugPrint('Error deleting target: $e');
      return false;
    }
  }
}











// import 'package:flutter/material.dart';
// import 'package:mega_pro/models/mar_manager_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class MarketingTargetService {
//   final SupabaseClient _supabase = Supabase.instance.client;

//   // ===================== GET MARKETING MANAGERS =====================
//   Future<List<MarketingManager>> getMarketingManagers() async {
//     try {
//       final data = await _supabase
//           .from('emp_profile')
//           .select('id, emp_id, full_name, district, position, status, email, phone, branch, role')
//           .eq('role', 'Marketing Manager')
//           .eq('status', 'Active')
//           .order('full_name');
      
//       return (data as List).map((e) => MarketingManager.fromJson(e)).toList();
//     } catch (e) {
//       debugPrint('Error getting managers: $e');
//       return [];
//     }
//   }

//   // ===================== GET AVAILABLE DISTRICTS =====================
//   Future<List<String>> getAvailableDistricts() async {
//     try {
//       final data = await _supabase
//           .from('emp_profile')
//           .select('district')
//           .eq('role', 'Marketing Manager')
//           .eq('status', 'Active')
//           .neq('district', '');

//       final districts = (data as List<dynamic>)
//           .map((e) => e['district'] as String?)
//           .where((district) => district != null && district.isNotEmpty && district != 'null')
//           .map((district) => district!.trim())
//           .toSet()
//           .toList();
      
//       districts.sort();
//       return ['All Districts', ...districts];
//     } catch (e) {
//       debugPrint('Error fetching districts: $e');
//       return _getFallbackDistricts();
//     }
//   }

//   List<String> _getFallbackDistricts() {
//     final fallbackDistricts = [
//       "Ahmednagar", "Akola", "Amravati", "Aurangabad", "Beed",
//       "Bhandara", "Buldhana", "Chandrapur", "Dhule", "Gadchiroli",
//       "Gondiya", "Hingoli", "Jalgaon", "Jalna", "Kolhapur",
//       "Latur", "Mumbai City", "Mumbai Suburban", "Nagpur", "Nanded",
//       "Nandurbar", "Nashik", "Osmanabad", "Palghar", "Parbhani",
//       "Pune", "Raigad", "Ratnagiri", "Sangli", "Satara",
//       "Sindhudurg", "Solapur", "Thane", "Wardha", "Washim", "Yavatmal"
//     ]..sort();
    
//     return ['All Districts', ...fallbackDistricts];
//   }

//   // ===================== ASSIGN TARGETS - ULTRA SIMPLE VERSION =====================
//   Future<bool> assignTargets({
//     required List<String> managerIds,
//     required String district,
//     required DateTime targetMonth,
//     required int revenueTarget,
//     required int orderTarget,
//     String? remarks,
//     required String branch,
//   }) async {
//     try {
//       print('🚀 STARTING TARGET ASSIGNMENT');
//       print('📋 Selected ${managerIds.length} managers');
//       print('📍 District: $district');
//       print('📅 Month: ${targetMonth.year}-${targetMonth.month}');
//       print('💰 Revenue Target: $revenueTarget');
//       print('📦 Order Target: $orderTarget');
      
//       // Check authentication
//       final currentUser = _supabase.auth.currentUser;
//       if (currentUser == null) {
//         print('❌ No user logged in');
//         return false;
//       }
//       print('👤 Current User ID: ${currentUser.id}');
      
//       // Process district
//       String targetDistrict = district;
//       if (district == 'All Districts') {
//         targetDistrict = 'All';
//       }
      
//       // Prepare month string
//       final monthStr = '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}-01';
//       final now = DateTime.now().toIso8601String();
      
//       // ===== TRY METHOD 1: Direct batch insert =====
//       print('🔄 Trying Method 1: Batch insert');
//       try {
//         // Prepare all targets
//         final List<Map<String, dynamic>> targets = [];
//         for (final managerId in managerIds) {
//           targets.add({
//             'manager_id': managerId,
//             'district': targetDistrict,
//             'target_month': monthStr,
//             'revenue_target': revenueTarget,
//             'order_target': orderTarget,
//             'achieved_revenue': 0,
//             'achieved_orders': 0,
//             'remarks': remarks,
//             'assigned_by': currentUser.id,
//             'assigned_at': now,
//             'updated_at': now,
//             'status': 'Active',
//             'branch': branch,
//           });
//         }
        
//         // Try direct insert
//         final response = await _supabase
//             .from('own_marketing_targets')
//             .insert(targets)
//             .select();
        
//         print('✅ SUCCESS! Inserted ${response.length} targets');
//         return true;
//       } catch (e) {
//         print('⚠️ Method 1 failed: $e');
        
//         // ===== TRY METHOD 2: Delete existing first, then insert =====
//         print('🔄 Trying Method 2: Delete then insert');
//         try {
//           // First delete any existing targets for this month
//           for (final managerId in managerIds) {
//             try {
//               await _supabase
//                   .from('own_marketing_targets')
//                   .delete()
//                   .eq('manager_id', managerId)
//                   .eq('target_month', monthStr);
//               print('🗑️  Deleted existing target for manager $managerId');
//             } catch (e) {
//               // No existing target, that's fine
//             }
//           }
          
//           // Now insert new targets
//           final targets = managerIds.map((managerId) {
//             return {
//               'manager_id': managerId,
//               'district': targetDistrict,
//               'target_month': monthStr,
//               'revenue_target': revenueTarget,
//               'order_target': orderTarget,
//               'achieved_revenue': 0,
//               'achieved_orders': 0,
//               'remarks': remarks,
//               'assigned_by': currentUser.id,
//               'assigned_at': now,
//               'updated_at': now,
//               'status': 'Active',
//               'branch': branch,
//             };
//           }).toList();
          
//           final response = await _supabase
//               .from('own_marketing_targets')
//               .insert(targets)
//               .select();
          
//           print('✅ SUCCESS! Inserted ${response.length} targets after delete');
//           return true;
//         } catch (e) {
//           print('⚠️ Method 2 failed: $e');
          
//           // ===== TRY METHOD 3: Insert one by one =====
//           print('🔄 Trying Method 3: One by one insert');
//           int successCount = 0;
          
//           for (final managerId in managerIds) {
//             try {
//               await _supabase
//                   .from('own_marketing_targets')
//                   .insert({
//                     'manager_id': managerId,
//                     'district': targetDistrict,
//                     'target_month': monthStr,
//                     'revenue_target': revenueTarget,
//                     'order_target': orderTarget,
//                     'achieved_revenue': 0,
//                     'achieved_orders': 0,
//                     'remarks': remarks,
//                     'assigned_by': currentUser.id,
//                     'assigned_at': now,
//                     'updated_at': now,
//                     'status': 'Active',
//                     'branch': branch,
//                   });
//               successCount++;
//               print('✓ Inserted for manager: $managerId');
//             } catch (e) {
//               print('✗ Failed for manager $managerId: $e');
              
//               // Try one more time with upsert
//               try {
//                 await _supabase
//                     .from('own_marketing_targets')
//                     .upsert({
//                       'manager_id': managerId,
//                       'district': targetDistrict,
//                       'target_month': monthStr,
//                       'revenue_target': revenueTarget,
//                       'order_target': orderTarget,
//                       'achieved_revenue': 0,
//                       'achieved_orders': 0,
//                       'remarks': remarks,
//                       'assigned_by': currentUser.id,
//                       'assigned_at': now,
//                       'updated_at': now,
//                       'status': 'Active',
//                       'branch': branch,
//                     }, onConflict: 'manager_id,target_month');
//                 successCount++;
//                 print('✓ Upsert succeeded for manager: $managerId');
//               } catch (e2) {
//                 print('✗ Upsert also failed for manager $managerId: $e2');
//               }
//             }
//           }
          
//           print('📊 Final result: $successCount/${managerIds.length} successful');
//           return successCount > 0;
//         }
//       }
//     } catch (e, stackTrace) {
//       print('💥 FATAL ERROR:');
//       print('Error: $e');
//       print('Stack trace: $stackTrace');
//       return false;
//     }
//   }

//   // ===================== GET RECENT TARGETS =====================
//   Future<List<Map<String, dynamic>>> getRecentTargets({int limit = 10}) async {
//     try {
//       final response = await _supabase
//           .from('own_marketing_targets')
//           .select('''
//             *,
//             emp_profile:manager_id(full_name, district, emp_id)
//           ''')
//           .order('assigned_at', ascending: false)
//           .limit(limit);
      
//       return (response as List).map((target) {
//         final manager = target['emp_profile'] as Map<String, dynamic>?;
//         return {
//           'id': target['id'],
//           'manager_id': target['manager_id'],
//           'manager_name': manager?['full_name'] ?? 'Unknown',
//           'manager_emp_id': manager?['emp_id'] ?? '',
//           'district': target['district'] ?? 'Unknown',
//           'target_month': target['target_month'],
//           'revenue_target': target['revenue_target'] ?? 0,
//           'achieved_revenue': target['achieved_revenue'] ?? 0,
//           'order_target': target['order_target'] ?? 0,
//           'achieved_orders': target['achieved_orders'] ?? 0,
//           'assigned_at': target['assigned_at'],
//           'remarks': target['remarks'],
//           'status': target['status'],
//         };
//       }).toList();
//     } catch (e) {
//       debugPrint('Error getting recent targets: $e');
//       return [];
//     }
//   }

//   // ===================== GET MANAGER TARGET =====================
//   Future<Map<String, dynamic>?> getManagerTarget({
//     required String managerId,
//     required DateTime month,
//   }) async {
//     try {
//       final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
      
//       final data = await _supabase
//           .from('own_marketing_targets')
//           .select('*')
//           .eq('manager_id', managerId)
//           .eq('target_month', monthStr)
//           .maybeSingle();
      
//       if (data == null) return null;
      
//       return {
//         'revenue_target': data['revenue_target'] ?? 0,
//         'order_target': data['order_target'] ?? 0,
//         'achieved_revenue': data['achieved_revenue'] ?? 0,
//         'achieved_orders': data['achieved_orders'] ?? 0,
//         'district': data['district'] ?? 'Unknown',
//         'remarks': data['remarks'],
//         'assigned_at': data['assigned_at'],
//         'status': data['status'],
//       };
//     } catch (e) {
//       debugPrint('Error getting manager target: $e');
//       return null;
//     }
//   }

//   // ===================== DEBUG MANAGER DATA =====================
//   Future<void> debugManagerData() async {
//     try {
//       print('🔍 DEBUGGING MANAGER DATA');
      
//       final managers = await getMarketingManagers();
//       print('📊 Total marketing managers: ${managers.length}');
      
//       if (managers.isEmpty) {
//         print('❌ No marketing managers found!');
//         return;
//       }
      
//       // Print first 3 managers
//       for (var i = 0; i < managers.length && i < 3; i++) {
//         final manager = managers[i];
//         print('\n👤 Manager ${i + 1}:');
//         print('   Name: ${manager.fullName}');
//         print('   ID: ${manager.id}');
//         print('   ID Type: ${manager.id.runtimeType}');
//         print('   ID Length: ${manager.id.length}');
//         print('   Has dashes: ${manager.id.contains('-')}');
//         print('   Emp ID: ${manager.empId}');
//         print('   District: ${manager.district}');
//       }
      
//       // Check table structure
//       try {
//         print('\n📋 Checking own_marketing_targets table...');
//         final sample = await _supabase
//             .from('own_marketing_targets')
//             .select('*')
//             .limit(1);
        
//         if (sample.isNotEmpty) {
//           print('✅ Table exists and has data');
//           print('   Sample columns: ${sample[0].keys.join(', ')}');
//         } else {
//           print('ℹ️ Table exists but has no data');
//         }
//       } catch (e) {
//         print('❌ Error checking table: $e');
//       }
//     } catch (e) {
//       print('💥 Debug error: $e');
//     }
//   }

//   // ===================== GET PRODUCT SUMMARY =====================
//   Future<Map<String, dynamic>> getProductSummary() async {
//     try {
//       final Map<String, Map<String, dynamic>> products = {
//         "मिल्क पॉवर / Milk Power": {"weight": 20, "unit": "kg", "price": 350},
//         "दुध सरिता / Dugdh Sarita": {"weight": 25, "unit": "kg", "price": 450},
//         "दुग्धराज / Dugdh Raj": {"weight": 30, "unit": "kg", "price": 600},
//         "डायमंड संतुलित पशु आहार / Diamond Balanced Animal Feed": {"weight": 10, "unit": "kg", "price": 800},
//         "मिल्क पॉवर प्लस / Milk Power Plus": {"weight": 5, "unit": "kg", "price": 1200},
//         "संतुलित पशु आहार / Santulit Pashu Aahar": {"weight": 5, "unit": "kg", "price": 1200},
//         "जीवन धारा / Jeevan Dhara": {"weight": 5, "unit": "kg", "price": 1200},
//         "Dairy Special संतुलित पशु आहार": {"weight": 5, "unit": "kg", "price": 1200},
//       };

//       double totalPrice = 0;
//       double totalWeight = 0;
//       int minPrice = 999999;
//       int maxPrice = 0;

//       products.forEach((name, data) {
//         final price = data['price'] as int;
//         final weight = data['weight'] as int;
        
//         totalPrice += price.toDouble();
//         totalWeight += weight.toDouble();
        
//         if (price < minPrice) minPrice = price;
//         if (price > maxPrice) maxPrice = price;
//       });

//       final averagePricePerKg = totalWeight > 0 ? totalPrice / totalWeight : 0;

//       return {
//         'products': products,
//         'total_products': products.length,
//         'min_price': minPrice,
//         'max_price': maxPrice,
//         'average_price_per_kg': averagePricePerKg,
//         'min_order_weight': 5,
//         'max_order_weight': 1000,
//       };
//     } catch (e) {
//       debugPrint('Error generating product summary: $e');
//       return {
//         'products': {},
//         'total_products': 0,
//         'min_price': 0,
//         'max_price': 0,
//         'average_price_per_kg': 0,
//         'min_order_weight': 5,
//         'max_order_weight': 1000,
//       };
//     }
//   }

//   // ===================== UPDATE TARGET PROGRESS =====================
//   Future<bool> updateTargetProgress({
//     required String targetId,
//     required int revenueAchieved,
//     required int ordersAchieved,
//   }) async {
//     try {
//       await _supabase
//           .from('own_marketing_targets')
//           .update({
//             'achieved_revenue': revenueAchieved,
//             'achieved_orders': ordersAchieved,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', targetId);

//       return true;
//     } catch (e) {
//       debugPrint('Error updating target progress: $e');
//       return false;
//     }
//   }

//   // ===================== DELETE TARGET =====================
//   Future<bool> deleteTarget(String targetId) async {
//     try {
//       await _supabase
//           .from('own_marketing_targets')
//           .delete()
//           .eq('id', targetId);
//       return true;
//     } catch (e) {
//       debugPrint('Error deleting target: $e');
//       return false;
//     }
//   }
// }



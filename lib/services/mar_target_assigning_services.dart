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

  // ===================== ASSIGN TARGETS - ULTRA SIMPLE VERSION =====================
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
      
      // Check authentication
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return false;
      }
      print('👤 Current User ID: ${currentUser.id}');
      
      // Process district
      String targetDistrict = district;
      if (district == 'All Districts') {
        targetDistrict = 'All';
      }
      
      // Prepare month string
      final monthStr = '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}-01';
      final now = DateTime.now().toIso8601String();
      
      // ===== TRY METHOD 1: Direct batch insert =====
      print('🔄 Trying Method 1: Batch insert');
      try {
        // Prepare all targets
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
        
        // Try direct insert
        final response = await _supabase
            .from('own_marketing_targets')
            .insert(targets)
            .select();
        
        print('✅ SUCCESS! Inserted ${response.length} targets');
        return true;
      } catch (e) {
        print('⚠️ Method 1 failed: $e');
        
        // ===== TRY METHOD 2: Delete existing first, then insert =====
        print('🔄 Trying Method 2: Delete then insert');
        try {
          // First delete any existing targets for this month
          for (final managerId in managerIds) {
            try {
              await _supabase
                  .from('own_marketing_targets')
                  .delete()
                  .eq('manager_id', managerId)
                  .eq('target_month', monthStr);
              print('🗑️  Deleted existing target for manager $managerId');
            } catch (e) {
              // No existing target, that's fine
            }
          }
          
          // Now insert new targets
          final targets = managerIds.map((managerId) {
            return {
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
            };
          }).toList();
          
          final response = await _supabase
              .from('own_marketing_targets')
              .insert(targets)
              .select();
          
          print('✅ SUCCESS! Inserted ${response.length} targets after delete');
          return true;
        } catch (e) {
          print('⚠️ Method 2 failed: $e');
          
          // ===== TRY METHOD 3: Insert one by one =====
          print('🔄 Trying Method 3: One by one insert');
          int successCount = 0;
          
          for (final managerId in managerIds) {
            try {
              await _supabase
                  .from('own_marketing_targets')
                  .insert({
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
              successCount++;
              print('✓ Inserted for manager: $managerId');
            } catch (e) {
              print('✗ Failed for manager $managerId: $e');
              
              // Try one more time with upsert
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
                print('✓ Upsert succeeded for manager: $managerId');
              } catch (e2) {
                print('✗ Upsert also failed for manager $managerId: $e2');
              }
            }
          }
          
          print('📊 Final result: $successCount/${managerIds.length} successful');
          return successCount > 0;
        }
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

  // ===================== GET MANAGER TARGET =====================
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
//   Future<List<MarketingManager>> getMarketingManagers({String? district}) async {
//     try {
//       debugPrint('Fetching marketing managers...');
      
//       // Build query with method chaining
//       var query = _supabase
//           .from('emp_profile')
//           .select('id, emp_id, full_name, email, phone, position, branch, district, status, role')
//           .eq('role', 'Marketing Manager')
//           .eq('status', 'Active');

//       // Apply district filter if provided
//       if (district != null && district.isNotEmpty && district != 'All Districts') {
//         query = query.eq('district', district);
//       }

//       final data = await query.order('full_name');
      
//       debugPrint('Fetched ${data.length} marketing managers');
      
//       final managers = (data as List<dynamic>)
//           .map((e) => MarketingManager.fromJson(e as Map<String, dynamic>))
//           .toList();
          
//       return managers;
//     } catch (e) {
//       debugPrint('Error fetching marketing managers: $e');
//       return [];
//     }
//   }

//   // ===================== GET BRANCHES =====================
//   Future<List<String>> getBranches() async {
//     try {
//       final data = await _supabase
//           .from('emp_profile')
//           .select('branch')
//           .eq('role', 'Marketing Manager')
//           .eq('status', 'Active');

//       final branches = (data as List<dynamic>)
//           .map((e) => e['branch'] as String?)
//           .where((branch) => branch != null && branch.isNotEmpty)
//           .map((branch) => branch!)
//           .toSet()
//           .toList();
      
//       branches.sort();
//       return ['All Branches', ...branches];
//     } catch (e) {
//       debugPrint('Error fetching branches: $e');
//       return ['All Branches'];
//     }
//   }

//   // ===================== GET DISTRICTS =====================
//   Future<List<String>> getDistricts() async {
//     try {
//       debugPrint('Fetching districts...');
      
//       final data = await _supabase
//           .from('emp_profile')
//           .select('district')
//           .eq('role', 'Marketing Manager')
//           .eq('status', 'Active')
//           .neq('district', '');

//       final districts = (data as List<dynamic>)
//           .map((e) => e['district'] as String?)
//           .where((district) => district != null && district.isNotEmpty && district.trim() != 'null')
//           .map((district) => district!.trim())
//           .toSet()
//           .toList();
      
//       districts.sort();
//       debugPrint('Found ${districts.length} unique districts');
      
//       return ['All Districts', ...districts];
//     } catch (e) {
//       debugPrint('Error fetching districts: $e');
//       return _getFallbackDistricts();
//     }
//   }

//   // Fallback districts list
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

//   // ===================== GET ASSIGNED TARGETS =====================
//   Future<List<MarketingTarget>> getAssignedTargets({
//     String? branch,
//     DateTime? month,
//     String? district,
//   }) async {
//     try {
//       // Start building the query
//       var query = _supabase
//           .from('own_marketing_targets')
//           .select('''
//             *,
//             manager:emp_profile!inner(
//               id, emp_id, full_name, email, phone, position, branch, district, status, role
//             )
//           ''');

//       // Apply filters
//       if (branch != null && branch != 'All Branches') {
//         query = query.eq('branch', branch);
//       }

//       if (month != null) {
//         final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
//         query = query.eq('target_month', monthStr);
//       }

//       if (district != null && district != 'All Districts') {
//         query = query.eq('district', district);
//       }

//       // Execute the query with ordering
//       final data = await query.order('target_month', ascending: false).order('branch');
      
//       return (data as List<dynamic>)
//           .map((e) => MarketingTarget.fromJson(e as Map<String, dynamic>))
//           .toList();
//     } catch (e) {
//       debugPrint('Error fetching assigned targets: $e');
//       return [];
//     }
//   }

//   // ===================== GET RECENT TARGETS =====================
//   Future<List<Map<String, dynamic>>> getRecentTargets({int limit = 10, String? district}) async {
//     try {
//       var query = _supabase
//           .from('own_marketing_targets')
//           .select('''
//             *,
//             emp_profile!inner(full_name, district)
//           ''');

//       // Apply district filter if provided
//       if (district != null && district != 'All Districts') {
//         query = query.eq('district', district);
//       }

//       final response = await query
//           .order('assigned_at', ascending: false)
//           .limit(limit);
      
//       // Transform the data
//       return (response as List<dynamic>).map((target) {
//         final manager = target['emp_profile'] as Map<String, dynamic>?;
//         return {
//           'id': target['id'],
//           'manager_name': manager?['full_name'] ?? 'Unknown',
//           'district': manager?['district'] ?? target['district'] ?? '',
//           'target_month': target['target_month'],
//           'revenue_target': target['revenue_target'],
//           'achieved_revenue': target['achieved_revenue'] ?? 0,
//           'order_target': target['order_target'],
//           'achieved_orders': target['achieved_orders'] ?? 0,
//           'assigned_at': target['assigned_at'],
//           'status': target['status'],
//           'remarks': target['remarks'],
//         };
//       }).toList();
//     } catch (e) {
//       debugPrint('Error fetching recent targets: $e');
//       return [];
//     }
//   }

//   // ===================== GET TARGET FOR MARKETING MANAGER =====================
//   Future<MarketingTarget?> getManagerTarget({
//     required String managerId,
//     required DateTime month,
//   }) async {
//     try {
//       final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
      
//       debugPrint('Fetching target for manager: $managerId, month: $monthStr');
      
//       final data = await _supabase
//           .from('own_marketing_targets')
//           .select('''
//             *,
//             manager:emp_profile!inner(
//               id, emp_id, full_name, email, phone, position, branch, district, status, role
//             )
//           ''')
//           .eq('manager_id', managerId)
//           .eq('target_month', monthStr)
//           .maybeSingle();

//       if (data == null) {
//         debugPrint('No target found for manager: $managerId');
//         return null;
//       }
      
//       final target = MarketingTarget.fromJson(data);
//       debugPrint('Target found: ${target.revenueTarget} revenue, ${target.orderTarget} orders');
      
//       return target;
//     } catch (e) {
//       debugPrint('Error fetching manager target: $e');
//       return null;
//     }
//   }

//   // ===================== ASSIGN TARGETS =====================
//   Future<bool> assignTargets({
//   required List<String> managerIds,
//   required String district,
//   required DateTime targetMonth,
//   required int revenueTarget,
//   required int orderTarget,
//   String? remarks,
//   required String branch,
// }) async {
//   try {
//     debugPrint('=== ASSIGN TARGETS START ===');
//     debugPrint('Manager IDs: $managerIds');
//     debugPrint('District: $district');
//     debugPrint('Target Month: $targetMonth');
//     debugPrint('Revenue Target: $revenueTarget');
//     debugPrint('Order Target: $orderTarget');
//     debugPrint('Remarks: $remarks');
    
//     final currentUser = _supabase.auth.currentUser;
//     debugPrint('Current User ID: ${currentUser?.id}');
    
//     // Check if user is authenticated
//     if (currentUser == null) {
//       debugPrint('ERROR: No authenticated user');
//       return false;
//     }
    
//     // Validate district
//     String targetDistrict = district;
//     if (district == 'All Districts') {
//       targetDistrict = 'All';
//     }
    
//     debugPrint('Processed District: $targetDistrict');
    
//     // Prepare targets data
//     final List<Map<String, dynamic>> targets = [];
//     final now = DateTime.now();
//     final monthStr = '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}-01';
    
//     debugPrint('Month String: $monthStr');
    
//     for (final managerId in managerIds) {
//       targets.add({
//         'manager_id': managerId,
//         'district': targetDistrict,
//         'target_month': monthStr,
//         'revenue_target': revenueTarget,
//         'order_target': orderTarget,
//         'achieved_revenue': 0,
//         'achieved_orders': 0,
//         'remarks': remarks,
//         'assigned_by': currentUser.id,
//         'assigned_at': now.toIso8601String(),
//         'updated_at': now.toIso8601String(),
//         'status': 'Active',
//         'branch': branch,
//       });
//     }
    
//     debugPrint('Prepared ${targets.length} target records');
    
//     // Check if targets already exist
//     try {
//       for (final target in targets) {
//         final existing = await _supabase
//             .from('own_marketing_targets')
//             .select('id')
//             .eq('manager_id', target['manager_id'])
//             .eq('target_month', target['target_month'])
//             .maybeSingle();
            
//         if (existing != null) {
//           debugPrint('Target already exists for manager ${target['manager_id']} in month ${target['target_month']}');
//         }
//       }
//     } catch (e) {
//       debugPrint('Error checking existing targets: $e');
//     }
    
//     // Insert targets
//     debugPrint('Inserting targets...');
//     final response = await _supabase
//         .from('own_marketing_targets')
//         .upsert(
//           targets,
//           onConflict: 'manager_id, target_month',
//         )
//         .select();
    
//     debugPrint('Upsert response: $response');
//     debugPrint('Upsert successful: ${response.isNotEmpty}');
    
//     if (response.isEmpty) {
//       debugPrint('ERROR: Upsert returned empty response');
//       return false;
//     }
    
//     // Also update the emp_profile table to ensure district is set
//     for (final managerId in managerIds) {
//       try {
//         await _supabase
//             .from('emp_profile')
//             .update({
//               'district': targetDistrict,
//               'updated_at': now.toIso8601String(),
//             })
//             .eq('id', managerId);
//       } catch (e) {
//         debugPrint('Error updating manager district: $e');
//       }
//     }
    
//     debugPrint('=== ASSIGN TARGETS COMPLETE ===');
//     return true;
//   } catch (e, stackTrace) {
//     debugPrint('=== ERROR ASSIGNING TARGETS ===');
//     debugPrint('Error: $e');
//     debugPrint('Stack trace: $stackTrace');
//     return false;
//   }
// }

//   // ===================== UPDATE TARGET PROGRESS =====================
//   Future<bool> updateTargetProgress({
//     required String targetId,
//     required int revenueAchieved,
//     required int ordersAchieved,
//   }) async {
//     try {
//       // Update target achieved values
//       await _supabase
//           .from('own_marketing_targets')
//           .update({
//             'achieved_revenue': revenueAchieved,
//             'achieved_orders': ordersAchieved,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', targetId);

//       // Add daily progress record
//       await _supabase.from('own_target_progress').insert({
//         'target_id': targetId,
//         'progress_date': DateTime.now().toIso8601String().split('T')[0],
//         'revenue_achieved': revenueAchieved,
//         'orders_achieved': ordersAchieved,
//         'recorded_at': DateTime.now().toIso8601String(),
//       });

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

//   // ===================== GET TARGET STATISTICS =====================
//   Future<Map<String, dynamic>> getTargetStatistics({
//     String? district,
//     DateTime? startDate,
//     DateTime? endDate,
//   }) async {
//     try {
//       var query = _supabase
//           .from('own_marketing_targets')
//           .select('''
//             district,
//             revenue_target,
//             order_target,
//             achieved_revenue,
//             achieved_orders
//           ''');

//       if (district != null && district != 'All Districts') {
//         query = query.eq('district', district);
//       }

//       if (startDate != null) {
//         final startDateStr = startDate.toIso8601String().split('T')[0];
//         query = query.gte('target_month', startDateStr);
//       }

//       if (endDate != null) {
//         final endDateStr = endDate.toIso8601String().split('T')[0];
//         query = query.lte('target_month', endDateStr);
//       }

//       final data = await query;

//       if (data.isEmpty) {
//         return {
//           'total_revenue_target': 0,
//           'total_order_target': 0,
//           'total_achieved_revenue': 0,
//           'total_achieved_orders': 0,
//           'revenue_completion': 0.0,
//           'order_completion': 0.0,
//         };
//       }

//       int totalRevenueTarget = 0;
//       int totalOrderTarget = 0;
//       int totalAchievedRevenue = 0;
//       int totalAchievedOrders = 0;

//       for (final target in data as List<dynamic>) {
//         totalRevenueTarget += (target['revenue_target'] as int? ?? 0);
//         totalOrderTarget += (target['order_target'] as int? ?? 0);
//         totalAchievedRevenue += (target['achieved_revenue'] as int? ?? 0);
//         totalAchievedOrders += (target['achieved_orders'] as int? ?? 0);
//       }

//       final revenueCompletion = totalRevenueTarget > 0 
//           ? (totalAchievedRevenue / totalRevenueTarget) * 100 
//           : 0.0;
//       final orderCompletion = totalOrderTarget > 0 
//           ? (totalAchievedOrders / totalOrderTarget) * 100 
//           : 0.0;

//       return {
//         'total_revenue_target': totalRevenueTarget,
//         'total_order_target': totalOrderTarget,
//         'total_achieved_revenue': totalAchievedRevenue,
//         'total_achieved_orders': totalAchievedOrders,
//         'revenue_completion': revenueCompletion,
//         'order_completion': orderCompletion,
//         'district_count': data.length,
//       };
//     } catch (e) {
//       debugPrint('Error fetching target statistics: $e');
//       return {
//         'total_revenue_target': 0,
//         'total_order_target': 0,
//         'total_achieved_revenue': 0,
//         'total_achieved_orders': 0,
//         'revenue_completion': 0.0,
//         'order_completion': 0.0,
//         'district_count': 0,
//       };
//     }
//   }

//   // ===================== GET DISTRICT PERFORMANCE =====================
//   Future<List<Map<String, dynamic>>> getDistrictPerformance({
//     DateTime? month,
//     int limit = 10,
//   }) async {
//     try {
//       var query = _supabase
//           .from('own_marketing_targets')
//           .select('''
//             district,
//             revenue_target,
//             order_target,
//             achieved_revenue,
//             achieved_orders
//           ''');

//       if (month != null) {
//         final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
//         query = query.eq('target_month', monthStr);
//       }

//       final data = await query;

//       // Group by district and calculate performance
//       final districtMap = <String, Map<String, dynamic>>{};

//       for (final target in data as List<dynamic>) {
//         final district = target['district'] as String? ?? 'Unknown';
//         final revenueTarget = target['revenue_target'] as int? ?? 0;
//         final orderTarget = target['order_target'] as int? ?? 0;
//         final achievedRevenue = target['achieved_revenue'] as int? ?? 0;
//         final achievedOrders = target['achieved_orders'] as int? ?? 0;

//         if (!districtMap.containsKey(district)) {
//           districtMap[district] = {
//             'district': district,
//             'revenue_target': 0,
//             'order_target': 0,
//             'achieved_revenue': 0,
//             'achieved_orders': 0,
//             'revenue_completion': 0.0,
//             'order_completion': 0.0,
//           };
//         }

//         final current = districtMap[district]!;
//         current['revenue_target'] = (current['revenue_target'] as int) + revenueTarget;
//         current['order_target'] = (current['order_target'] as int) + orderTarget;
//         current['achieved_revenue'] = (current['achieved_revenue'] as int) + achievedRevenue;
//         current['achieved_orders'] = (current['achieved_orders'] as int) + achievedOrders;
//       }

//       // Calculate completion percentages
//       for (final district in districtMap.values) {
//         final revenueTarget = district['revenue_target'] as int;
//         final orderTarget = district['order_target'] as int;
//         final achievedRevenue = district['achieved_revenue'] as int;
//         final achievedOrders = district['achieved_orders'] as int;

//         district['revenue_completion'] = revenueTarget > 0 
//             ? (achievedRevenue / revenueTarget) * 100 
//             : 0.0;
//         district['order_completion'] = orderTarget > 0 
//             ? (achievedOrders / orderTarget) * 100 
//             : 0.0;
//       }

//       // Sort by revenue completion (highest first) and limit
//       return districtMap.values
//           .toList()
//           .cast<Map<String, dynamic>>()
//           ..sort((a, b) => (b['revenue_completion'] as double)
//               .compareTo(a['revenue_completion'] as double))
//           ..take(limit);
//     } catch (e) {
//       debugPrint('Error fetching district performance: $e');
//       return [];
//     }
//   }

//   // ===================== GET PRODUCT SUMMARY =====================
//   Future<Map<String, dynamic>> getProductSummary() async {
//     try {
//       // This is a static method since product data is hardcoded
//       // You could also fetch this from a database table if available
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
//         'min_order_weight': 5, // Minimum 5kg per order
//         'max_order_weight': 1000, // Maximum 1000kg per order
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
// }
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================
  // LOAD EMPLOYEE PROFILE
  // ============================
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _profile = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('🔄 Loading profile for user: ${user.email} (${user.id})');

      // Try to get profile from emp_profile table
      final response = await _supabase
          .from('emp_profile')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        _profile = response;
        print('✅ Profile loaded from emp_profile');
        debugProfile();
      } else {
        // Try matching by email
        final emailResponse = await _supabase
            .from('emp_profile')
            .select()
            .eq('email', user.email as Object)
            .maybeSingle();
        
        if (emailResponse != null) {
          _profile = emailResponse;
          print('✅ Profile loaded by email from emp_profile');
          debugProfile();
        } else {
          print('⚠️ No employee profile found in emp_profile table');
          
          // Create a default profile with user info to prevent crashes
          _profile = {
            'id': user.id,
            'user_id': user.id,
            'emp_id': user.id, // Use user ID as emp_id for now
            'email': user.email,
            'full_name': user.email?.split('@').first ?? 'Employee',
            'name': user.email?.split('@').first ?? 'Employee',
            'position': 'Employee',
            'role': 'Employee',
            'created_at': DateTime.now().toIso8601String(),
          };
          print('📋 Created default profile with user info');
          debugProfile();
        }
      }

    } catch (e) {
      print('❌ Error loading employee profile: $e');
      _error = 'Failed to load profile: $e';
      
      // Create fallback profile even on error
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _profile = {
          'id': user.id,
          'user_id': user.id,
          'emp_id': user.id,
          'email': user.email,
          'full_name': user.email?.split('@').first ?? 'Employee',
          'name': user.email?.split('@').first ?? 'Employee',
          'position': 'Employee',
          'role': 'Employee',
          'created_at': DateTime.now().toIso8601String(),
        };
        print('📋 Created fallback profile due to error');
      }
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================
  // CLEAR PROFILE (for logout)
  // ============================
  void clearProfile() {
    print('🧹 Clearing employee profile...');
    _profile = null;
    _error = null;
    notifyListeners();
  }

  // ============================
  // GET EMPLOYEE ID
  // ============================
  String? get employeeId {
    if (_profile == null) return null;
    
    // Try different possible employee ID field names
    return _profile?['emp_id']?.toString() ??
           _profile?['employee_id']?.toString() ??
           _profile?['id']?.toString() ??
           _profile?['user_id']?.toString();
  }

  // ============================
  // GET EMPLOYEE NAME
  // ============================
  String get employeeName {
    if (_profile == null) return 'Employee';
    
    return _profile?['full_name']?.toString() ??
           _profile?['name']?.toString() ??
           _profile?['username']?.toString() ??
           _profile?['email']?.toString().split('@').first ??
           'Employee';
  }

  // ============================
  // GET EMPLOYEE POSITION
  // ============================
  String get employeePosition {
    if (_profile == null) return 'Position';
    
    return _profile?['position']?.toString() ??
           _profile?['role']?.toString() ??
           _profile?['designation']?.toString() ??
           'Employee';
  }

  // ============================
  // GET EMPLOYEE DISTRICT
  // ============================
  String? get employeeDistrict {
    if (_profile == null) return null;
    
    return _profile?['district']?.toString() ??
           _profile?['location']?.toString() ??
           _profile?['area']?.toString();
  }

  // ============================
  // CHECK IF PROFILE IS LOADED
  // ============================
  bool isProfileLoaded() {
    return _profile != null;
  }

  // ============================
  // DEBUG PROFILE INFO
  // ============================
  void debugProfile() {
    print('=== EMPLOYEE PROFILE DEBUG ===');
    print('Profile loaded: ${_profile != null}');
    if (_profile != null) {
      print('Profile data keys: ${_profile!.keys.toList()}');
      print('Employee ID from getter: $employeeId');
      print('Employee Name: $employeeName');
      print('Employee Position: $employeePosition');
      print('Employee District: $employeeDistrict');
    }
    print('============================');
  }
}










//does not work much 

// import 'package:flutter/foundation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class EmployeeProvider with ChangeNotifier {
//   final SupabaseClient _supabase = Supabase.instance.client;
  
//   Map<String, dynamic>? _profile;
//   bool _isLoading = false;
//   String? _error;

//   Map<String, dynamic>? get profile => _profile;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   // ============================
//   // LOAD EMPLOYEE PROFILE
//   // ============================
//   Future<void> loadProfile() async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final user = _supabase.auth.currentUser;
//       if (user == null) {
//         _profile = null;
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }

//       print('🔄 Loading profile for user: ${user.email} (${user.id})');

//       // List of possible table names to try
//       final List<String> possibleTables = [
//         'emp_mar_orders',  // Based on error hint
//         'emp_profiles',
//         'employees',
//         'employee_profiles',
//         'users',
//         'profiles'
//       ];

//       Map<String, dynamic>? foundProfile;
      
//       for (final tableName in possibleTables) {
//         try {
//           print('🔍 Trying table: $tableName');
          
//           // First, check if table exists by trying a simple query
//           try {
//             // Try to get column info or do a simple count
//             await _supabase.from(tableName).select('count').limit(1);
//           } catch (e) {
//             print('⚠️ Table $tableName not accessible: $e');
//             continue;
//           }

//           // Try different column names for matching
//           final List<String> possibleIdColumns = [
//             'user_id',
//             'id',
//             'employee_id',
//             'emp_id',
//             'auth_user_id',
//             'uid'
//           ];

//           final List<String> possibleEmailColumns = [
//             'email',
//             'user_email'
//           ];

//           // Try matching by ID columns
//           for (final idColumn in possibleIdColumns) {
//             try {
//               final response = await _supabase
//                   .from(tableName)
//                   .select()
//                   .eq(idColumn, user.id)
//                   .maybeSingle();
              
//               if (response != null) {
//                 foundProfile = response;
//                 print('✅ Found profile in table $tableName using column $idColumn');
//                 break;
//               }
//             } catch (e) {
//               // Column might not exist, continue to next
//             }
//           }

//           if (foundProfile != null) break;

//           // Try matching by email columns
//           for (final emailColumn in possibleEmailColumns) {
//             try {
//               final response = await _supabase
//                   .from(tableName)
//                   .select()
//                   .eq(emailColumn, user.email as Object)
//                   .maybeSingle();
              
//               if (response != null) {
//                 foundProfile = response;
//                 print('✅ Found profile in table $tableName using column $emailColumn');
//                 break;
//               }
//             } catch (e) {
//               // Column might not exist, continue to next
//             }
//           }

//           if (foundProfile != null) break;

//         } catch (e) {
//           print('⚠️ Error querying table $tableName: $e');
//           continue;
//         }
//       }

//       if (foundProfile != null) {
//         _profile = foundProfile;
//         print('✅ Profile loaded successfully');
//         debugProfile();
//       } else {
//         print('⚠️ No employee profile found in any table');
        
//         // Create a default profile with user info to prevent crashes
//         _profile = {
//           'id': user.id,
//           'user_id': user.id,
//           'email': user.email,
//           'full_name': user.email?.split('@').first ?? 'Employee',
//           'name': user.email?.split('@').first ?? 'Employee',
//           'position': 'Employee',
//           'role': 'Employee',
//           'created_at': DateTime.now().toIso8601String(),
//         };
//         print('📋 Created default profile with user info');
//         debugProfile();
//       }

//     } catch (e) {
//       print('❌ Error loading employee profile: $e');
//       _error = 'Failed to load profile: $e';
      
//       // Create fallback profile even on error
//       final user = _supabase.auth.currentUser;
//       if (user != null) {
//         _profile = {
//           'id': user.id,
//           'user_id': user.id,
//           'email': user.email,
//           'full_name': user.email?.split('@').first ?? 'Employee',
//           'name': user.email?.split('@').first ?? 'Employee',
//           'position': 'Employee',
//           'role': 'Employee',
//           'created_at': DateTime.now().toIso8601String(),
//         };
//         print('📋 Created fallback profile due to error');
//       }
      
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // ============================
//   // CLEAR PROFILE (for logout)
//   // ============================
//   void clearProfile() {
//     print('🧹 Clearing employee profile...');
//     _profile = null;
//     _error = null;
//     notifyListeners();
//   }

//   // ============================
//   // GET EMPLOYEE ID
//   // ============================
//   String? get employeeId {
//     if (_profile == null) return null;
    
//     // Try different possible employee ID field names
//     return _profile?['emp_id']?.toString() ??
//            _profile?['employee_id']?.toString() ??
//            _profile?['id']?.toString() ??
//            _profile?['user_id']?.toString();
//   }

//   // ============================
//   // GET EMPLOYEE NAME
//   // ============================
//   String get employeeName {
//     if (_profile == null) return 'Employee';
    
//     return _profile?['full_name']?.toString() ??
//            _profile?['name']?.toString() ??
//            _profile?['username']?.toString() ??
//            _profile?['email']?.toString().split('@').first ??
//            'Employee';
//   }

//   // ============================
//   // GET EMPLOYEE POSITION
//   // ============================
//   String get employeePosition {
//     if (_profile == null) return 'Position';
    
//     return _profile?['position']?.toString() ??
//            _profile?['role']?.toString() ??
//            _profile?['designation']?.toString() ??
//            'Employee';
//   }

//   // ============================
//   // GET EMPLOYEE DISTRICT
//   // ============================
//   String? get employeeDistrict {
//     if (_profile == null) return null;
    
//     return _profile?['district']?.toString() ??
//            _profile?['location']?.toString() ??
//            _profile?['area']?.toString();
//   }

//   // ============================
//   // CHECK IF PROFILE IS LOADED
//   // ============================
//   bool isProfileLoaded() {
//     return _profile != null;
//   }

//   // ============================
//   // MANUALLY SET PROFILE (for testing)
//   // ============================
//   void setProfile(Map<String, dynamic> profile) {
//     _profile = profile;
//     notifyListeners();
//   }

//   // ============================
//   // DEBUG PROFILE INFO
//   // ============================
//   void debugProfile() {
//     print('=== EMPLOYEE PROFILE DEBUG ===');
//     print('Profile loaded: ${_profile != null}');
//     if (_profile != null) {
//       print('Profile data keys: ${_profile!.keys.toList()}');
//       print('Employee ID from getter: $employeeId');
//       print('Employee Name: $employeeName');
//       print('Employee Position: $employeePosition');
//       print('Employee District: $employeeDistrict');
//     }
//     print('============================');
//   }

//   // ============================
//   // GET ALL TABLES (for debugging)
//   // ============================
//   Future<void> debugTables() async {
//     print('=== AVAILABLE TABLES DEBUG ===');
//     try {
//       // Try to list all tables by querying information_schema
//       // Note: This might require special permissions
//       final response = await _supabase
//           .from('information_schema.tables')
//           .select('table_name')
//           .eq('table_schema', 'public')
//           .order('table_name');
      
//       final tables = response as List<dynamic>;
//       print('Found ${tables.length} tables:');
//       for (var table in tables) {
//         print('  - ${table['table_name']}');
//       }
//         } catch (e) {
//       print('❌ Could not list tables: $e');
      
//       // Try alternative method - test common table names
//       print('Testing common table names...');
//       final commonTables = [
//         'emp_mar_orders',
//         'employees',
//         'emp_profiles',
//         'users',
//         'profiles',
//         'attendance',
//         'orders',
//         'targets'
//       ];
      
//       for (var table in commonTables) {
//         try {
//           await _supabase.from(table).select('count').limit(1);
//           print('  ✅ Table exists: $table');
//         } catch (e) {
//           print('  ❌ Table not found: $table');
//         }
//       }
//     }
//     print('=============================');
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class EmployeeProvider with ChangeNotifier {
//   final supabase = Supabase.instance.client;

//   bool loading = true;
//   Map<String, dynamic>? _profile;

//   Map<String, dynamic>? get profile => _profile;

//   Future<void> loadEmployeeProfile() async {
//     try {
//       loading = true;
//       notifyListeners();

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         loading = false;
//         notifyListeners();
//         return;
//       }

//       // ✅ FIXED TABLE NAME + explicit fields
//       final data = await supabase
//           .from('emp_profile') // ✅ CORRECT (singular)
//           .select(
//             'emp_id, full_name, email, phone, position, branch, role, user_id',
//           )
//           .eq('user_id', user.id)
//           .maybeSingle();

//       if (data == null) {
//         debugPrint('❌ No emp_profile row found for user ${user.id}');
//         _profile = null;
//       } else {
//         debugPrint('✅ Employee profile loaded: $data');
//         _profile = data;
//       }
//     } catch (e) {
//       debugPrint("EmployeeProvider error: $e");
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }
// }










// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class EmployeeProvider with ChangeNotifier {
//   final supabase = Supabase.instance.client;

//   bool loading = true;

//   /// Employee profile map
//   Map<String, dynamic>? _profile;

//   /// Order counts
//   int totalOrders = 0;
//   int pendingOrders = 0;
//   int completedOrders = 0;

//   /// ✅ REQUIRED GETTER (THIS FIXES YOUR ERROR)
//   Map<String, dynamic>? get profile => _profile;

//   /// Load employee profile
//   Future<void> loadEmployeeProfile() async {
//     loading = true;
//     notifyListeners();

//     final user = supabase.auth.currentUser;
//     if (user == null) {
//       loading = false;
//       notifyListeners();
//       return;
//     }

//     // 🔹 employee table
//     final data = await supabase
//         .from('emp_profiles')
//         .select()
//         .eq('user_id', user.id)
//         .single();

//     _profile = data;

//     // Load stats
//     await _loadOrderStats(user.id);

//     loading = false;
//     notifyListeners();
//   }

//   /// Load order counts
//   Future<void> _loadOrderStats(String employeeId) async {
//     final orders = await supabase
//         .from('emp_orders')
//         .select('status')
//         .eq('employee_id', employeeId);

//     totalOrders = orders.length;
//     pendingOrders =
//         orders.where((e) => e['status'] == 'pending').length;
//     completedOrders =
//         orders.where((e) => e['status'] == 'completed').length;
//   }
// }

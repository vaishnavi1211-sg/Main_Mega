import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;

  bool loading = true;
  Map<String, dynamic>? _profile;

  Map<String, dynamic>? get profile => _profile;

  Future<void> loadEmployeeProfile() async {
    try {
      loading = true;
      notifyListeners();

      final user = supabase.auth.currentUser;
      if (user == null) {
        loading = false;
        notifyListeners();
        return;
      }

      final data = await supabase
          .from('emp_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle(); // ❗ avoid crash

      _profile = data;
    } catch (e) {
      debugPrint("EmployeeProvider error: $e");
    } finally {
      loading = false; // ✅ ALWAYS reached
      notifyListeners();
    }
  }
}
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;

  bool attendanceMarkedToday = false;
  bool loading = false;
  bool loadingHistory = false;

  String? checkInTime;
  String? location;
  String? photoUrl;

  List<String> presentDates = [];

  // ============================
  // CHECK TODAY ATTENDANCE
  // ============================
  Future<void> checkTodayAttendance() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No user found');
        return;
      }

      final today = DateTime.now().toIso8601String().substring(0, 10);
      debugPrint('Checking attendance for date: $today');

      final data = await supabase
          .from('emp_attendance')
          .select()
          .eq('employee_id', user.id)
          .eq('date', today)
          .maybeSingle();

      debugPrint('Attendance data: $data');
      attendanceMarkedToday = data != null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking attendance: $e');
      attendanceMarkedToday = false;
      notifyListeners();
    }
  }

  // ============================
  // MARK ATTENDANCE
  // ============================
  Future<void> markAttendance({
    required String employeeName,
    required String selfieUrl,
    required String locationText,
  }) async {
    loading = true;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final now = DateTime.now();
      final date = now.toIso8601String().substring(0, 10);
      final time =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      debugPrint('Inserting attendance data...');
      debugPrint('employee_id: ${user.id}');
      debugPrint('employee_name: $employeeName');
      debugPrint('date: $date');
      debugPrint('marked_time: $time');
      debugPrint('location: $locationText');
      debugPrint('selfie_url: $selfieUrl');

      // First check if table exists
      try {
        // Test query to check table
        await supabase.from('emp_attendance').select('count').limit(1);
      } catch (e) {
        debugPrint('Table check error: $e');
        throw Exception('emp_attendance table might not exist. Please create it in Supabase.');
      }

      // Insert attendance record
      final response = await supabase.from('emp_attendance').insert({
        'employee_id': user.id,
        'employee_name': employeeName,
        'date': date,
        'marked_time': time,
        'location': locationText,
        'selfie_url': selfieUrl,
      }).select();

      debugPrint('Attendance inserted successfully: $response');

      // Update local state
      attendanceMarkedToday = true;
      checkInTime = time;
      location = locationText;
      photoUrl = selfieUrl;

      // Load updated history
      await loadAttendanceHistory();

      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      notifyListeners();
      debugPrint('Error marking attendance: $e');
      rethrow; // Re-throw to show error in UI
    }
  }

  // ============================
  // LOAD HISTORY
  // ============================
  Future<void> loadAttendanceHistory() async {
    loadingHistory = true;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        presentDates = [];
        loadingHistory = false;
        notifyListeners();
        return;
      }

      final data = await supabase
          .from('emp_attendance')
          .select('date')
          .eq('employee_id', user.id)
          .order('date', ascending: false);

      debugPrint('Loaded ${data.length} attendance records');
      presentDates = data.map<String>((e) => e['date'] as String).toList();
    } catch (e) {
      debugPrint('Error loading attendance history: $e');
      presentDates = [];
    } finally {
      loadingHistory = false;
      notifyListeners();
    }
  }

  bool isPresent(DateTime date) {
    try {
      final d = date.toIso8601String().substring(0, 10);
      return presentDates.contains(d);
    } catch (e) {
      debugPrint('Error checking presence: $e');
      return false;
    }
  }
}








// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class AttendanceProvider with ChangeNotifier {
//   final supabase = Supabase.instance.client;

//   bool submitting = false;
//   bool markedToday = false;

//   /// ================= CHECK TODAY =================
//   Future<void> checkTodayAttendance() async {
//     final user = supabase.auth.currentUser;
//     if (user == null) return;

//     final today = DateTime.now().toIso8601String().substring(0, 10);

//     final data = await supabase
//         .from('emp_attendance')
//         .select()
//         .eq('employee_id', user.id)
//         .gte('created_at', '$today 00:00:00')
//         .lte('created_at', '$today 23:59:59');

//     markedToday = data.isNotEmpty;
//     notifyListeners();
//   }

//   /// ================= MARK ATTENDANCE =================
//   Future<void> markAttendance({
//     required File image,
//     required String employeeName,
//     required String employeeCode,
//   }) async {
//     submitting = true;
//     notifyListeners();

//     final user = supabase.auth.currentUser;
//     if (user == null) return;

//     final fileName =
//         '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

//     /// Upload selfie
//     await supabase.storage
//         .from('emp_attendance_images')
//         .upload(fileName, image);

//     final imageUrl = supabase.storage
//         .from('emp_attendance_images')
//         .getPublicUrl(fileName);

//     /// Insert attendance
//     await supabase.from('emp_attendance').insert({
//       'employee_id': user.id,
//       'employee_name': employeeName,
//       'employee_code': employeeCode,
//       'selfie_image': imageUrl,
//       'source': 'camera',
//     });

//     markedToday = true;
//     submitting = false;
//     notifyListeners();
//   }
// }

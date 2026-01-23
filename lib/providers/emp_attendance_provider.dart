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
      
      // Store the check-in time and location if attendance was marked
      if (data != null) {
        checkInTime = data['marked_time'];
        location = data['location'];
        photoUrl = data['selfie_url'];
      }
      
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

      // Check if attendance already marked today
      final existingRecord = await supabase
          .from('emp_attendance')
          .select()
          .eq('employee_id', user.id)
          .eq('date', date)
          .maybeSingle();

      if (existingRecord != null) {
        throw Exception('Attendance already marked for today');
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

      // Add to present dates
      if (!presentDates.contains(date)) {
        presentDates.insert(0, date);
      }

      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      notifyListeners();
      debugPrint('Error marking attendance: $e');
      rethrow;
    }
  }

  // ============================
  // LOAD HISTORY
  // ============================
  Future<void> loadAttendanceHistory(String empId) async {
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

  // ============================
  // GET TODAY'S ATTENDANCE DETAILS
  // ============================
  Future<Map<String, dynamic>?> getTodayAttendanceDetails() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      final data = await supabase
          .from('emp_attendance')
          .select()
          .eq('employee_id', user.id)
          .eq('date', today)
          .maybeSingle();

      return data;
    } catch (e) {
      debugPrint('Error getting today\'s attendance: $e');
      return null;
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

  // ============================
  // RESET ATTENDANCE (for testing/debugging)
  // ============================
  void resetAttendance() {
    attendanceMarkedToday = false;
    checkInTime = null;
    location = null;
    photoUrl = null;
    notifyListeners();
  }
}


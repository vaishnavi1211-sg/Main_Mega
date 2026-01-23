import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  Map<String, dynamic>? _selectedAttendanceDetails;
  List<String> _presentDates = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadAttendanceHistory();
      await _loadAttendanceDetails(DateTime.now());
    });
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('emp_attendance')
          .select('date')
          .eq('employee_id', user.id)
          .order('date', ascending: false);

      setState(() {
        _presentDates = data.map((item) => item['date'] as String).toList();
      });
    } catch (e) {
      debugPrint('Error loading attendance history: $e');
    } finally {
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _loadAttendanceDetails(DateTime date) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      final data = await supabase
          .from('emp_attendance')
          .select('*')
          .eq('employee_id', user.id)
          .eq('date', formattedDate)
          .maybeSingle();

      setState(() {
        _selectedAttendanceDetails = data;
      });
    } catch (e) {
      debugPrint('Error loading attendance details: $e');
      setState(() {
        _selectedAttendanceDetails = null;
      });
    }
  }

  bool isPresent(DateTime date) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return _presentDates.contains(formattedDate);
  }

  Widget _buildAttendanceDetailsCard(Map<String, dynamic> attendanceData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowGrey,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Present",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Employee Name
          _buildDetailRow(
            icon: Icons.person,
            label: "Employee Name",
            value: attendanceData['employee_name'] ?? 'N/A',
          ),

          const SizedBox(height: 12),

          // Time Information
          _buildDetailRow(
            icon: Icons.access_time,
            label: "Check-in Time",
            value: attendanceData['marked_time'] ?? 'N/A',
          ),

          const SizedBox(height: 12),

          // Location Information
          _buildDetailRow(
            icon: Icons.location_on,
            label: "Location",
            value: attendanceData['location'] ?? 'Location not recorded',
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          // Selfie Image (if available)
          if (attendanceData['selfie_url'] != null && 
              attendanceData['selfie_url'].toString().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selfie Photo",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderGrey,
                      width: 1,
                    ),
                    color: AppColors.softGreyBg,
                  ),
                  child: _buildImage(attendanceData['selfie_url']),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Meter Photo (if available)
          if (attendanceData['meter_photo_url'] != null && 
              attendanceData['meter_photo_url'].toString().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Meter Photo",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderGrey,
                      width: 1,
                    ),
                    color: AppColors.softGreyBg,
                  ),
                  child: _buildImage(attendanceData['meter_photo_url']),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      // Real URL - use Image.network
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 40,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo,
              size: 40,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 8),
            Text(
              'Photo uploaded',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildNoAttendanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowGrey,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: GlobalColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: GlobalColors.danger.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.close,
                  size: 14,
                  color: GlobalColors.danger,
                ),
                const SizedBox(width: 6),
                Text(
                  "Absent",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GlobalColors.danger,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No attendance record found for this date",
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowGrey,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.today,
                  size: 14,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  "Today",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Mark your attendance for today",
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/mark-attendance');
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Mark Attendance"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: GlobalColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecordsList() {
    final sortedDates = List<String>.from(_presentDates)
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowGrey,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              size: 50,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 12),
            Text(
              "No Attendance Records",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your attendance records will appear here",
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowGrey,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Recent Attendance",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dateTime = DateTime.parse(date);
              final isToday = isSameDay(dateTime, DateTime.now());
              final isSelected = isSameDay(dateTime, selectedDay);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue.withOpacity(0.05) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected 
                      ? Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.3), 
                          width: 1
                        )
                      : null,
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "${dateTime.day}/${dateTime.month}/${dateTime.year}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    _getDayName(dateTime),
                    style: TextStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  trailing: isToday 
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Today",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      selectedDay = dateTime;
                      focusedDay = dateTime;
                    });
                    _loadAttendanceDetails(dateTime);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryBlue,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDayName(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  String _getMonthName(int month) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          "Attendance History",
          style: TextStyle(
            color: GlobalColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: GlobalColors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlobalColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingHistory
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    /// ================= MONTHLY SUMMARY =================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowGrey,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${_getMonthName(focusedDay.month)} ${focusedDay.year}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _summaryItem(
                                "Present",
                                _presentDates.where((date) => 
                                  date.startsWith("${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}")
                                ).length,
                                AppColors.success,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: AppColors.borderGrey,
                              ),
                              _summaryItem(
                                "Absent",
                                DateTime(focusedDay.year, focusedDay.month + 1, 0).day - 
                                  _presentDates.where((date) => 
                                    date.startsWith("${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}")
                                  ).length,
                                GlobalColors.danger,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ================= CALENDAR =================
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowGrey,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TableCalendar(
                        firstDay: DateTime(focusedDay.year, focusedDay.month - 6),
                        lastDay: DateTime(focusedDay.year, focusedDay.month + 6),
                        focusedDay: focusedDay,

                        selectedDayPredicate: (day) =>
                            isSameDay(selectedDay, day),

                        onDaySelected: (selected, focused) async {
                          setState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });
                          await _loadAttendanceDetails(selected);
                        },

                        onPageChanged: (focused) {
                          setState(() {
                            focusedDay = focused;
                          });
                        },

                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          weekendTextStyle: TextStyle(
                            color: GlobalColors.danger.withOpacity(0.8),
                          ),
                          defaultTextStyle: TextStyle(
                            color: AppColors.primaryText,
                          ),
                          outsideTextStyle: TextStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),

                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: AppColors.primaryBlue,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: AppColors.primaryBlue,
                          ),
                        ),

                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
                          weekendStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),

                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (isPresent(day)) {
                              return Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ================= ATTENDANCE DETAILS CARD =================
                    if (isPresent(selectedDay) && _selectedAttendanceDetails != null)
                      _buildAttendanceDetailsCard(_selectedAttendanceDetails!)
                    else if (!isSameDay(selectedDay, DateTime.now()))
                      _buildNoAttendanceCard()
                    else
                      _buildTodayCard(),

                    const SizedBox(height: 20),

                    /// ================= ATTENDANCE RECORDS LIST =================
                    _buildAttendanceRecordsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _summaryItem(String title, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:mega_pro/providers/emp_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import

// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/providers/emp_attendance_provider.dart';

// class AttendanceHistoryPage extends StatefulWidget {
//   const AttendanceHistoryPage({super.key});

//   @override
//   State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
// }

// class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
//   DateTime focusedDay = DateTime.now();
//   DateTime selectedDay = DateTime.now();
//   Map<String, dynamic>? _selectedAttendanceDetails;

//   @override
//   void initState() {
//     super.initState();
//     // Load attendance history when page opens
//     Future.microtask(() async {
//       final provider = context.read<AttendanceProvider>();
//       await provider.loadAttendanceHistory(EmployeeProvider() as String);
//       // Load details for today initially
//       await _loadAttendanceDetails(DateTime.now());
//     });
//   }

//   // Load attendance details for a specific date
//   Future<void> _loadAttendanceDetails(DateTime date) async {
//     context.read<AttendanceProvider>();
//     final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    
//     try {
//       // Get Supabase instance
//       final supabase = Supabase.instance.client;
      
//       // First check if user is logged in
//       final user = supabase.auth.currentUser;
//       if (user == null) return;

//       // Fetch attendance details for the selected date
//       final data = await supabase
//           .from('emp_attendance')
//           .select('*')
//           .eq('employee_id', user.id)
//           .eq('date', formattedDate)
//           .maybeSingle();

//       setState(() {
//         _selectedAttendanceDetails = data;
//       });
//     } catch (e) {
//       debugPrint('Error loading attendance details: $e');
//       setState(() {
//         _selectedAttendanceDetails = null;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<AttendanceProvider>();

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         title: const Text(
//           "Attendance History",
//           style: TextStyle(
//             color: GlobalColors.white,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         iconTheme: const IconThemeData(color: GlobalColors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: GlobalColors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: provider.loadingHistory
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               physics: const BouncingScrollPhysics(),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     /// ================= MONTHLY SUMMARY =================
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: GlobalColors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppColors.shadowGrey,
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.calendar_month,
//                                 color: GlobalColors.primaryBlue,
//                                 size: 18,
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 "${_getMonthName(focusedDay.month)} ${focusedDay.year}",
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: AppColors.primaryText,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               _summaryItem(
//                                 "Present",
//                                 _getMonthlyPresentCount(provider, focusedDay),
//                                 GlobalColors.success,
//                               ),
//                               Container(
//                                 width: 1,
//                                 height: 40,
//                                 color: AppColors.borderGrey,
//                               ),
//                               _summaryItem(
//                                 "Absent",
//                                 _getMonthlyAbsentCount(provider, focusedDay),
//                                 GlobalColors.danger,
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     /// ================= CALENDAR =================
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: GlobalColors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppColors.shadowGrey,
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: TableCalendar(
//                         firstDay: DateTime(focusedDay.year, focusedDay.month - 6),
//                         lastDay: DateTime(focusedDay.year, focusedDay.month + 6),
//                         focusedDay: focusedDay,

//                         selectedDayPredicate: (day) =>
//                             isSameDay(selectedDay, day),

//                         onDaySelected: (selected, focused) async {
//                           setState(() {
//                             selectedDay = selected;
//                             focusedDay = focused;
//                           });
//                           // Load attendance details for selected day
//                           await _loadAttendanceDetails(selected);
//                         },

//                         onPageChanged: (focused) {
//                           setState(() {
//                             focusedDay = focused;
//                           });
//                         },

//                         calendarStyle: CalendarStyle(
//                           todayDecoration: BoxDecoration(
//                             color: GlobalColors.primaryBlue.withOpacity(0.2),
//                             shape: BoxShape.circle,
//                           ),
//                           selectedDecoration: const BoxDecoration(
//                             color: GlobalColors.primaryBlue,
//                             shape: BoxShape.circle,
//                           ),
//                           weekendTextStyle: TextStyle(
//                             color: GlobalColors.danger.withOpacity(0.8),
//                           ),
//                           defaultTextStyle: TextStyle(
//                             color: AppColors.primaryText,
//                           ),
//                           outsideTextStyle: TextStyle(
//                             color: AppColors.secondaryText,
//                           ),
//                         ),

//                         headerStyle: HeaderStyle(
//                           formatButtonVisible: false,
//                           titleCentered: true,
//                           titleTextStyle: TextStyle(
//                             color: AppColors.primaryText,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                           leftChevronIcon: Icon(
//                             Icons.chevron_left,
//                             color: GlobalColors.primaryBlue,
//                           ),
//                           rightChevronIcon: Icon(
//                             Icons.chevron_right,
//                             color: GlobalColors.primaryBlue,
//                           ),
//                         ),

//                         daysOfWeekStyle: const DaysOfWeekStyle(
//                           weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
//                           weekendStyle: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             color: Colors.red,
//                           ),
//                         ),

//                         /// ✅ CORRECT WAY to MARK PRESENT DAYS
//                         calendarBuilders: CalendarBuilders(
//                           markerBuilder: (context, day, events) {
//                             if (provider.isPresent(day)) {
//                               return Positioned(
//                                 bottom: 4,
//                                 child: Container(
//                                   width: 6,
//                                   height: 6,
//                                   decoration: const BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     color: GlobalColors.success,
//                                   ),
//                                 ),
//                               );
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     /// ================= ATTENDANCE DETAILS CARD =================
//                     if (provider.isPresent(selectedDay) && _selectedAttendanceDetails != null)
//                       _buildAttendanceDetailsCard(_selectedAttendanceDetails!)
//                     else if (!isSameDay(selectedDay, DateTime.now()))
//                       _buildNoAttendanceCard()
//                     else
//                       _buildTodayCard(),

//                     const SizedBox(height: 20),

//                     /// ================= ATTENDANCE RECORDS LIST =================
//                     _buildAttendanceRecordsList(provider),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   /// ================= ATTENDANCE DETAILS CARD =================
//   Widget _buildAttendanceDetailsCard(Map<String, dynamic> attendanceData) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: GlobalColors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowGrey,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header with status and date
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: GlobalColors.success.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: GlobalColors.success.withOpacity(0.3),
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.check_circle,
//                       size: 14,
//                       color: GlobalColors.success,
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       "Present",
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: GlobalColors.success,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Text(
//                 "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primaryText,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 16),

//           // Time Information
//           _buildDetailRow(
//             icon: Icons.access_time,
//             label: "Check-in Time",
//             value: attendanceData['marked_time'] ?? 'N/A',
//           ),

//           const SizedBox(height: 12),

//           // Location Information
//           _buildDetailRow(
//             icon: Icons.location_on,
//             label: "Location",
//             value: attendanceData['location'] ?? 'Location not recorded',
//             maxLines: 2,
//           ),

//           const SizedBox(height: 16),

//           // Selfie Image (if available)
//           if (attendanceData['selfie_url'] != null && 
//               attendanceData['selfie_url'].toString().isNotEmpty)
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Attendance Selfie",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.primaryText,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   height: 200,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: AppColors.borderGrey,
//                       width: 1,
//                     ),
//                     color: Colors.grey[100],
//                   ),
//                   child: _buildSelfieImage(attendanceData['selfie_url']),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSelfieImage(String imageUrl) {
//     // Check if it's a real URL or just a placeholder
//     if (imageUrl.startsWith('attendance_selfie_')) {
//       // It's a placeholder - show a generic image
//       return Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.camera_alt,
//             size: 50,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Selfie was taken',
//             style: TextStyle(
//               color: Colors.grey[500],
//               fontSize: 12,
//             ),
//           ),
//         ],
//       );
//     } else {
//       // It's a real URL - you would load the image here
//       // For now, show a placeholder
//       return Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.photo,
//             size: 50,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Selfie Image',
//             style: TextStyle(
//               color: Colors.grey[500],
//               fontSize: 12,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'URL: ${imageUrl.substring(0, min(30, imageUrl.length))}...',
//             style: TextStyle(
//               color: Colors.grey[500],
//               fontSize: 10,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       );
//     }
//   }

//   Widget _buildNoAttendanceCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: GlobalColors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowGrey,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: GlobalColors.danger.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: GlobalColors.danger.withOpacity(0.3),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.close,
//                   size: 14,
//                   color: GlobalColors.danger,
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   "Absent",
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: GlobalColors.danger,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: AppColors.primaryText,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "No attendance record found for this date",
//             style: TextStyle(
//               fontSize: 13,
//               color: AppColors.secondaryText,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTodayCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: GlobalColors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowGrey,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: GlobalColors.primaryBlue.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: GlobalColors.primaryBlue.withOpacity(0.3),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.today,
//                   size: 14,
//                   color: GlobalColors.primaryBlue,
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   "Today",
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: GlobalColors.primaryBlue,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: AppColors.primaryText,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Mark your attendance for today",
//             style: TextStyle(
//               fontSize: 13,
//               color: AppColors.secondaryText,
//             ),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton.icon(
//             onPressed: () {
//               // Navigate to mark attendance page
//               // You'll need to implement this navigation
//               Navigator.pushNamed(context, '/mark-attendance');
//             },
//             icon: const Icon(Icons.add, size: 16),
//             label: const Text("Mark Attendance"),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: GlobalColors.primaryBlue,
//               foregroundColor: GlobalColors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// ================= ATTENDANCE RECORDS LIST =================
//   Widget _buildAttendanceRecordsList(AttendanceProvider provider) {
//     // Sort dates in descending order (most recent first)
//     final sortedDates = List<String>.from(provider.presentDates)
//       ..sort((a, b) => b.compareTo(a));

//     if (sortedDates.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: GlobalColors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.shadowGrey,
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Icon(
//               Icons.calendar_today,
//               size: 50,
//               color: Colors.grey[300],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               "No Attendance Records",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.primaryText,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Your attendance records will appear here",
//               style: TextStyle(
//                 fontSize: 13,
//                 color: AppColors.secondaryText,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: GlobalColors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowGrey,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text(
//               "Recent Attendance",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.primaryText,
//               ),
//             ),
//           ),
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: sortedDates.length,
//             itemBuilder: (context, index) {
//               final date = sortedDates[index];
//               final dateTime = DateTime.parse(date);
//               final isToday = isSameDay(dateTime, DateTime.now());
//               final isSelected = isSameDay(dateTime, selectedDay);
              
//               return Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: isSelected ? GlobalColors.primaryBlue.withOpacity(0.05) : null,
//                   borderRadius: BorderRadius.circular(8),
//                   border: isSelected 
//                       ? Border.all(color: GlobalColors.primaryBlue.withOpacity(0.3), width: 1)
//                       : null,
//                 ),
//                 child: ListTile(
//                   leading: Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: GlobalColors.success.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       Icons.check_circle,
//                       color: GlobalColors.success,
//                       size: 20,
//                     ),
//                   ),
//                   title: Text(
//                     "${dateTime.day}/${dateTime.month}/${dateTime.year}",
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryText,
//                     ),
//                   ),
//                   subtitle: Text(
//                     _getDayName(dateTime),
//                     style: TextStyle(
//                       color: AppColors.secondaryText,
//                     ),
//                   ),
//                   trailing: isToday 
//                       ? Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: GlobalColors.primaryBlue.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             "Today",
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: FontWeight.w600,
//                               color: GlobalColors.primaryBlue,
//                             ),
//                           ),
//                         )
//                       : null,
//                   onTap: () {
//                     setState(() {
//                       selectedDay = dateTime;
//                       focusedDay = dateTime;
//                     });
//                     _loadAttendanceDetails(dateTime);
//                   },
//                 ),
//               );
//             },
//           ),
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }

//   /// ================= HELPER METHODS =================
//   Widget _summaryItem(String title, int value, Color color) {
//     return Column(
//       children: [
//         Text(
//           value.toString(),
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 12,
//             color: AppColors.secondaryText,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDetailRow({
//     required IconData icon,
//     required String label,
//     required String value,
//     int maxLines = 1,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(
//           icon,
//           size: 20,
//           color: GlobalColors.primaryBlue,
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: AppColors.secondaryText,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.primaryText,
//                 ),
//                 maxLines: maxLines,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   int _getMonthlyPresentCount(AttendanceProvider provider, DateTime month) {
//     final monthKey = "${month.year}-${month.month.toString().padLeft(2, '0')}";
//     return provider.presentDates
//         .where((date) => date.startsWith(monthKey))
//         .length;
//   }

//   int _getMonthlyAbsentCount(AttendanceProvider provider, DateTime month) {
//     // Assuming working days in a month (adjust as needed)
//     final workingDays = DateTime(month.year, month.month + 1, 0).day;
//     final presentCount = _getMonthlyPresentCount(provider, month);
//     final absentCount = workingDays - presentCount;
//     return absentCount > 0 ? absentCount : 0;
//   }

//   String _getDayName(DateTime date) {
//     final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
//     return days[date.weekday - 1];
//   }

//   String _getMonthName(int month) {
//     final months = ['January', 'February', 'March', 'April', 'May', 'June', 
//                     'July', 'August', 'September', 'October', 'November', 'December'];
//     return months[month - 1];
//   }
  
//   int min(int a, int b) => a < b ? a : b;
// }

















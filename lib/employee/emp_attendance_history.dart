import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_attendance_provider.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Load attendance history when page opens
    Future.microtask(() {
      context.read<AttendanceProvider>().loadAttendanceHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
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
      body: provider.loadingHistory
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
                        color: GlobalColors.white,
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
                                color: GlobalColors.primaryBlue,
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
                                _getMonthlyPresentCount(provider, focusedDay),
                                GlobalColors.success,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: AppColors.borderGrey,
                              ),
                              _summaryItem(
                                "Absent",
                                _getMonthlyAbsentCount(provider, focusedDay),
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
                        color: GlobalColors.white,
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

                        onDaySelected: (selected, focused) {
                          setState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });
                        },

                        onPageChanged: (focused) {
                          setState(() {
                            focusedDay = focused;
                          });
                        },

                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: GlobalColors.primaryBlue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: GlobalColors.primaryBlue,
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
                            color: GlobalColors.primaryBlue,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: GlobalColors.primaryBlue,
                          ),
                        ),

                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
                          weekendStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),

                        /// ✅ CORRECT WAY to MARK PRESENT DAYS
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (provider.isPresent(day)) {
                              return Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: GlobalColors.success,
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

                    /// ================= LEGEND =================
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GlobalColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowGrey,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem(GlobalColors.success, "Present"),
                          _buildLegendItem(GlobalColors.primaryBlue, "Today"),
                          _buildLegendItem(AppColors.borderGrey, "Absent"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ================= ATTENDANCE DETAILS =================
                    if (provider.isPresent(selectedDay))
                      _buildDetailsCard("Present", GlobalColors.success)
                    else if (!isSameDay(selectedDay, DateTime.now()))
                      _buildDetailsCard("Absent", GlobalColors.danger),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  /// ================= HELPER METHODS =================
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

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlobalColors.white,
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _getDayName(selectedDay),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Date",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
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
        ],
      ),
    );
  }

  int _getMonthlyPresentCount(AttendanceProvider provider, DateTime month) {
    final monthKey = "${month.year}-${month.month.toString().padLeft(2, '0')}";
    return provider.presentDates
        .where((date) => date.startsWith(monthKey))
        .length;
  }

  int _getMonthlyAbsentCount(AttendanceProvider provider, DateTime month) {
    // Assuming working days in a month (adjust as needed)
    final workingDays = DateTime(month.year, month.month + 1, 0).day;
    final presentCount = _getMonthlyPresentCount(provider, month);
    final absentCount = workingDays - presentCount;
    return absentCount > 0 ? absentCount : 0;
  }

  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getMonthName(int month) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}


// import 'package:flutter/material.dart';
// import 'package:mega_pro/providers/emp_attendance_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:table_calendar/table_calendar.dart';

// import 'package:mega_pro/global/global_variables.dart';

// class AttendanceHistoryPage extends StatefulWidget {
//   const AttendanceHistoryPage({super.key});

//   @override
//   State<AttendanceHistoryPage> createState() =>
//       _AttendanceHistoryPageState();
// }

// class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedDay;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() {
//       context.read<AttendanceProvider>().loadAttendanceHistory();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<AttendanceProvider>();

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         title: const Text(
//           "Attendance History",
//           style: TextStyle(color: Colors.white),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: provider.loading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   _buildCalendar(provider),
//                   const SizedBox(height: 20),
//                   _legend(),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildCalendar(AttendanceProvider provider) {
//     return TableCalendar(
//       firstDay: DateTime.utc(2022, 1, 1),
//       lastDay: DateTime.utc(2030, 12, 31),
//       focusedDay: _focusedDay,
//       calendarFormat: CalendarFormat.month,
//       selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
//       onDaySelected: (selectedDay, focusedDay) {
//         setState(() {
//           _selectedDay = selectedDay;
//           _focusedDay = focusedDay;
//         });
//       },
//       calendarBuilders: CalendarBuilders(
//         defaultBuilder: (context, day, focusedDay) {
//           final isPresent = provider.isPresent(day);

//           return Container(
//             margin: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: isPresent
//                   ? Colors.green.withOpacity(0.8)
//                   : Colors.transparent,
//             ),
//             alignment: Alignment.center,
//             child: Text(
//               '${day.day}',
//               style: TextStyle(
//                 color: isPresent ? Colors.white : Colors.black,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           );
//         },
//       ),
//       headerStyle: const HeaderStyle(
//         formatButtonVisible: false,
//         titleCentered: true,
//       ),
//     );
//   }

//   Widget _legend() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         _legendItem(Colors.green, "Present"),
//         const SizedBox(width: 20),
//         _legendItem(Colors.grey, "Absent"),
//       ],
//     );
//   }

//   Widget _legendItem(Color color, String label) {
//     return Row(
//       children: [
//         Container(
//           width: 16,
//           height: 16,
//           decoration: BoxDecoration(
//             color: color,
//             shape: BoxShape.circle,
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(label),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class MarketingManagerAttendanceHistoryPage extends StatefulWidget {
  const MarketingManagerAttendanceHistoryPage({super.key});

  @override
  State<MarketingManagerAttendanceHistoryPage> createState() => _MarketingManagerAttendanceHistoryPageState();
}

class _MarketingManagerAttendanceHistoryPageState extends State<MarketingManagerAttendanceHistoryPage> {
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
          .from('marketing_manager_attendance')
          .select('date')
          .eq('manager_id', user.id)
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
          .from('marketing_manager_attendance')
          .select('*')
          .eq('manager_id', user.id)
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

          // Enterprise Name
          _buildDetailRow(
            icon: Icons.business,
            label: "Enterprise Name",
            value: attendanceData['enterprise_name'] ?? 'N/A',
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
      // Real URL - you can use Image.network here
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
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 40,
            color: AppColors.mutedText,
          ),
          const SizedBox(height: 8),
          Text(
            'Photo taken',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
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
            "Mark your visit attendance for today",
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/marketing-manager-attendance');
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
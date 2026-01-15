import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:mega_pro/global/global_variables.dart';

class ManagerAttendancePage extends StatefulWidget {
  const ManagerAttendancePage({super.key});

  @override
  State<ManagerAttendancePage> createState() => _ManagerAttendancePageState();
}

class _ManagerAttendancePageState extends State<ManagerAttendancePage> {
  final supabase = Supabase.instance.client;
  
  DateTime _selectedDate = DateTime.now();
// Today, This Week, This Month, Custom
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _loading = false;
  
  // Statistics
  int _totalEmployees = 0;
  int _presentToday = 0;
  int _lateToday = 0;
  int _absentToday = 0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      await _loadEmployees();
      await _loadAttendanceData();
      _calculateStatistics();
    } catch (e) {
      debugPrint('Error loading manager data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
  
  Future<void> _loadEmployees() async {
    try {
      final data = await supabase
          .from('employee_profiles') // Your employees table
          .select('*')
          .order('full_name');
      
      setState(() {
        _employees = List<Map<String, dynamic>>.from(data);
        _totalEmployees = _employees.length;
      });
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }
  }
  
  Future<void> _loadAttendanceData() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final data = await supabase
          .from('emp_attendance')
          .select('*')
          .eq('date', today)
          .order('marked_time');
      
      setState(() {
        _attendanceRecords = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    }
  }
  
  void _calculateStatistics() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayAttendance = _attendanceRecords
        .where((record) => record['date'] == today)
        .toList();
    
    int present = 0;
    int late = 0;
    
    for (var record in todayAttendance) {
      final time = record['marked_time']?.toString() ?? '';
      if (time.isNotEmpty) {
        final hour = int.tryParse(time.split(':')[0]) ?? 0;
        // Consider late if after 10 AM (adjust as needed)
        if (hour >= 10) {
          late++;
        } else {
          present++;
        }
      } else {
        present++;
      }
    }
    
    setState(() {
      _presentToday = present;
      _lateToday = late;
      _absentToday = _totalEmployees - (present + late);
    });
  }
  
  Widget _buildStatisticsCard() {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: GlobalColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: GlobalColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Statistics Grid
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total',
                  _totalEmployees.toString(),
                  Icons.group,
                  GlobalColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Present',
                  _presentToday.toString(),
                  Icons.check_circle,
                  GlobalColors.success,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Late',
                  _lateToday.toString(),
                  Icons.access_time,
                  GlobalColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Absent',
                  _absentToday.toString(),
                  Icons.cancel,
                  GlobalColors.danger,
                ),
              ),
            ],
          ),
          
          // Attendance Rate
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: GlobalColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Rate',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_totalEmployees > 0 ? ((_presentToday / _totalEmployees) * 100).toStringAsFixed(1) : '0.0'}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GlobalColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttendanceTable() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Attendance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                '${_attendanceRecords.length} of $_totalEmployees',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Employee',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Time',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 40), // For view button
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Table Rows
          if (_attendanceRecords.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 50,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No attendance marked yet',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._attendanceRecords.map((record) => _attendanceRow(record)).toList(),
        ],
      ),
    );
  }
  
  Widget _attendanceRow(Map<String, dynamic> record) {
    final status = _getAttendanceStatus(record);
    final statusColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderGrey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Employee Avatar & Name
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: GlobalColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: GlobalColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['employee_name'] ?? 'Employee',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record['position'] ?? 'Employee',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Time
          Expanded(
            child: Text(
              record['marked_time']?.toString() ?? '--:--',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Status
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // View Button
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.visibility,
              size: 18,
              color: GlobalColors.primaryBlue,
            ),
            onPressed: () {
              _showAttendanceDetails(record);
            },
          ),
        ],
      ),
    );
  }
  
  String _getAttendanceStatus(Map<String, dynamic> record) {
    final time = record['marked_time']?.toString() ?? '';
    if (time.isEmpty) return 'Absent';
    
    final hour = int.tryParse(time.split(':')[0]) ?? 0;
    // Late if after 10 AM (adjust threshold as needed)
    if (hour >= 10) return 'Late';
    return 'Present';
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return GlobalColors.success;
      case 'Late':
        return GlobalColors.warning;
      case 'Absent':
        return GlobalColors.danger;
      default:
        return Colors.grey;
    }
  }
  
  void _showAttendanceDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Attendance Details',
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailItem('Employee', record['employee_name'] ?? 'N/A'),
            _detailItem('Date', record['date'] ?? 'N/A'),
            _detailItem('Time', record['marked_time'] ?? 'N/A'),
            _detailItem('Location', record['location'] ?? 'N/A'),
            
            // Selfie Preview
            if (record['selfie_url'] != null && record['selfie_url'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Selfie:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderGrey),
                      color: Colors.grey[100],
                    ),
                    child: _buildSelfiePreview(record['selfie_url']),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSelfiePreview(String imagePath) {
    if (imagePath.contains('/') && imagePath.endsWith('.jpg')) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error loading selfie: $e');
      }
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Selfie',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAbsentEmployeesList() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final presentEmployeeIds = _attendanceRecords
        .where((record) => record['date'] == today)
        .map((record) => record['employee_id'])
        .toSet();
    
    final absentEmployees = _employees
        .where((emp) => !presentEmployeeIds.contains(emp['id']))
        .toList();
    
    if (absentEmployees.isEmpty) return const SizedBox();
    
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
              Icon(
                Icons.warning,
                color: GlobalColors.danger,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Absent Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: GlobalColors.danger,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: GlobalColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  absentEmployees.length.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GlobalColors.danger,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          ...absentEmployees.map((emp) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GlobalColors.danger.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GlobalColors.danger.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: GlobalColors.danger,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp['full_name'] ?? 'Employee',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        emp['position'] ?? 'Employee',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.phone,
                    size: 18,
                    color: GlobalColors.primaryBlue,
                  ),
                  onPressed: () {
                    // Call employee
                  },
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        title: const Text(
          "Attendance Dashboard",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: GlobalColors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Statistics Overview
                  _buildStatisticsCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Today's Attendance Table
                  _buildAttendanceTable(),
                  
                  const SizedBox(height: 20),
                  
                  // Absent Employees List
                  _buildAbsentEmployeesList(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
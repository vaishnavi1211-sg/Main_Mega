import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

final supabase = Supabase.instance.client;

class DistrictTeamMembersPage extends StatefulWidget {
  const DistrictTeamMembersPage({super.key});

  @override
  State<DistrictTeamMembersPage> createState() => _DistrictTeamMembersPageState();
}

class _DistrictTeamMembersPageState extends State<DistrictTeamMembersPage> {
  final Color themePrimary = GlobalColors.primaryBlue;
  final Color bg = const Color(0xFFF9FAFB);

  // Manager's information
  String? _managerDistrict;
  String? _managerName;
  
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic> _employeeStats = {};
  Map<String, List<Map<String, dynamic>>> _employeeOrders = {};
  Map<String, List<String>> _employeeAttendance = {};
  
  // Real-time subscriptions
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _attendanceChannel;
  Timer? _pollingTimer;
  Timer? _autoRefreshTimer;
  DateTime _lastDataUpdate = DateTime.now();
  static const Duration autoRefreshInterval = Duration(seconds: 30);
  
  // Branch/Taluka related
  List<String> _branchesInDistrict = [];
  String? _selectedBranch;
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredEmployees = [];

  // View mode
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadManagerProfileAndEmployees();
      _setupRealtimeSubscriptions();
      _setupAutoRefresh();
    });
  }

  void _setupAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(autoRefreshInterval, (timer) {
      if (mounted && !_isLoading) {
        print('🔄 Auto-refresh triggered');
        _refreshData();
      }
    });
  }

  void _setupRealtimeSubscriptions() {
    try {
      _ordersChannel = supabase.channel('team-orders')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'emp_mar_orders',
            callback: (payload) {
              print('🔄 Order change detected - refreshing team data');
              _handleDataChange();
            },
          )
          .subscribe();

      _attendanceChannel = supabase.channel('team-attendance')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'emp_attendance',
            callback: (payload) {
              print('🔄 Attendance change detected - refreshing team data');
              _handleDataChange();
            },
          )
          .subscribe();

    } catch (e) {
      print('❌ Error setting up real-time: $e');
      _setupPollingFallback();
    }
  }

  void _setupPollingFallback() {
    print('🔄 Setting up polling fallback (every 30 seconds)...');
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        _refreshData();
      }
    });
  }

  void _handleDataChange() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_isLoading) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    _attendanceChannel?.unsubscribe();
    _pollingTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;
    print('🔄 Refreshing team data...');
    await _fetchEmployeesByManagerDistrict();
  }

  Future<void> _loadManagerProfileAndEmployees() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Please login to access this page.';
          _isLoading = false;
        });
        return;
      }

      final managerProfile = await supabase
          .from('emp_profile')
          .select('district, branch, role, emp_id, full_name, id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (managerProfile == null || managerProfile.isEmpty) {
        setState(() {
          _errorMessage = 'Marketing Manager profile not found.';
          _isLoading = false;
        });
        return;
      }

      _managerDistrict = managerProfile['district']?.toString();
      _managerName = managerProfile['full_name']?.toString();

      if (_managerDistrict == null || _managerDistrict!.isEmpty) {
        setState(() {
          _errorMessage = 'Your profile does not have a district assigned.';
          _isLoading = false;
        });
        return;
      }

      await _fetchEmployeesByManagerDistrict();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEmployeesByManagerDistrict() async {
    if (_managerDistrict == null || _managerDistrict!.isEmpty) return;

    try {
      final response = await supabase
          .from('emp_profile')
          .select('''
            id,
            emp_id,
            full_name,
            email,
            phone,
            position,
            branch,
            district,
            joining_date,
            status,
            salary,
            role,
            profile_image,
            created_at,
            department
          ''')
          .eq('district', _managerDistrict!)
          .order('full_name', ascending: true);

      List<Map<String, dynamic>> employeesList = List<Map<String, dynamic>>.from(response);

      final filteredEmployees = employeesList.where((emp) {
        final role = emp['role']?.toString() ?? '';
        return role != 'Marketing Manager' && role != 'Owner';
      }).toList();

      final branchSet = <String>{};
      for (var emp in filteredEmployees) {
        final branch = emp['branch']?.toString();
        if (branch != null && branch.isNotEmpty) {
          branchSet.add(branch);
        }
      }
      _branchesInDistrict = branchSet.toList()..sort();

      await _loadEmployeeStatsAndOrders(filteredEmployees);
      
      setState(() {
        _employees = filteredEmployees;
        _filteredEmployees = List.from(filteredEmployees);
        _isLoading = false;
        _lastDataUpdate = DateTime.now();
      });
          
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching employees: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployeeStatsAndOrders(List<Map<String, dynamic>> employees) async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

    for (var employee in employees) {
      final empId = employee['emp_id']?.toString();
      final userId = employee['id']?.toString();
      
      if (empId == null || empId.isEmpty) continue;

      try {
        // Get orders for current month
        final ordersResponse = await supabase
            .from('emp_mar_orders')
            .select('''
              id,
              created_at,
              total_price,
              status,
              customer_name,
              bags,
              total_weight,
              weight_unit,
              feed_category
            ''')
            .eq('employee_id', empId)
            .gte('created_at', firstDayOfMonth.toIso8601String())
            .lte('created_at', lastDayOfMonth.toIso8601String())
            .order('created_at', ascending: false);

        List<Map<String, dynamic>> ordersList = List<Map<String, dynamic>>.from(ordersResponse);
        _employeeOrders[empId] = ordersList;

        final totalOrders = ordersList.length;
        
        final completedOrders = ordersList.where((order) {
          final status = order['status']?.toString().toLowerCase();
          return status == 'completed' || status == 'delivered';
        }).toList();

        final pendingOrders = ordersList.where((order) {
          final status = order['status']?.toString().toLowerCase();
          return status == 'pending' || status == 'packing' || status == 'ready_for_dispatch';
        }).toList();

        double totalSales = 0;
        for (var order in completedOrders) {
          totalSales += (order['total_price'] as num?)?.toDouble() ?? 0;
        }

        final completionRate = totalOrders > 0 
            ? (completedOrders.length / totalOrders) * 100 
            : 0.0;

        final avgOrderValue = completedOrders.isNotEmpty 
            ? totalSales / completedOrders.length 
            : 0.0;

        // Get attendance data
        List<String> attendanceDates = [];
        
        if (userId != null) {
          final attendanceResponse = await supabase
              .from('emp_attendance')
              .select('date')
              .eq('employee_id', userId)
              .gte('date', firstDayOfMonth.toIso8601String())
              .lte('date', lastDayOfMonth.toIso8601String())
              .order('date', ascending: false);

          attendanceDates = List<String>.from(attendanceResponse.map((e) => e['date'] as String));
        } 
        
        if (attendanceDates.isEmpty) {
          final attendanceResponse = await supabase
              .from('emp_attendance')
              .select('date')
              .eq('employee_id', empId)
              .gte('date', firstDayOfMonth.toIso8601String())
              .lte('date', lastDayOfMonth.toIso8601String())
              .order('date', ascending: false);

          attendanceDates = List<String>.from(attendanceResponse.map((e) => e['date'] as String));
        }

        _employeeAttendance[empId] = attendanceDates;

        final attendedDays = attendanceDates.length;
        
        int workingDays = 0;
        for (var day = firstDayOfMonth; 
             day.isBefore(lastDayOfMonth) || day.isAtSameMomentAs(lastDayOfMonth); 
             day = day.add(const Duration(days: 1))) {
          if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
            workingDays++;
          }
        }
        
        final attendancePercentage = workingDays > 0 ? (attendedDays / workingDays) * 100 : 0.0;

        double workQualityScore = 0.0;
        if (completedOrders.isNotEmpty) {
          workQualityScore = (avgOrderValue / 5000 * 100).clamp(0.0, 100.0);
        }

        final teamCollaborationScore = 70.0 + (completionRate / 100 * 20).clamp(0.0, 20.0);

        final performanceScore = (
          completionRate * 0.35 +
          workQualityScore * 0.25 +
          attendancePercentage * 0.25 +
          teamCollaborationScore * 0.15
        ).clamp(0.0, 100.0);

        _employeeStats[empId] = {
          'total_orders': totalOrders,
          'completed_orders': completedOrders.length,
          'pending_orders': pendingOrders.length,
          'total_sales': totalSales,
          'attendance_percentage': attendancePercentage,
          'attended_days': attendedDays,
          'working_days': workingDays,
          'completion_rate': completionRate,
          'work_quality': workQualityScore,
          'team_collaboration': teamCollaborationScore,
          'performance_score': performanceScore,
          'avg_order_value': avgOrderValue,
        };

      } catch (e) {
        print('Error loading stats for employee $empId: $e');
        _employeeStats[empId] = {
          'total_orders': 0,
          'completed_orders': 0,
          'pending_orders': 0,
          'total_sales': 0.0,
          'attendance_percentage': 0.0,
          'attended_days': 0,
          'working_days': 22,
          'completion_rate': 0.0,
          'work_quality': 0.0,
          'team_collaboration': 70.0,
          'performance_score': 0.0,
          'avg_order_value': 0.0,
        };
        _employeeAttendance[empId] = [];
      }
    }
  }

  void _filterEmployees() {
    List<Map<String, dynamic>> filtered = List.from(_employees);

    if (_selectedBranch != null && _selectedBranch!.isNotEmpty && _selectedBranch != 'All Branches') {
      filtered = filtered.where((emp) {
        return emp['branch']?.toString() == _selectedBranch;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((employee) {
        final name = employee['full_name']?.toString().toLowerCase() ?? '';
        final position = employee['position']?.toString().toLowerCase() ?? '';
        final empId = employee['emp_id']?.toString().toLowerCase() ?? '';
        final email = employee['email']?.toString().toLowerCase() ?? '';

        return name.contains(_searchQuery.toLowerCase()) ||
              position.contains(_searchQuery.toLowerCase()) ||
              empId.contains(_searchQuery.toLowerCase()) ||
              email.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredEmployees = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterEmployees();
  }

  void _onBranchChanged(String? branch) {
    setState(() {
      _selectedBranch = branch;
    });
    _filterEmployees();
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }


  void _viewEmployeeDetails(Map<String, dynamic> employee) {
    final empId = employee['emp_id']?.toString() ?? '';
    final stats = _employeeStats[empId] ?? {};
    final orders = _employeeOrders[empId] ?? [];
    final attendance = _employeeAttendance[empId] ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailPage(
          employee: employee,
          stats: stats,
          orders: orders,
          attendance: attendance,
          themePrimary: themePrimary,
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final empId = employee['emp_id']?.toString() ?? '';
    final stats = _employeeStats[empId] ?? {};
    
    final status = employee['status']?.toString() ?? 'Inactive';
    final isActive = status.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : Colors.orange;
    
    final performanceValue = (stats['performance_score'] is num) 
        ? (stats['performance_score'] as num).toDouble() 
        : 0.0;
    final attendanceValue = (stats['attendance_percentage'] is num) 
        ? (stats['attendance_percentage'] as num).toDouble() 
        : 0.0;
    final completedOrders = (stats['completed_orders'] is num) 
        ? (stats['completed_orders'] as num).toInt() 
        : 0;
    final totalOrders = (stats['total_orders'] is num) 
        ? (stats['total_orders'] as num).toInt() 
        : 0;
    final attendedDays = (stats['attended_days'] is num) 
        ? (stats['attended_days'] as num).toInt() 
        : 0;
    final workingDays = (stats['working_days'] is num) 
        ? (stats['working_days'] as num).toInt() 
        : 22;
    
    final joinDate = employee['joining_date'] != null
        ? DateFormat('MMM yyyy').format(DateTime.parse(employee['joining_date']))
        : 'N/A';
    
    return GestureDetector(
      onTap: () => _viewEmployeeDetails(employee),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Name and Role
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: themePrimary.withOpacity(0.1),
                  radius: 28,
                  child: Text(
                    employee['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'E',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: themePrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee['full_name']?.toString() ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        employee['position']?.toString() ?? 'Employee',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Employee ID, Department, Since
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Employee ID',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        employee['emp_id']?.toString() ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Department',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        employee['department']?.toString() ?? 'Not Set',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Since',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        joinDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Current Month Stats
            Text(
              'Current Month (${DateFormat('MMMM yyyy').format(DateTime.now())})',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Completed Orders', '$completedOrders', Colors.green),
                  _buildStatColumn('Total Orders', '$totalOrders', Colors.blue),
                  _buildStatColumn('Present Days', '$attendedDays/$workingDays', Colors.orange),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Performance and Attendance
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getPerformanceColor(performanceValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getPerformanceColor(performanceValue).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${performanceValue.toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _getPerformanceColor(performanceValue),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Overall Performance',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getAttendanceColor(attendanceValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getAttendanceColor(attendanceValue).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${attendanceValue.toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _getAttendanceColor(attendanceValue),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Attendance',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeGridItem(Map<String, dynamic> employee) {
    final empId = employee['emp_id']?.toString() ?? '';
    final stats = _employeeStats[empId] ?? {};
    final performanceValue = (stats['performance_score'] is num) 
        ? (stats['performance_score'] as num).toDouble() 
        : 0.0;
    final attendanceValue = (stats['attendance_percentage'] is num) 
        ? (stats['attendance_percentage'] as num).toDouble() 
        : 0.0;
    final completedOrders = (stats['completed_orders'] is num) 
        ? (stats['completed_orders'] as num).toInt() 
        : 0;
    final totalOrders = (stats['total_orders'] is num) 
        ? (stats['total_orders'] as num).toInt() 
        : 0;
    final attendedDays = (stats['attended_days'] is num) 
        ? (stats['attended_days'] as num).toInt() 
        : 0;
    final workingDays = (stats['working_days'] is num) 
        ? (stats['working_days'] as num).toInt() 
        : 22;

    return GestureDetector(
      onTap: () => _viewEmployeeDetails(employee),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: themePrimary.withOpacity(0.1),
                    radius: 20,
                    child: Text(
                      employee['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'E',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themePrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee['full_name']?.toString() ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                        Text(
                          employee['position']?.toString() ?? 'Employee',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildGridMetric('Perf', '${performanceValue.toStringAsFixed(0)}%', Colors.blue),
                        _buildGridMetric('Att', '${attendanceValue.toStringAsFixed(0)}%', Colors.green),
                        _buildGridMetric('Orders', '$completedOrders/$totalOrders', Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Present: $attendedDays/$workingDays days',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Employees',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name, position, or ID...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () => _onSearchChanged(''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchFilter() {
    if (_branchesInDistrict.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Branch',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 45,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _branchesInDistrict.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedBranch == null || _selectedBranch == 'All Branches';
                  return _buildBranchChip('All', isSelected, () {
                    _onBranchChanged('All Branches');
                  });
                }
                final branch = _branchesInDistrict[index - 1];
                final isSelected = _selectedBranch == branch;
                return _buildBranchChip(branch, isSelected, () {
                  _onBranchChanged(branch);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? themePrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? themePrimary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
            const SizedBox(height: 20),
            Text(
              'Unable to Load Data',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: themePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No Team Members Found',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            Text(
              'There are no employees in your district yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: themePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading team members...',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_filteredEmployees.isEmpty) {
      if (_searchQuery.isNotEmpty || (_selectedBranch != null && _selectedBranch != 'All Branches')) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No employees found', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No employees in this branch',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedBranch = 'All Branches';
                      _filterEmployees();
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: themePrimary),
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
        );
      }
      return _buildEmptyState();
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _filteredEmployees.length,
        itemBuilder: (context, index) {
          return _buildEmployeeGridItem(_filteredEmployees[index]);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _filteredEmployees.length,
        itemBuilder: (context, index) {
          return _buildEmployeeCard(_filteredEmployees[index]);
        },
      );
    }
  }

  Color _getPerformanceColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    if (score >= 50) return Colors.blue;
    return Colors.red;
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: themePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'District Team',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_managerDistrict != null)
              Text(
                '$_managerDistrict District',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: Colors.white),
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            onPressed: _toggleViewMode,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: Column(
                    children: [
                      // Manager Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: themePrimary.withOpacity(0.1),
                              radius: 20,
                              child: Icon(Icons.person, color: themePrimary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Location',
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _managerName != null
                                        ? '$_managerName · $_managerDistrict'
                                        : 'District: $_managerDistrict',
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: themePrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_filteredEmployees.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: themePrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSearchBar(),
                      _buildBranchFilter(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Team Members',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Updated: ${DateFormat('HH:mm').format(_lastDataUpdate)}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildEmployeeList(),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// EmployeeDetailPage with the exact layout from your image
class EmployeeDetailPage extends StatefulWidget {
  final Map<String, dynamic> employee;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> orders;
  final List<String> attendance;
  final Color themePrimary;

  const EmployeeDetailPage({
    super.key,
    required this.employee,
    required this.stats,
    required this.orders,
    required this.attendance,
    required this.themePrimary,
  });

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;

    
    final joinDate = employee['joining_date'] != null
        ? DateFormat('MMM yyyy').format(DateTime.parse(employee['joining_date']))
        : 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: widget.themePrimary,
        title: Text(
          'My Profile',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: widget.themePrimary.withOpacity(0.1),
                    child: Text(
                      employee['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'E',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: widget.themePrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    employee['full_name']?.toString() ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee['position']?.toString() ?? 'Employee',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: (employee['status']?.toString() ?? '').toLowerCase() == 'active'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      employee['status']?.toString() ?? 'Active',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (employee['status']?.toString() ?? '').toLowerCase() == 'active'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem('Employee ID', employee['emp_id']?.toString() ?? 'N/A'),
                  _buildInfoItem('Department', employee['department']?.toString() ?? 'Not Set'),
                  _buildInfoItem('Since', joinDate),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tab Section
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      indicatorColor: widget.themePrimary,
                      labelColor: widget.themePrimary,
                      unselectedLabelColor: Colors.grey[600],
                      tabs: const [
                        Tab(text: 'Details'),
                        Tab(text: 'Performance'),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      children: [
                        _buildDetailsTab(),
                        _buildPerformanceTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    final employee = widget.employee;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDetailRow(Icons.email, 'Email', employee['email']?.toString() ?? 'N/A'),
                const Divider(),
                _buildDetailRow(Icons.phone, 'Phone', employee['phone']?.toString() ?? 'N/A'),
                const Divider(),
                _buildDetailRow(Icons.business, 'Branch', employee['branch']?.toString() ?? 'N/A'),
                const Divider(),
                _buildDetailRow(Icons.location_city, 'District', employee['district']?.toString() ?? 'N/A'),
                const Divider(),
                _buildDetailRow(Icons.attach_money, 'Salary', 
                  employee['salary'] != null 
                      ? '₹${NumberFormat('#,##,###').format(employee['salary'])}'
                      : 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final stats = widget.stats;
    
    final performanceScore = (stats['performance_score'] is num) 
        ? (stats['performance_score'] as num).toDouble() 
        : 0.0;
    final attendancePercentage = (stats['attendance_percentage'] is num) 
        ? (stats['attendance_percentage'] as num).toDouble() 
        : 0.0;
    final completedOrders = (stats['completed_orders'] is num) 
        ? (stats['completed_orders'] as num).toInt() 
        : 0;
    final totalOrders = (stats['total_orders'] is num) 
        ? (stats['total_orders'] as num).toInt() 
        : 0;
    final attendedDays = (stats['attended_days'] is num) 
        ? (stats['attended_days'] as num).toInt() 
        : 0;
    final workingDays = (stats['working_days'] is num) 
        ? (stats['working_days'] as num).toInt() 
        : 22;
    final totalSales = (stats['total_sales'] is num) 
        ? (stats['total_sales'] as num).toDouble() 
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Month (${DateFormat('MMMM yyyy').format(DateTime.now())})',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricBox('Completed Orders', '$completedOrders', Colors.green),
                    _buildMetricBox('Total Orders', '$totalOrders', Colors.blue),
                    _buildMetricBox('Present Days', '$attendedDays/$workingDays', Colors.orange),
                  ],
                ),
                if (totalSales > 0) ...[
                  const SizedBox(height: 12),
                  _buildMetricBox('Total Sales', '₹${NumberFormat.compact().format(totalSales)}', Colors.purple),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPerformanceBox(
                    'Overall Performance',
                    '${performanceScore.toStringAsFixed(1)}%',
                    _getPerformanceColor(performanceScore),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPerformanceBox(
                    'Attendance',
                    '${attendancePercentage.toStringAsFixed(1)}%',
                    _getAttendanceColor(attendancePercentage),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: widget.themePrimary),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    if (score >= 50) return Colors.blue;
    return Colors.red;
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}


























// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:intl/intl.dart';

// final supabase = Supabase.instance.client;

// class DistrictTeamMembersPage extends StatefulWidget {
//   const DistrictTeamMembersPage({super.key});

//   @override
//   State<DistrictTeamMembersPage> createState() => _DistrictTeamMembersPageState();
// }

// class _DistrictTeamMembersPageState extends State<DistrictTeamMembersPage> {
//   final Color themePrimary = const Color(0xFF2563EB);
//   final Color bg = const Color(0xFFF9FAFB);

//   // Manager's information
//   String? _managerDistrict;
//   String? _managerBranch;
//   String? _managerName;
  
//   bool _isLoading = true;
//   String? _errorMessage;
//   List<Map<String, dynamic>> _employees = [];
//   Map<String, dynamic> _employeeStats = {};
//   Map<String, List<Map<String, dynamic>>> _employeeOrders = {};
//   Map<String, List<String>> _employeeAttendance = {};
  
//   // Branch/Taluka related
//   List<String> _branchesInDistrict = [];
//   String? _selectedBranch;
//   String _searchQuery = '';
//   List<Map<String, dynamic>> _filteredEmployees = [];

//   // View mode
//   bool _isGridView = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadManagerProfileAndEmployees();
//     });
//   }

//   Future<void> _loadManagerProfileAndEmployees() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         setState(() {
//           _errorMessage = 'Please login to access this page.';
//           _isLoading = false;
//         });
//         return;
//       }

//       // Get manager's profile from emp_profile
//       final managerProfile = await supabase
//           .from('emp_profile')
//           .select('district, branch, role, emp_id, full_name, id')
//           .eq('user_id', user.id)
//           .maybeSingle();

//       if (managerProfile == null || managerProfile.isEmpty) {
//         // Try alternative: check by email
//         final altProfile = await supabase
//             .from('emp_profile')
//             .select('district, branch, role, emp_id, full_name, id')
//             .eq('email', user.email ?? '')
//             .eq('role', 'Marketing Manager')
//             .maybeSingle();
        
//         if (altProfile != null && altProfile.isNotEmpty) {
//           _managerDistrict = altProfile['district']?.toString();
//           _managerBranch = altProfile['branch']?.toString();
//           _managerName = altProfile['full_name']?.toString();
//         } else {
//           setState(() {
//             _errorMessage = 'Marketing Manager profile not found. Please complete your profile.';
//             _isLoading = false;
//           });
//           return;
//         }
//       } else {
//         _managerDistrict = managerProfile['district']?.toString();
//         _managerBranch = managerProfile['branch']?.toString();
//         _managerName = managerProfile['full_name']?.toString();
//       }

//       if (_managerDistrict == null || _managerDistrict!.isEmpty) {
//         setState(() {
//           _errorMessage = 'Your profile does not have a district assigned. Please update your profile.';
//           _isLoading = false;
//         });
//         return;
//       }

//       // Fetch employees from the same DISTRICT as manager
//       await _fetchEmployeesByManagerDistrict();
      
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error loading data: ${e.toString()}';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _fetchEmployeesByManagerDistrict() async {
//     if (_managerDistrict == null || _managerDistrict!.isEmpty) {
//       setState(() {
//         _errorMessage = 'Manager district not found in profile';
//         _isLoading = false;
//       });
//       return;
//     }

//     try {
//       final response = await supabase
//           .from('emp_profile')
//           .select('''
//             id,
//             emp_id,
//             full_name,
//             email,
//             phone,
//             position,
//             branch,
//             district,
//             joining_date,
//             status,
//             salary,
//             role,
//             profile_image,
//             created_at
//           ''')
//           .eq('district', _managerDistrict!)
//           .order('full_name', ascending: true);

//       List<Map<String, dynamic>> employeesList = List<Map<String, dynamic>>.from(response);

//       // Filter employees - exclude Manager and Owner
//       final filteredEmployees = employeesList.where((emp) {
//         final role = emp['role']?.toString() ?? '';
//         if (role == 'Marketing Manager' || role == 'Owner') {
//           return false;
//         }
//         return true;
//       }).toList();

//       // Extract unique branches
//       final branchSet = <String>{};
//       for (var emp in filteredEmployees) {
//         final branch = emp['branch']?.toString();
//         if (branch != null && branch.isNotEmpty) {
//           branchSet.add(branch);
//         }
//       }
//       _branchesInDistrict = branchSet.toList()..sort();

//       // Load stats, orders, and attendance for each employee
//       await _loadEmployeeStatsAndOrders(filteredEmployees);
      
//       setState(() {
//         _employees = filteredEmployees;
//         _filteredEmployees = List.from(filteredEmployees);
//         _isLoading = false;
//       });
          
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error fetching employees: ${e.toString()}';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _loadEmployeeStatsAndOrders(List<Map<String, dynamic>> employees) async {
//     for (var employee in employees) {
//       final empId = employee['emp_id']?.toString();
//       final userId = employee['id']?.toString();
      
//       if (empId == null || empId.isEmpty) continue;

//       try {
//         // Get orders from emp_mar_orders table
//         final ordersResponse = await supabase
//             .from('emp_mar_orders')
//             .select('''
//               id,
//               created_at,
//               total_price,
//               status,
//               customer_name,
//               bags,
//               weight_per_bag,
//               weight_unit,
//               price_per_bag,
//               total_weight,
//               feed_category,
//               district
//             ''')
//             .eq('employee_id', empId)
//             .order('created_at', ascending: false)
//             .limit(50);

//         List<Map<String, dynamic>> ordersList = [];
//         ordersList = List<Map<String, dynamic>>.from(ordersResponse);
//               _employeeOrders[empId] = ordersList;

//         // Calculate order statistics for current month
//         final now = DateTime.now();
//         final currentMonth = now.month;
//         final currentYear = now.year;
        
//         // Filter orders for current month
//         final currentMonthOrders = ordersList.where((order) {
//           try {
//             final date = DateTime.parse(order['created_at'] ?? '');
//             return date.year == currentYear && date.month == currentMonth;
//           } catch (e) {
//             return false;
//           }
//         }).toList();

//         final totalOrders = currentMonthOrders.length;
        
//         final completedOrders = currentMonthOrders.where((order) {
//           final status = order['status']?.toString().toLowerCase();
//           return status == 'completed' || status == 'delivered';
//         }).toList();

//         final pendingOrders = currentMonthOrders.where((order) {
//           final status = order['status']?.toString().toLowerCase();
//           return status == 'pending' || status == 'packing' || status == 'ready_for_dispatch';
//         }).toList();

//         // Calculate total sales for current month
//         double totalSales = 0;
//         for (var order in completedOrders) {
//           totalSales += (order['total_price'] as num?)?.toDouble() ?? 0;
//         }

//         // Calculate completion rate for current month
//         final completionRate = totalOrders > 0 
//             ? (completedOrders.length / totalOrders) * 100 
//             : 0.0;

//         // Calculate average order value for current month
//         final avgOrderValue = completedOrders.isNotEmpty 
//             ? totalSales / completedOrders.length 
//             : 0.0;

//         // Get attendance data for current month
//         List<String> attendanceDates = [];
        
//         // Try to get attendance using user_id
//         if (userId != null) {
//           final attendanceResponse = await supabase
//               .from('emp_attendance')
//               .select('date')
//               .eq('employee_id', userId)
//               .gte('date', '$currentYear-${currentMonth.toString().padLeft(2, '0')}-01')
//               .lte('date', '$currentYear-${currentMonth.toString().padLeft(2, '0')}-31')
//               .order('date', ascending: false);

//           attendanceDates = List<String>.from(attendanceResponse.map((e) => e['date'] as String));
//                 } 
        
//         // If no attendance found with user_id, try with emp_id
//         if (attendanceDates.isEmpty) {
//           final attendanceResponse = await supabase
//               .from('emp_attendance')
//               .select('date')
//               .eq('employee_id', empId)
//               .gte('date', '$currentYear-${currentMonth.toString().padLeft(2, '0')}-01')
//               .lte('date', '$currentYear-${currentMonth.toString().padLeft(2, '0')}-31')
//               .order('date', ascending: false);

//           attendanceDates = List<String>.from(attendanceResponse.map((e) => e['date'] as String));
//                 }

//         _employeeAttendance[empId] = attendanceDates;

//         final attendedDays = attendanceDates.length;
        
//         // Calculate working days (excluding weekends)
//         final firstDay = DateTime(currentYear, currentMonth, 1);
//         final lastDay = DateTime(currentYear, currentMonth + 1, 0);
//         int workingDays = 0;
        
//         for (var day = firstDay; 
//              day.isBefore(lastDay) || day.isAtSameMomentAs(lastDay); 
//              day = day.add(const Duration(days: 1))) {
//           if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
//             workingDays++;
//           }
//         }
        
//         final attendancePercentage = workingDays > 0 ? (attendedDays / workingDays) * 100 : 0.0;

//         // Calculate work quality score based on average order value (max 5000 = 100%)
//         double workQualityScore = 0.0;
//         if (completedOrders.isNotEmpty) {
//           workQualityScore = (avgOrderValue / 5000 * 100).clamp(0.0, 100.0);
//         }

//         // Calculate team collaboration score (based on task completion rate)
//         final teamCollaborationScore = 70.0 + (completionRate / 100 * 20).clamp(0.0, 20.0);

//         // Calculate overall performance score with weighted factors
//         final performanceScore = (
//           completionRate * 0.35 +        // 35% weight to task completion
//           workQualityScore * 0.25 +      // 25% weight to work quality
//           attendancePercentage * 0.25 +   // 25% weight to attendance
//           teamCollaborationScore * 0.15   // 15% weight to collaboration
//         ).clamp(0.0, 100.0);

//         _employeeStats[empId] = {
//           'total_orders': totalOrders,
//           'completed_orders': completedOrders.length,
//           'pending_orders': pendingOrders.length,
//           'total_sales': totalSales,
//           'attendance_percentage': attendancePercentage,
//           'attended_days': attendedDays,
//           'working_days': workingDays,
//           'completion_rate': completionRate,
//           'work_quality': workQualityScore,
//           'team_collaboration': teamCollaborationScore,
//           'performance_score': performanceScore,
//           'avg_order_value': avgOrderValue,
//         };

//         print('📊 Stats for ${employee['full_name']}:');
//         print('  Performance: ${performanceScore.toStringAsFixed(1)}%');
//         print('  Attendance: $attendedDays/$workingDays days');
//         print('  Orders: $completedOrders/$totalOrders completed');
//         print('  Sales: ₹$totalSales');

//       } catch (e) {
//         print('Error loading stats for employee $empId: $e');
//         _employeeStats[empId] = {
//           'total_orders': 0,
//           'completed_orders': 0,
//           'pending_orders': 0,
//           'total_sales': 0.0,
//           'attendance_percentage': 0.0,
//           'attended_days': 0,
//           'working_days': 22,
//           'completion_rate': 0.0,
//           'work_quality': 0.0,
//           'team_collaboration': 70.0,
//           'performance_score': 0.0,
//           'avg_order_value': 0.0,
//         };
//         _employeeAttendance[empId] = [];
//       }
//     }
//   }

//   void _filterEmployees() {
//     List<Map<String, dynamic>> filtered = List.from(_employees);

//     // Apply branch filter
//     if (_selectedBranch != null && _selectedBranch!.isNotEmpty && _selectedBranch != 'All Branches') {
//       filtered = filtered.where((emp) {
//         return emp['branch']?.toString() == _selectedBranch;
//       }).toList();
//     }

//     // Apply search filter
//     if (_searchQuery.isNotEmpty) {
//       filtered = filtered.where((employee) {
//         final name = employee['full_name']?.toString().toLowerCase() ?? '';
//         final position = employee['position']?.toString().toLowerCase() ?? '';
//         final empId = employee['emp_id']?.toString().toLowerCase() ?? '';
//         final email = employee['email']?.toString().toLowerCase() ?? '';
//         final phone = employee['phone']?.toString().toLowerCase() ?? '';
//         final branch = employee['branch']?.toString().toLowerCase() ?? '';

//         return name.contains(_searchQuery.toLowerCase()) ||
//               position.contains(_searchQuery.toLowerCase()) ||
//               empId.contains(_searchQuery.toLowerCase()) ||
//               email.contains(_searchQuery.toLowerCase()) ||
//               phone.contains(_searchQuery.toLowerCase()) ||
//               branch.contains(_searchQuery.toLowerCase());
//       }).toList();
//     }

//     setState(() {
//       _filteredEmployees = filtered;
//     });
//   }

//   void _onSearchChanged(String query) {
//     setState(() {
//       _searchQuery = query;
//     });
//     _filterEmployees();
//   }

//   void _onBranchChanged(String? branch) {
//     setState(() {
//       _selectedBranch = branch;
//     });
//     _filterEmployees();
//   }

//   void _toggleViewMode() {
//     setState(() {
//       _isGridView = !_isGridView;
//     });
//   }

//   Future<void> _refreshData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//       _selectedBranch = null;
//       _searchQuery = '';
//       _employeeStats.clear();
//       _employeeOrders.clear();
//       _employeeAttendance.clear();
//       _branchesInDistrict.clear();
//       _filteredEmployees.clear();
//     });
//     await _loadManagerProfileAndEmployees();
//   }

//   void _viewEmployeeDetails(Map<String, dynamic> employee) {
//     final empId = employee['emp_id']?.toString() ?? '';
//     final stats = _employeeStats[empId] ?? {};
//     final orders = _employeeOrders[empId] ?? [];
//     final attendance = _employeeAttendance[empId] ?? [];

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => EmployeeDetailPage(
//           employee: employee,
//           stats: stats,
//           orders: orders,
//           attendance: attendance,
//           themePrimary: themePrimary,
//         ),
//       ),
//     );
//   }

//   Widget _buildEmployeeCard(Map<String, dynamic> employee) {
//     final empId = employee['emp_id']?.toString() ?? '';
//     final stats = _employeeStats[empId] ?? {};
    
//     // Check if employee is in the same branch as manager
//     final bool sameBranch = employee['branch']?.toString() == _managerBranch;
    
//     // Get status and color
//     final status = employee['status']?.toString() ?? 'Inactive';
//     final isActive = status.toLowerCase() == 'active';
//     final statusColor = isActive ? Colors.green : Colors.orange;
    
//     // Safely convert values to avoid type errors
//     final performanceValue = (stats['performance_score'] is num) 
//         ? (stats['performance_score'] as num).toDouble() 
//         : 0.0;
//     final attendanceValue = (stats['attendance_percentage'] is num) 
//         ? (stats['attendance_percentage'] as num).toDouble() 
//         : 0.0;
//     final totalOrders = (stats['total_orders'] is num) 
//         ? (stats['total_orders'] as num).toInt() 
//         : 0;
//     final totalSales = (stats['total_sales'] is num) 
//         ? (stats['total_sales'] as num).toDouble() 
//         : 0.0;
    
//     return GestureDetector(
//       onTap: () => _viewEmployeeDetails(employee),
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: sameBranch ? Colors.green.withOpacity(0.5) : Colors.grey[200]!,
//             width: sameBranch ? 2 : 1,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Row
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Profile Avatar
//                 CircleAvatar(
//                   backgroundColor: sameBranch
//                       ? themePrimary.withOpacity(0.1)
//                       : themePrimary.withOpacity(0.1),
//                   radius: 24,
//                   child: Icon(
//                     Icons.person,
//                     color: sameBranch ? themePrimary : themePrimary,
//                     size: 20,
//                   ),
//                 ),
                
//                 const SizedBox(width: 12),
                
//                 // Name and Position
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   employee['full_name']?.toString() ?? 'Unknown',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.grey[900],
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 const SizedBox(height: 2),
//                                 Text(
//                                   employee['position']?.toString() ?? 'Employee',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 13,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
                          
//                           // Same Branch Badge
//                         ],
//                       ),
                      
//                       const SizedBox(height: 6),
                      
//                       // Employee ID
//                       Row(
//                         children: [
//                           Icon(Icons.badge, size: 12, color: Colors.grey[500]),
//                           const SizedBox(width: 4),
//                           Text(
//                             'ID: ${employee['emp_id']?.toString() ?? 'N/A'}',
//                             style: GoogleFonts.poppins(
//                               fontSize: 11,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Status Badge
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   decoration: BoxDecoration(
//                     color: statusColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: statusColor.withOpacity(0.3)),
//                   ),
//                   child: Text(
//                     status,
//                     style: GoogleFonts.poppins(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                       color: statusColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 12),
            
//             // Performance Metrics Row
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   // Performance
//                   _buildMetricColumn(
//                     'Performance',
//                     '${performanceValue.toStringAsFixed(1)}%',
//                     Icons.trending_up,
//                     Colors.blue,
//                   ),
                  
//                   // Attendance
//                   _buildMetricColumn(
//                     'Attendance',
//                     '${attendanceValue.toStringAsFixed(1)}%',
//                     Icons.calendar_today,
//                     Colors.green,
//                   ),
                  
//                   // Orders
//                   _buildMetricColumn(
//                     'Orders',
//                     '$totalOrders',
//                     Icons.shopping_cart,
//                     Colors.orange,
//                   ),
                  
//                   // Sales
//                   _buildMetricColumn(
//                     'Sales',
//                     '₹${totalSales.toStringAsFixed(0)}',
//                     Icons.currency_rupee,
//                     Colors.purple,
//                   ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 12),
            
//             // Location and Contact Info
//             Row(
//               children: [
//                 // Location Info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               employee['district']?.toString() ?? 'No District',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey[800],
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           Icon(Icons.business, size: 14, color: Colors.grey[600]),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               employee['branch']?.toString() ?? 'No Branch',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey[800],
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 const SizedBox(width: 16),
                
//                 // Contact Info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.email, size: 14, color: Colors.grey[600]),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               employee['email']?.toString() ?? 'No Email',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 color: Colors.grey[700],
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           Icon(Icons.phone, size: 14, color: Colors.grey[600]),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               employee['phone']?.toString() ?? 'No Phone',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 color: Colors.grey[700],
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 8),
            
         
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMetricColumn(String label, String value, IconData icon, Color color) {
//     return Column(
//       children: [
//         Icon(icon, size: 16, color: color),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: GoogleFonts.poppins(
//             fontSize: 13,
//             fontWeight: FontWeight.w700,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           label,
//           style: GoogleFonts.poppins(
//             fontSize: 10,
//             color: Colors.grey[600],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEmployeeGridItem(Map<String, dynamic> employee) {
//     final empId = employee['emp_id']?.toString() ?? '';
//     final stats = _employeeStats[empId] ?? {};
//     final bool sameBranch = employee['branch']?.toString() == _managerBranch;
//     final status = employee['status']?.toString() ?? 'Inactive';
//     final isActive = status.toLowerCase() == 'active';
//     final statusColor = isActive ? Colors.green : Colors.orange;
    
//     final performanceValue = (stats['performance_score'] is num) 
//         ? (stats['performance_score'] as num).toDouble() 
//         : 0.0;
//     final attendanceValue = (stats['attendance_percentage'] is num) 
//         ? (stats['attendance_percentage'] as num).toDouble() 
//         : 0.0;
//     final totalOrders = (stats['total_orders'] is num) 
//         ? (stats['total_orders'] as num).toInt() 
//         : 0;

//     return GestureDetector(
//       onTap: () => _viewEmployeeDetails(employee),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: sameBranch ? Colors.grey[200]! : Colors.grey[200]!,
//             width: sameBranch ? 2 : 1,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 6,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Profile and Name Row
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: sameBranch
//                         ? themePrimary.withOpacity(0.1)
//                         : themePrimary.withOpacity(0.1),
//                     radius: 20,
//                     child: Icon(
//                       Icons.person,
//                       color: sameBranch ? themePrimary : themePrimary,
//                       size: 18,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           employee['full_name']?.toString() ?? 'Unknown',
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                           maxLines: 1,
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           employee['position']?.toString() ?? 'Employee',
//                           style: GoogleFonts.poppins(
//                             fontSize: 11,
//                             color: Colors.grey[600],
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: 8),
              
//               // Status and Branch
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Text(
//                       status,
//                       style: GoogleFonts.poppins(
//                         fontSize: 9,
//                         fontWeight: FontWeight.w600,
//                         color: statusColor,
//                       ),
//                     ),
//                   ),
//                   const Spacer(),
//                   Icon(Icons.business, size: 10, color: Colors.grey[600]),
//                   const SizedBox(width: 4),
//                   Text(
//                     employee['branch']?.toString() ?? 'No Branch',
//                     style: GoogleFonts.poppins(
//                       fontSize: 9,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: 8),
              
//               // Metrics Row
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     Column(
//                       children: [
//                         Text(
//                           '${performanceValue.toStringAsFixed(0)}%',
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.blue,
//                           ),
//                         ),
//                         Text(
//                           'Perf',
//                           style: GoogleFonts.poppins(
//                             fontSize: 9,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                     Column(
//                       children: [
//                         Text(
//                           '${attendanceValue.toStringAsFixed(0)}%',
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.green,
//                           ),
//                         ),
//                         Text(
//                           'Att',
//                           style: GoogleFonts.poppins(
//                             fontSize: 9,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                     Column(
//                       children: [
//                         Text(
//                           '$totalOrders',
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.orange,
//                           ),
//                         ),
//                         Text(
//                           'Orders',
//                           style: GoogleFonts.poppins(
//                             fontSize: 9,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
              
//               const SizedBox(height: 8),
              
//               // Contact Info
//               Row(
//                 children: [
//                   Icon(Icons.phone, size: 10, color: Colors.grey[600]),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       employee['phone']?.toString() ?? 'No Phone',
//                       style: GoogleFonts.poppins(
//                         fontSize: 10,
//                         color: Colors.grey[700],
//                       ),
//                       maxLines: 1,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Search Employees',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[800],
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextField(
//             onChanged: _onSearchChanged,
//             decoration: InputDecoration(
//               hintText: 'Search by name, position, ID, email, phone, or branch...',
//               prefixIcon: const Icon(Icons.search, color: Colors.grey),
//               suffixIcon: _searchQuery.isNotEmpty
//                   ? IconButton(
//                       icon: const Icon(Icons.clear, color: Colors.grey),
//                       onPressed: () => _onSearchChanged(''),
//                     )
//                   : null,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.grey[300]!),
//               ),
//               filled: true,
//               fillColor: Colors.white,
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 20,
//                 vertical: 16,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.grey[300]!),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: themePrimary, width: 2),
//               ),
//             ),
//             style: GoogleFonts.poppins(fontSize: 15),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBranchFilter() {
//     if (_branchesInDistrict.isEmpty) return const SizedBox();

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Text(
//                 'Filter by Branch',
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[800],
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 '${_branchesInDistrict.length} branches',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           SizedBox(
//             height: 50,
//             child: ListView.separated(
//               scrollDirection: Axis.horizontal,
//               itemCount: _branchesInDistrict.length + 1,
//               separatorBuilder: (context, index) => const SizedBox(width: 8),
//               itemBuilder: (context, index) {
//                 if (index == 0) {
//                   final isSelected = _selectedBranch == null || _selectedBranch == 'All Branches';
//                   return _buildBranchChip('All Branches', isSelected, () {
//                     _onBranchChanged('All Branches');
//                   });
//                 }
//                 final branch = _branchesInDistrict[index - 1];
//                 final isSelected = _selectedBranch == branch;
//                 return _buildBranchChip(branch, isSelected, () {
//                   _onBranchChanged(branch);
//                 });
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBranchChip(String label, bool selected, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected ? themePrimary : Colors.white,
//           borderRadius: BorderRadius.circular(25),
//           border: Border.all(
//             color: selected ? themePrimary : Colors.grey[300]!,
//             width: 1.5,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(selected ? 0.1 : 0.05),
//               blurRadius: selected ? 8 : 4,
//               offset: Offset(0, selected ? 2 : 1),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (selected)
//               Icon(
//                 Icons.check_circle,
//                 color: Colors.white,
//                 size: 14,
//               ),
//             if (selected) const SizedBox(width: 6),
//             Text(
//               label,
//               style: GoogleFonts.poppins(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//                 color: selected ? Colors.white : Colors.grey[700],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
//             const SizedBox(height: 20),
//             Text(
//               'Unable to Load Data',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[800],
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               _errorMessage ?? 'An error occurred',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: _refreshData,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: themePrimary,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 12,
//                 ),
//               ),
//               icon: const Icon(Icons.refresh, size: 20),
//               label: const Text('Try Again'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.group_off_rounded, size: 72, color: Colors.grey[400]),
//             const SizedBox(height: 20),
//             Text(
//               'No Team Members Found',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[800],
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               _managerDistrict != null
//                   ? 'There are no employees in your district ($_managerDistrict) yet.'
//                   : 'District information not available.',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: _refreshData,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: themePrimary,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 14,
//                 ),
//               ),
//               icon: const Icon(Icons.refresh, size: 20),
//               label: const Text('Refresh'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
//             strokeWidth: 2.5,
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Loading team members...',
//             style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
//           ),
//           if (_managerDistrict != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Text(
//                 'District: $_managerDistrict',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[500],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmployeeList() {
//     if (_filteredEmployees.isEmpty) {
//       if (_searchQuery.isNotEmpty || (_selectedBranch != null && _selectedBranch != 'All Branches')) {
//         return Center(
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.search_off,
//                   size: 64,
//                   color: Colors.grey[400],
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No employees found',
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   _searchQuery.isNotEmpty
//                       ? 'No results for "$_searchQuery"'
//                       : 'No employees in $_selectedBranch branch',
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[500],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _searchQuery = '';
//                       _selectedBranch = 'All Branches';
//                       _filterEmployees();
//                     });
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: themePrimary,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('Clear Filters'),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }
//       return _buildEmptyState();
//     }

//     if (_isGridView) {
//       return GridView.builder(
//         padding: const EdgeInsets.all(16),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 0.85,
//         ),
//         itemCount: _filteredEmployees.length,
//         itemBuilder: (context, index) {
//           return _buildEmployeeGridItem(_filteredEmployees[index]);
//         },
//       );
//     } else {
//       return ListView.builder(
//         padding: const EdgeInsets.only(bottom: 20),
//         itemCount: _filteredEmployees.length,
//         itemBuilder: (context, index) {
//           return _buildEmployeeCard(_filteredEmployees[index]);
//         },
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         iconTheme: const IconThemeData(color: Colors.white),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'District Team',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//             if (_managerDistrict != null)
//               Text(
//                 '$_managerDistrict District',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.white.withOpacity(0.8),
//                 ),
//               ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(
//               _isGridView ? Icons.list : Icons.grid_view,
//               color: Colors.white,
//             ),
//             tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
//             onPressed: _toggleViewMode,
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             tooltip: 'Refresh',
//             onPressed: _refreshData,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? _buildLoadingState()
//           : _errorMessage != null
//               ? _buildErrorState()
//               : RefreshIndicator(
//                   onRefresh: _refreshData,
//                   child: Column(
//                     children: [
//                       // Manager Info Card
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           border: Border(
//                             bottom: BorderSide(
//                               color: Colors.grey[200]!,
//                               width: 1,
//                             ),
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             CircleAvatar(
//                               backgroundColor: themePrimary.withOpacity(0.1),
//                               radius: 20,
//                               child: Icon(
//                                 Icons.person,
//                                 color: themePrimary,
//                                 size: 18,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Your Location',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.grey[800],
//                                     ),
//                                   ),
//                                   const SizedBox(height: 2),
//                                   Text(
//                                     _managerName != null
//                                         ? '$_managerName · $_managerDistrict'
//                                         : 'District: $_managerDistrict',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 12,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 6,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: themePrimary.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Column(
//                                 children: [
//                                   Text(
//                                     _isGridView ? 'Grid' : 'List',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w600,
//                                       color: themePrimary,
//                                     ),
//                                   ),
//                                   Text(
//                                     '${_filteredEmployees.length}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w700,
//                                       color: themePrimary,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
                      
//                       // Filters Section
//                       _buildSearchBar(),
//                       _buildBranchFilter(),
                      
//                       // Results Header
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           border: Border(
//                             top: BorderSide(color: Colors.grey[200]!),
//                             bottom: BorderSide(color: Colors.grey[200]!),
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             Text(
//                               _selectedBranch != null && _selectedBranch != 'All Branches'
//                                   ? '$_selectedBranch Branch'
//                                   : 'All Branches',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.grey[800],
//                               ),
//                             ),
//                             const Spacer(),
//                             Text(
//                               '${_filteredEmployees.length} of ${_employees.length} employees',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
                      
//                       // Employee List/Grid
//                       Expanded(
//                         child: _buildEmployeeList(),
//                       ),
//                     ],
//                   ),
//                 ),
//     );
//   }
// }

// // EmployeeDetailPage with complete performance data
// class EmployeeDetailPage extends StatefulWidget {
//   final Map<String, dynamic> employee;
//   final Map<String, dynamic> stats;
//   final List<Map<String, dynamic>> orders;
//   final List<String> attendance;
//   final Color themePrimary;

//   const EmployeeDetailPage({
//     super.key,
//     required this.employee,
//     required this.stats,
//     required this.orders,
//     required this.attendance,
//     required this.themePrimary,
//   });

//   @override
//   State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
// }

// class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
//   @override
//   Widget build(BuildContext context) {
//     final employee = widget.employee;
//     final stats = widget.stats;

//     // Safely convert values
//     final performanceScore = (stats['performance_score'] is num) 
//         ? (stats['performance_score'] as num).toDouble() 
//         : 0.0;
//     final attendancePercentage = (stats['attendance_percentage'] is num) 
//         ? (stats['attendance_percentage'] as num).toDouble() 
//         : 0.0;
//     final completionRate = (stats['completion_rate'] is num) 
//         ? (stats['completion_rate'] as num).toDouble() 
//         : 0.0;
//     final totalSales = (stats['total_sales'] is num) 
//         ? (stats['total_sales'] as num).toDouble() 
//         : 0.0;
//     final avgOrderValue = (stats['avg_order_value'] is num) 
//         ? (stats['avg_order_value'] as num).toDouble() 
//         : 0.0;
//     final workQuality = (stats['work_quality'] is num) 
//         ? (stats['work_quality'] as num).toDouble() 
//         : 0.0;
//     final teamCollaboration = (stats['team_collaboration'] is num) 
//         ? (stats['team_collaboration'] as num).toDouble() 
//         : 0.0;
//     final attendedDays = (stats['attended_days'] is num) 
//         ? (stats['attended_days'] as num).toInt() 
//         : 0;
//     final workingDays = (stats['working_days'] is num) 
//         ? (stats['working_days'] as num).toInt() 
//         : 22;
//     final totalOrders = (stats['total_orders'] is num) 
//         ? (stats['total_orders'] as num).toInt() 
//         : 0;
//     final completedOrders = (stats['completed_orders'] is num) 
//         ? (stats['completed_orders'] as num).toInt() 
//         : 0;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FAFB),
//       appBar: AppBar(
//         backgroundColor: widget.themePrimary,
//         title: Text(
//           employee['full_name']?.toString() ?? 'Employee Details',
//           style: const TextStyle(color: Colors.white),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Profile Card
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 50,
//                       backgroundColor: widget.themePrimary.withOpacity(0.1),
//                       child: Icon(
//                         Icons.person,
//                         color: widget.themePrimary,
//                         size: 40,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       employee['full_name']?.toString() ?? 'Unknown',
//                       style: GoogleFonts.poppins(
//                         fontSize: 22,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[900],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       employee['position']?.toString() ?? 'Employee',
//                       style: GoogleFonts.poppins(
//                         fontSize: 16,
//                         color: widget.themePrimary,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: (employee['status']?.toString() ?? '')
//                                         .toLowerCase() ==
//                                     'active'
//                                 ? Colors.green.withOpacity(0.1)
//                                 : Colors.orange.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             employee['status']?.toString() ?? 'Inactive',
//                             style: GoogleFonts.poppins(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: (employee['status']?.toString() ?? '')
//                                           .toLowerCase() ==
//                                       'active'
//                                   ? Colors.green
//                                   : Colors.orange,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[100],
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             'ID: ${employee['emp_id']?.toString() ?? 'N/A'}',
//                             style: GoogleFonts.poppins(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 16),
            
//             // Performance Metrics Card
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Performance Metrics',
//                       style: GoogleFonts.poppins(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Overall Performance
//                     _buildMetricDetail(
//                       'Overall Performance',
//                       '${performanceScore.toStringAsFixed(1)}%',
//                       Icons.stars,
//                       _getPerformanceColor(performanceScore),
//                     ),
//                     const Divider(),
                    
//                     // Attendance
//                     _buildMetricDetail(
//                       'Attendance',
//                       '${attendancePercentage.toStringAsFixed(1)}%',
//                       Icons.calendar_today,
//                       _getAttendanceColor(attendancePercentage),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '$attendedDays days present out of $workingDays working days',
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const Divider(),
                    
//                     // Orders Performance
//                     _buildMetricDetail(
//                       'Task Completion',
//                       '${completionRate.toStringAsFixed(1)}%',
//                       Icons.task_alt,
//                       Colors.blue,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '$completedOrders completed out of $totalOrders total orders',
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const Divider(),
                    
//                     // Sales Performance
//                     _buildMetricDetail(
//                       'Total Sales',
//                       '₹${totalSales.toStringAsFixed(0)}',
//                       Icons.currency_rupee,
//                       Colors.purple,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Avg order value: ₹${avgOrderValue.toStringAsFixed(0)}',
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const Divider(),
                    
//                     // Work Quality
//                     _buildMetricDetail(
//                       'Work Quality',
//                       '${workQuality.toStringAsFixed(1)}%',
//                       Icons.star ,
//                       Colors.teal,
//                     ),
//                     const Divider(),
                    
//                     // Team Collaboration
//                     _buildMetricDetail(
//                       'Team Collaboration',
//                       '${teamCollaboration.toStringAsFixed(1)}%',
//                       Icons.groups,
//                       Colors.amber,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 16),
            
//             // Recent Orders Card
//             if (widget.orders.isNotEmpty)
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Recent Orders',
//                             style: GoogleFonts.poppins(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                           Text(
//                             '$totalOrders total',
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
                      
//                       ...widget.orders.take(5).map((order) => _buildOrderItem(order)),
                      
//                       if (widget.orders.length > 5)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8),
//                           child: Center(
//                             child: Text(
//                               '+ ${widget.orders.length - 5} more orders',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 color: Colors.grey[600],
//                                 fontStyle: FontStyle.italic,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
            
//             const SizedBox(height: 16),
            
//             // Details Card
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Employee Details',
//                       style: GoogleFonts.poppins(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildDetailRow(Icons.email, 'Email', employee['email']?.toString() ?? 'N/A'),
//                     const Divider(),
//                     _buildDetailRow(Icons.phone, 'Phone', employee['phone']?.toString() ?? 'N/A'),
//                     const Divider(),
//                     _buildDetailRow(Icons.business, 'Branch', employee['branch']?.toString() ?? 'N/A'),
//                     const Divider(),
//                     _buildDetailRow(Icons.location_city, 'District', employee['district']?.toString() ?? 'N/A'),
//                     const Divider(),
//                     _buildDetailRow(Icons.calendar_today, 'Joining Date', 
//                       employee['joining_date'] != null 
//                           ? DateFormat('dd MMM yyyy').format(DateTime.parse(employee['joining_date']))
//                           : 'N/A'),
//                     const Divider(),
//                     _buildDetailRow(Icons.attach_money, 'Salary', 
//                       employee['salary'] != null 
//                           ? '₹${NumberFormat('#,##,###').format(employee['salary'])}'
//                           : 'N/A'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMetricDetail(String label, String value, IconData icon, Color color) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: color, size: 20),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 value,
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildOrderItem(Map<String, dynamic> order) {
//     final status = order['status']?.toString() ?? 'pending';
//     final statusColor = _getOrderStatusColor(status);
    
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 order['customer_name'] ?? 'Unknown Customer',
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[800],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: statusColor.withOpacity(0.3)),
//                 ),
//                 child: Text(
//                   status.toUpperCase(),
//                   style: GoogleFonts.poppins(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w600,
//                     color: statusColor,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '${order['bags'] ?? 0} bags · ₹${order['total_price'] ?? 0}',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               Text(
//                 DateFormat('dd MMM').format(
//                   DateTime.parse(order['created_at'] ?? DateTime.now().toIso8601String())
//                 ),
//                 style: GoogleFonts.poppins(
//                   fontSize: 11,
//                   color: Colors.grey[500],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         children: [
//           Icon(icon, size: 24, color: widget.themePrimary),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getPerformanceColor(double score) {
//     if (score >= 85) return Colors.green;
//     if (score >= 70) return Colors.orange;
//     if (score >= 50) return Colors.blue;
//     return Colors.red;
//   }

//   Color _getAttendanceColor(double percentage) {
//     if (percentage >= 90) return Colors.green;
//     if (percentage >= 75) return Colors.blue;
//     if (percentage >= 60) return Colors.orange;
//     return Colors.red;
//   }

//   Color _getOrderStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'completed':
//       case 'delivered':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'cancelled':
//         return Colors.red;
//       case 'packing':
//         return Colors.blue;
//       case 'ready_for_dispatch':
//         return Colors.purple;
//       case 'dispatched':
//         return Colors.indigo;
//       default:
//         return Colors.grey;
//     }
//   }
// }











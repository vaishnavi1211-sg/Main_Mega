import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class DistrictTeamMembersPage extends StatefulWidget {
  const DistrictTeamMembersPage({super.key});

  @override
  State<DistrictTeamMembersPage> createState() => _DistrictTeamMembersPageState();
}

class _DistrictTeamMembersPageState extends State<DistrictTeamMembersPage> {
  final Color themePrimary = const Color(0xFF2563EB);
  final Color bg = const Color(0xFFF9FAFB);

  // Manager's information
  String? _managerDistrict;
  String? _managerBranch;
  String? _managerName;
  
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic> _employeeStats = {};
  Map<String, List<Map<String, dynamic>>> _employeeOrders = {};
  
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
    });
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

      // Get manager's profile from emp_profile
      final managerProfile = await supabase
          .from('emp_profile')
          .select('district, branch, role, emp_id, full_name')
          .eq('user_id', user.id)
          .maybeSingle();

      if (managerProfile == null || managerProfile.isEmpty) {
        // Try alternative: check by email
        final altProfile = await supabase
            .from('emp_profile')
            .select('district, branch, role, emp_id, full_name')
            .eq('email', user.email ?? '')
            .eq('role', 'Marketing Manager')
            .maybeSingle();
        
        if (altProfile != null && altProfile.isNotEmpty) {
          _managerDistrict = altProfile['district']?.toString();
          _managerBranch = altProfile['branch']?.toString();
          _managerName = altProfile['full_name']?.toString();
        } else {
          setState(() {
            _errorMessage = 'Marketing Manager profile not found. Please complete your profile.';
            _isLoading = false;
          });
          return;
        }
      } else {
        _managerDistrict = managerProfile['district']?.toString();
        _managerBranch = managerProfile['branch']?.toString();
        _managerName = managerProfile['full_name']?.toString();
      }

      if (_managerDistrict == null || _managerDistrict!.isEmpty) {
        setState(() {
          _errorMessage = 'Your profile does not have a district assigned. Please update your profile.';
          _isLoading = false;
        });
        return;
      }

      // Fetch employees from the same DISTRICT as manager
      await _fetchEmployeesByManagerDistrict();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEmployeesByManagerDistrict() async {
    if (_managerDistrict == null || _managerDistrict!.isEmpty) {
      setState(() {
        _errorMessage = 'Manager district not found in profile';
        _isLoading = false;
      });
      return;
    }

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
            performance,
            attendance,
            profile_image,
            created_at
          ''')
          .eq('district', _managerDistrict!)
          .order('full_name', ascending: true);

      List<Map<String, dynamic>> employeesList = List<Map<String, dynamic>>.from(response);

      // Filter active employees only - Use broader filter to include all
      final activeEmployees = employeesList.where((emp) {
        final role = emp['role']?.toString() ?? '';
        
        // Exclude only Marketing Manager and Owner roles
        if (role == 'Marketing Manager' || role == 'Owner') {
          return false;
        }
        
        // Include all other roles regardless of status for now
        return true;
      }).toList();

      // Extract unique branches from employees in this district
      final branchSet = <String>{};
      for (var emp in activeEmployees) {
        final branch = emp['branch']?.toString();
        if (branch != null && branch.isNotEmpty) {
          branchSet.add(branch);
        }
      }
      _branchesInDistrict = branchSet.toList()..sort();

      // Load stats and orders for each employee
      await _loadEmployeeStats(activeEmployees);
      
      setState(() {
        _employees = activeEmployees;
        _filteredEmployees = List.from(activeEmployees);
        _isLoading = false;
      });
          
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching employees: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployeeStats(List<Map<String, dynamic>> employees) async {
    for (var employee in employees) {
      final empId = employee['emp_id']?.toString();
      if (empId == null || empId.isEmpty) continue;

      try {
        // Get total orders count
        final ordersResponse = await supabase
            .from('orders')
            .select('id, order_date, total_amount, status, customer_name')
            .eq('emp_id', empId)
            .order('order_date', ascending: false)
            .limit(10);

        final ordersList = List<Map<String, dynamic>>.from(ordersResponse);
        _employeeOrders[empId] = ordersList;

        // Calculate statistics
        final completedOrders = ordersList.where((order) {
          final status = order['status']?.toString().toLowerCase();
          return status == 'completed' || status == 'delivered' || status == 'paid';
        }).toList();

        final totalSales = completedOrders.fold<double>(
          0, 
          (sum, order) => sum + (double.tryParse(order['total_amount'].toString()) ?? 0)
        );

        final attendance = double.tryParse(employee['attendance']?.toString() ?? '0') ?? 0;
        final performance = double.tryParse(employee['performance']?.toString() ?? '0') ?? 0;
        final salary = double.tryParse(employee['salary']?.toString() ?? '0') ?? 0;

        // Get attendance data for the employee
        final attendanceResponse = await supabase
            .from('emp_attendance')
            .select('*')
            .eq('emp_id', empId)
            .gte('date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
            .order('date', ascending: false);

        final attendanceList = List<Map<String, dynamic>>.from(attendanceResponse);
        final presentDays = attendanceList.where((a) => a['status'] == 'present').length;

        _employeeStats[empId] = {
          'total_orders': ordersList.length,
          'completed_orders': completedOrders.length,
          'total_sales': totalSales,
          'attendance': attendance,
          'performance': performance,
          'salary': salary,
          'present_days': presentDays,
          'total_days_checked': attendanceList.length,
          'attendance_percentage': attendanceList.isNotEmpty ? (presentDays / attendanceList.length * 100) : 0,
          'avg_order_value': ordersList.isNotEmpty ? totalSales / ordersList.length : 0,
          'completion_rate': ordersList.isNotEmpty ? (completedOrders.length / ordersList.length * 100) : 0,
        };

      } catch (e) {
        _employeeStats[empId] = {
          'total_orders': 0,
          'completed_orders': 0,
          'total_sales': 0,
          'attendance': 0,
          'performance': 0,
          'salary': 0,
          'present_days': 0,
          'total_days_checked': 0,
          'attendance_percentage': 0,
          'avg_order_value': 0,
          'completion_rate': 0,
        };
      }
    }
  }

  void _filterEmployees() {
    List<Map<String, dynamic>> filtered = List.from(_employees);

    // Apply branch filter
    if (_selectedBranch != null && _selectedBranch!.isNotEmpty && _selectedBranch != 'All Branches') {
      filtered = filtered.where((emp) {
        return emp['branch']?.toString() == _selectedBranch;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((employee) {
        final name = employee['full_name']?.toString().toLowerCase() ?? '';
        final position = employee['position']?.toString().toLowerCase() ?? '';
        final empId = employee['emp_id']?.toString().toLowerCase() ?? '';
        final email = employee['email']?.toString().toLowerCase() ?? '';
        final phone = employee['phone']?.toString().toLowerCase() ?? '';
        final branch = employee['branch']?.toString().toLowerCase() ?? '';

        return name.contains(_searchQuery.toLowerCase()) ||
              position.contains(_searchQuery.toLowerCase()) ||
              empId.contains(_searchQuery.toLowerCase()) ||
              email.contains(_searchQuery.toLowerCase()) ||
              phone.contains(_searchQuery.toLowerCase()) ||
              branch.contains(_searchQuery.toLowerCase());
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

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedBranch = null;
      _searchQuery = '';
      _employeeStats.clear();
      _employeeOrders.clear();
      _branchesInDistrict.clear();
      _filteredEmployees.clear();
    });
    await _loadManagerProfileAndEmployees();
  }

  void _viewEmployeeDetails(Map<String, dynamic> employee) {
    final empId = employee['emp_id']?.toString() ?? '';
    final stats = _employeeStats[empId] ?? {};
    final orders = _employeeOrders[empId] ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailPage1(
          employee: employee,
          stats: stats,
          orders: orders,
          themePrimary: themePrimary,
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final empId = employee['emp_id']?.toString() ?? '';
    final stats = _employeeStats[empId] ?? {};
    
    // Check if employee is in the same branch as manager
    final bool sameBranch = employee['branch']?.toString() == _managerBranch;
    
    // Get status and color
    final status = employee['status']?.toString() ?? 'Inactive';
    final isActive = status.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : Colors.orange;
    
    return GestureDetector(
      onTap: () => _viewEmployeeDetails(employee),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sameBranch ? Colors.green.withOpacity(0.5) : Colors.grey[200]!,
            width: sameBranch ? 2 : 1,
          ),
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
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Avatar
                CircleAvatar(
                  backgroundColor: sameBranch
                      ? Colors.green.withOpacity(0.1)
                      : themePrimary.withOpacity(0.1),
                  radius: 24,
                  child: Icon(
                    Icons.person,
                    color: sameBranch ? Colors.green : themePrimary,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Name and Position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Same Branch Badge
                          if (sameBranch)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Same Branch',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Employee ID
                      Row(
                        children: [
                          Icon(Icons.badge, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'ID: ${employee['emp_id']?.toString() ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Performance Metrics Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Performance
                  _buildMetricColumn(
                    'Performance',
                    '${stats['performance']?.toStringAsFixed(1) ?? '0.0'}%',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                  
                  // Attendance
                  _buildMetricColumn(
                    'Attendance',
                    '${stats['attendance_percentage']?.toStringAsFixed(1) ?? '0.0'}%',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                  
                  // Orders
                  _buildMetricColumn(
                    'Orders',
                    '${stats['total_orders'] ?? 0}',
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                  
                  // Sales
                  _buildMetricColumn(
                    'Sales',
                    '₹${(stats['total_sales'] ?? 0).toStringAsFixed(0)}',
                    Icons.currency_rupee,
                    Colors.purple,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Location and Contact Info
            Row(
              children: [
                // Location Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              employee['district']?.toString() ?? 'No District',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              employee['branch']?.toString() ?? 'No Branch',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              employee['email']?.toString() ?? 'No Email',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              employee['phone']?.toString() ?? 'No Phone',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Same District Badge
            if (employee['district']?.toString() == _managerDistrict)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: themePrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 10,
                        color: themePrimary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Same District',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: themePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
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
    final bool sameBranch = employee['branch']?.toString() == _managerBranch;
    final status = employee['status']?.toString() ?? 'Inactive';
    final isActive = status.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: () => _viewEmployeeDetails(employee),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sameBranch ? Colors.green.withOpacity(0.5) : Colors.grey[200]!,
            width: sameBranch ? 2 : 1,
          ),
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
              // Profile and Name Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: sameBranch
                        ? Colors.green.withOpacity(0.1)
                        : themePrimary.withOpacity(0.1),
                    radius: 20,
                    child: Icon(
                      Icons.person,
                      color: sameBranch ? Colors.green : themePrimary,
                      size: 18,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employee['position']?.toString() ?? 'Employee',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Status and Branch
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.business, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    employee['branch']?.toString() ?? 'No Branch',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Metrics Row
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${stats['performance']?.toStringAsFixed(0) ?? '0'}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Perf',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${stats['attendance_percentage']?.toStringAsFixed(0) ?? '0'}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Att',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${stats['total_orders'] ?? 0}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'Orders',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Contact Info
              Row(
                children: [
                  Icon(Icons.phone, size: 10, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      employee['phone']?.toString() ?? 'No Phone',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
              hintText: 'Search by name, position, ID, email, phone, or branch...',
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themePrimary, width: 2),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 15),
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
          Row(
            children: [
              Text(
                'Filter by Branch',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Text(
                '${_branchesInDistrict.length} branches',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _branchesInDistrict.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedBranch == null || _selectedBranch == 'All Branches';
                  return _buildBranchChip('All Branches', isSelected, () {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? themePrimary : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? themePrimary : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(selected ? 0.1 : 0.05),
              blurRadius: selected ? 8 : 4,
              offset: Offset(0, selected ? 2 : 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 14,
              ),
            if (selected) const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
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
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: themePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _managerDistrict != null
                  ? 'There are no employees in your district ($_managerDistrict) yet.'
                  : 'District information not available.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: themePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
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
          if (_managerDistrict != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'District: $_managerDistrict',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
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
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No employees found',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No results for "$_searchQuery"'
                      : 'No employees in $_selectedBranch branch',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themePrimary,
                    foregroundColor: Colors.white,
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
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
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: Colors.white,
            ),
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
                      // Manager Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: themePrimary.withOpacity(0.1),
                              radius: 20,
                              child: Icon(
                                Icons.person,
                                color: themePrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Location',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _managerName != null
                                        ? '$_managerName · $_managerDistrict "}'
                                        : 'District: $_managerDistrict',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: themePrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _isGridView ? 'Grid' : 'List',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: themePrimary,
                                    ),
                                  ),
                                  Text(
                                    '${_filteredEmployees.length}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: themePrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Filters Section
                      _buildSearchBar(),
                      _buildBranchFilter(),
                      
                      // Results Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedBranch != null && _selectedBranch != 'All Branches'
                                  ? '$_selectedBranch Branch'
                                  : 'All Branches',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_filteredEmployees.length} of ${_employees.length} employees',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Employee List/Grid
                      Expanded(
                        child: _buildEmployeeList(),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// EmployeeDetailPage1 (Simplified)
class EmployeeDetailPage1 extends StatefulWidget {
  final Map<String, dynamic> employee;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> orders;
  final Color themePrimary;

  const EmployeeDetailPage1({
    super.key,
    required this.employee,
    required this.stats,
    required this.orders,
    required this.themePrimary,
  });

  @override
  State<EmployeeDetailPage1> createState() => _EmployeeDetailPage1State();
}

class _EmployeeDetailPage1State extends State<EmployeeDetailPage1> {
  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: widget.themePrimary,
        title: Text(
          employee['full_name']?.toString() ?? 'Employee Details',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: widget.themePrimary.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: widget.themePrimary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        fontSize: 16,
                        color: widget.themePrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (employee['status']?.toString() ?? '')
                                        .toLowerCase() ==
                                    'active'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            employee['status']?.toString() ?? 'Inactive',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: (employee['status']?.toString() ?? '')
                                          .toLowerCase() ==
                                      'active'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ID: ${employee['emp_id']?.toString() ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.email, 'Email', employee['email']?.toString() ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(Icons.phone, 'Phone', employee['phone']?.toString() ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(Icons.business, 'Branch', employee['branch']?.toString() ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(Icons.location_city, 'District', employee['district']?.toString() ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(Icons.calendar_today, 'Joining Date', employee['joining_date']?.toString() ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(Icons.attach_money, 'Salary', '₹${employee['salary']?.toString() ?? '0'}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: widget.themePrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
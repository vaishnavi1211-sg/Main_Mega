import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client; 

// ===============================================
// EMPLOYEE DETAILS PAGE
// ===============================================

class EmployeeDetailPage extends StatefulWidget {
  const EmployeeDetailPage({super.key});

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  final Color themePrimary = const Color(0xFF2563EB);
  final Color bg = const Color(0xFFF9FAFB);
  
  String? _managerDistrict;
  String? _managerBranch;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _employees = [];
  Map<String, double> _employeeTargets = {}; // emp_id -> target_amount
  TextEditingController _globalTargetController = TextEditingController();
  DateTime? _selectedMonth;
  bool _isAssigningTargets = false;
  String? _managerEmail;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadManagerProfileAndEmployees();
  }

  @override
  void dispose() {
    _globalTargetController.dispose();
    super.dispose();
  }

  Future<void> _loadManagerProfileAndEmployees() async {
    try {
      print('Loading manager profile and employees...');
      
      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated. Please login again.';
          _isLoading = false;
        });
        return;
      }
      print('Current user ID: ${user.id}');
      _managerEmail = user.email;

      // Get manager's profile from emp_profile
      final managerProfile = await supabase
          .from('emp_profile')
          .select('district, branch, role, email, emp_id')
          .eq('user_id', user.id)
          .maybeSingle();

      print('Manager profile response: $managerProfile');
      
      if (managerProfile == null || managerProfile.isEmpty) {
        // Try alternative: check by email
        final altProfile = await supabase
            .from('emp_profile')
            .select('district, branch, role, emp_id')
            .eq('email', user.email ?? '')
            .eq('role', 'Marketing Manager')
            .maybeSingle();
            
        if (altProfile != null && altProfile.isNotEmpty) {
          _managerDistrict = altProfile['district']?.toString();
          _managerBranch = altProfile['branch']?.toString();
        } else {
          setState(() {
            _errorMessage = 'Marketing Manager profile not found. Please contact administrator.';
            _isLoading = false;
          });
          return;
        }
      } else {
        _managerDistrict = managerProfile['district']?.toString();
        _managerBranch = managerProfile['branch']?.toString();
      }
      
      print('Manager district: $_managerDistrict, branch: $_managerBranch');
      
      // Fetch employees from the same branch
      await _fetchEmployeesByBranch();
      
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEmployeesByBranch() async {
    if (_managerBranch == null || _managerBranch!.isEmpty) {
      setState(() {
        _errorMessage = 'Manager branch not found in profile';
        _isLoading = false;
      });
      return;
    }

    try {
      print('Fetching employees for branch: $_managerBranch');
      
      // Fetch employees from emp_profile table with the same branch
      // Exclude marketing managers to show only team members
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
            user_id,
            created_at,
            profile_image
          ''')
          .eq('branch', _managerBranch!)
          .neq('role', 'Marketing Manager')
          .order('full_name', ascending: true);

      print('Response type: ${response.runtimeType}');
      print('Response: $response');
      
      final employeesList = List<Map<String, dynamic>>.from(response);
      print('Found ${employeesList.length} employees in $_managerBranch');
      
      // Load existing targets for the selected month
      await _loadExistingTargets(employeesList);
      
      setState(() {
        _employees = employeesList;
        _isLoading = false;
        _errorMessage = null;
      });
          
    } catch (e) {
      print('Error fetching employees: $e');
      setState(() {
        _errorMessage = 'Error fetching employees: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingTargets(List<Map<String, dynamic>> employees) async {
    if (_selectedMonth == null) return;
    
    _selectedMonth!.toIso8601String().split('T')[0].substring(0, 7);
    
    try {
      final employeeIds = employees
          .map((e) => e['emp_id']?.toString())
          .where((id) => id != null)
          .toList();
      
      if (employeeIds.isEmpty) return;
      
      // Load existing targets for this month
      final existingTargets = await supabase
          .from('emp_mar_targets')
          .select('emp_id, target_amount')
          .filter('emp_id', 'in', '(${employeeIds.map((id) => "'$id'").join(',')})');
          //.eq('target_month', formattedMonth);
      
      // Update employee targets map
      for (var target in existingTargets) {
        final empId = target['emp_id'] as String;
        final amount = double.parse(target['target_amount'].toString());
        _employeeTargets[empId] = amount;
      }
    } catch (e) {
      print('Error loading existing targets: $e');
    }
  }

  Future<void> _assignTargetToAll() async {
    if (_globalTargetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target value')),
      );
      return;
    }

    final targetValue = double.tryParse(_globalTargetController.text);
    if (targetValue == null || targetValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target value (greater than 0)')),
      );
      return;
    }

    if (_selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a month')),
      );
      return;
    }

    setState(() {
      _isAssigningTargets = true;
    });

    try {
      // Format month for display and database
      final monthYear = '${_selectedMonth!.month}/${_selectedMonth!.year}';
      final formattedMonth = _selectedMonth!.toIso8601String().split('T')[0].substring(0, 7); // YYYY-MM
      
      // Prepare batch of target assignments
      final List<Map<String, dynamic>> targetAssignments = [];
      int successCount = 0;
      
      for (var employee in _employees) {
        final employeeId = employee['emp_id']?.toString();
        if (employeeId != null && employeeId.isNotEmpty) {
          targetAssignments.add({
            'emp_id': employeeId,
            'employee_name': employee['full_name']?.toString() ?? 'Unknown',
            'branch': _managerBranch,
            'district': _managerDistrict,
            'assigned_by': _managerEmail ?? 'Marketing Manager',
            'target_amount': targetValue,
            'target_month': formattedMonth,
            'month_display': monthYear,
            'assigned_date': DateTime.now().toIso8601String(),
            'status': 'Assigned',
          });
          successCount++;
        }
      }

      if (targetAssignments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No employees found to assign targets')),
        );
        setState(() { _isAssigningTargets = false; });
        return;
      }

      // Insert into emp_mar_targets table using upsert
      final response = await supabase
          .from('emp_mar_targets')
          .upsert(
            targetAssignments,
            onConflict: 'emp_id,target_month',
          );

      print('Targets assigned response: $response');

      // Update local state for all employees
      for (var employee in _employees) {
        final employeeId = employee['emp_id']?.toString();
        if (employeeId != null) {
          _employeeTargets[employeeId] = targetValue;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Target of $targetValue T assigned to $successCount employees for $monthYear'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the input field
      _globalTargetController.clear();

      // Refresh the list
      setState(() {});

    } catch (e) {
      print('Error assigning targets: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning targets: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAssigningTargets = false;
      });
    }
  }

  Future<void> _updateIndividualTarget(String empId, String empName, double newTarget) async {
    if (_selectedMonth == null) return;
    
    try {
      final formattedMonth = _selectedMonth!.toIso8601String().split('T')[0].substring(0, 7);
      final monthYear = '${_selectedMonth!.month}/${_selectedMonth!.year}';
      
      await supabase
          .from('emp_mar_targets')
          .upsert({
            'emp_id': empId,
            'employee_name': empName,
            'branch': _managerBranch,
            'district': _managerDistrict,
            'assigned_by': _managerEmail ?? 'Marketing Manager',
            'target_amount': newTarget,
            'target_month': formattedMonth,
            'month_display': monthYear,
            'assigned_date': DateTime.now().toIso8601String(),
            'status': 'Assigned',
          }, onConflict: 'emp_id,target_month');
      
      setState(() {
        _employeeTargets[empId] = newTarget;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Target updated for $empName: $newTarget T'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating individual target: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating target: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: 'Select target month',
      fieldLabelText: 'Target month',
      fieldHintText: 'Month/Year',
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _employeeTargets.clear(); // Clear old targets when month changes
      });
      await _loadExistingTargets(_employees);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _employeeTargets.clear();
    });
    await _loadManagerProfileAndEmployees();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themePrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Try Again', style: GoogleFonts.poppins()),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Database Check', style: GoogleFonts.poppins()),
                        content: Text(
                          'Please ensure:\n\n'
                          '1. Your profile has a "branch" value\n'
                          '2. There are employees in emp_profile with same branch\n'
                          '3. Employee roles are NOT "Marketing Manager"\n'
                          '4. Branch values match exactly\n'
                          '5. Table "emp_mar_targets" exists',
                          style: GoogleFonts.poppins(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK', style: GoogleFonts.poppins()),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text('Database Help', style: GoogleFonts.poppins()),
                ),
              ],
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
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Team Members Found',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _managerBranch != null
                        ? 'Branch: $_managerBranch'
                        : 'Branch not found',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To add team members:\n\n'
                    '1. Go to Supabase emp_profile table\n'
                    '2. Add employees with:\n'
                    '   • Branch: $_managerBranch\n'
                    '   • Role: Sales Executive, Field Agent, etc.\n'
                    '   • Status: Active\n'
                    '3. Avoid role: "Marketing Manager"\n'
                    '4. Ensure emp_id is filled for each employee',
                    textAlign: TextAlign.left,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: themePrimary,
                foregroundColor: Colors.white,
              ),
              child: Text('Refresh', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkTargetAssignmentCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: themePrimary),
                const SizedBox(width: 8),
                Text(
                  'Assign Monthly Target to All ',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Branch Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themePrimary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: themePrimary.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target will be assigned to:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Branch: $_managerBranch',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themePrimary,
                        ),
                      ),
                      Text(
                        'Total Employees: ${_employees.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themePrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Bulk Assign',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: themePrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Month Selection with current target info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Month for Target        ',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectMonth(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedMonth != null
                                    ? '${_selectedMonth!.month}/${_selectedMonth!.year}'
                                    : 'Select Month',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Icon(Icons.calendar_today, color: themePrimary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Target Input
            Text(
              'Monthly Target (Tons)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _globalTargetController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter target amount in tons',
                hintStyle: GoogleFonts.poppins(fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                prefixIcon: Icon(Icons.flag, color: themePrimary),
                suffixText: 'T',
                suffixStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: themePrimary,
                  fontWeight: FontWeight.w600,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            // Assign Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAssigningTargets ? null : _assignTargetToAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isAssigningTargets
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, size: 20),
                label: Text(
                  _isAssigningTargets
                      ? 'Assigning Targets...'
                      : 'Assign Target to All Employees',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Management',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _managerBranch != null 
                              ? 'Branch: $_managerBranch' 
                              : 'Loading...',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.calendar_month, color: themePrimary),
                      onPressed: () => _selectMonth(context),
                      tooltip: 'Change Month',
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: themePrimary),
                      onPressed: _refreshData,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading team members...'),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorState()
                    : _employees.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _refreshData,
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 16),
                              children: [
                                // Bulk Target Assignment Card
                                _buildBulkTargetAssignmentCard(),
                                
                                // Employee List Title
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.people, color: themePrimary, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Team Members (${_employees.length})',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${_employeeTargets.length}/${_employees.length} targets set',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Employee List
                                ..._employees.map((employee) {
                                  final empId = employee['emp_id']?.toString() ?? '';
                                  final currentTarget = _employeeTargets[empId] ?? 0.0;
                                  return EmployeeCard(
                                    employee: employee,
                                    themePrimary: themePrimary,
                                    branch: _managerBranch,
                                    currentTarget: currentTarget,
                                    selectedMonth: _selectedMonth,
                                    onUpdateTarget: (newTarget) => _updateIndividualTarget(
                                      empId,
                                      employee['full_name']?.toString() ?? 'Employee',
                                      newTarget,
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ===============================================
// EMPLOYEE CARD (Updated with individual target editing)
// ===============================================

class EmployeeCard extends StatefulWidget {
  const EmployeeCard({
    super.key,
    required this.employee,
    required this.themePrimary,
    required this.branch,
    required this.currentTarget,
    required this.selectedMonth,
    required this.onUpdateTarget,
  });

  final Map<String, dynamic> employee;
  final Color themePrimary;
  final String? branch;
  final double currentTarget;
  final DateTime? selectedMonth;
  final Function(double) onUpdateTarget;

  @override
  State<EmployeeCard> createState() => _EmployeeCardState();
}

class _EmployeeCardState extends State<EmployeeCard> {
  late TextEditingController _targetController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(
      text: widget.currentTarget > 0 ? widget.currentTarget.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EmployeeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTarget != widget.currentTarget && !_isEditing) {
      _targetController.text = widget.currentTarget > 0 
          ? widget.currentTarget.toStringAsFixed(1) 
          : '';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not Set';
    
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    
    if (date is String) {
      try {
        final parsedDate = DateTime.parse(date.split('T')[0]);
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      } catch (e) {
        return date;
      }
    }
    
    return date.toString();
  }

  String _formatPerformance(dynamic performance) {
    if (performance == null) return '0';
    if (performance is num) {
      return performance.toStringAsFixed(1);
    }
    return performance.toString();
  }

  void _saveTarget() {
    final newTarget = double.tryParse(_targetController.text);
    if (newTarget == null || newTarget < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target value')),
      );
      return;
    }
    
    widget.onUpdateTarget(newTarget);
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final performance = _formatPerformance(widget.employee['performance']);
    final attendance = _formatPerformance(widget.employee['attendance']);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Name, Position, and Status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.themePrimary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: widget.themePrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employee['full_name']?.toString() ?? 'Unknown Employee',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.employee['position']?.toString() ?? 'Employee'} • ${widget.employee['role']?.toString() ?? 'Employee'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (widget.employee['status']?.toString() ?? '').toLowerCase() == 'active'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.employee['status']?.toString() ?? 'Inactive',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: (widget.employee['status']?.toString() ?? '').toLowerCase() == 'active' 
                          ? Colors.green 
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Employee ID: ${widget.employee['emp_id']?.toString() ?? widget.employee['id']?.toString() ?? 'N/A'}',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
            ),
            const Divider(height: 24),

            // Contact Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildDetailChip(Icons.phone, widget.employee['phone']?.toString() ?? 'N/A'),
                ),
                Expanded(
                  child: _buildDetailChip(Icons.email, widget.employee['email']?.toString() ?? 'N/A'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildDetailChip(Icons.location_city, widget.employee['district']?.toString() ?? 'N/A'),
                ),
                Expanded(
                  child: _buildDetailChip(Icons.calendar_today, 
                    'Joined: ${_formatDate(widget.employee['joining_date'])}'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Performance Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Execution',
                    '$performance%',
                    double.parse(performance) >= 80 ? Colors.green : Colors.orange,
                    14.0
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Attendance',
                    '$attendance%',
                    double.parse(attendance) >= 90 ? Colors.blue : Colors.orange,
                    9.0
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Salary',
                    widget.employee['salary'] != null 
                        ? '₹${(widget.employee['salary'] as num).toInt()}'
                        : 'N/A',
                    Colors.purple,
                    10.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Target',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.selectedMonth != null
                                ? 'Month: ${widget.selectedMonth!.month}/${widget.selectedMonth!.year}'
                                : 'Month not selected',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.currentTarget > 0 
                              ? widget.themePrimary.withOpacity(0.1) 
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.currentTarget > 0 
                              ? '${widget.currentTarget.toStringAsFixed(1)} T' 
                              : 'Not Set',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.currentTarget > 0 ? widget.themePrimary : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Individual Target Edit
                  if (_isEditing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Individual Target (Tons)',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _targetController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Enter target in tons',
                                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  suffixText: 'T',
                                  suffixStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                ),
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _saveTarget,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.themePrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: const Text('Save'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _targetController.text = widget.currentTarget > 0 
                                      ? widget.currentTarget.toStringAsFixed(1) 
                                      : '';
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Individual target override',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, fontSize) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}













// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:mega_pro/global/global_variables.dart';


// class EmployeeDetailPage extends StatelessWidget {
//   const EmployeeDetailPage({super.key});

//   // Mock Employee Data (Sales are in Tons)
//   final List<Map<String, dynamic>> _employeeData = const [
//     {
//       "name": "Arjun Kulkarni",
//       "id": "EMP001",
//       "district": "Kolhapur",
//       "role": "Sales Rep (Karvir, Panhala)",
//       "total_sales": 380,
//       "phone": "98765 12345",
//       "email": "arjun.k@corp.com"
//     },
//     {
//       "name": "Priya Deshmukh",
//       "id": "EMP002",
//       "district": "Kolhapur",
//       "role": "Sales Rep (Shirol, Kagal)",
//       "total_sales": 320,
//       "phone": "90123 45678",
//       "email": "priya.d@corp.com"
//     },
//     {
//       "name": "Rohit Jadhav",
//       "id": "EMP003",
//       "district": "Pune",
//       "role": "Regional Manager",
//       "total_sales": 775,
//       "phone": "92345 67890",
//       "email": "rohit.j@corp.com"
//     },
//     {
//       "name": "Sneha Patil",
//       "id": "EMP004",
//       "district": "Sangli",
//       "role": "Sales Rep (Miraj, Walwa)",
//       "total_sales": 275,
//       "phone": "87654 32109",
//       "email": "sneha.p@corp.com"
//     },
//     {
//       "name": "Vikram Singh",
//       "id": "EMP005",
//       "district": "Satara",
//       "role": "Sales Rep (Karad, Koregaon)",
//       "total_sales": 350,
//       "phone": "89012 34567",
//       "email": "vikram.s@corp.com"
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         title: Text(
//           "Employee Directory",
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: _employeeData.length,
//         itemBuilder: (context, index) {
//           final employee = _employeeData[index];
//           return EmployeeCard(employee: employee);
//         },
//       ),
//     );
//   }
// }

// class EmployeeCard extends StatelessWidget {
//   const EmployeeCard({super.key, required this.employee});

//   final Map<String, dynamic> employee;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// NAME + ROLE
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: AppColors.lightBlue,
//                   child: const Icon(
//                     Icons.person,
//                     color: GlobalColors.primaryBlue,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       employee["name"],
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 16,
//                       ),
//                     ),
//                     Text(
//                       employee["role"],
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         color: AppColors.secondaryText,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//                 Text(
//                   employee["id"],
//                   style: GoogleFonts.poppins(
//                     fontSize: 12,
//                     color: AppColors.mutedText,
//                   ),
//                 ),
//               ],
//             ),

//             const Divider(height: 24),

//             /// LOCATION + PHONE
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildDetailChip(
//                     Icons.location_on, employee["district"]),
//                 _buildDetailChip(Icons.phone, employee["phone"]),
//               ],
//             ),

//             const SizedBox(height: 12),

//             _buildSalesInfo(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailChip(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: AppColors.mutedText),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: GoogleFonts.poppins(
//             fontSize: 13,
//             color: AppColors.primaryText,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSalesInfo() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//       decoration: BoxDecoration(
//         color: AppColors.lightBlue,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             "Total Sales (YTD):",
//             style: GoogleFonts.poppins(
//               fontSize: 13,
//               color: AppColors.primaryText,
//             ),
//           ),
//           Text(
//             '${employee["total_sales"].toStringAsFixed(0)} T',
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w700,
//               fontSize: 14,
//               color: GlobalColors.primaryBlue,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

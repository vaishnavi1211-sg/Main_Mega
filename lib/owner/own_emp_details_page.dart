import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/models/own_dashboard_model.dart';
import 'package:mega_pro/services/supabase_services.dart';
import 'package:intl/intl.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final DashboardData dashboardData;
  
  const EmployeeDetailsPage({super.key, required this.dashboardData});

  @override
  State<EmployeeDetailsPage> createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  
  // Filters
  String _selectedStatus = 'All';
  String _selectedRole = 'All';
  String _selectedDistrict = 'All Districts';
  String _searchQuery = '';
  
  // Data
  bool _isLoading = true;
  List<Map<String, dynamic>> _employees = [];
  String? _error;
  
  // Filter options - REMOVED Marketing Employee and Production Employee
  final List<String> _statusFilters = ['All', 'Active', 'Inactive'];
  final List<String> _roleFilters = [
    'All',
    'Owner',
    'Admin',
    'Marketing Manager',
    'Production Manager',
    'Employee'
  ];
  List<String> _districtFilters = ['All Districts'];
  
  // Animation
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _employees = await _supabaseService.getAllEmployees();
      
      final districts = _employees
          .map((e) => e['district']?.toString() ?? 'Unassigned')
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      
      setState(() {
        _districtFilters = ['All Districts', ...districts];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // FIXED: Safe name getter to prevent "Unknown" from showing
  String _getSafeName(Map<String, dynamic> emp) {
    final name = emp['name']?.toString();
    if (name == null || 
        name.isEmpty || 
        name.toLowerCase() == 'unknown' || 
        name.toLowerCase() == 'null' ||
        name.trim().isEmpty) {
      return 'Employee'; // Default fallback instead of "Unknown"
    }
    return name;
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    return _employees.where((emp) {
      if (_selectedStatus != 'All') {
        final status = (emp['status'] as String?)?.toLowerCase() ?? '';
        if (status != _selectedStatus.toLowerCase()) return false;
      }
      
      if (_selectedRole != 'All') {
        final role = emp['role']?.toString() ?? '';
        if (role != _selectedRole) return false;
      }
      
      if (_selectedDistrict != 'All Districts') {
        final district = emp['district']?.toString() ?? 'Unassigned';
        if (district != _selectedDistrict) return false;
      }
      
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = _getSafeName(emp).toLowerCase();
        final email = (emp['email'] as String?)?.toLowerCase() ?? '';
        final phone = (emp['phone'] as String?)?.toLowerCase() ?? '';
        final role = (emp['role'] as String?)?.toLowerCase() ?? '';
        
        if (!name.contains(query) && 
            !email.contains(query) && 
            !phone.contains(query) && 
            !role.contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _employeesByRole {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var emp in _filteredEmployees) {
      final role = emp['role']?.toString() ?? 'Employee';
      if (!grouped.containsKey(role)) {
        grouped[role] = [];
      }
      grouped[role]!.add(emp);
    }
    
    // Sort roles in a specific order
    final roleOrder = {
      'Owner': 1,
      'Admin': 2,
      'Marketing Manager': 3,
      'Production Manager': 4,
      'Employee': 5,
    };
    
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final aOrder = roleOrder[a] ?? 99;
      final bOrder = roleOrder[b] ?? 99;
      return aOrder.compareTo(bOrder);
    });
    
    final sortedMap = <String, List<Map<String, dynamic>>>{};
    for (var key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    
    return sortedMap;
  }

  Map<String, List<Map<String, dynamic>>> get _employeesByDistrict {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var emp in _filteredEmployees) {
      final district = emp['district']?.toString() ?? 'Unassigned';
      if (!grouped.containsKey(district)) {
        grouped[district] = [];
      }
      grouped[district]!.add(emp);
    }
    
    final sortedKeys = grouped.keys.toList()..sort();
    final sortedMap = <String, List<Map<String, dynamic>>>{};
    for (var key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    
    return sortedMap;
  }

  int get _activeCount => _employees.where((e) => 
    (e['status'] as String?)?.toLowerCase() == 'active').length;
  
  int get _inactiveCount => _employees.where((e) => 
    (e['status'] as String?)?.toLowerCase() == 'inactive').length;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF059669);
      case 'inactive':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  Color _getRoleColor(String role) {
    if (role.contains('Owner')) return const Color.fromARGB(255, 228, 225, 223);
    if (role.contains('Admin')) return const Color.fromARGB(255, 212, 202, 202);
    if (role.contains('Marketing')) return const Color.fromARGB(255, 204, 210, 204)  ;
     if (role.contains('Production')) return const Color.fromARGB(255, 211, 207, 218);
    return const Color.fromARGB(255, 198, 207, 204); // Employee
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _employees.isEmpty
                  ? _buildEmptyState()
                  : _buildMainContent(),
    );
  }

  // FIXED: App Bar with proper primary blue color
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: GlobalColors.primaryBlue,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Employees',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: _loadEmployees,
            tooltip: 'Refresh',
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            _buildTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: _searchFocusNode.hasFocus
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: 'Search employees...',
            hintStyle: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: 15,
            ),
            prefixIcon: const Icon(Icons.search_rounded, 
              color: GlobalColors.primaryBlue,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, 
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            label: _selectedStatus,
            icon: Icons.fiber_manual_record_rounded,
            iconColor: _getStatusColor(_selectedStatus),
            onTap: _showStatusFilter,
            isActive: _selectedStatus != 'All',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedRole == 'All' ? 'Role' : _selectedRole,
            icon: Icons.badge_rounded,
            iconColor: _selectedRole == 'All' 
                ? const Color(0xFF64748B) 
                : _getRoleColor(_selectedRole),
            onTap: _showRoleFilter,
            isActive: _selectedRole != 'All',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedDistrict == 'All Districts' ? 'District' : _selectedDistrict,
            icon: Icons.location_on_rounded,
            iconColor: _selectedDistrict == 'All Districts' 
                ? const Color(0xFF64748B) 
                : const Color(0xFF7C3AED),
            onTap: _showDistrictFilter,
            isActive: _selectedDistrict != 'All Districts',
          ),
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildClearAllChip(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? iconColor.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isActive ? iconColor.withOpacity(0.5) : const Color(0xFFE2E8F0),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                label.length > 15 ? '${label.substring(0, 15)}...' : label,
                style: TextStyle(
                  color: isActive ? iconColor : const Color(0xFF1E293B),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down_rounded, color: iconColor, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearAllChip() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = 'All';
            _selectedRole = 'All';
            _selectedDistrict = 'All Districts';
          });
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 16),
              const SizedBox(width: 4),
              const Text(
                'Clear',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: GlobalColors.primaryBlue,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: GlobalColors.primaryBlue,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'By Role'),
          Tab(text: 'By District'),
        ],
      ),
    );
  }

  bool get _hasActiveFilters {
    return _selectedStatus != 'All' || 
           _selectedRole != 'All' || 
           _selectedDistrict != 'All Districts';
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildStatsSection(),
        _buildResultsInfo(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEmployeeList(_filteredEmployees),
              _buildGroupedEmployeeList(_employeesByRole, 'role'),
              _buildGroupedEmployeeList(_employeesByDistrict, 'district'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard(
            'Total',
            _employees.length.toString(),
            Icons.people_rounded,
            GlobalColors.primaryBlue,
          ),
          _buildStatCard(
            'Active',
            _activeCount.toString(),
            Icons.check_circle_rounded,
            const Color(0xFF059669),
          ),
          _buildStatCard(
            'Inactive',
            _inactiveCount.toString(),
            Icons.cancel_rounded,
            const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _searchQuery.isEmpty
                ? '${_filteredEmployees.length} employees found'
                : '${_filteredEmployees.length} matches for "${_searchQuery}"',
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Updated ${DateFormat('HH:mm').format(DateTime.now())}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(List<Map<String, dynamic>> employees) {
    if (employees.isEmpty) {
      return _buildEmptyFilterState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final emp = employees[index];
        return _buildEmployeeCard(emp);
      },
    );
  }

  Widget _buildGroupedEmployeeList(Map<String, List<Map<String, dynamic>>> groupedData, String groupBy) {
    if (groupedData.isEmpty) {
      return _buildEmptyFilterState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedData.length,
      itemBuilder: (context, index) {
        final groupKey = groupedData.keys.elementAt(index);
        final groupEmployees = groupedData[groupKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: groupBy == 'role' 
                          ? _getRoleColor(groupKey).withOpacity(0.1)
                          : const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      groupBy == 'role' ? Icons.badge_rounded : Icons.location_on_rounded,
                      size: 14,
                      color: groupBy == 'role' 
                          ? _getRoleColor(groupKey)
                          : const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    groupKey,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${groupEmployees.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...groupEmployees.map((emp) => _buildEmployeeCard(emp)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // FIXED: Employee card using safe name getter
  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    final name = _getSafeName(emp);
    final email = emp['email']?.toString() ?? 'No email provided';
    final phone = emp['phone']?.toString() ?? 'No phone';
    final status = emp['status']?.toString() ?? 'Active';
    final role = emp['role']?.toString() ?? 'Employee';
    final district = emp['district']?.toString() ?? 'Not assigned';
    final joinDate = emp['created_at']?.toString();
    final date = joinDate != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(joinDate))
        : 'N/A';

    final statusColor = _getStatusColor(status);
    final roleColor = _getRoleColor(role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showEmployeeDetails(emp),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            roleColor,
                            roleColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: roleColor.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: roleColor,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (phone.isNotEmpty && phone != 'No phone') ...[
                        Container(width: 1, height: 20, color: Colors.grey.shade300),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          district,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: GlobalColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(GlobalColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading employees...',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Failed to load employees',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadEmployees,
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: Color(0xFF94A3B8),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Employees Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Employees will appear here once added',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.filter_alt_off_rounded,
              color: Color(0xFF94A3B8),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No matches found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              ..._statusFilters.map((status) {
                final isSelected = _selectedStatus == status;
                final statusColor = status == 'All' 
                    ? const Color(0xFF64748B)
                    : _getStatusColor(status);
                
                return _buildFilterOption(
                  title: status,
                  isSelected: isSelected,
                  color: statusColor,
                  icon: status != 'All' 
                      ? Icons.fiber_manual_record_rounded
                      : Icons.people_rounded,
                  onTap: () {
                    setState(() {
                      _selectedStatus = status;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // FIXED: Role filter with updated role list
  void _showRoleFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Role',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _roleFilters.length,
                  itemBuilder: (context, index) {
                    final role = _roleFilters[index];
                    final isSelected = _selectedRole == role;
                    final roleColor = role == 'All' 
                        ? const Color(0xFF64748B)
                        : _getRoleColor(role);
                    
                    return _buildFilterOption(
                      title: role,
                      isSelected: isSelected,
                      color: roleColor,
                      icon: role != 'All' ? Icons.badge_rounded : Icons.people_rounded,
                      onTap: () {
                        setState(() {
                          _selectedRole = role;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDistrictFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by District',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _districtFilters.length,
                  itemBuilder: (context, index) {
                    final district = _districtFilters[index];
                    final isSelected = _selectedDistrict == district;
                    final count = district == 'All Districts' 
                        ? _employees.length 
                        : _employees.where((e) => e['district'] == district).length;
                    
                    return _buildDistrictFilterOption(
                      district: district,
                      isSelected: isSelected,
                      count: count,
                      onTap: () {
                        setState(() {
                          _selectedDistrict = district;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String title,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? color : const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictFilterOption({
    required String district,
    required bool isSelected,
    required int count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7C3AED).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  district,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF7C3AED).withOpacity(0.2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 12),
                const Icon(Icons.check_circle_rounded, 
                  color: Color(0xFF7C3AED), 
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // FIXED: Employee details with safe name
  void _showEmployeeDetails(Map<String, dynamic> emp) {
    final name = _getSafeName(emp);
    final role = emp['role']?.toString() ?? 'Employee';
    final roleColor = _getRoleColor(role);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    roleColor,
                                    roleColor.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: roleColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: roleColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.close_rounded, 
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildDetailCard(
                              'Status',
                              emp['status']?.toString() ?? 'Active',
                              Icons.fiber_manual_record_rounded,
                              _getStatusColor(emp['status']?.toString() ?? 'Active'),
                            ),
                            _buildDetailCard(
                              'District',
                              emp['district']?.toString() ?? 'Not assigned',
                              Icons.location_on_rounded,
                              const Color(0xFF7C3AED),
                            ),
                            _buildDetailCard(
                              'Phone',
                              emp['phone']?.toString() ?? 'N/A',
                              Icons.phone_rounded,
                              const Color(0xFF059669),
                            ),
                            _buildDetailCard(
                              'Joined',
                              emp['created_at'] != null
                                  ? DateFormat('MMM yyyy').format(DateTime.parse(emp['created_at'].toString()))
                                  : 'N/A',
                              Icons.calendar_month_rounded,
                              const Color(0xFFEA580C),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              _buildContactRow(
                                Icons.email_outlined,
                                'Email',
                                emp['email']?.toString() ?? 'No email provided',
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              _buildContactRow(
                                Icons.phone_outlined,
                                'Phone',
                                emp['phone']?.toString() ?? 'No phone provided',
                              ),
                              if (emp['address'] != null && emp['address'].toString().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                _buildContactRow(
                                  Icons.home_outlined,
                                  'Address',
                                  emp['address'].toString(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        if (emp['total_orders'] != null || emp['total_revenue'] != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Performance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  GlobalColors.primaryBlue.withOpacity(0.1),
                                  const Color(0xFF2563EB).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                if (emp['total_orders'] != null)
                                  Column(
                                    children: [
                                      Text(
                                        emp['total_orders'].toString(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: GlobalColors.primaryBlue,
                                        ),
                                      ),
                                      const Text(
                                        'Orders',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (emp['total_revenue'] != null) ...[
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '₹${NumberFormat.compact().format(emp['total_revenue'])}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                      const Text(
                                        'Revenue',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.update_rounded, 
                                size: 16, 
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
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
          },
        );
      },
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
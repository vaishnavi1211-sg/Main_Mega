import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mega_pro/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mega_pro/global/global_variables.dart';

class EmployeeProfileDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EmployeeProfileDashboard({super.key, this.userData});

  @override
  State<EmployeeProfileDashboard> createState() =>
      _EmployeeProfileDashboardState();
}

class _EmployeeProfileDashboardState extends State<EmployeeProfileDashboard> {
  final ImagePicker picker = ImagePicker();
  File? profileImage;

  Map<String, dynamic>? employeeData;
  bool isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _positionController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _positionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      // If userData is passed from dashboard, use it directly
      if (widget.userData != null && widget.userData!.isNotEmpty) {
        _processUserData(widget.userData!);
        return;
      }

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        _createDefaultProfile();
        return;
      }

      // Get data from emp_profile table using user_id
      final data = await supabase
          .from('emp_profile')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) {
        // Try with email as fallback
        final emailData = await supabase
            .from('emp_profile')
            .select('*')
            .eq('email', user.email!)
            .maybeSingle();

        if (emailData != null) {
          _processUserData(emailData);
        } else {
          _createDefaultProfile(user.email!);
        }
      } else {
        _processUserData(data);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _createDefaultProfile('employee@mega.com');
    }
  }

  void _processUserData(Map<String, dynamic> data) {
    setState(() {
      employeeData = {
        'empId': data['emp_id'] ?? 'N/A',
        'empName': data['full_name'] ?? 'Employee',
        'position': data['position'] ?? 'Employee',
        'branch': data['branch'] ?? 'Not Set',
        'district': data['district'] ?? 'Not Set',
        'department': data['department'] ?? 'Not Set',
        'joiningDate': data['joining_date'] != null
            ? DateTime.parse(data['joining_date'])
            : DateTime.now(),
        'status': data['status'] ?? 'Active',
        'phone': data['phone'] ?? 'Not Provided',
        'email': data['email'] ?? 'N/A',
        'performance': (data['performance'] ?? 0).toDouble(),
        'attendance': (data['attendance'] ?? 0).toDouble(),
        'role': data['role'] ?? 'Employee',
        'salary': data['salary'] ?? 0,
        'profile_image': data['profile_image'],
      };

      _nameController.text = data['full_name']?.toString() ?? '';
      _emailController.text = data['email']?.toString() ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';
      _positionController.text = data['position']?.toString() ?? '';

      isLoading = false;
    });
  }

  void _createDefaultProfile([String email = 'employee@mega.com']) {
    setState(() {
      employeeData = {
        'empId': 'EMP${DateTime.now().millisecondsSinceEpoch % 1000}',
        'empName': 'Employee',
        'position': 'Employee',
        'branch': 'Main Branch',
        'district': 'Corporate',
        'department': 'General',
        'joiningDate': DateTime.now(),
        'status': 'Active',
        'phone': '9876543210',
        'email': email,
        'performance': 85.0,
        'attendance': 95.0,
        'role': 'Employee',
        'salary': 0,
      };

      _nameController.text = 'Employee';
      _emailController.text = email;
      _phoneController.text = '9876543210';
      _positionController.text = 'Employee';

      isLoading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file != null) {
      setState(() => profileImage = File(file.path));
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user != null) {
          await supabase
              .from('emp_profile')
              .update({
                'full_name': _nameController.text,
                'phone': _phoneController.text,
                'position': _positionController.text,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', user.id);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _isEditing = false;
          });

          await _loadProfile();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: GlobalColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: GlobalColors.primaryBlue),
        ),
      );
    }

    if (employeeData == null) {
      return Scaffold(
        backgroundColor: GlobalColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Profile Not Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Contact administrator to set up your profile',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.primaryBlue,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final employee = employeeData!;

    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RoleSelectionScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(employee),
            const SizedBox(height: 20),
            _buildTabSection(employee),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> employee) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GlobalColors.primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : null,
                      child:
                          profileImage == null &&
                              employee['profile_image'] == null
                          ? Text(
                              (employee['empName'] is String &&
                                      employee['empName'].isNotEmpty)
                                  ? employee['empName']
                                        .substring(0, 2)
                                        .toUpperCase()
                                  : "EMP",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: GlobalColors.primaryBlue,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: GlobalColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee['empName']?.toString() ?? 'Employee',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      employee['position']?.toString() ?? 'Employee',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        employee['status']?.toString() ?? 'Active',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEmployeeIdCard(employee),
        ],
      ),
    );
  }

  Widget _buildEmployeeIdCard(Map<String, dynamic> employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _idItem("Employee ID", employee['empId']?.toString() ?? 'N/A'),
          _idItem("Department", employee['department']?.toString() ?? 'N/A'),
          _idItem(
            "Since",
            DateFormat("MMM yyyy").format(
              employee['joiningDate'] is DateTime
                  ? employee['joiningDate']
                  : DateTime.now(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _idItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection(Map<String, dynamic> employee) {
    return Container(
      constraints: const BoxConstraints(minHeight: 450),
      child: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TabBar(
              labelColor: GlobalColors.primaryBlue,
              tabs: [
                Tab(text: "Details"),
                Tab(text: "Performance"),
              ],
            ),
            SizedBox(
              height: 450,
              child: TabBarView(
                children: [_detailsTab(employee), _performanceTab(employee)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsTab(Map<String, dynamic> employee) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Edit Form or Display Info
            _isEditing ? _buildEditForm() : _buildDisplayInfo(employee),

            // Additional Information (only when not editing)
            if (!_isEditing) ...[
              const SizedBox(height: 20),
              _buildAdditionalInfo(employee),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Edit Profile Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field (read-only)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Position Field
              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(
                  labelText: 'Position',
                  prefixIcon: const Icon(Icons.work),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your position';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.text =
                              employeeData!['empName']?.toString() ?? '';
                          _phoneController.text =
                              employeeData!['phone']?.toString() ?? '';
                          _positionController.text =
                              employeeData!['position']?.toString() ?? '';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
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

  Widget _buildDisplayInfo(Map<String, dynamic> employee) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoItem(
              Icons.email,
              "Email",
              employee['email']?.toString() ?? 'N/A',
            ),
            const Divider(),
            _infoItem(
              Icons.phone,
              "Phone",
              employee['phone']?.toString() ?? 'N/A',
            ),
            const Divider(),
            _infoItem(
              Icons.location_on,
              "District",
              employee['district']?.toString() ?? 'N/A',
            ),
            const Divider(),
            _infoItem(
              Icons.business,
              "Branch",
              employee['branch']?.toString() ?? 'N/A',
            ),
            const Divider(),
            _infoItem(
              Icons.calendar_today,
              "Joining Date",
              DateFormat('dd MMMM yyyy').format(
                employee['joiningDate'] is DateTime
                    ? employee['joiningDate']
                    : DateTime.now(),
              ),
            ),
            if (employee['role'] != null) ...[
              const Divider(),
              _infoItem(
                Icons.work,
                "Role",
                employee['role']?.toString() ?? 'N/A',
              ),
            ],
            if (employee['salary'] != null && employee['salary'] > 0) ...[
              const Divider(),
              _infoItem(
                Icons.currency_rupee,
                "Salary",
                "₹${employee['salary']}",
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GlobalColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: GlobalColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
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

  Widget _performanceTab(Map<String, dynamic> employee) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Performance Metrics
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricCard(
                      "Performance",
                      employee['performance']?.toDouble() ?? 0.0,
                      GlobalColors.primaryBlue,
                    ),
                    Container(width: 1, height: 60, color: Colors.grey[300]),
                    _metricCard(
                      "Attendance",
                      employee['attendance']?.toDouble() ?? 0.0,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Additional Employee Metrics
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Employee Performance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _employeeMetric(
                      title: "Task Completion",
                      value: "92.5%",
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _employeeMetric(
                      title: "Work Quality",
                      value: "88%",
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _employeeMetric(
                      title: "Team Collaboration",
                      value: "95%",
                      color: Colors.purple,
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

  Widget _metricCard(String title, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${value.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _employeeMetric({
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(Map<String, dynamic> employee) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Change password
                    },
                    icon: const Icon(Icons.lock, size: 16),
                    label: const Text('Change Password'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Contact support
                    },
                    icon: const Icon(Icons.support_agent, size: 16),
                    label: const Text('Support'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
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
}

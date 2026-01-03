import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mega_pro/global/global_variables.dart';

class EmployeeProfileDashboard extends StatefulWidget {
  const EmployeeProfileDashboard({super.key});

  @override
  State<EmployeeProfileDashboard> createState() => _EmployeeProfileDashboardState();
}

class _EmployeeProfileDashboardState extends State<EmployeeProfileDashboard> {
  final ImagePicker picker = ImagePicker();
  File? profileImage;
  Map<String, dynamic>? employeeData;
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('emp_profile')
        .select()
        .eq('user_id', user.id)
        .single();

    setState(() {
      employeeData = {
        'emp_id': data['emp_id'],
        'full_name': data['full_name'],
        'position': data['position'],
        'branch': data['branch'],
        'district': data['district'],
        'joining_date': DateTime.parse(data['joining_date']),
        'status': data['status'],
        'phone': data['phone'],
        'email': data['email'],
        'performance': (data['performance'] ?? 0).toDouble(),
        'attendance': (data['attendance'] ?? 0).toDouble(),
        'department': data['department'],
        'role': data['role'],
        'profile_image': data['profile_image'],
        'created_at': data['created_at'],
      };
      
      _nameController.text = data['full_name']?.toString() ?? '';
      _emailController.text = data['email']?.toString() ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';
      _positionController.text = data['position']?.toString() ?? '';
    });
  }

  Future<void> _pickProfileImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file != null) {
      setState(() => profileImage = File(file.path));
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
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
    if (employeeData == null) {
      return Scaffold(
        backgroundColor: GlobalColors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GlobalColors.white,
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
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Profile Form
            _buildProfileForm(),

            // Additional Information
            if (!_isEditing) _buildAdditionalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: GlobalColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GlobalColors.primaryBlue.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: profileImage != null
                    ? CircleAvatar(
                        backgroundImage: FileImage(profileImage!),
                      )
                    : employeeData!['profile_image'] != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(
                              employeeData!['profile_image'].toString(),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: GlobalColors.primaryBlue,
                          ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: GlobalColors.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            employeeData!['full_name']?.toString() ?? 'Employee',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            employeeData!['position']?.toString() ?? 'Employee',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: employeeData!['status']?.toString() == 'Active'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              employeeData!['status']?.toString() ?? 'Active',
              style: TextStyle(
                color: employeeData!['status']?.toString() == 'Active'
                    ? Colors.green
                    : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Name Field
            _buildFormField(
              'Full Name',
              _nameController,
              Icons.person_rounded,
              _isEditing,
            ),
            const SizedBox(height: 16),

            // Email Field (read-only)
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              readOnly: true,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Phone Field
            _buildFormField(
              'Phone Number',
              _phoneController,
              Icons.phone_rounded,
              _isEditing,
            ),
            const SizedBox(height: 16),

            // Position Field
            _buildFormField(
              'Position',
              _positionController,
              Icons.work_rounded,
              _isEditing,
            ),

            if (_isEditing) ...[
              const SizedBox(height: 24),
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
                          _nameController.text = employeeData!['full_name']?.toString() ?? '';
                          _phoneController.text = employeeData!['phone']?.toString() ?? '';
                          _positionController.text = employeeData!['position']?.toString() ?? '';
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
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool editable,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: !editable,
        fillColor: editable ? Colors.transparent : Colors.grey.shade50,
      ),
      readOnly: !editable,
      style: TextStyle(
        color: editable ? Colors.grey.shade800 : Colors.grey.shade600,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          // Performance Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Performance',
                  employeeData!['performance'],
                  GlobalColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Attendance',
                  employeeData!['attendance'],
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Department Info
          _buildInfoItem(
            'Department',
            employeeData!['department']?.toString() ?? 'Not Set',
            Icons.business_rounded,
          ),
          const SizedBox(height: 12),

          // Role Info
          _buildInfoItem(
            'Role',
            employeeData!['role']?.toString() ?? 'Employee',
            Icons.badge_rounded,
          ),
          const SizedBox(height: 12),

          // Branch Info
          _buildInfoItem(
            'Branch',
            employeeData!['branch']?.toString() ?? 'Not Set',
            Icons.location_on_rounded,
          ),
          const SizedBox(height: 12),

          // District Info
          _buildInfoItem(
            'District',
            employeeData!['district']?.toString() ?? 'Not Set',
            Icons.map_rounded,
          ),
          const SizedBox(height: 12),

          // Employee ID
          _buildInfoItem(
            'Employee ID',
            employeeData!['emp_id']?.toString() ?? 'Not Set',
            Icons.numbers_rounded,
          ),
          const SizedBox(height: 12),

          // Join Date
          _buildInfoItem(
            'Joined Date',
            _formatDate(employeeData!['joining_date']),
            Icons.calendar_today_rounded,
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Change password
                  },
                  icon: const Icon(Icons.lock_rounded, size: 16),
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
                  icon: const Icon(Icons.support_agent_rounded, size: 16),
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
    );
  }

  Widget _buildMetricCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GlobalColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: GlobalColors.primaryBlue),
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
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not Available';
    
    if (date is DateTime) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
    
    if (date is String) {
      try {
        final parsedDate = DateTime.parse(date.split('T')[0]);
        return DateFormat('dd/MM/yyyy').format(parsedDate);
      } catch (e) {
        return date;
      }
    }
    
    return date.toString();
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mega_pro/global/global_variables.dart';

class MarketingProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const MarketingProfilePage({super.key, this.userData});

  @override
  State<MarketingProfilePage> createState() => _MarketingProfilePageState();
}

class _MarketingProfilePageState extends State<MarketingProfilePage> {
  final ImagePicker picker = ImagePicker();
  File? profileImage;

  Map<String, dynamic>? managerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    try {
      final supabase = Supabase.instance.client;
      
      // If userData is passed from dashboard, use it directly
      if (widget.userData != null && widget.userData!.isNotEmpty) {
        _processUserData(widget.userData!);
        return;
      }
      
      // Otherwise fetch from database
      final user = supabase.auth.currentUser;
      if (user == null) return;

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
      _createDefaultProfile('manager@mega.com');
    }
  }

  void _processUserData(Map<String, dynamic> data) {
    setState(() {
      managerData = {
        'empId': data['emp_id'] ?? 'N/A',
        'empName': data['full_name'] ?? 'Marketing Manager',
        'position': data['position'] ?? 'Marketing Manager',
        'branch': data['branch'] ?? 'Head Office',
        'district': data['district'] ?? 'N/A',
        'joiningDate': data['joining_date'] != null 
            ? DateTime.parse(data['joining_date']) 
            : DateTime.now(),
        'status': data['status'] ?? 'Active',
        'phone': data['phone'] ?? 'Not Provided',
        'email': data['email'] ?? 'N/A',
        'performance': (data['performance'] ?? 0).toDouble(),
        'attendance': (data['attendance'] ?? 0).toDouble(),
        'role': data['role'] ?? 'Marketing Manager',
        'salary': data['salary'] ?? 0,
      };
      isLoading = false;
    });
  }

  void _createDefaultProfile(String email) {
    setState(() {
      managerData = {
        'empId': 'MM${DateTime.now().millisecondsSinceEpoch % 1000}',
        'empName': 'Marketing Manager',
        'position': 'Marketing Manager',
        'branch': 'Marketing Department',
        'district': 'Corporate',
        'joiningDate': DateTime.now(),
        'status': 'Active',
        'phone': '9876543210',
        'email': email,
        'performance': 85.0,
        'attendance': 95.0,
        'role': 'Marketing Manager',
        'salary': 0,
      };
      isLoading = false;
    });
  }

  // ================= IMAGE PICKER =================
  Future<void> pickProfileImage() async {
    final XFile? file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file != null) {
      setState(() => profileImage = File(file.path));
    }
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: GlobalColors.primaryBlue,
        ),
      );
    }

    if (managerData == null) {
      return Center(
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
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final manager = managerData!;

    return Scaffold(
      backgroundColor: GlobalColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(manager),
            const SizedBox(height: 20),
            _buildTabSection(manager),
            const SizedBox(height: 20), // Add bottom padding
          ],
        ),
      ),
      
    );
  }

  // ================= PROFILE HEADER =================
  Widget _buildProfileHeader(Map<String, dynamic> manager) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GlobalColors.primaryBlue,
            GlobalColors.primaryBlue.withOpacity(0.9),
          ],
        ),
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
                      backgroundImage:
                          profileImage != null ? FileImage(profileImage!) : null,
                      child: profileImage == null
                          ? Text(
                              (manager['empName'] is String && 
                              manager['empName'].isNotEmpty)
                                ? manager['empName'].substring(0, 2).toUpperCase()
                                : "MM",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: GlobalColors.primaryBlue,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: GlobalColors.primaryBlue,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager['empName']?.toString() ?? 'Marketing Manager',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      manager['position']?.toString() ?? 'Marketing Manager',
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
                        manager['status']?.toString() ?? 'Active',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          _buildManagerIdCard(manager),
        ],
      ),
    );
  }

  Widget _buildManagerIdCard(Map<String, dynamic> manager) {
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
          _idItem("Employee ID", manager['empId']?.toString() ?? 'N/A'),
          _idItem("Branch", manager['branch']?.toString() ?? 'N/A'),
          _idItem(
            "Since",
            DateFormat("MMM yyyy").format(
              manager['joiningDate'] is DateTime 
                ? manager['joiningDate'] 
                : DateTime.now()
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
        Text(title,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }

  // ================= TABS =================
  Widget _buildTabSection(Map<String, dynamic> manager) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 450,
      ),
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
              height: 450, // Increased height to prevent overflow
              child: TabBarView(
                children: [
                  _detailsTab(manager),
                  _performanceTab(manager),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsTab(Map<String, dynamic> manager) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoItem(Icons.email, "Email", manager['email']?.toString() ?? 'N/A'),
                const Divider(),
                _infoItem(Icons.phone, "Phone", manager['phone']?.toString() ?? 'N/A'),
                const Divider(),
                _infoItem(Icons.location_on, "District", manager['district']?.toString() ?? 'N/A'),
                const Divider(),
                _infoItem(Icons.business, "Branch", manager['branch']?.toString() ?? 'N/A'),
                const Divider(),
                _infoItem(
                  Icons.calendar_today, 
                  "Joining Date", 
                  DateFormat('dd MMMM yyyy').format(
                    manager['joiningDate'] is DateTime 
                      ? manager['joiningDate'] 
                      : DateTime.now()
                  ),
                ),
                if (manager['role'] != null) ...[
                  const Divider(),
                  _infoItem(Icons.work, "Role", manager['role']?.toString() ?? 'N/A'),
                ],
                if (manager['salary'] != null && manager['salary'] > 0) ...[
                  const Divider(),
                  _infoItem(Icons.currency_rupee, "Salary", "₹${manager['salary']}"),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _performanceTab(Map<String, dynamic> manager) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    _metricCard("Performance", manager['performance']?.toDouble() ?? 0.0,
                        GlobalColors.primaryBlue),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey[300],
                    ),
                    _metricCard("Attendance", manager['attendance']?.toDouble() ?? 0.0,
                        AppColors.successGreen),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Additional Marketing Metrics
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
                      "Marketing Performance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _marketingMetric(
                      title: "Target Achievement",
                      value: "92.5%",
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _marketingMetric(
                      title: "Campaign ROI",
                      value: "24.5%",
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _marketingMetric(
                      title: "Team Productivity",
                      value: "88%",
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

  Widget _marketingMetric({
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
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
}
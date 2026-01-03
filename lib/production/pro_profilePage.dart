import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mega_pro/global/global_variables.dart';

class ProductionProfilePage extends StatefulWidget {
  const ProductionProfilePage({super.key});

  @override
  State<ProductionProfilePage> createState() => _ProductionProfilePageState();
}

class _ProductionProfilePageState extends State<ProductionProfilePage> {
  final ImagePicker picker = ImagePicker();
  File? profileImage;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        _createDefaultProfile();
        return;
      }

      final data = await supabase
          .from('emp_profile')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) {
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
      _createDefaultProfile('production@mega.com');
    }
  }

  void _processUserData(Map<String, dynamic> data) {
    setState(() {
      userData = {
        'empId': data['emp_id'] ?? 'N/A',
        'empName': data['full_name'] ?? 'Production Manager',
        'position': data['position'] ?? 'Production Manager',
        'branch': data['branch'] ?? 'Production Unit',
        'department': data['department'] ?? 'Production',
        'joiningDate': data['joining_date'] != null
            ? DateTime.parse(data['joining_date'])
            : DateTime.now(),
        'status': data['status'] ?? 'Active',
        'phone': data['phone'] ?? 'Not Provided',
        'email': data['email'] ?? 'N/A',
        'performance': (data['performance'] ?? 0).toDouble(),
        'attendance': (data['attendance'] ?? 0).toDouble(),
        'role': data['role'] ?? 'Production Manager',
        'salary': data['salary'] ?? 0,
        'shift': data['shift'] ?? 'Day',
        'experience': data['experience'] ?? '0 years',
      };
      isLoading = false;
    });
  }

  void _createDefaultProfile([String email = 'production@mega.com']) {
    setState(() {
      userData = {
        'empId': 'PM${DateTime.now().millisecondsSinceEpoch % 1000}',
        'empName': 'Production Manager',
        'position': 'Production Manager',
        'branch': 'Production Unit',
        'department': 'Production',
        'joiningDate': DateTime.now(),
        'status': 'Active',
        'phone': '9876543210',
        'email': email,
        'performance': 92.0,
        'attendance': 96.0,
        'role': 'Production Manager',
        'salary': 0,
        'shift': 'Day',
        'experience': '5 years',
      };
      isLoading = false;
    });
  }

  Future<void> pickProfileImage() async {
    final XFile? file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file != null) {
      setState(() => profileImage = File(file.path));
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/', 
        (route) => false
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  Widget _buildProfileHeader(Map<String, dynamic> user) {
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
                    width: 90,
                    height: 90,
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
                              (user['empName'] is String &&
                                      user['empName'].isNotEmpty)
                                  ? user['empName']
                                      .substring(0, 2)
                                      .toUpperCase()
                                  : "PM",
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            user['empName']?.toString() ?? 'Production Manager',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
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
                                      Navigator.pop(context);
                                      _logout();
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
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user['position']?.toString() ?? 'Production Manager',
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
                        user['status']?.toString() ?? 'Active',
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
          _buildUserIdCard(user),
        ],
      ),
    );
  }

  Widget _buildUserIdCard(Map<String, dynamic> user) {
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
          _idItem("Employee ID", user['empId']?.toString() ?? 'N/A'),
          _idItem("Department", user['department']?.toString() ?? 'Production'),
          _idItem(
            "Since",
            DateFormat("MMM yyyy").format(
                user['joiningDate'] is DateTime
                    ? user['joiningDate']
                    : DateTime.now()),
          ),
        ],
      ),
    );
  }

  Widget _idItem(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
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
      ),
    );
  }

  Widget _buildTabSection(Map<String, dynamic> user) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              labelColor: GlobalColors.primaryBlue,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: GlobalColors.primaryBlue,
                    width: 2.0,
                  ),
                ),
              ),
              tabs: const [
                Tab(text: "Details"),
                Tab(text: "Production Stats"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 500,
            child: TabBarView(
              children: [
                _detailsTab(user),
                _productionStatsTab(user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsTab(Map<String, dynamic> user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _infoItem(Icons.email, "Email",
                    user['email']?.toString() ?? 'N/A'),
                const Divider(),
                _infoItem(Icons.phone, "Phone",
                    user['phone']?.toString() ?? 'N/A'),
                const Divider(),
                _infoItem(Icons.business, "Branch",
                    user['branch']?.toString() ?? 'N/A'),
                const Divider(),
                _infoItem(Icons.work, "Department",
                    user['department']?.toString() ?? 'Production'),
                const Divider(),
                _infoItem(Icons.calendar_today, "Joining Date",
                  DateFormat('dd MMMM yyyy').format(
                    user['joiningDate'] is DateTime
                        ? user['joiningDate']
                        : DateTime.now(),
                  ),
                ),
                const Divider(),
                _infoItem(Icons.work, "Role",
                    user['role']?.toString() ?? 'Production Manager'),
                const Divider(),
                _infoItem(Icons.access_time, "Shift",
                    user['shift']?.toString() ?? 'Day'),
                const Divider(),
                _infoItem(Icons.timeline, "Experience",
                    user['experience']?.toString() ?? 'N/A'),
                if (user['salary'] != null && user['salary'] > 0) ...[
                  const Divider(),
                  _infoItem(Icons.currency_rupee, "Salary",
                      "₹${user['salary']}"),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _productionStatsTab(Map<String, dynamic> user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
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
                    _metricCard("Performance",
                        user['performance']?.toDouble() ?? 0.0,
                        GlobalColors.primaryBlue),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey[300],
                    ),
                    _metricCard("Attendance",
                        user['attendance']?.toDouble() ?? 0.0,
                        Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Production Performance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _productionMetric(
                      title: "Quality Rate",
                      value: "98.5%",
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _productionMetric(
                      title: "Efficiency",
                      value: "94%",
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _productionMetric(
                      title: "Machine Uptime",
                      value: "96%",
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _productionMetric(
                      title: "Safety Score",
                      value: "99%",
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

  Widget _productionMetric({
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
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: GlobalColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: GlobalColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            color: GlobalColors.primaryBlue,
          ),
        ),
      );
    }

    if (userData == null) {
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
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final user = userData!;

    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),        
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 20),
                  _buildTabSection(user),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:mega_pro/global/global_variables.dart';

// class ProductionManagerProfile extends StatefulWidget {
//   const ProductionManagerProfile({super.key});

//   @override
//   State<ProductionManagerProfile> createState() =>
//       _ProductionManagerProfileState();
// }

// class _ProductionManagerProfileState extends State<ProductionManagerProfile> {
//   final supabase = Supabase.instance.client;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   // Production manager data
//   final Map<String, dynamic> productionManagerData = {
//     'name': 'Rajesh Kumar',
//     'email': 'rajesh.kumar@megapro.com',
//     'employeeId': 'PM-2023-045',
//     'department': 'Production',
//     'designation': 'Production Manager',
//     'joiningDate': 'March 15, 2022',
//     'contact': '+91 98765 43210',
//     'location': 'Mumbai Plant',
//     'shift': 'Day Shift (8 AM - 5 PM)',
//     'manager': 'Amit Sharma (Plant Head)',
//   };

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.menu),
//           onPressed: () => _scaffoldKey.currentState?.openDrawer(),
//         ),
//         title: const Text(
//           "Production Manager Profile",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         actions: [
//           IconButton(
//             onPressed: () => _showEditProfileDialog(context),
//             icon: const Icon(Icons.edit_outlined),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _profileHeader(),
//             const SizedBox(height: 24),
//             _metricsSection(),
//             const SizedBox(height: 16),
//             _personalInfoSection(),
//             const SizedBox(height: 16),
//             _teamSection(),
//             const SizedBox(height: 16),
//             _toolsSection(),
//             const SizedBox(height: 16),
//             _settingsSection(),
//             const SizedBox(height: 24),
//             _logoutButton(),
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }

//   // ================= HEADER =================

//   Widget _profileHeader() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: _cardDecoration(),
//       child: Column(
//         children: [
//           Stack(
//             alignment: Alignment.bottomRight,
//             children: [
//               Container(
//                 width: 100,
//                 height: 100,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border:
//                       Border.all(color: GlobalColors.primaryBlue, width: 3),
//                 ),
//                 child: const Icon(
//                   Icons.factory_rounded,
//                   size: 50,
//                   color: GlobalColors.primaryBlue,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.all(6),
//                 decoration: const BoxDecoration(
//                   color: Colors.green,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.verified_rounded,
//                     size: 16, color: Colors.white),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             productionManagerData['name'],
//             style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.w700,
//                 color: GlobalColors.primaryBlue),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             productionManagerData['designation'],
//             style: TextStyle(color: Colors.grey.shade600),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             productionManagerData['email'],
//             style: TextStyle(color: Colors.grey.shade600),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= SECTIONS =================

//   Widget _metricsSection() {
//     return _sectionCard(
//       title: "Production Metrics",
//       icon: Icons.analytics_rounded,
//       children: [
//         _metricRow("Daily Target", "125 MT", "Achieved: 130 MT",
//             Icons.flag_rounded, Colors.blue),
//         _metricRow("Monthly Output", "2,850 MT", "On Track",
//             Icons.calendar_month_rounded, Colors.green),
//         _metricRow("Quality Rate", "98.5%", "Above Standard",
//             Icons.high_quality_rounded, Colors.purple),
//         _metricRow("Downtime", "2.3%", "Below Target",
//             Icons.timer_off_rounded, Colors.orange),
//       ],
//     );
//   }

//   Widget _personalInfoSection() {
//     return _sectionCard(
//       title: "Personal Information",
//       icon: Icons.person_outline_rounded,
//       children: productionManagerData.entries
//           .map((e) => _infoRow(e.key, e.value))
//           .toList(),
//     );
//   }

//   Widget _teamSection() {
//     return _sectionCard(
//       title: "Production Team",
//       icon: Icons.groups_rounded,
//       children: [
//         _teamMember("Vikram Singh", "Shift Supervisor", "3 Teams",
//             Icons.badge_rounded),
//         _teamMember("Priya Sharma", "QC Manager", "95% Quality",
//             Icons.verified_user_rounded),
//         _teamMember("Anil Patel", "Maintenance Head", "12 Machines",
//             Icons.build_rounded),
//         _teamMember("Sneha Reddy", "Inventory Manager", "Optimized Stock",
//             Icons.inventory_2_rounded),
//       ],
//     );
//   }

//   Widget _toolsSection() {
//     return _sectionCard(
//       title: "Production Tools",
//       icon: Icons.settings_applications_rounded,
//       children: [
//         _toolItem("Inventory Management", Icons.inventory_2_rounded, onTap: () {}),
//         _toolItem("Order Processing", Icons.receipt_long_rounded, onTap: () {}),
//         _toolItem("Production Schedule", Icons.schedule_rounded, onTap: () {}),
//         _toolItem("Quality Reports", Icons.assignment_rounded, onTap: () {}),
//       ],
//     );
//   }

//   Widget _settingsSection() {
//     return _sectionCard(
//       title: "Account Settings",
//       icon: Icons.settings_outlined,
//       children: [
//         _settingItem(
//             title: "Change Password",
//             icon: Icons.lock_outline_rounded,
//             onTap: () {}),
//         _settingItem(
//             title: "Notification Settings",
//             icon: Icons.notifications_outlined,
//             onTap: () {}),
//         _settingItem(
//             title: "Production Alerts",
//             icon: Icons.warning_amber_rounded,
//             onTap: () {}),
//         _settingItem(
//             title: "Language",
//             icon: Icons.language_rounded,
//             trailingText: "English",
//             onTap: () {}),
//       ],
//     );
//   }

//   Widget _logoutButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         onPressed: () => _showLogoutConfirmation(context),
//         icon: const Icon(Icons.logout_rounded),
//         label: const Text("Logout"),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.red.shade50,
//           foregroundColor: Colors.red,
//           elevation: 0,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//             side: BorderSide(color: Colors.red.shade200),
//           ),
//         ),
//       ),
//     );
//   }

//   // ================= REUSABLE WIDGETS =================

//   Widget _sectionCard(
//       {required String title,
//       required IconData icon,
//       required List<Widget> children}) {
//     return Container(
//       decoration: _cardDecoration(),
//       child: Column(
//         children: [
//           ListTile(
//             leading: Icon(icon, color: GlobalColors.primaryBlue),
//             title: Text(title,
//                 style: const TextStyle(fontWeight: FontWeight.w600)),
//           ),
//           const Divider(height: 0),
//           ...children,
//         ],
//       ),
//     );
//   }

//   Widget _metricRow(String label, String value, String subText, IconData icon,
//       Color color) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: color.withOpacity(.1),
//         child: Icon(icon, color: color, size: 18),
//       ),
//       title: Text(value,
//           style: TextStyle(
//               fontWeight: FontWeight.w600, color: color, fontSize: 15)),
//       subtitle: Text(label),
//       trailing:
//           Text(subText, style: TextStyle(color: Colors.grey.shade600)),
//     );
//   }

//   Widget _infoRow(String label, String value) =>
//       ListTile(title: Text(label), trailing: Text(value));

//   Widget _teamMember(
//       String name, String role, String detail, IconData icon) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: GlobalColors.primaryBlue.withOpacity(.1),
//         child: Icon(icon, color: GlobalColors.primaryBlue),
//       ),
//       title: Text(name),
//       subtitle: Text(role),
//       trailing:
//           Text(detail, style: const TextStyle(color: Colors.green)),
//     );
//   }

//   Widget _toolItem(String title, IconData icon,
//           {required VoidCallback onTap}) =>
//       ListTile(
//         onTap: onTap,
//         leading:
//             Icon(icon, color: GlobalColors.primaryBlue),
//         title: Text(title),
//         trailing: const Icon(Icons.chevron_right_rounded),
//       );

//   Widget _settingItem(
//       {required String title,
//       required IconData icon,
//       String? trailingText,
//       required VoidCallback onTap}) {
//     return ListTile(
//       onTap: onTap,
//       leading:
//           Icon(icon, color: GlobalColors.primaryBlue),
//       title: Text(title),
//       trailing: Row(mainAxisSize: MainAxisSize.min, children: [
//         if (trailingText != null) Text(trailingText),
//         const Icon(Icons.chevron_right_rounded),
//       ]),
//     );
//   }

//   BoxDecoration _cardDecoration() => BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(.05),
//               blurRadius: 10,
//               offset: const Offset(0, 2)),
//         ],
//       );

//   // ================= DIALOGS =================

//   void _showEditProfileDialog(BuildContext context) {}
//   void _showLogoutConfirmation(BuildContext context) {}
// }

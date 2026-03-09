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
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _positionController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfile();
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
        'district': data['district'] ?? 'Not Set',
        'joiningDate': data['joining_date'] != null
            ? DateTime.parse(data['joining_date'])
            : DateTime.now(),
        'status': data['status'] ?? 'Active',
        'phone': data['phone'] ?? 'Not Provided',
        'email': data['email'] ?? 'N/A',
        'role': data['role'] ?? 'Production Manager',
        'salary': data['salary'] ?? 0,
        'shift': data['shift'] ?? 'Day',
        'experience': data['experience'] ?? '0 years',
        'profile_image': data['profile_image'],
      };

      _nameController.text = data['full_name']?.toString() ?? 'Production Manager';
      _emailController.text = data['email']?.toString() ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';
      _positionController.text = data['position']?.toString() ?? 'Production Manager';

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
        'district': 'Corporate',
        'joiningDate': DateTime.now(),
        'status': 'Active',
        'phone': '9876543210',
        'email': email,
        'role': 'Production Manager',
        'salary': 0,
        'shift': 'Day',
        'experience': '5 years',
      };

      _nameController.text = 'Production Manager';
      _emailController.text = email;
      _phoneController.text = '9876543210';
      _positionController.text = 'Production Manager';

      isLoading = false;
    });
  }

  Future<void> pickProfileImage() async {
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

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }

          setState(() => _isEditing = false);
          
          // Reload profile
          await _loadProfile();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      print('Error logging out: $e');
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

    final user = userData!;

    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text(
                    'Are you sure you want to logout?',
                  ),
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
      body: SingleChildScrollView(
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
    );
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
                          : (user['profile_image'] != null
                              ? NetworkImage(user['profile_image'])
                              : null),
                      child: profileImage == null &&
                              user['profile_image'] == null
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
                  if (_isEditing)
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
                      user['empName']?.toString() ?? 'Production Manager',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
              ),
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
                  : DateTime.now(),
            ),
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
    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      child: DefaultTabController(
        length: 1, // Changed to 1 since we removed performance stats
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
              child: const TabBar(
                labelColor: GlobalColors.primaryBlue,
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: GlobalColors.primaryBlue,
                      width: 2.0,
                    ),
                  ),
                ),
                tabs: [
                  Tab(text: "Details"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 500,
              child: TabBarView(
                children: [_detailsTab(user)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsTab(Map<String, dynamic> user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _isEditing ? _buildEditForm() : _buildDisplayInfo(user),
            if (!_isEditing) ...[
              const SizedBox(height: 20),
              _buildAdditionalInfo(user),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                              userData!['empName']?.toString() ?? '';
                          _phoneController.text =
                              userData!['phone']?.toString() ?? '';
                          _positionController.text =
                              userData!['position']?.toString() ?? '';
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

  Widget _buildDisplayInfo(Map<String, dynamic> user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoItem(
              Icons.email,
              "Email",
              user['email']?.toString() ?? 'N/A',
            ),
            const Divider(),
            _infoItem(
              Icons.phone,
              "Phone",
              user['phone']?.toString() ?? 'N/A',
            ),
            const Divider(),
            _infoItem(
              Icons.location_on,
              "District",
              user['district']?.toString() ?? 'Not Set',
            ),
            const Divider(),
            _infoItem(
              Icons.business,
              "Branch",
              user['branch']?.toString() ?? 'N/A',
            ),
            const Divider(),
            _infoItem(
              Icons.work,
              "Department",
              user['department']?.toString() ?? 'Production',
            ),
            const Divider(),
            _infoItem(
              Icons.calendar_today,
              "Joining Date",
              DateFormat('dd MMMM yyyy').format(
                user['joiningDate'] is DateTime
                    ? user['joiningDate']
                    : DateTime.now(),
              ),
            ),
            const Divider(),
            _infoItem(
              Icons.work,
              "Role",
              user['role']?.toString() ?? 'Production Manager',
            ),
            const Divider(),
            _infoItem(
              Icons.access_time,
              "Shift",
              user['shift']?.toString() ?? 'Day',
            ),
            const Divider(),
            _infoItem(
              Icons.timeline,
              "Experience",
              user['experience']?.toString() ?? 'N/A',
            ),
            if (user['salary'] != null && user['salary'] > 0) ...[
              const Divider(),
              _infoItem(
                Icons.currency_rupee,
                "Salary",
                "₹${user['salary']}",
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

  Widget _buildAdditionalInfo(Map<String, dynamic> user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _isEditing = true);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: GlobalColors.primaryBlue),
                      foregroundColor: GlobalColors.primaryBlue,
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




















// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:mega_pro/global/global_variables.dart';

// class ProductionProfilePage extends StatefulWidget {
//   const ProductionProfilePage({super.key});

//   @override
//   State<ProductionProfilePage> createState() => _ProductionProfilePageState();
// }

// class _ProductionProfilePageState extends State<ProductionProfilePage> {
//   final ImagePicker picker = ImagePicker();
//   File? profileImage;

//   Map<String, dynamic>? userData;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//   }

//   Future<void> _loadProfile() async {
//     try {
//       final supabase = Supabase.instance.client;
//       final user = supabase.auth.currentUser;

//       if (user == null) {
//         _createDefaultProfile();
//         return;
//       }

//       final data = await supabase
//           .from('emp_profile')
//           .select('*')
//           .eq('user_id', user.id)
//           .maybeSingle();

//       if (data == null) {
//         final emailData = await supabase
//             .from('emp_profile')
//             .select('*')
//             .eq('email', user.email!)
//             .maybeSingle();

//         if (emailData != null) {
//           _processUserData(emailData);
//         } else {
//           _createDefaultProfile(user.email!);
//         }
//       } else {
//         _processUserData(data);
//       }
//     } catch (e) {
//       debugPrint('Error loading profile: $e');
//       _createDefaultProfile('production@mega.com');
//     }
//   }

//   void _processUserData(Map<String, dynamic> data) {
//     setState(() {
//       userData = {
//         'empId': data['emp_id'] ?? 'N/A',
//         'empName': data['full_name'] ?? 'Production Manager',
//         'position': data['position'] ?? 'Production Manager',
//         'branch': data['branch'] ?? 'Production Unit',
//         'department': data['department'] ?? 'Production',
//         'joiningDate': data['joining_date'] != null
//             ? DateTime.parse(data['joining_date'])
//             : DateTime.now(),
//         'status': data['status'] ?? 'Active',
//         'phone': data['phone'] ?? 'Not Provided',
//         'email': data['email'] ?? 'N/A',
//         'performance': (data['performance'] ?? 0).toDouble(),
//         'attendance': (data['attendance'] ?? 0).toDouble(),
//         'role': data['role'] ?? 'Production Manager',
//         'salary': data['salary'] ?? 0,
//         'shift': data['shift'] ?? 'Day',
//         'experience': data['experience'] ?? '0 years',
//       };
//       isLoading = false;
//     });
//   }

//   void _createDefaultProfile([String email = 'production@mega.com']) {
//     setState(() {
//       userData = {
//         'empId': 'PM${DateTime.now().millisecondsSinceEpoch % 1000}',
//         'empName': 'Production Manager',
//         'position': 'Production Manager',
//         'branch': 'Production Unit',
//         'department': 'Production',
//         'joiningDate': DateTime.now(),
//         'status': 'Active',
//         'phone': '9876543210',
//         'email': email,
//         'performance': 92.0,
//         'attendance': 96.0,
//         'role': 'Production Manager',
//         'salary': 0,
//         'shift': 'Day',
//         'experience': '5 years',
//       };
//       isLoading = false;
//     });
//   }

//   Future<void> pickProfileImage() async {
//     final XFile? file = await picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 75,
//     );
//     if (file != null) {
//       setState(() => profileImage = File(file.path));
//     }
//   }

//   Future<void> _logout() async {
//     try {
//       await Supabase.instance.client.auth.signOut();
//       Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
//     } catch (e) {
//       print('Error logging out: $e');
//     }
//   }

//   Widget _buildProfileHeader(Map<String, dynamic> user) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: GlobalColors.primaryBlue,
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(24),
//           bottomRight: Radius.circular(24),
//         ),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Stack(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 3),
//                     ),
//                     child: CircleAvatar(
//                       radius: 40,
//                       backgroundColor: Colors.white,
//                       backgroundImage: profileImage != null
//                           ? FileImage(profileImage!)
//                           : null,
//                       child: profileImage == null
//                           ? Text(
//                               (user['empName'] is String &&
//                                       user['empName'].isNotEmpty)
//                                   ? user['empName']
//                                         .substring(0, 2)
//                                         .toUpperCase()
//                                   : "PM",
//                               style: TextStyle(
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.bold,
//                                 color: GlobalColors.primaryBlue,
//                               ),
//                             )
//                           : null,
//                     ),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: GestureDetector(
//                       onTap: pickProfileImage,
//                       child: Container(
//                         padding: const EdgeInsets.all(6),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.15),
//                               blurRadius: 4,
//                             ),
//                           ],
//                         ),
//                         child: Icon(
//                           Icons.camera_alt,
//                           size: 18,
//                           color: GlobalColors.primaryBlue,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Text(
//                             user['empName']?.toString() ?? 'Production Manager',
//                             style: const TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           onPressed: () {
//                             showDialog(
//                               context: context,
//                               builder: (context) => AlertDialog(
//                                 title: const Text('Confirm Logout'),
//                                 content: const Text(
//                                   'Are you sure you want to logout?',
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     child: const Text('Cancel'),
//                                   ),
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.pop(context);
//                                       _logout();
//                                     },
//                                     child: const Text(
//                                       'Logout',
//                                       style: TextStyle(color: Colors.red),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.logout, color: Colors.white),
//                           tooltip: 'Logout',
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       user['position']?.toString() ?? 'Production Manager',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 6,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         user['status']?.toString() ?? 'Active',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           _buildUserIdCard(user),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserIdCard(Map<String, dynamic> user) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withOpacity(0.2)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           _idItem("Employee ID", user['empId']?.toString() ?? 'N/A'),
//           _idItem("Department", user['department']?.toString() ?? 'Production'),
//           _idItem(
//             "Since",
//             DateFormat("MMM yyyy").format(
//               user['joiningDate'] is DateTime
//                   ? user['joiningDate']
//                   : DateTime.now(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _idItem(String title, String value) {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.8),
//               fontSize: 12,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabSection(Map<String, dynamic> user) {
//     return DefaultTabController(
//       length: 2,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 6,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: TabBar(
//               labelColor: GlobalColors.primaryBlue,
//               unselectedLabelColor: Colors.grey[600],
//               indicator: BoxDecoration(
//                 border: Border(
//                   bottom: BorderSide(
//                     color: GlobalColors.primaryBlue,
//                     width: 2.0,
//                   ),
//                 ),
//               ),
//               tabs: const [
//                 Tab(text: "Details"),
//                 Tab(text: "Production Stats"),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             height: 500,
//             child: TabBarView(
//               children: [_detailsTab(user), _productionStatsTab(user)],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _detailsTab(Map<String, dynamic> user) {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 _infoItem(
//                   Icons.email,
//                   "Email",
//                   user['email']?.toString() ?? 'N/A',
//                 ),
//                 const Divider(),
//                 _infoItem(
//                   Icons.phone,
//                   "Phone",
//                   user['phone']?.toString() ?? 'N/A',
//                 ),
//                 const Divider(),
//                 _infoItem(
//                   Icons.business,
//                   "Branch",
//                   user['branch']?.toString() ?? 'N/A',
//                 ),
//                 const Divider(),
//                 _infoItem(
//                   Icons.work,
//                   "Department",
//                   user['department']?.toString() ?? 'Production',
//                 ),
//                 const Divider(),
//                 _infoItem(
//                   Icons.calendar_today,
//                   "Joining Date",
//                   DateFormat('dd MMMM yyyy').format(
//                     user['joiningDate'] is DateTime
//                         ? user['joiningDate']
//                         : DateTime.now(),
//                   ),
//                 ),
//                 const Divider(),
//                 _infoItem(
//                   Icons.work,
//                   "Role",
//                   user['role']?.toString() ?? 'Production Manager',
//                 ),
//                 const Divider(),
//                 _infoItem(
//                   Icons.access_time,
//                   "Shift",
//                   user['shift']?.toString() ?? 'Day',
//                 ),
//                 const Divider(),
//                 _infoItem(
//                   Icons.timeline,
//                   "Experience",
//                   user['experience']?.toString() ?? 'N/A',
//                 ),
//                 if (user['salary'] != null && user['salary'] > 0) ...[
//                   const Divider(),
//                   _infoItem(
//                     Icons.currency_rupee,
//                     "Salary",
//                     "₹${user['salary']}",
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _productionStatsTab(Map<String, dynamic> user) {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Column(
//           children: [
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _metricCard(
//                       "Performance",
//                       user['performance']?.toDouble() ?? 0.0,
//                       GlobalColors.primaryBlue,
//                     ),
//                     Container(width: 1, height: 60, color: Colors.grey[300]),
//                     _metricCard(
//                       "Attendance",
//                       user['attendance']?.toDouble() ?? 0.0,
//                       Colors.green,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Production Performance",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _productionMetric(
//                       title: "Quality Rate",
//                       value: "98.5%",
//                       color: Colors.green,
//                     ),
//                     const SizedBox(height: 12),
//                     _productionMetric(
//                       title: "Efficiency",
//                       value: "94%",
//                       color: Colors.blue,
//                     ),
//                     const SizedBox(height: 12),
//                     _productionMetric(
//                       title: "Machine Uptime",
//                       value: "96%",
//                       color: Colors.orange,
//                     ),
//                     const SizedBox(height: 12),
//                     _productionMetric(
//                       title: "Safety Score",
//                       value: "99%",
//                       color: Colors.purple,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _metricCard(String title, double value, Color color) {
//     return Expanded(
//       child: Column(
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "${value.toStringAsFixed(1)}%",
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Container(
//             width: 60,
//             height: 6,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(3),
//             ),
//             child: FractionallySizedBox(
//               alignment: Alignment.centerLeft,
//               widthFactor: value / 100,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: color,
//                   borderRadius: BorderRadius.circular(3),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _productionMetric({
//     required String title,
//     required String value,
//     required Color color,
//   }) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey[700],
//           ),
//         ),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _infoItem(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: GlobalColors.primaryBlue.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, size: 20, color: GlobalColors.primaryBlue),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         backgroundColor: GlobalColors.background,
//         body: const Center(
//           child: CircularProgressIndicator(color: GlobalColors.primaryBlue),
//         ),
//       );
//     }

//     if (userData == null) {
//       return Scaffold(
//         backgroundColor: GlobalColors.background,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, size: 64, color: Colors.grey),
//               const SizedBox(height: 16),
//               const Text(
//                 'Profile Not Found',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Contact administrator to set up your profile',
//                 style: TextStyle(color: Colors.grey),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _loadProfile,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                 ),
//                 child: const Text(
//                   'Retry',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final user = userData!;

//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         title: Text(
//           "My Profile",
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//             fontSize: 22,
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               //physics: const BouncingScrollPhysics(),
//               child: Column(
//                 children: [
//                   _buildProfileHeader(user),
//                   const SizedBox(height: 20),
//                   _buildTabSection(user),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

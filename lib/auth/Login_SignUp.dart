import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mega_pro/dashboards/emp_dashboard.dart';
import 'package:mega_pro/dashboards/mar_dashboard.dart';
import 'package:mega_pro/dashboards/pro_dashboard.dart';
import 'package:mega_pro/dashboards/own_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required String selectedRole});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLogin ? "Welcome Back!" : "Create Account",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isLogin
                      ? "Login to access your dashboard"
                      : "Sign up after admin creates your profile",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                /// FORM
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _inputField(
                        label: "Email",
                        icon: Icons.email_outlined,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 16),

                      _inputField(
                        label: "Password",
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),

                      if (!isLogin)
                        _inputField(
                          label: "Confirm Password",
                          icon: Icons.lock_outline,
                          controller: _confirmPasswordController,
                          isPassword: true,
                        ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isLogin ? "Log In" : "Create Account",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      isLogin = !isLogin;
                      errorMessage = null;
                      _confirmPasswordController.clear();
                    });
                  },
                  child: Text.rich(
                    TextSpan(
                      text: isLogin
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      children: [
                        TextSpan(
                          text: isLogin ? "Sign Up" : "Login",
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: (value) {
        if (value == null || value.isEmpty) return "This field is required";
        if (label == "Email" && !value.contains("@")) {
          return "Enter valid email";
        }
        if (label == "Password" && value.length < 6) {
          return "Minimum 6 characters";
        }
        if (label == "Confirm Password" &&
            value != _passwordController.text) {
          return "Passwords do not match";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // FIXED: Better role detection with exact matching
  void _navigateToDashboard(Map<String, dynamic> employee) {
    final role = employee['role']?.toString().trim() ?? 'Employee';
    
    print('Navigating with role: $role');
    print('Employee data: $employee');
    
    switch (role) {
      case 'Marketing Manager':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MarketingManagerDashboard(userData: employee),
          ),
        );
        break;
      case 'Production Manager':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductionDashboard(userData: employee),
          ),
        );
        break;
      case 'Owner':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerDashboard(userData: employee),
          ),
        );
        break;
      case 'Employee':
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeDashboard(userData: employee),
          ),
        );
        break;
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => errorMessage = null);
    final supabase = Supabase.instance.client;

    try {
      // ================= AUTH =================
      if (isLogin) {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw 'Authentication failed. Please try again.';
      }

      // 1️⃣ Find employee row by email
      final response = await supabase
          .from('emp_profile')
          .select()
          .eq('email', user.email!)
          .maybeSingle();

      if (response == null) {
        throw 'Employee not found. Contact admin to create your profile.';
      }

      // Convert to Map for easier handling
      final employee = Map<String, dynamic>.from(response);

      // 2️⃣ Attach user_id ONLY ONCE
      if (employee['user_id'] == null) {
        await supabase.from('emp_profile').update({
          'user_id': user.id,
        }).eq('email', user.email!);
        
        // Refresh employee data with updated user_id
        final updatedResponse = await supabase
            .from('emp_profile')
            .select()
            .eq('email', user.email!)
            .maybeSingle();
            
        if (updatedResponse != null) {
          // Navigate with updated data
          _navigateToDashboard(Map<String, dynamic>.from(updatedResponse));
        } else {
          _navigateToDashboard(employee);
        }
      } else {
        // Navigate with existing data
        _navigateToDashboard(employee);
      }

    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }
}










//working properly for all roles with user data passing

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'package:mega_pro/dashboards/emp_dashboard.dart';
// import 'package:mega_pro/dashboards/mar_dashboard.dart';
// import 'package:mega_pro/dashboards/pro_dashboard.dart';
// import 'package:mega_pro/dashboards/own_dashboard.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key, required String selectedRole});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   bool isLogin = true;
//   final _formKey = GlobalKey<FormState>();
//   String? errorMessage;

//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _fullNameController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _fullNameController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F5F9),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Container(
//             width: 400,
//             padding: const EdgeInsets.all(32),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(24),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 20,
//                   offset: const Offset(0, 8),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   isLogin ? "Welcome Back!" : "Create Account",
//                   style: GoogleFonts.poppins(
//                     fontSize: 26,
//                     fontWeight: FontWeight.w600,
//                     color: const Color(0xFF2563EB),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   isLogin
//                       ? "Login to access your dashboard"
//                       : "Sign up after admin creates your profile",
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 30),

//                 /// FORM
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       _inputField(
//                         label: "Email",
//                         icon: Icons.email_outlined,
//                         controller: _emailController,
//                       ),
//                       const SizedBox(height: 16),

//                       _inputField(
//                         label: "Password",
//                         icon: Icons.lock_outline,
//                         controller: _passwordController,
//                         isPassword: true,
//                       ),
//                       const SizedBox(height: 16),

//                       if (!isLogin)
//                         _inputField(
//                           label: "Confirm Password",
//                           icon: Icons.lock_outline,
//                           controller: _confirmPasswordController,
//                           isPassword: true,
//                         ),

//                       const SizedBox(height: 24),

//                       SizedBox(
//                         width: double.infinity,
//                         height: 55,
//                         child: ElevatedButton(
//                           onPressed: _handleAuth,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF2563EB),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                           child: Text(
//                             isLogin ? "Log In" : "Create Account",
//                             style: GoogleFonts.poppins(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 if (errorMessage != null) ...[
//                   const SizedBox(height: 12),
//                   Text(
//                     errorMessage!,
//                     style: const TextStyle(color: Colors.red),
//                   ),
//                 ],

//                 const SizedBox(height: 20),

//                 GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       isLogin = !isLogin;
//                       errorMessage = null;
//                       _confirmPasswordController.clear();
//                     });
//                   },
//                   child: Text.rich(
//                     TextSpan(
//                       text: isLogin
//                           ? "Don't have an account? "
//                           : "Already have an account? ",
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.grey[700],
//                       ),
//                       children: [
//                         TextSpan(
//                           text: isLogin ? "Sign Up" : "Login",
//                           style: const TextStyle(
//                             color: Color(0xFF2563EB),
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _inputField({
//     required String label,
//     required IconData icon,
//     required TextEditingController controller,
//     bool isPassword = false,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: isPassword,
//       validator: (value) {
//         if (value == null || value.isEmpty) return "This field is required";
//         if (label == "Email" && !value.contains("@")) {
//           return "Enter valid email";
//         }
//         if (label == "Password" && value.length < 6) {
//           return "Minimum 6 characters";
//         }
//         if (label == "Confirm Password" &&
//             value != _passwordController.text) {
//           return "Passwords do not match";
//         }
//         return null;
//       },
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
//         filled: true,
//         fillColor: const Color(0xFFF8FAFC),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//         ),
//       ),
//     );
//   }

//   void _navigateToDashboard(String role, PostgrestMap employee) {
//     final r = role.toLowerCase();

//     if (r.contains('marketing')) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const MarketingManagerDashboard(userData: {}),
//         ),
//       );
//     } else if (r.contains('production')) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const ProductionDashboard(userData: {}),
//         ),
//       );
//     } else if (r.contains('owner')) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const OwnerDashboard(userData: {}),
//         ),
//       );
//     } else {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const EmployeeDashboard(userData: {}),
//         ),
//       );
//     }
//   }

//   Future<void> _handleAuth() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => errorMessage = null);
//     final supabase = Supabase.instance.client;

//     try {
//       // ================= AUTH =================
//       if (isLogin) {
//         await supabase.auth.signInWithPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );
//       } else {
//         await supabase.auth.signUp(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );
//       }

//       final user = supabase.auth.currentUser;
//       if (user == null) return;

//       // 1️⃣ Find employee row by email
//       final employee = await supabase
//           .from('emp_profile')
//           .select()
//           .eq('email', user.email!)
//           .maybeSingle();

//       if (employee == null) {
//         throw 'Employee not found. Contact admin.';
//       }

//       // 2️⃣ Attach user_id ONLY ONCE
//       if (employee['user_id'] == null) {
//         await supabase.from('emp_profile').update({
//           'user_id': user.id,
//         }).eq('email', user.email!);
//       }

//       // ================= NAVIGATE WITH USER DATA =================
//       _navigateToDashboard(employee['role'], employee);

//     } catch (e) {
//       setState(() {
//         errorMessage = e.toString().replaceAll('Exception:', '').trim();
//       });
//     }
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'package:mega_pro/dashboards/emp_dashboard.dart';
// import 'package:mega_pro/dashboards/mar_dashboard.dart';
// import 'package:mega_pro/dashboards/pro_dashboard.dart';
// import 'package:mega_pro/dashboards/own_dashboard.dart';
// import 'package:mega_pro/global/global_variables.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key, required String selectedRole});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   bool isLogin = true;
//   final _formKey = GlobalKey<FormState>();
//   String? errorMessage;

//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _fullNameController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _fullNameController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Container(
//             width: 420,
//             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
//             decoration: BoxDecoration(
//               color: GlobalColors.white,
//               borderRadius: BorderRadius.circular(26),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 25,
//                   offset: const Offset(0, 12),
//                 ),
//               ],
//             ),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     isLogin ? "Welcome Back !" : "Create Account",
//                     style: GoogleFonts.poppins(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryBlue,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     isLogin
//                         ? "Login to access your dashboard"
//                         : "Sign up after admin creates your profile",
//                     style: TextStyle(
//                       color: AppColors.secondaryText,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 30),

//                   _inputField("Email", Icons.email_outlined, _emailController),
//                   _inputField("Password", Icons.lock_outline, _passwordController,
//                       isPassword: true),

//                   if (!isLogin)
//                     _inputField(
//                       "Confirm Password",
//                       Icons.lock_outline,
//                       _confirmPasswordController,
//                       isPassword: true,
//                       confirm: true,
//                     ),

//                   const SizedBox(height: 28),

//                   SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed: _handleAuth,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryBlue,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: Text(
//                         isLogin ? "Log In" : "Create Account",
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),

//                   if (errorMessage != null) ...[
//                     const SizedBox(height: 20),
//                     Text(
//                       errorMessage!,
//                       style: const TextStyle(color: Colors.red),
//                     )
//                   ],

//                   const SizedBox(height: 26),

//                   Center(
//                     child: GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           isLogin = !isLogin;
//                           errorMessage = null;
//                         });
//                       },
//                       child: Text(
//                         isLogin
//                             ? "Don't have account? Ask admin to add you"
//                             : "Already have account? Log in",
//                         style: TextStyle(
//                           color: AppColors.primaryBlue,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _inputField(
//     String label,
//     IconData icon,
//     TextEditingController controller, {
//     bool isPassword = false,
//     bool confirm = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 18),
//       child: TextFormField(
//         controller: controller,
//         obscureText: isPassword,
//         validator: (v) {
//           if (v == null || v.isEmpty) return "Required";
//           if (label == "Email" && !v.contains('@')) return "Invalid email";
//           if (label == "Password" && v.length < 6) return "Min 6 chars";
//           if (confirm && v != _passwordController.text) {
//             return "Passwords do not match";
//           }
//           return null;
//         },
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon, color: AppColors.primaryBlue),
//           filled: true,
//           fillColor: AppColors.softGreyBg,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }

//   // ================= AUTH FIX =================

// // Future<void> _handleAuth() async {
// // if (!_formKey.currentState!.validate()) return;

// // setState(() => errorMessage = null);
// // final supabase = Supabase.instance.client;

// // try {
// //   // ================= AUTH =================
// //   if (isLogin) {
// //     await supabase.auth.signInWithPassword(
// //       email: _emailController.text.trim(),
// //       password: _passwordController.text.trim(),
// //     );
// //   } else {
// //     await supabase.auth.signUp(
// //       email: _emailController.text.trim(),
// //       password: _passwordController.text.trim(),
// //     );
// //   }

// //   final user = supabase.auth.currentUser;

// // if (user == null) return;

// // // 1️⃣ Find employee row by email
// // final employee = await supabase
// //     .from('emp_profile')
// //     .select()
// //     .eq('email', user.email!)
// //     .maybeSingle();

// // if (employee == null) {
// //   throw 'Employee not found. Contact admin.';
// // }

// // // 2️⃣ Attach user_id ONLY ONCE
// // if (employee['user_id'] == null) {
// //   await supabase.from('emp_profile').update({
// //     'user_id': user.id,
// //   }).eq('email', user.email!);
// // }


// //     // ================= NAVIGATE =================
// //     _navigateToDashboard(employee['role']);

// //   } catch (e) {
// //     setState(() {
// //       errorMessage = e.toString().replaceAll('Exception:', '').trim();
// //     });
// //   }
// // }
//   // ================= ROLE → DASHBOARD =================

//   // In your AuthScreen.dart, update the _navigateToDashboard method:

// void _navigateToDashboard(String role, PostgrestMap employee) {
//     final r = role.toLowerCase();

//     if (r.contains('marketing')) {
//       Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//               builder: (_) => const MarketingManagerDashboard(userData: {},)));
//     } else if (r.contains('production')) {
//       Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//               builder: (_) => const ProductionDashboard(userData: {},)));
//     } else if (r.contains('owner')) {
//       Navigator.pushReplacement(context,
//           MaterialPageRoute(builder: (_) => const OwnerDashboardClean(userData: {},)));
//     } else {
//       Navigator.pushReplacement(context,
//           MaterialPageRoute(builder: (_) => const EmployeeDashboard(userData: {},)));
//     }
//   }


// // Then update the _handleAuth method to pass employee data:
// Future<void> _handleAuth() async {
//   if (!_formKey.currentState!.validate()) return;

//   setState(() => errorMessage = null);
//   final supabase = Supabase.instance.client;

//   try {
//     // ================= AUTH =================
//     if (isLogin) {
//       await supabase.auth.signInWithPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//     } else {
//       await supabase.auth.signUp(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//     }

//     final user = supabase.auth.currentUser;
//     if (user == null) return;

//     // 1️⃣ Find employee row by email
//     final employee = await supabase
//         .from('emp_profile')
//         .select()
//         .eq('email', user.email!)
//         .maybeSingle();

//     if (employee == null) {
//       throw 'Employee not found. Contact admin.';
//     }

//     // 2️⃣ Attach user_id ONLY ONCE
//     if (employee['user_id'] == null) {
//       await supabase.from('emp_profile').update({
//         'user_id': user.id,
//       }).eq('email', user.email!);
//     }

//     // ================= NAVIGATE WITH USER DATA =================
//     _navigateToDashboard(employee['role'], employee);

//   } catch (e) {
//     setState(() {
//       errorMessage = e.toString().replaceAll('Exception:', '').trim();
//     });
//   }
// }
// }






//works great only for employee role


// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'package:mega_pro/dashboards/emp_dashboard.dart';
// import 'package:mega_pro/dashboards/mar_dashboard.dart';
// import 'package:mega_pro/dashboards/pro_dashboard.dart';
// import 'package:mega_pro/dashboards/own_dashboard.dart';
// import 'package:mega_pro/global/global_variables.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key, required String selectedRole});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   bool isLogin = true;
//   final _formKey = GlobalKey<FormState>();
//   String? errorMessage;

//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _fullNameController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _fullNameController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Container(
//             width: 420,
//             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
//             decoration: BoxDecoration(
//               color: GlobalColors.white,
//               borderRadius: BorderRadius.circular(26),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 25,
//                   offset: const Offset(0, 12),
//                 ),
//               ],
//             ),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     isLogin ? "Welcome Back !" : "Create Account",
//                     style: GoogleFonts.poppins(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryBlue,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     isLogin
//                         ? "Login to access your dashboard"
//                         : "Sign up after admin creates your profile",
//                     style: TextStyle(
//                       color: AppColors.secondaryText,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 30),

//                   _inputField("Email", Icons.email_outlined, _emailController),
//                   _inputField("Password", Icons.lock_outline, _passwordController,
//                       isPassword: true),

//                   if (!isLogin)
//                     _inputField(
//                       "Confirm Password",
//                       Icons.lock_outline,
//                       _confirmPasswordController,
//                       isPassword: true,
//                       confirm: true,
//                     ),

//                   const SizedBox(height: 28),

//                   SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed: _handleAuth,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryBlue,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: Text(
//                         isLogin ? "Log In" : "Create Account",
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),

//                   if (errorMessage != null) ...[
//                     const SizedBox(height: 20),
//                     Text(
//                       errorMessage!,
//                       style: const TextStyle(color: Colors.red),
//                     )
//                   ],

//                   const SizedBox(height: 26),

//                   Center(
//                     child: GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           isLogin = !isLogin;
//                           errorMessage = null;
//                         });
//                       },
//                       child: Text(
//                         isLogin
//                             ? "Don't have account? Ask admin to add you"
//                             : "Already have account? Log in",
//                         style: TextStyle(
//                           color: AppColors.primaryBlue,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _inputField(
//     String label,
//     IconData icon,
//     TextEditingController controller, {
//     bool isPassword = false,
//     bool confirm = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 18),
//       child: TextFormField(
//         controller: controller,
//         obscureText: isPassword,
//         validator: (v) {
//           if (v == null || v.isEmpty) return "Required";
//           if (label == "Email" && !v.contains('@')) return "Invalid email";
//           if (label == "Password" && v.length < 6) return "Min 6 chars";
//           if (confirm && v != _passwordController.text) {
//             return "Passwords do not match";
//           }
//           return null;
//         },
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon, color: AppColors.primaryBlue),
//           filled: true,
//           fillColor: AppColors.softGreyBg,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }

//   // ================= AUTH FIX =================

// Future<void> _handleAuth() async {
// if (!_formKey.currentState!.validate()) return;

// setState(() => errorMessage = null);
// final supabase = Supabase.instance.client;

// try {
//   // ================= AUTH =================
//   if (isLogin) {
//     await supabase.auth.signInWithPassword(
//       email: _emailController.text.trim(),
//       password: _passwordController.text.trim(),
//     );
//   } else {
//     await supabase.auth.signUp(
//       email: _emailController.text.trim(),
//       password: _passwordController.text.trim(),
//     );
//   }

//   final user = supabase.auth.currentUser;

// if (user == null) return;

// // 1️⃣ Find employee row by email
// final employee = await supabase
//     .from('emp_profile')
//     .select()
//     .eq('email', user.email!)
//     .maybeSingle();

// if (employee == null) {
//   throw 'Employee not found. Contact admin.';
// }

// // 2️⃣ Attach user_id ONLY ONCE
// if (employee['user_id'] == null) {
//   await supabase.from('emp_profile').update({
//     'user_id': user.id,
//   }).eq('email', user.email!);
// }


//     // ================= NAVIGATE =================
//     _navigateToDashboard(employee['role']);

//   } catch (e) {
//     setState(() {
//       errorMessage = e.toString().replaceAll('Exception:', '').trim();
//     });
//   }
// }
//   // ================= ROLE → DASHBOARD =================

//   void _navigateToDashboard(String role) {
//     final r = role.toLowerCase();

//     if (r.contains('marketing')) {
//       Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//               builder: (_) => const MarketingManagerDashboard()));
//     } else if (r.contains('production')) {
//       Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//               builder: (_) => const ProductionDashboard()));
//     } else if (r.contains('owner')) {
//       Navigator.pushReplacement(context,
//           MaterialPageRoute(builder: (_) => const OwnerDashboardClean()));
//     } else {
//       Navigator.pushReplacement(context,
//           MaterialPageRoute(builder: (_) => const EmployeeDashboard()));
//     }
//   }
// }












// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'package:mega_pro/dashboards/emp_dashboard.dart';
// import 'package:mega_pro/dashboards/mar_dashboard.dart';
// import 'package:mega_pro/dashboards/pro_dashboard.dart';
// import 'package:mega_pro/dashboards/own_dashboard.dart';
// import 'package:mega_pro/global/global_variables.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key, required String selectedRole});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   bool isLogin = true;
//   final _formKey = GlobalKey<FormState>();
//   String? errorMessage;

//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _fullNameController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _fullNameController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Container(
//             width: 420,
//             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
//             decoration: BoxDecoration(
//               color: GlobalColors.white,
//               borderRadius: BorderRadius.circular(26),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 25,
//                   offset: const Offset(0, 12),
//                 ),
//               ],
//             ),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   /// HEADER
//                   Text(
//                     isLogin ? " Welcome Back !" : "Create Account",
//                     style: GoogleFonts.poppins(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryBlue,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     isLogin
//                         ? "Login to access your dashboard"
//                         : "Sign up to get started",
//                     style: TextStyle(
//                       color: AppColors.secondaryText,
//                       fontSize: 14,
//                     ),
//                   ),

//                   const SizedBox(height: 30),

//                   if (!isLogin)
//                     _inputField(
//                       "Full Name",
//                       Icons.person_outline,
//                       _fullNameController,
//                     ),

//                   _inputField(
//                     "Email",
//                     Icons.email_outlined,
//                     _emailController,
//                   ),

//                   _inputField(
//                     "Password",
//                     Icons.lock_outline,
//                     _passwordController,
//                     isPassword: true,
//                   ),

//                   if (!isLogin)
//                     _inputField(
//                       "Confirm Password",
//                       Icons.lock_outline,
//                       _confirmPasswordController,
//                       isPassword: true,
//                       confirm: true,
//                     ),

//                   const SizedBox(height: 28),

//                   /// BUTTON
//                   SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed: _handleAuth,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryBlue,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: Text(
//                         isLogin ? "Log In" : "Create Account",
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),

//                   if (errorMessage != null) ...[
//                     const SizedBox(height: 20),
//                     Container(
//                       padding: const EdgeInsets.all(14),
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: Colors.red.shade100,
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.error_outline,
//                               color: Colors.red.shade600),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               errorMessage!,
//                               style: TextStyle(
//                                 color: Colors.red.shade700,
//                                 fontSize: 13,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],

//                   const SizedBox(height: 26),

//                   /// TOGGLE
//                   Center(
//                     child: GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           isLogin = !isLogin;
//                           errorMessage = null;
//                           _confirmPasswordController.clear();
//                         });
//                       },
//                       child: RichText(
//                         text: TextSpan(
//                           text: isLogin
//                               ? "Don't have an account? "
//                               : "Already have an account? ",
//                           style: TextStyle(
//                             color: AppColors.secondaryText,
//                             fontSize: 14,
//                           ),
//                           children: [
//                             TextSpan(
//                               text: isLogin ? "Sign Up" : "Log In",
//                               style: TextStyle(
//                                 color: AppColors.primaryBlue,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ===============================================================
//   // INPUT FIELD
//   // ===============================================================

//   Widget _inputField(
//     String label,
//     IconData icon,
//     TextEditingController controller, {
//     bool isPassword = false,
//     bool confirm = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 18),
//       child: TextFormField(
//         controller: controller,
//         obscureText: isPassword,
//         validator: (v) {
//           if (v == null || v.isEmpty) return "Required";
//           if (label == "Email" && !v.contains('@')) return "Invalid email";
//           if (label == "Password" && v.length < 6) return "Minimum 6 characters";
//           if (confirm && v != _passwordController.text) {
//             return "Passwords do not match";
//           }
//           return null;
//         },
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon, color: AppColors.primaryBlue),
//           filled: true,
//           fillColor: AppColors.softGreyBg,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide.none,
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide(
//               color: AppColors.primaryBlue,
//               width: 1.5,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ===============================================================
//   // AUTH LOGIC (UNCHANGED)
//   // ===============================================================

//   Future<void> _handleAuth() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => errorMessage = null);
//     final supabase = Supabase.instance.client;

//     try {
//       if (isLogin) {
//         await supabase.auth.signInWithPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );
//       } else {
//         final res = await supabase.auth.signUp(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//           data: {'full_name': _fullNameController.text.trim()},
//         );

//         final user = res.user;
//         if (user == null) throw 'Signup failed';

//         await supabase.from('users').insert({
//           'id': user.id,
//           'email': user.email,
//           'full_name': _fullNameController.text.trim(),
//           'role_id': 1, 
//         });
//       }

//       final user = supabase.auth.currentUser;
//       if (user == null) throw 'Auth failed';

//       final profile = await supabase
//           .from('users')
//           .select('roles(name)')
//           .eq('id', user.id)
//           .single();

//       _navigateToDashboard(profile['roles']['name']);
//     } catch (e) {
//       setState(() => errorMessage = e.toString());
//     }
//   }

//   // ===============================================================
//   // ROLE → DASHBOARD (UNCHANGED)
//   // ===============================================================

//   void _navigateToDashboard(String role) {
//   final normalizedRole = role.toString().trim().toLowerCase();

//   if (normalizedRole.contains('marketing')) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//           builder: (_) => const MarketingManagerDashboard()),
//     );
//   } else if (normalizedRole.contains('production')) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//           builder: (_) => const ProductionDashboard()),
//     );
//   } else if (normalizedRole.contains('owner')) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//           builder: (_) => const OwnerDashboardClean()),
//     );
//   } else {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//           builder: (_) => const EmployeeDashboard()),
//     );
//   }
// }

// }







// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:mega_pro/dashboards/emp_dashboard.dart';
// import 'package:mega_pro/dashboards/mar_dashboard.dart';
// import 'package:mega_pro/dashboards/pro_dashboard.dart';
// import 'package:mega_pro/dashboards/own_dashboard.dart';
// import 'package:mega_pro/global/global_variables.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key, required String selectedRole});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   bool isLogin = true;
//   final _formKey = GlobalKey<FormState>();
//   String? errorMessage;

//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _fullNameController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _fullNameController.dispose();
//     super.dispose();
//   }

//   // ===============================================================
//   // UI
//   // ===============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Container(
//             width: 400,
//             padding: const EdgeInsets.all(32),
//             decoration: BoxDecoration(
//               color: GlobalColors.white,
//               borderRadius: BorderRadius.circular(24),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(.08),
//                   blurRadius: 20,
//                 ),
//               ],
//             ),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   Text(
//                     isLogin ? "Welcome Back!" : "Create Account",
//                     style: GoogleFonts.poppins(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryBlue,
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   if (!isLogin)
//                     _field(
//                       "Full Name",
//                       Icons.person_outline,
//                       _fullNameController,
//                     ),

//                   _field("Email", Icons.email_outlined, _emailController),
//                   _field(
//                     "Password",
//                     Icons.lock_outline,
//                     _passwordController,
//                     isPassword: true,
//                   ),

//                   if (!isLogin)
//                     _field(
//                       "Confirm Password",
//                       Icons.lock_outline,
//                       _confirmPasswordController,
//                       isPassword: true,
//                       confirm: true,
//                     ),

//                   const SizedBox(height: 24),

//                   SizedBox(
//                     width: double.infinity,
//                     height: 54,
//                     child: ElevatedButton(
//                       onPressed: _handleAuth,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryBlue,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       child: Text(
//                         isLogin ? "Login" : "Sign Up",
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),

//                   if (errorMessage != null) ...[
//                     const SizedBox(height: 16),
//                     Text(
//                       errorMessage!,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(color: Colors.red),
//                     ),
//                   ],

//                   const SizedBox(height: 20),

//                   GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         isLogin = !isLogin;
//                         errorMessage = null;
//                         _confirmPasswordController.clear();
//                       });
//                     },
//                     child: Text(
//                       isLogin
//                           ? "Don't have an account? Sign Up"
//                           : "Already have an account? Login",
//                       style: TextStyle(color: AppColors.primaryBlue),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ===============================================================
//   // INPUT FIELD
//   // ===============================================================

//   Widget _field(
//     String label,
//     IconData icon,
//     TextEditingController controller, {
//     bool isPassword = false,
//     bool confirm = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: TextFormField(
//         controller: controller,
//         obscureText: isPassword,
//         validator: (v) {
//           if (v == null || v.isEmpty) return "Required";
//           if (label == "Email" && !v.contains('@')) return "Invalid email";
//           if (label == "Password" && v.length < 6) return "Min 6 chars";
//           if (confirm && v != _passwordController.text) {
//             return "Passwords do not match";
//           }
//           return null;
//         },
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon, color: AppColors.primaryBlue),
//           filled: true,
//           fillColor: AppColors.softGreyBg,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//         ),
//       ),
//     );
//   }

//   // ===============================================================
//   // AUTH LOGIC (FIXED)
//   // ===============================================================

//   Future<void> _handleAuth() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => errorMessage = null);
//     final supabase = Supabase.instance.client;

//     try {
//       if (isLogin) {
//         await supabase.auth.signInWithPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );
//       } else {
//         await supabase.auth.signUp(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//           data: {'full_name': _fullNameController.text.trim()},
//         );
//       }

//       final user = supabase.auth.currentUser;
//       if (user == null) throw "Authentication failed";

//       // 🔐 CHECK ROLE FROM ADMIN-CREATED RECORD
//       final employee = await supabase
//           .from('employees')
//           .select()
//           .eq('email', user.email!)
//           .maybeSingle();

//       if (employee == null) {
//         await supabase.auth.signOut();
//         throw "Your account is not approved by admin";
//       }

//       // 🔗 Attach auth user_id once
//       if (employee['user_id'] == null) {
//         await supabase
//             .from('employees')
//             .update({'user_id': user.id})
//             .eq('email', user.email!);
//       }

//       _navigateToDashboard(employee['role']);
//     } catch (e) {
//       setState(() => errorMessage = e.toString());
//     }
//   }

//   // ===============================================================
//   // ROLE → DASHBOARD
//   // ===============================================================

//   void _navigateToDashboard(String role) {
//     switch (role) {
//       case 'Marketing Manager':
//         Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (_) => const MarketingManagerDashboard()));
//         break;
//       case 'Production Manager':
//         Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (_) => const ProductionDashboard()));
//         break;
//       case 'Owner':
//         Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (_) => const OwnerDashboardClean()));
//         break;
//       default:
//         Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (_) => const EmployeeDashboard()));
//     }
//   }
// }





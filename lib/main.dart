
import 'package:flutter/material.dart';
import 'package:mega_pro/auth/Login_SignUp.dart';
import 'package:mega_pro/dashboards/emp_dashboard.dart';
import 'package:mega_pro/employee/emp_create_order_page.dart';
import 'package:mega_pro/employee/emp_profile.dart';
import 'package:mega_pro/employee/emp_recent_order_page.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_attendance_provider.dart';
import 'package:mega_pro/providers/emp_mar_target_provider.dart';
import 'package:mega_pro/providers/emp_order_provider.dart';
import 'package:mega_pro/providers/emp_provider.dart';
import 'package:mega_pro/providers/pro_inventory_provider.dart';
import 'package:mega_pro/providers/pro_orders_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



Future<void> main() async {
  await Supabase.initialize(
    url: "https://phkkiyxfcepqauxncqpm.supabase.co",
    anonKey: "sb_publishable_GdCo8okHOGBmrW9OH_qsZg_PDOl7a1u",
  );
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
    ChangeNotifierProvider(create: (_) => OrderProvider()),
    ChangeNotifierProvider(create: (_) => AttendanceProvider()),
            ChangeNotifierProvider(create: (_) => TargetProvider()),
    ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductionOrdersProvider()),

 // Add this

      ],
      child: MaterialApp(
        title: 'Enterprise Management System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue,
          ),
          scaffoldBackgroundColor: AppColors.scaffoldBg,
          useMaterial3: true,
        ),
        home: const RoleSelectionScreen(),
        routes: {
          '/employee/home': (_) => const EmployeeDashboard(userData: {},),
          '/employee/create': (_) => const CattleFeedOrderScreen(),
          '/employee/orders': (_) => const RecentOrdersScreen(),
          '/employee/profile': (_) => const EmployeeProfileDashboard(),
        },
      ),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Text(
                  "Cattle Feed Management System",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Streamline operations, track performance, and make data-driven decisions",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),

                /// Row 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRoleCard(
                      context,
                      icon: Icons.group_rounded,
                      color: AppColors.primaryBlue,
                      title: "Enterprise Employee",
                      description: "",
                      role: "Employee",
                    ),
                    _buildRoleCard(
                      context,
                      icon: Icons.bar_chart_rounded,
                      color: GlobalColors.success,
                      title: "Marketing Manager",
                      description: "",
                      role: "Marketing Manager",
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// Row 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRoleCard(
                      context,
                      icon: Icons.factory_rounded,
                      color: GlobalColors.warning,
                      title: "Production Manager",
                      description: "",
                      role: "Production Manager",
                    ),
                    _buildRoleCard(
                      context,
                      icon: Icons.crop_rounded,
                      color: GlobalColors.danger,
                      title: "Enterprise Owner",
                      description: "",
                      role: "Owner",
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                Text(
                  "Select your role to access your personalized dashboard",
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String role,
    bool isPrimary = false,
  }) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GlobalColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? AppColors.primaryBlue
                        : GlobalColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPrimary
                          ? Colors.transparent
                          : AppColors.primaryBlue.withOpacity(0.3),
                    ),
                    boxShadow: isPrimary
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.primaryBlue.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AuthScreen(selectedRole: role),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Access Dashboard",
                            style: TextStyle(
                              color: isPrimary
                                  ? Colors.white
                                  : AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

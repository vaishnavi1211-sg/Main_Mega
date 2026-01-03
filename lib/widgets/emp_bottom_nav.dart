import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:mega_pro/global/global_variables.dart';

class EmployeeBottomNav extends StatelessWidget {
  final int currentIndex;
  const EmployeeBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final routes = [
      '/employee/home',
      '/employee/create',
      '/employee/orders',
      '/employee/profile',
    ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: GlobalColors.primaryBlue,
      unselectedItemColor: GlobalColors.textGrey,
      onTap: (index) {
        if (ModalRoute.of(context)?.settings.name != routes[index]) {
          Navigator.pushReplacementNamed(context, routes[index]);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Iconsax.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Iconsax.add_square), label: "Create"),
        BottomNavigationBarItem(icon: Icon(Iconsax.receipt_item), label: "Orders"),
        BottomNavigationBarItem(icon: Icon(Iconsax.user), label: "Profile"),
      ],
    );
  }
}

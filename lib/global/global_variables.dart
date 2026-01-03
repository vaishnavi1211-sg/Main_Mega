import 'package:flutter/material.dart';


// Add these to your GlobalColors class

class AppColors {
  // Brand
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0x1A1976D2);
  static const Color lightestBlue= Color.fromARGB(26, 17, 95, 174);


  // Backgrounds
  static const Color scaffoldBg = Color(0xFFF9FAFB);
  static const Color cardBg = Colors.white;
  static const Color softGreyBg = Color(0xFFF3F4F6);

  // Text
  static const Color primaryText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color mutedText = Color(0xFF9CA3AF);

  // Borders & Shadows
  static const Color borderGrey = Color(0xFFE5E7EB);
  static const Color shadowGrey = Color(0x33000000);

  // Status
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successLight = Color(0x1A2E7D32);

  // Rating
  static const Color ratingAmber = Color(0xFFFFB300);

   late Color dangerRed;

  static var success;
}


class GlobalColors {
  // Brand
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color background = Color(0xFFF3F4F8);
  static const Color white = Colors.white;
  static const Color black = Colors.black87;

  // Text
  static const Color textGrey = Colors.grey;
  static const Color textLightGrey = Color(0xFF9CA3AF);

  // Status
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color danger = Colors.red;
  static const Color info = Colors.white;
  static const Color purple = Colors.purple;

  // Chart
  static const Color chartGrid = Color(0xFFE5E7EB);
  static const Color chartBackgroundBar = Color(0xFFF1F5F9);

  // Shadows
  static Color shadow = Colors.grey.shade300;

  static var lightBlue;
}



// import 'package:flutter/material.dart';

// class GlobalVariables {
//   // Brand Colors (Indian professional look)
//   static const Color primaryColor = Color(0xFF2563EB);
//   static const Color secondaryColor = Color(0xFF1E40AF);
//   static const Color backgroundColor = Color(0xFFF9FAFB);
//   static const Color cardColor = Colors.white;
//   static const Color textPrimary = Color(0xFF111827);
//   static const Color textSecondary = Color(0xFF6B7280);

//   // Gradients
//   static const LinearGradient primaryGradient = LinearGradient(
//     colors: [primaryColor, secondaryColor],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );

//   // Padding
//   static const double screenPadding = 16;
//   static const double cardRadius = 16;
// }

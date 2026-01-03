import 'package:flutter/material.dart';
import 'global_variables.dart';

class AppTextStyles {
  // HEADINGS
  static const TextStyle headingLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  // BODY
  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.primaryText,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryText,
  );

  static final TextStyle bodyMuted = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.mutedText,
  );

  // LABELS
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );

  // KPI / NUMBERS
  static const TextStyle metric = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static const TextStyle metricSuccess = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.successGreen,
  );

  // STATUS
  static const TextStyle statusSuccess = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AppColors.successGreen,
  );
}

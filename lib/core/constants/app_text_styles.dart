import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'app_colors.dart';

/// Typography scale for AI Studio per ui_ux.md §3.3.
/// Applies flutter_screenutil_plus .sp extension for responsive scaling.
abstract class AppTextStyles {
  // Display
  static TextStyle get displayXL => TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  // Headings
  static TextStyle get headingL => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get headingM => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  // Body
  static TextStyle get bodyL => TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyM => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textMuted,
      );

  // Caption
  static TextStyle get caption => TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textMuted,
      );

  // Button label
  static TextStyle get buttonLabel => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        height: 1.0,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  // Legacy aliases for backward compatibility
  static TextStyle get displayLarge => displayXL;
  static TextStyle get headingMedium => headingM;
  static TextStyle get bodyLarge => bodyL;
  static TextStyle get bodyMedium => bodyM;
}

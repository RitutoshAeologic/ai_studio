import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography system for AI Studio with responsive ScreenUtil .sp font scaling per ui_ux.md.
abstract class AppTextStyles {
  // ── Modern Light Mode Primary Styles ────────────────────────────────────────

  /// Display XL — Main Screen Title (28sp)
  static TextStyle get displayXL => GoogleFonts.inter(
        fontSize: 28.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// Display L — Section Title (24sp)
  static TextStyle get displayL => GoogleFonts.inter(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 26.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Heading M — Subsection Header (18sp)
  static TextStyle get headingM => GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Heading S — Small Header (16sp)
  static TextStyle get headingS => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Body L — Standard Input / Prominent Body Text (15sp)
  static TextStyle get bodyL => GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle headingLarge({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // ── Backwards Compatibility Methods (Refactored to .sp) ────────────────────
  static TextStyle displayLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 32.sp,
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 26.sp,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle headingLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle headingMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle headingSmall({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle labelLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.bone,
      );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.slate,
      );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color ?? AppColors.slate,
      );

  static TextStyle buttonLabel({Color? color}) => GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color ?? AppColors.bone,
      );

  static TextStyle creditCounter({Color? color, double? fontSize}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize.sp,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.creditGoldTitle,
      );

  static TextStyle jobStatus({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color ?? AppColors.slate,
      );

  static TextStyle jobId({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle dataLabel({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );
}

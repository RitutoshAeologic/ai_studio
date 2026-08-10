import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography system for AI Studio — Responsive parameter-driven factory functions.
/// ScreenUtil .sp font scaling per ui_ux.md.
abstract class AppTextStyles {
  // ── Display / XL Headings ───────────────────────────────────────────────────

  static TextStyle displayXL({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 28.sp,
        fontWeight: fontWeight ?? FontWeight.w800,
        color: color ?? AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle displayL({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 24.sp,
        fontWeight: fontWeight ?? FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle displayLarge({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 32.sp,
        fontWeight: fontWeight ?? FontWeight.w800,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle displayMedium({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 26.sp,
        fontWeight: fontWeight ?? FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  // ── Headings ────────────────────────────────────────────────────────────────

  static TextStyle headingLarge({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 22.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle headingL({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 20.sp,
        fontWeight: fontWeight ?? FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle headingM({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle headingMedium({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle headingS({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle headingSmall({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 15.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  // ── Body / UI Text ──────────────────────────────────────────────────────────

  static TextStyle bodyL({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyM({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle labelLarge({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle labelMedium({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle labelSmall({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: 0.5,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle caption({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle buttonLabel({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? Colors.white,
      );

  // ── Data / System Readout ───────────────────────────────────────────────────

  static TextStyle creditCounter(
          {Color? color, double? fontSize, FontWeight? fontWeight}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: (fontSize ?? 14).sp,
        fontWeight: fontWeight ?? FontWeight.w700,
        color: color ?? AppColors.creditGoldTitle,
      );

  static TextStyle jobStatus({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 11.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        letterSpacing: 0.5,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle jobId({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 11.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.textMuted,
      );

  static TextStyle dataLabel({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 12.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );
}

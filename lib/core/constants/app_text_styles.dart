import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography system for AI Studio — Darkroom design direction per revision cf6dff878693f1759a868d5c4231771b2b14e3a9.
///
/// Three-role pairing:
///   SpaceGrotesk → Display / headings (geometric, "generation tool" feel)
///   Inter        → Body / UI text (neutral, high-legibility at small sizes)
///   JetBrainsMono → Credit counters, job IDs, status strings (system readout)
abstract class AppTextStyles {
  // ── Display / Headings — Space Grotesk ─────────────────────────────────────
  static TextStyle displayLarge({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 32.sp,
        fontWeight: fontWeight ?? FontWeight.w700,
        letterSpacing: -0.5,
        color: color ?? AppColors.bone,
      );

  static TextStyle displayMedium({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 26.sp,
        fontWeight: fontWeight ?? FontWeight.w700,
        letterSpacing: -0.3,
        color: color ?? AppColors.bone,
      );

  static TextStyle headingLarge({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 22.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: -0.2,
        color: color ?? AppColors.bone,
      );

  static TextStyle headingMedium({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 18.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.bone,
      );

  static TextStyle headingSmall({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 15.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.bone,
      );

  // ── Body / UI — Inter ──────────────────────────────────────────────────────
  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.bone,
      );

  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.bone,
      );

  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.slate,
      );

  static TextStyle labelLarge({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.bone,
      );

  static TextStyle labelMedium({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.slate,
      );

  static TextStyle labelSmall({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.slate,
      );

  static TextStyle buttonLabel({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: 0.2,
        color: color ?? AppColors.bone,
      );

  // ── Data / System Readout — JetBrains Mono ─────────────────────────────────
  static TextStyle creditCounter({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: (fontSize ?? 20).sp,
        fontWeight: fontWeight ?? FontWeight.w700,
        color: color ?? AppColors.ember,
      );

  static TextStyle jobStatus({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 11.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        letterSpacing: 0.5,
        color: color ?? AppColors.slate,
      );

  static TextStyle jobId({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 11.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.slate,
      );

  static TextStyle dataLabel({Color? color, FontWeight? fontWeight}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 12.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.bone,
      );

  // ── Backward Compatibility Aliases ─────────────────────────────────────────
  static TextStyle displayXL({Color? color, FontWeight? fontWeight}) =>
      displayLarge(color: color, fontWeight: fontWeight);
  static TextStyle displayL({Color? color, FontWeight? fontWeight}) =>
      displayMedium(color: color, fontWeight: fontWeight);
  static TextStyle headingL({Color? color, FontWeight? fontWeight}) =>
      headingLarge(color: color, fontWeight: fontWeight);
  static TextStyle headingM({Color? color, FontWeight? fontWeight}) =>
      headingMedium(color: color, fontWeight: fontWeight);
  static TextStyle headingS({Color? color, FontWeight? fontWeight}) =>
      headingSmall(color: color, fontWeight: fontWeight);
  static TextStyle bodyL({Color? color, FontWeight? fontWeight}) =>
      bodyLarge(color: color, fontWeight: fontWeight);
  static TextStyle bodyM({Color? color, FontWeight? fontWeight}) =>
      bodyMedium(color: color, fontWeight: fontWeight);
  static TextStyle caption({Color? color, FontWeight? fontWeight}) =>
      bodySmall(color: color, fontWeight: fontWeight);
}

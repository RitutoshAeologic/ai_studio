import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system for AI Studio — Darkroom design direction.
///
/// Three-role pairing:
///   SpaceGrotesk → Display / headings (geometric, "generation tool" feel)
///   Inter        → Body / UI text (neutral, high-legibility at small sizes)
///   JetBrainsMono → Credit counters, job IDs, status strings (system readout)
abstract class AppTextStyles {
  // ── Display / Headings — Space Grotesk ─────────────────────────────────────
  static TextStyle displayLarge({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color ?? AppColors.bone,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 26.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color ?? AppColors.bone,
      );

  static TextStyle headingLarge({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color ?? AppColors.bone,
      );

  static TextStyle headingMedium({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.bone,
      );

  static TextStyle headingSmall({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.bone,
      );

  // ── Body / UI — Inter ──────────────────────────────────────────────────────
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.bone,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.bone,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.slate,
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

  // ── Data / System Readout — JetBrains Mono ─────────────────────────────────
  /// Use for: credit balance, job IDs, status strings, timecodes.
  static TextStyle creditCounter({Color? color, double fontSize = 20}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize.sp,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ember,
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
        color: color ?? AppColors.slate,
      );

  static TextStyle dataLabel({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.bone,
      );
}

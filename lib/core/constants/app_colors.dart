import 'package:flutter/material.dart';

/// Design tokens for AI Studio colors — Sleek Modern Light Mode.
/// Provides a crisp, high-contrast, premium light aesthetic with vibrant indigo-violet accents.
abstract class AppColors {
  // Backgrounds
  static const Color bgApp = Color(0xFFF8F9FE);
  static const Color bgCanvas = Color(0xFFF1F3F9);
  static const Color bgPrimary = Color(0xFFF8F9FE);

  // Surfaces
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfacePanel = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceInput = Color(0xFFF3F5FA);

  // Legacy aliases
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgSurfaceElevated = Color(0xFFFFFFFF);

  // Primary Action & Accents
  static const Color primaryAction = Color(0xFF6C5CE7);
  static const Color primaryActionHover = Color(0xFF5A4AD1);
  static const Color primaryActionPressed = Color(0xFF4839B3);

  static const Color accentGlowStart = Color(0xFF6C5CE7);
  static const Color accentGlowEnd = Color(0xFFA64CE7);
  static const Color accentGlowSoft = Color(0x246C5CE7);

  // Legacy accent aliases
  static const Color accentPrimary = Color(0xFF6C5CE7);
  static const Color accentGradientStart = Color(0xFF6C5CE7);
  static const Color accentGradientEnd = Color(0xFFA64CE7);

  // Status indicators
  static const Color successIndicator = Color(0xFF10B981);
  static const Color successIndicatorSoft = Color(0xFFECFDF5);
  static const Color warningIndicator = Color(0xFFF59E0B);
  static const Color errorIndicator = Color(0xFFFF4757);
  static const Color errorIndicatorSoft = Color(0xFFFFEEF0);

  // Legacy status aliases
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFFF4757);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E1E2E);
  static const Color textMuted = Color(0xFF6C728F);
  static const Color textSecondary = Color(0xFF6C728F);
  static const Color textDisabled = Color(0xFFB0B5C9);

  // Borders
  static const Color borderSubtle = Color(0xFFE2E6F0);
  static const Color borderFocus = Color(0xFF6C5CE7);

  // Specialty & Credit Badge
  static const Color creditGold = Color(0xFFF39C12);
  static const Color creditGoldBg = Color(0xFFFFFBEB);
  static const Color creditGoldCircleBg = Color(0xFFFEF3C7);
  static const Color creditGoldBorder = Color(0xFFFDE68A);
  static const Color creditGoldIcon = Color(0xFFD97706);
  static const Color creditGoldTitle = Color(0xFFB45309);
  static const Color creditGoldSubtext = Color(0xFF92400E);

  // Gradients
  static const LinearGradient aiActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGlowStart, accentGlowEnd],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accentGlowStart, accentGlowEnd],
  );
}

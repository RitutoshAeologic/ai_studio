import 'package:flutter/material.dart';

/// Design tokens for AI Studio — Sleek Modern Light Mode & Brand Palettes per ui_ux.md.
abstract class AppColors {
  // ── Base Surfaces (Light Mode) ──────────────────────────────────────────────
  static const Color bgApp = Color(0xFFF8F9FE);
  static const Color bgPrimary = Color(0xFFF8F9FE);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfacePanel = Color(0xFFFFFFFF);
  static const Color surfaceInput = Color(0xFFF3F5FA);
  static const Color borderSubtle = Color(0xFFE2E6F0);
  static const Color borderFocus = Color(0xFF6C5CE7);

  // ── Typography ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E1E2E);
  static const Color textMuted = Color(0xFF6C728F);
  static const Color textDisabled = Color(0xFFA0A5BA);

  // ── Primary Action Accent (Indigo-to-Violet) ──────────────────────────────
  static const Color primaryAction = Color(0xFF6C5CE7);
  static const Color accentGlowStart = Color(0xFF6C5CE7);
  static const Color accentGlowEnd = Color(0xFFA64CE7);
  static const Color accentGlowSoft = Color(0x296C5CE7);

  // ── Reward / Credit Gold Palette ──────────────────────────────────────────
  static const Color creditGoldBg = Color(0xFFFFFBEB);
  static const Color creditGoldCircleBg = Color(0xFFFEF3C7);
  static const Color creditGoldBorder = Color(0xFFFDE68A);
  static const Color creditGoldIcon = Color(0xFFD97706);
  static const Color creditGoldTitle = Color(0xFFB45309);
  static const Color creditGoldSubtext = Color(0xFF92400E);

  // ── Status & Indicators ────────────────────────────────────────────────────
  static const Color errorIndicator = Color(0xFFFF4757);
  static const Color errorIndicatorSoft = Color(0x1FFF4757);
  static const Color successIndicator = Color(0xFF2DD58C);
  static const Color successIndicatorSoft = Color(0x1F2DD58C);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient aiActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFFA64CE7)],
  );

  // ── Legacy Compatibility Aliases (Mapped to Light Mode Palette) ─────────────
  static const Color ink = bgApp;
  static const Color surface = surfaceCard;
  static const Color bone = textPrimary;
  static const Color slate = textMuted;
  static const Color ember = primaryAction;
  static const Color emberSoft = accentGlowSoft;
  static const Color emberPressed = primaryAction;
  static const Color signalViolet = primaryAction;
  static const Color signalVioletSoft = accentGlowSoft;
  static const Color statusSuccess = successIndicator;
  static const Color statusSuccessSoft = successIndicatorSoft;
  static const Color statusWarning = creditGoldIcon;
  static const Color statusWarningSoft = creditGoldBg;
  static const Color statusError = errorIndicator;
  static const Color statusErrorSoft = errorIndicatorSoft;
  static const Color jobIdle = textMuted;
  static const Color jobQueued = textMuted;
  static const Color jobProcessing = creditGoldIcon;
  static const Color jobCompleted = primaryAction;
  static const Color jobError = errorIndicator;
  static const LinearGradient emberGradient = aiActionGradient;
  static const LinearGradient meshGradient = aiActionGradient;
}

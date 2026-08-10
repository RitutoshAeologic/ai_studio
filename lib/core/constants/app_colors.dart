import 'package:flutter/material.dart';

/// Design tokens for AI Studio — "Darkroom" palette per revision cf6dff878693f1759a868d5c4231771b2b14e3a9.
/// Inspired by darkroom photography / camera workflow. Warmer and more specific
/// than generic SaaS-neon. Color itself communicates feature ownership:
///   ember        → CTAs, active states, credit readouts (app-wide)
///   signalViolet → 3D/MESH-only screens exclusively
abstract class AppColors {
  // ── Base Surfaces ──────────────────────────────────────────────────────────
  /// Base app background — deepest layer
  static const Color ink = Color(0xFF111318);

  /// Cards, sheets, modals — elevated surface
  static const Color surface = Color(0xFF1B1E26);

  /// Input field backgrounds — subtle step above surface
  static const Color surfaceInput = Color(0xFF23262F);

  /// Dividers, subtle borders
  static const Color borderSubtle = Color(0xFF2A2D38);

  /// Focus / active border
  static const Color borderFocus = Color(0xFFFF7A45);

  // ── Text ──────────────────────────────────────────────────────────────────
  /// Primary text on dark surfaces
  static const Color bone = Color(0xFFF3F1EA);

  /// Secondary text, inactive icons
  static const Color slate = Color(0xFF8A93A6);

  /// Disabled text
  static const Color textDisabled = Color(0xFF4A4E5A);

  // ── Primary Accent ─────────────────────────────────────────────────────────
  /// Ember — primary CTA, active states, credit badge, progress fills
  static const Color ember = Color(0xFFFF7A45);

  /// Ember at 12% opacity — subtle background tint
  static const Color emberSoft = Color(0x1FFF7A45);

  /// Ember pressed state
  static const Color emberPressed = Color(0xFFE0622E);

  // ── Reserved Feature Accent ────────────────────────────────────────────────
  /// Signal Violet — used ONLY for 3D/MESH_GEN feature screens.
  /// Not used app-wide so it stays meaningful when it appears.
  static const Color signalViolet = Color(0xFF6E56CF);
  static const Color signalVioletSoft = Color(0x1F6E56CF);

  // ── Semantic Status ────────────────────────────────────────────────────────
  static const Color statusSuccess = Color(0xFF2DD58C);
  static const Color statusSuccessSoft = Color(0x1F2DD58C);
  static const Color statusWarning = Color(0xFFFACC15);
  static const Color statusWarningSoft = Color(0x1FFACC15);
  static const Color statusError = Color(0xFFFF4757);
  static const Color statusErrorSoft = Color(0x1FFF4757);

  // ── Job Status Semantic Colors ─────────────────────────────────────────────
  static const Color jobIdle = Color(0xFF8A93A6);
  static const Color jobQueued = Color(0xFF8A93A6);
  static const Color jobProcessing = Color(0xFFFF7A45);
  static const Color jobCompleted = Color(0xFF2DD58C);
  static const Color jobError = Color(0xFFFF4757);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient emberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A45), Color(0xFFFF5722)],
  );

  static const LinearGradient meshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6E56CF), Color(0xFF4A35A8)],
  );

  // ── Convenience Aliases ───────────────────────────────────────────────────
  static const Color bgApp = ink;
  static const Color bgPrimary = ink;
  static const Color surfaceCard = surface;
  static const Color surfacePanel = surface;
  static const Color textPrimary = bone;
  static const Color textMuted = slate;
  static const Color primaryAction = ember;
  static const Color accentGlowStart = ember;
  static const Color accentGlowEnd = ember;
  static const Color accentGlowSoft = emberSoft;
  static const Color creditGoldBg = emberSoft;
  static const Color creditGoldCircleBg = emberSoft;
  static const Color creditGoldBorder = emberSoft;
  static const Color creditGoldIcon = ember;
  static const Color creditGoldTitle = ember;
  static const Color creditGoldSubtext = slate;
  static const Color errorIndicator = statusError;
  static const Color errorIndicatorSoft = statusErrorSoft;
  static const Color successIndicator = statusSuccess;
  static const Color successIndicatorSoft = statusSuccessSoft;
  static const LinearGradient aiActionGradient = emberGradient;
}

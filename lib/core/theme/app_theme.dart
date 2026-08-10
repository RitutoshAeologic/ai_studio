import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Application Theme definition — Sleek Modern Light Theme.
abstract class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgApp,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryAction,
        secondary: AppColors.accentGlowEnd,
        surface: AppColors.surfaceCard,
        onSurface: AppColors.textPrimary,
        error: AppColors.errorIndicator,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingM,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 1,
        shadowColor: AppColors.primaryAction.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: AppTextStyles.bodyL.copyWith(color: AppColors.textMuted),
        labelStyle: AppTextStyles.bodyM,
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.errorIndicator),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.errorIndicator),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.errorIndicator, width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayXL,
        titleMedium: AppTextStyles.headingM,
        bodyLarge: AppTextStyles.bodyL,
        bodyMedium: AppTextStyles.bodyM,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.buttonLabel,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}

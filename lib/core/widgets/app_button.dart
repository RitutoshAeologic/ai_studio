import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'aperture_indicator.dart';

/// Primary action button — Darkroom design system.
/// Solid ember background, Inter 600 label, built-in loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = 52,
    this.borderRadius = 10,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isActive = isEnabled && !isLoading;
    final bgColor = color ?? AppColors.ember;

    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: isActive ? onPressed : null,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: AppColors.emberPressed.withAlpha(80),
            highlightColor: AppColors.emberPressed.withAlpha(40),
            child: Center(
              child: isLoading
                  ? const ApertureIndicator(
                      size: 28,
                      color: AppColors.bone,
                      state: ApertureState.open,
                    )
                  : Text(
                      label,
                      style: AppTextStyles.buttonLabel(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary outlined button — transparent background, ember border.
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
    this.width,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isEnabled ? AppColors.ember : AppColors.borderSubtle,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: AppColors.ember,
        ),
        child: Text(label, style: AppTextStyles.buttonLabel(color: AppColors.ember)),
      ),
    );
  }
}

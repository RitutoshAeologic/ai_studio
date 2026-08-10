import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Primary action button with gradient accent & press animation.
/// Responsive layout using ScreenUtil, AppColors, and AppTextStyles per ui_ux.md.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? color;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isEnabled && !widget.isLoading;
    final effectiveHeight = widget.height ?? 52.h;
    final effectiveRadius = widget.borderRadius ?? 12.r;

    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: effectiveHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.color != null ? null : AppColors.aiActionGradient,
              color: widget.color,
              borderRadius: BorderRadius.circular(effectiveRadius),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.accentGlowSoft,
                        blurRadius: 12.r,
                        spreadRadius: 1.r,
                      )
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isActive ? widget.onPressed : null,
                onTapDown: isActive ? (_) => _pressController.forward() : null,
                onTapUp: isActive ? (_) => _pressController.reverse() : null,
                onTapCancel: isActive ? () => _pressController.reverse() : null,
                borderRadius: BorderRadius.circular(effectiveRadius),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 22.r,
                          height: 22.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.r,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.label,
                          style: AppTextStyles.buttonLabel.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary outlined button with responsive border and scaling.
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
    this.width,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 52.h,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isEnabled ? AppColors.primaryAction : AppColors.borderSubtle,
            width: 1.5.r,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          foregroundColor: AppColors.primaryAction,
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonLabel.copyWith(
            color: AppColors.primaryAction,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// Primary gradient CTA button with loading, disabled, and pressed states.
/// Follows ui_ux.md §5.1 component behavior and utilizes ScreenUtil responsiveness.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? prefixIcon;
  final Color? backgroundColor;
  final bool useGradient;
  final double? width;
  final double height;
  final Widget? customChild;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.prefixIcon,
    this.backgroundColor,
    this.useGradient = true,
    this.width,
    this.height = 52,
    this.customChild,
  });

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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.isDisabled || widget.isLoading) return;
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool effectivelyDisabled = widget.isDisabled || widget.isLoading;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: effectivelyDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width ?? double.infinity,
          height: widget.height.h,
          decoration: BoxDecoration(
            gradient: effectivelyDisabled || !widget.useGradient
                ? null
                : AppColors.aiActionGradient,
            color: effectivelyDisabled
                ? AppColors.surfacePanel
                : (widget.useGradient
                    ? null
                    : (widget.backgroundColor ?? AppColors.primaryAction)),
            borderRadius: BorderRadius.circular(12.r),
            border: effectivelyDisabled
                ? Border.all(color: AppColors.borderSubtle, width: 1.r)
                : null,
          ),
          child: Center(
            child: widget.customChild ??
                (widget.isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            AppStrings.loadingEllipsis,
                            style: AppTextStyles.buttonLabel.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.prefixIcon != null) ...[
                            Icon(
                              widget.prefixIcon,
                              size: 18.r,
                              color: effectivelyDisabled
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                            ),
                            SizedBox(width: 8.w),
                          ],
                          Text(
                            widget.label,
                            style: AppTextStyles.buttonLabel.copyWith(
                              color: effectivelyDisabled
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      )),
          ),
        ),
      ),
    );
  }
}

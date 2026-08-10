import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Styled text input field with focus glow and real-time external error support.
/// Renders error messages cleanly BELOW the container to prevent box clipping.
class AppTextField extends StatefulWidget {
  final String hint;
  final String? label;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final bool readOnly;
  final String? errorText;
  final AutovalidateMode? autovalidateMode;

  const AppTextField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.prefixIcon,
    this.readOnly = false,
    this.errorText,
    this.autovalidateMode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;
  bool _isFocused = false;
  late FocusNode _focusNode;
  String? _internalErrorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? activeErrorText =
        (widget.errorText?.isNotEmpty == true) ? widget.errorText : _internalErrorText;
    final bool hasError = activeErrorText != null && activeErrorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.bodyM.copyWith(
              color: hasError
                  ? AppColors.errorIndicator
                  : (_isFocused ? AppColors.primaryAction : AppColors.textPrimary),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surfaceInput,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: hasError
                  ? AppColors.errorIndicator
                  : (_isFocused ? AppColors.borderFocus : AppColors.borderSubtle),
              width: (hasError || _isFocused) ? 1.5.r : 1.0.r,
            ),
            boxShadow: hasError
                ? [
                    BoxShadow(
                      color: AppColors.errorIndicator.withAlpha(30),
                      blurRadius: 8.r,
                      spreadRadius: 1.r,
                    )
                  ]
                : (_isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.accentGlowSoft,
                          blurRadius: 8.r,
                          spreadRadius: 1.r,
                        )
                      ]
                    : null),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword && _obscure,
            keyboardType: widget.keyboardType,
            autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
            validator: (val) {
              final err = widget.validator?.call(val);
              if (_internalErrorText != err) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _internalErrorText = err);
                });
              }
              return null; // Suppress internal error string inside InputDecoration to prevent box clipping
            },
            onChanged: (val) {
              widget.onChanged?.call(val);
              if (widget.validator != null) {
                final err = widget.validator!(val);
                if (_internalErrorText != err) {
                  setState(() => _internalErrorText = err);
                }
              }
            },
            textInputAction: widget.textInputAction,
            readOnly: widget.readOnly,
            style: AppTextStyles.bodyL,
            cursorColor: AppColors.primaryAction,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyL.copyWith(color: AppColors.textMuted),
              prefixIcon: widget.prefixIcon,
              prefixIconColor: hasError
                  ? AppColors.errorIndicator
                  : (_isFocused ? AppColors.primaryAction : AppColors.textMuted),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20.r,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 14.h,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14.r,
                color: AppColors.errorIndicator,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  activeErrorText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.errorIndicator,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Reusable text input field with ScreenUtil scaling and reactive validation.
/// Fully compliant with ScreenUtil, AppColors, and AppTextStyles per ui_ux.md.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.errorText,
    this.isObscure = false,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.autofillHints,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final String? errorText;
  final bool isObscure;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  bool get effectiveIsObscure => isObscure || isPassword;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  bool _hasFocus = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.effectiveIsObscure;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final borderColor = hasError
        ? AppColors.errorIndicator
        : _hasFocus
            ? AppColors.borderFocus
            : AppColors.borderSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.caption(
            fontWeight: FontWeight.w600,
            color: _hasFocus ? AppColors.primaryAction : AppColors.textMuted,
          ),
        ),
        SizedBox(height: 6.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: AppColors.surfaceInput,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: borderColor, width: _hasFocus ? 1.5 : 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9.r),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: _obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              style: AppTextStyles.bodyMedium(),
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onFieldSubmitted,
              validator: widget.validator,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTextStyles.bodyMedium(color: AppColors.textDisabled),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: true,
                fillColor: AppColors.surfaceInput,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 14.h,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _hasFocus ? AppColors.ember : AppColors.slate,
                        size: 20.r,
                      )
                    : null,
                suffixIcon: widget.effectiveIsObscure
                    ? GestureDetector(
                        onTap: () =>
                            setState(() => _obscureText = !_obscureText),
                        child: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.slate,
                          size: 20.r,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
        // Outside & below container error display discipline
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: hasError
              ? Padding(
                  key: ValueKey(widget.errorText),
                  padding: EdgeInsets.only(top: 5.h, left: 2.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 13.r,
                        color: AppColors.statusError,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: AppTextStyles.caption(
                            color: AppColors.errorIndicator,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no-error')),
        ),
      ],
    );
  }
}

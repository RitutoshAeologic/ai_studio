import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/unfocus_on_tap.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordView extends GetView<AuthController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetFormAndErrors();
    });

    return UnfocusOnTap(
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 56.h),

                // ── Wordmark ────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: const BoxDecoration(
                        color: AppColors.ember,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_outlined,
                          size: 22.r, color: AppColors.bone),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.headingLarge(color: AppColors.bone),
                    ),
                  ],
                ),

                SizedBox(height: 52.h),

                // ── State-driven body ────────────────────────────────────────
                Obx(() {
                  if (controller.resetEmailSent.value) {
                    return _SuccessState(
                      email: controller.resetEmailAddress.value,
                    );
                  }
                  return _InputFormState(
                    controller: controller,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Form State
// ─────────────────────────────────────────────────────────────────────────────
class _InputFormState extends StatelessWidget {
  const _InputFormState({
    required this.controller,
  });

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Headline ──────────────────────────────────────────────────────
        Text(
          AppStrings.forgotPasswordTitle,
          style: AppTextStyles.displayLarge(),
        ),
        SizedBox(height: 10.h),
        Text(
          AppStrings.forgotPasswordSubtitle,
          style: AppTextStyles.bodyMedium(color: AppColors.slate),
        ),

        SizedBox(height: 40.h),

        // ── Email field ───────────────────────────────────────────────────
        Obx(() => AppTextField(
              controller: controller.forgotPasswordEmailCtrl,
              label: AppStrings.emailLabel,
              hint: AppStrings.emailHint,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              errorText: controller.forgotPasswordEmailError.value,
              onChanged: (_) =>
                  controller.validateForgotPasswordEmail(controller.forgotPasswordEmailCtrl.text),
              onFieldSubmitted: (_) =>
                  controller.sendPasswordResetEmail(controller.forgotPasswordEmailCtrl.text),
            )),

        SizedBox(height: 20.h),

        // ── Error Banner ──────────────────────────────────────────────────
        Obx(() {
          if (controller.errorMessage.value.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.statusErrorSoft,
              borderRadius: BorderRadius.circular(8.r),
              border:
                  Border.all(color: AppColors.statusError.withAlpha(80)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    color: AppColors.statusError, size: 16.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    controller.errorMessage.value,
                    style: AppTextStyles.bodySmall(
                        color: AppColors.statusError),
                  ),
                ),
              ],
            ),
          );
        }),

        // ── Send Reset Link Button ────────────────────────────────────────
        Obx(() => AppButton(
              label: AppStrings.sendResetLink,
              isLoading: controller.isForgotPasswordLoading.value,
              onPressed: () =>
                  controller.sendPasswordResetEmail(controller.forgotPasswordEmailCtrl.text),
            )),

        SizedBox(height: 20.h),

        // ── Back to Sign In ───────────────────────────────────────────────
        Center(
          child: TextButton(
            onPressed: () {
              controller.resetFormAndErrors();
              Get.offNamed(AppRoutes.login);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded,
                    size: 16.r, color: AppColors.slate),
                SizedBox(width: 6.w),
                Text(
                  AppStrings.backToSignIn,
                  style:
                      AppTextStyles.labelMedium(color: AppColors.slate),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 40.h),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success Confirmation State
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessState extends StatefulWidget {
  const _SuccessState({required this.email});

  final String email;

  @override
  State<_SuccessState> createState() => _SuccessStateState();
}

class _SuccessStateState extends State<_SuccessState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  // Resend cooldown
  static const int _cooldownSeconds = 60;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownRemaining = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldownRemaining <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldownRemaining = 0);
      } else {
        if (mounted) setState(() => _cooldownRemaining--);
      }
    });
  }

  void _resend() {
    if (_cooldownRemaining > 0) return;
    final ctrl = Get.find<AuthController>();
    ctrl.sendPasswordResetEmail(widget.email);
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Animated Icon ─────────────────────────────────────────────────
        Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                color: AppColors.ember.withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.ember.withAlpha(80), width: 1.5),
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 38.r,
                color: AppColors.ember,
              ),
            ),
          ),
        ),

        SizedBox(height: 32.h),

        // ── Headline ──────────────────────────────────────────────────────
        Text(
          AppStrings.resetEmailSentTitle,
          style: AppTextStyles.displayLarge(),
        ),
        SizedBox(height: 10.h),
        Text(
          AppStrings.resetEmailSentBody,
          style: AppTextStyles.bodyMedium(color: AppColors.slate),
        ),

        SizedBox(height: 12.h),

        // ── Email pill ────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mail_outline,
                  size: 16.r, color: AppColors.primaryAction),
              SizedBox(width: 8.w),
              Text(
                widget.email,
                style: AppTextStyles.bodyMedium(
                    color: AppColors.primaryAction,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        SizedBox(height: 36.h),

        // ── Back to Sign In Button ─────────────────────────────────────────
        AppButton(
          label: AppStrings.backToSignIn,
          onPressed: () {
            Get.find<AuthController>().resetFormAndErrors();
            Get.offAllNamed(AppRoutes.login);
          },
        ),

        SizedBox(height: 16.h),

        // ── Resend link ───────────────────────────────────────────────────
        Center(
          child: _cooldownRemaining > 0
              ? Text(
                  'Resend available in ${_cooldownRemaining}s',
                  style:
                      AppTextStyles.bodySmall(color: AppColors.slate),
                )
              : TextButton(
                  onPressed: _resend,
                  child: Text(
                    AppStrings.resendEmail,
                    style: AppTextStyles.labelMedium(
                        color: AppColors.ember),
                  ),
                ),
        ),

        SizedBox(height: 40.h),
      ],
    );
  }
}

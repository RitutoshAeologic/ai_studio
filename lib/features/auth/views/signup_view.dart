import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/unfocus_on_tap.dart';
import '../controllers/auth_controller.dart';

class SignupView extends GetView<AuthController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    // Use controllers managed by AuthController so resetFormAndErrors() works.
    final nameCtrl = controller.signupNameCtrl;
    final emailCtrl = controller.signupEmailCtrl;
    final passwordCtrl = controller.signupPasswordCtrl;
    final confirmCtrl = controller.signupConfirmPasswordCtrl;

    return UnfocusOnTap(
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),

              // ── Back button ───────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  // Clear signup errors before going back
                  controller.resetFormAndErrors();
                  Get.back();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new,
                        size: 16.r, color: AppColors.slate),
                    SizedBox(width: 4.w),
                    Text(AppStrings.back,
                        style: AppTextStyles.labelMedium(color: AppColors.slate)),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // ── Headline ──────────────────────────────────────────────────
              Text(AppStrings.createAccountTitle,
                  style: AppTextStyles.displayLarge()),
              SizedBox(height: 4.h),
              Text(AppStrings.signUpSubtitle,
                  style: AppTextStyles.bodyMedium(color: AppColors.slate)),

              SizedBox(height: 4.h),

              // ── Free Credits Badge ────────────────────────────────────────
              Container(
                margin: EdgeInsets.only(top: 4.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.emberSoft,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                      color: AppColors.ember.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded,
                        color: AppColors.ember, size: 16.r),
                    SizedBox(width: 6.w),
                    Text(AppStrings.freeCreditsBadgeTitle,
                        style: AppTextStyles.labelMedium(color: AppColors.ember)),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // ── Form ──────────────────────────────────────────────────────
              Obx(() => AppTextField(
                    controller: nameCtrl,
                    label: AppStrings.fullNameLabel,
                    hint: AppStrings.fullNameHint,
                    prefixIcon: Icons.person_outline,
                    autofillHints: const [AutofillHints.name],
                    errorText: controller.signupNameError.value,
                    onChanged: (_) => controller.validateSignupName(nameCtrl.text),
                  )),

              SizedBox(height: 10.h),

              Obx(() => AppTextField(
                    controller: emailCtrl,
                    label: AppStrings.emailLabel,
                    hint: AppStrings.emailHint,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    errorText: controller.signupEmailError.value,
                    onChanged: (_) => controller.validateSignupEmail(emailCtrl.text),
                  )),

              SizedBox(height: 10.h),

              Obx(() => AppTextField(
                    controller: passwordCtrl,
                    label: AppStrings.passwordLabel,
                    hint: AppStrings.passwordSignupHint,
                    prefixIcon: Icons.lock_outline,
                    isObscure: true,
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: controller.signupPasswordError.value,
                    onChanged: (_) =>
                        controller.validateSignupPassword(passwordCtrl.text),
                  )),

              SizedBox(height: 10.h),

              Obx(() => AppTextField(
                    controller: confirmCtrl,
                    label: AppStrings.confirmPasswordLabel,
                    hint: AppStrings.confirmPasswordHint,
                    prefixIcon: Icons.lock_outline,
                    isObscure: true,
                    textInputAction: TextInputAction.done,
                    errorText: controller.signupConfirmPasswordError.value,
                    onChanged: (_) => controller.validateSignupConfirmPassword(
                        confirmCtrl.text, passwordCtrl.text),
                    onFieldSubmitted: (_) => controller.signUpWithEmail(
                        nameCtrl.text,
                        emailCtrl.text,
                        passwordCtrl.text,
                        confirmCtrl.text),
                  )),

              SizedBox(height: 16.h),

              // ── Error Banner ──────────────────────────────────────────────
              Obx(() {
                if (controller.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.statusErrorSoft,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.statusError.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppColors.statusError, size: 16.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(controller.errorMessage.value,
                            style: AppTextStyles.bodySmall(
                                color: AppColors.statusError)),
                      ),
                    ],
                  ),
                );
              }),

              // ── Create Account Button ─────────────────────────────────────
              Obx(() => AppButton(
                    label: AppStrings.createAccountButton,
                    isLoading: controller.isSignupLoading.value,
                    onPressed: () => controller.signUpWithEmail(
                        nameCtrl.text,
                        emailCtrl.text,
                        passwordCtrl.text,
                        confirmCtrl.text),
                  )),

              SizedBox(height: 10.h),

              // ── Terms ─────────────────────────────────────────────────────
              Center(
                child: Text(
                  AppStrings.termsAndPrivacyNotice,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(color: AppColors.textDisabled),
                ),
              ),

              SizedBox(height: 12.h),

              // ── Sign In Link ──────────────────────────────────────────────
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      AppStrings.alreadyHaveAccount,
                      style: AppTextStyles.bodyM(),
                    ),
                    GestureDetector(
                      onTap: () {
                        controller.resetFormAndErrors();
                        Get.back();
                      },
                      child: Text(
                        AppStrings.signInLink,
                        style: AppTextStyles.bodyM(
                          color: AppColors.primaryAction,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

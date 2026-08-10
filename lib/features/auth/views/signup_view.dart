import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
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

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

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
                    const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: AppColors.slate),
                    const SizedBox(width: 4),
                    Text(AppStrings.back,
                        style: AppTextStyles.labelMedium(color: AppColors.slate)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Headline ──────────────────────────────────────────────────
              Text(AppStrings.createAccountTitle,
                  style: AppTextStyles.displayLarge()),
              const SizedBox(height: 4),
              Text(AppStrings.signUpSubtitle,
                  style: AppTextStyles.bodyMedium(color: AppColors.slate)),

              const SizedBox(height: 4),

              // ── Free Credits Badge ────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.emberSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.ember.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: AppColors.ember, size: 16),
                    const SizedBox(width: 6),
                    Text(AppStrings.freeCreditsBadgeTitle,
                        style: AppTextStyles.labelMedium(color: AppColors.ember)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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

              const SizedBox(height: 10),

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

              const SizedBox(height: 10),

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

              const SizedBox(height: 10),

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

              const SizedBox(height: 16),

              // ── Error Banner ──────────────────────────────────────────────
              Obx(() {
                if (controller.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.statusErrorSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.statusError.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.statusError, size: 16),
                      const SizedBox(width: 8),
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

              const SizedBox(height: 10),

              // ── Terms ─────────────────────────────────────────────────────
              Center(
                child: Text(
                  AppStrings.termsAndPrivacyNotice,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(color: AppColors.textDisabled),
                ),
              ),

              const SizedBox(height: 12),

              // ── Sign In Link ──────────────────────────────────────────────
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.alreadyHaveAccount,
                        style:
                            AppTextStyles.bodyMedium(color: AppColors.slate)),
                    GestureDetector(
                      onTap: () {
                        controller.resetFormAndErrors();
                        Get.back();
                      },
                      child: Text(AppStrings.signInLink,
                          style: AppTextStyles.bodyMedium(
                              color: AppColors.ember)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Use controllers managed by AuthController so resetFormAndErrors() works.
    final emailCtrl = controller.loginEmailCtrl;
    final passwordCtrl = controller.loginPasswordCtrl;

    // Clear any stale errors every time this page is freshly shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetFormAndErrors();
    });

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // ── Wordmark ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.ember,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_outlined, size: 16, color: AppColors.bone),
                  ),
                  const SizedBox(width: 10),
                  Text(AppStrings.appName,
                      style: AppTextStyles.headingSmall(color: AppColors.bone)),
                ],
              ),

              const SizedBox(height: 52),

              // ── Headline ──────────────────────────────────────────────────
              Text(AppStrings.welcomeBack,
                  style: AppTextStyles.displayLarge()),
              const SizedBox(height: 8),
              Text(AppStrings.signInSubtitle,
                  style: AppTextStyles.bodyMedium(color: AppColors.slate)),

              const SizedBox(height: 40),

              // ── Form ──────────────────────────────────────────────────────
              Obx(() => AppTextField(
                    controller: emailCtrl,
                    label: AppStrings.emailLabel,
                    hint: AppStrings.emailHint,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    errorText: controller.loginEmailError.value,
                    onChanged: (_) => controller.validateLoginEmail(emailCtrl.text),
                  )),

              const SizedBox(height: 16),

              Obx(() => AppTextField(
                    controller: passwordCtrl,
                    label: AppStrings.passwordLabel,
                    hint: AppStrings.passwordLoginHint,
                    prefixIcon: Icons.lock_outline,
                    isObscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    errorText: controller.loginPasswordError.value,
                    onChanged: (_) =>
                        controller.validateLoginPassword(passwordCtrl.text),
                    onFieldSubmitted: (_) => controller.signInWithEmail(
                        emailCtrl.text, passwordCtrl.text),
                  )),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(AppStrings.forgotPassword,
                      style: AppTextStyles.labelMedium(color: AppColors.ember)),
                ),
              ),

              const SizedBox(height: 8),

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

              // ── Sign In Button ────────────────────────────────────────────
              Obx(() => AppButton(
                    label: AppStrings.signIn,
                    isLoading: controller.isLoginLoading.value,
                    onPressed: () => controller.signInWithEmail(
                        emailCtrl.text, passwordCtrl.text),
                  )),

              const SizedBox(height: 32),

              // ── Divider ───────────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.borderSubtle)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: AppTextStyles.bodySmall(color: AppColors.slate)),
                  ),
                  const Expanded(child: Divider(color: AppColors.borderSubtle)),
                ],
              ),

              const SizedBox(height: 32),

              // ── Sign Up Link ──────────────────────────────────────────────
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.dontHaveAccount,
                        style:
                            AppTextStyles.bodyMedium(color: AppColors.slate)),
                    GestureDetector(
                      onTap: () {
                        // Clear login errors before going to sign up
                        controller.resetFormAndErrors();
                        Get.toNamed('/signup');
                      },
                      child: Text(AppStrings.createOne,
                          style: AppTextStyles.bodyMedium(
                              color: AppColors.ember)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

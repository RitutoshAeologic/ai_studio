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

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Clear any stale errors every time this page is freshly shown.
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

              // ── Wordmark ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: const BoxDecoration(
                      color: AppColors.ember,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_outlined, size: 22.r, color: AppColors.bone),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    AppStrings.appName,
                    style: AppTextStyles.headingLarge(color: AppColors.bone),
                  ),
                ],
              ),

              SizedBox(height: 52.h),

              // ── Headline ──────────────────────────────────────────────────
              Text(AppStrings.welcomeBack,
                  style: AppTextStyles.displayLarge()),
              SizedBox(height: 8.h),
              Text(AppStrings.signInSubtitle,
                  style: AppTextStyles.bodyMedium(color: AppColors.slate)),

              SizedBox(height: 40.h),

              // ── Form ──────────────────────────────────────────────────────
              // NOTE: controller.loginEmailCtrl is referenced directly (not via a
              // local variable) so that after fenix recreation the Obx always reads
              // the fresh TextEditingController from the new controller instance.
              Obx(() => AppTextField(
                    controller: controller.loginEmailCtrl,
                    label: AppStrings.emailLabel,
                    hint: AppStrings.emailHint,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    errorText: controller.loginEmailError.value,
                    onChanged: (_) => controller.validateLoginEmail(
                        controller.loginEmailCtrl.text),
                  )),

              SizedBox(height: 16.h),

              Obx(() => AppTextField(
                    controller: controller.loginPasswordCtrl,
                    label: AppStrings.passwordLabel,
                    hint: AppStrings.passwordLoginHint,
                    prefixIcon: Icons.lock_outline,
                    isObscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    errorText: controller.loginPasswordError.value,
                    onChanged: (_) => controller.validateLoginPassword(
                        controller.loginPasswordCtrl.text),
                    onFieldSubmitted: (_) => controller.signInWithEmail(
                        controller.loginEmailCtrl.text,
                        controller.loginPasswordCtrl.text),
                  )),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    controller.resetFormAndErrors();
                    Get.toNamed(AppRoutes.forgotPassword);
                  },
                  child: Text(AppStrings.forgotPassword,
                      style: AppTextStyles.labelMedium(color: AppColors.ember)),
                ),
              ),

              SizedBox(height: 8.h),

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

              // ── Sign In Button ────────────────────────────────────────────
              Obx(() => AppButton(
                    label: AppStrings.signIn,
                    isLoading: controller.isLoginLoading.value,
                    onPressed: () => controller.signInWithEmail(
                        controller.loginEmailCtrl.text,
                        controller.loginPasswordCtrl.text),
                  )),

              SizedBox(height: 32.h),

              // ── Divider ───────────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.borderSubtle)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text('or',
                        style: AppTextStyles.bodySmall(color: AppColors.slate)),
                  ),
                  const Expanded(child: Divider(color: AppColors.borderSubtle)),
                ],
              ),

              SizedBox(height: 32.h),

              // ── Sign Up Link ──────────────────────────────────────────────
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(AppStrings.dontHaveAccount,
                        style:
                            AppTextStyles.bodyMedium(color: AppColors.slate)),
                    GestureDetector(
                      onTap: () {
                        controller.resetFormAndErrors();
                        Get.toNamed(AppRoutes.signup);
                      },
                      child: Text(
                        AppStrings.createOne,
                        style: AppTextStyles.bodyM(
                          color: AppColors.primaryAction,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

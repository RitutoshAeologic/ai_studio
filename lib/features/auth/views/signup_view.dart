import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

/// Premium Sign Up screen — Firebase email/password registration with real-time state-managed validation.
class SignupView extends GetView<AuthController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Row(
          children: [
            const _GlowAccentBar(
              colors: [
                Colors.transparent,
                AppColors.accentGlowEnd,
                AppColors.accentGlowStart,
                Colors.transparent,
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTopNavigationBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28.w,
                        vertical: 16.h,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroHeader(),
                            SizedBox(height: 20.h),
                            _buildCreditsBadge(),
                            SizedBox(height: 28.h),
                            _buildNameField(nameController),
                            SizedBox(height: 16.h),
                            _buildEmailField(emailController),
                            SizedBox(height: 16.h),
                            _buildPasswordField(passwordController),
                            SizedBox(height: 16.h),
                            _buildConfirmPasswordField(
                                confirmPasswordController, passwordController),
                            SizedBox(height: 6.h),
                            _buildPasswordHint(),
                            SizedBox(height: 28.h),
                            _buildErrorMessage(),
                            _buildCreateAccountButton(
                              formKey,
                              nameController,
                              emailController,
                              passwordController,
                              confirmPasswordController,
                            ),
                            SizedBox(height: 36.h),
                            _buildSignInRedirect(),
                            SizedBox(height: 20.h),
                            _buildTermsText(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Integrated Top Navigation Bar ────────────────────────────────────
  Widget _buildTopNavigationBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 16.r,
                ),
                SizedBox(width: 6.w),
                Text(
                  AppStrings.back,
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 28.r,
                height: 28.r,
                decoration: BoxDecoration(
                  gradient: AppColors.aiActionGradient,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 14.r,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                AppStrings.appName,
                style: AppTextStyles.buttonLabel.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Hero Header ──────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Text(AppStrings.createAccountTitle, style: AppTextStyles.displayXL),
        SizedBox(height: 8.h),
        Text(
          AppStrings.signUpSubtitle,
          style: AppTextStyles.bodyL.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ─── Free Credits Badge ───────────────────────────────────────────────
  Widget _buildCreditsBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.creditGoldBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.creditGoldBorder,
          width: 1.r,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: const BoxDecoration(
              color: AppColors.creditGoldCircleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: AppColors.creditGoldIcon,
              size: 20.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.freeCreditsBadgeTitle,
                  style: AppTextStyles.headingM.copyWith(
                    color: AppColors.creditGoldTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppStrings.freeCreditsBadgeSubtext,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.creditGoldSubtext,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Fields ──────────────────────────────────────────────────────────
  Widget _buildNameField(TextEditingController ctrl) {
    return Obx(() => AppTextField(
          label: AppStrings.fullNameLabel,
          hint: AppStrings.fullNameHint,
          controller: ctrl,
          textInputAction: TextInputAction.next,
          prefixIcon: Icon(Icons.person_outline_rounded, size: 18.r),
          errorText: controller.signupNameError.value,
          onChanged: (val) {
            controller.clearError();
            controller.validateSignupName(val);
          },
          validator: controller.validateSignupName,
        ));
  }

  Widget _buildEmailField(TextEditingController ctrl) {
    return Obx(() => AppTextField(
          label: AppStrings.emailLabel,
          hint: AppStrings.emailHint,
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: Icon(Icons.mail_outline_rounded, size: 18.r),
          errorText: controller.signupEmailError.value,
          onChanged: (val) {
            controller.clearError();
            controller.validateSignupEmail(val);
          },
          validator: controller.validateSignupEmail,
        ));
  }

  Widget _buildPasswordField(TextEditingController ctrl) {
    return Obx(() => AppTextField(
          label: AppStrings.passwordLabel,
          hint: AppStrings.passwordSignupHint,
          controller: ctrl,
          isPassword: true,
          textInputAction: TextInputAction.next,
          prefixIcon: Icon(Icons.lock_outline_rounded, size: 18.r),
          errorText: controller.signupPasswordError.value,
          onChanged: (val) {
            controller.clearError();
            controller.validateSignupPassword(val);
          },
          validator: controller.validateSignupPassword,
        ));
  }

  Widget _buildConfirmPasswordField(
      TextEditingController ctrl, TextEditingController passCtrl) {
    return Obx(() => AppTextField(
          label: AppStrings.confirmPasswordLabel,
          hint: AppStrings.confirmPasswordHint,
          controller: ctrl,
          isPassword: true,
          textInputAction: TextInputAction.done,
          prefixIcon: Icon(Icons.lock_outline_rounded, size: 18.r),
          errorText: controller.signupConfirmPasswordError.value,
          onChanged: (val) {
            controller.clearError();
            controller.validateSignupConfirmPassword(val, passCtrl.text);
          },
          validator: (val) =>
              controller.validateSignupConfirmPassword(val, passCtrl.text),
        ));
  }

  Widget _buildPasswordHint() {
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 12.r,
            color: AppColors.textMuted,
          ),
          SizedBox(width: 4.w),
          Text(AppStrings.passwordRequirementHint, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  // ─── Error Banner ─────────────────────────────────────────────────────
  Widget _buildErrorMessage() {
    return Obx(() {
      if (controller.errorMessage.value.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: _ErrorBanner(message: controller.errorMessage.value),
      );
    });
  }

  // ─── CTA ─────────────────────────────────────────────────────────────
  Widget _buildCreateAccountButton(
    GlobalKey<FormState> formKey,
    TextEditingController nameCtrl,
    TextEditingController emailCtrl,
    TextEditingController passCtrl,
    TextEditingController confirmPassCtrl,
  ) {
    return Obx(() => AppButton(
          label: AppStrings.createAccountButton,
          isLoading: controller.isSignupLoading.value,
          onPressed: () {
            controller.clearError();
            controller.signUpWithEmail(
              nameCtrl.text.trim(),
              emailCtrl.text.trim(),
              passCtrl.text,
              confirmPassCtrl.text,
            );
          },
        ));
  }

  // ─── Footer Links ─────────────────────────────────────────────────────
  Widget _buildSignInRedirect() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(AppStrings.alreadyHaveAccount, style: AppTextStyles.bodyM),
          GestureDetector(
            onTap: () {
              controller.clearError();
              Get.back();
            },
            child: Text(
              AppStrings.signIn,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.primaryAction,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsText() {
    return Center(
      child: Text(
        AppStrings.termsAndPrivacyNotice,
        style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _GlowAccentBar extends StatelessWidget {
  final List<Color> colors;
  const _GlowAccentBar({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.w,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.errorIndicatorSoft,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.errorIndicator.withAlpha(80),
          width: 1.r,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.errorIndicator,
            size: 16.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.errorIndicator,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

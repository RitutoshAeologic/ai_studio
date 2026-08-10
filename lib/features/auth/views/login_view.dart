import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

/// Premium Login screen — Firebase email/password sign-in with real-time state-managed validation.
class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Row(
          children: [
            const _GlowAccentBar(
              colors: [
                Colors.transparent,
                AppColors.accentGlowStart,
                AppColors.accentGlowEnd,
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
                            SizedBox(height: 36.h),
                            _buildEmailField(emailController),
                            SizedBox(height: 16.h),
                            _buildPasswordField(passwordController),
                            SizedBox(height: 10.h),
                            _buildForgotPassword(),
                            SizedBox(height: 32.h),
                            _buildErrorMessage(),
                            _buildSignInButton(
                                formKey, emailController, passwordController),
                            SizedBox(height: 40.h),
                            _buildSignUpRedirect(),
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
          Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  gradient: AppColors.aiActionGradient,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGlowSoft,
                      blurRadius: 12.r,
                      spreadRadius: 1.r,
                    )
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                AppStrings.appName,
                style: AppTextStyles.headingM.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.borderSubtle, width: 1.r),
            ),
            child: Text(
              AppStrings.signIn,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryAction,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        Text(AppStrings.welcomeBack, style: AppTextStyles.displayXL),
        SizedBox(height: 8.h),
        Text(
          AppStrings.signInSubtitle,
          style: AppTextStyles.bodyL.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ─── Fields ──────────────────────────────────────────────────────────
  Widget _buildEmailField(TextEditingController ctrl) {
    return Obx(() => AppTextField(
          label: AppStrings.emailLabel,
          hint: AppStrings.emailHint,
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: Icon(Icons.mail_outline_rounded, size: 18.r),
          errorText: controller.loginEmailError.value,
          onChanged: (val) {
            controller.clearError();
            controller.validateLoginEmail(val);
          },
          validator: controller.validateLoginEmail,
        ));
  }

  Widget _buildPasswordField(TextEditingController ctrl) {
    return Obx(() => AppTextField(
          label: AppStrings.passwordLabel,
          hint: AppStrings.passwordLoginHint,
          controller: ctrl,
          isPassword: true,
          textInputAction: TextInputAction.done,
          prefixIcon: Icon(Icons.lock_outline_rounded, size: 18.r),
          errorText: controller.loginPasswordError.value,
          onChanged: (val) {
            controller.clearError();
            controller.validateLoginPassword(val);
          },
          validator: controller.validateLoginPassword,
        ));
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Navigate to forgot password screen
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          AppStrings.forgotPassword,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primaryAction,
            fontWeight: FontWeight.w600,
          ),
        ),
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
  Widget _buildSignInButton(
    GlobalKey<FormState> formKey,
    TextEditingController emailCtrl,
    TextEditingController passCtrl,
  ) {
    return Obx(() => AppButton(
          label: AppStrings.signIn,
          isLoading: controller.isLoginLoading.value,
          onPressed: () {
            controller.clearError();
            controller.signInWithEmail(
              emailCtrl.text.trim(),
              passCtrl.text,
            );
          },
        ));
  }

  // ─── Sign Up Redirect ─────────────────────────────────────────────────
  Widget _buildSignUpRedirect() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(AppStrings.dontHaveAccount, style: AppTextStyles.bodyM),
          GestureDetector(
            onTap: () {
              controller.clearError();
              Get.toNamed(AppRoutes.signup);
            },
            child: Text(
              AppStrings.createOne,
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../shell/controllers/home_shell_controller.dart';
import '../../wallet/controllers/wallet_controller.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  bool _hapticsEnabled = true;
  bool _notificationsEnabled = true;

  void _showDarkSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ??
                  (isError
                      ? Icons.error_outline_rounded
                      : (isSuccess
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded)),
              color: isError
                  ? AppColors.statusError
                  : (isSuccess ? AppColors.statusSuccess : AppColors.ember),
              size: 20.r,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium(color: AppColors.bone),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C1E26),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(
            color: isError
                ? AppColors.statusError.withAlpha(120)
                : (isSuccess
                    ? AppColors.statusSuccess.withAlpha(120)
                    : AppColors.borderSubtle),
            width: 1.r,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        clipBehavior: Clip.antiAlias,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: AppColors.borderSubtle, width: 1.r),
        ),
        title: Text(
          'Edit Display Name',
          style: AppTextStyles.headingSmall(color: AppColors.bone),
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          cursorColor: AppColors.ember,
          style: AppTextStyles.bodyMedium(color: AppColors.bone),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: AppTextStyles.bodySmall(color: AppColors.slate),
            filled: true,
            fillColor: AppColors.surfaceInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonLabel(color: AppColors.slate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ember,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.updateDisplayName(newName);
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({'displayName': newName}, SetOptions(merge: true));
                  final authCtrl = Get.find<AuthController>();
                  authCtrl.signupNameCtrl.text = newName;
                }
              }
              if (context.mounted) {
                Navigator.of(ctx).pop();
                _showDarkSnackBar(context, 'Display name updated!',
                    isSuccess: true);
                setState(() {});
              }
            },
            child: Text(
              'Save',
              style: AppTextStyles.buttonLabel(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sendPasswordReset(BuildContext context, String email) async {
    if (email.isEmpty) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        _showDarkSnackBar(context, 'Password reset email sent to $email',
            isSuccess: true);
      }
    } catch (e) {
      if (context.mounted) {
        _showDarkSnackBar(context, 'Failed to send reset email: $e',
            isError: true);
      }
    }
  }

  void _showHelpAndFeedbackDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    const supportEmail = 'support@aistudio.app';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: AppColors.borderSubtle, width: 1.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.ember.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent_rounded,
                  color: AppColors.ember, size: 22.r),
            ),
            SizedBox(width: 12.w),
            Text(
              'Help & Support',
              style: AppTextStyles.headingSmall(color: AppColors.bone),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need assistance with video generation, face swap, or credits?',
              style: AppTextStyles.bodyMedium(color: AppColors.slate),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: AppColors.ember, size: 20.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      supportEmail,
                      style: AppTextStyles.labelMedium(
                        color: AppColors.bone,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: supportEmail));
                      _showDarkSnackBar(
                        context,
                        'Support email copied to clipboard!',
                        isSuccess: true,
                      );
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.ember,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Copy',
                        style: AppTextStyles.caption(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '• Support response within 24 hours.\n• For billing or generation refund inquiries, please include your User ID.',
              style: AppTextStyles.caption(color: AppColors.slate),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ember,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: AppTextStyles.buttonLabel(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyAndTermsDialog(BuildContext context) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: AppColors.borderSubtle, width: 1.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.ember.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.privacy_tip_outlined,
                  color: AppColors.ember, size: 22.r),
            ),
            SizedBox(width: 12.w),
            Text(
              'Privacy & Terms',
              style: AppTextStyles.headingSmall(color: AppColors.bone),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPolicySection(
                  title: '1. Data Privacy & Processing',
                  content:
                      'All source images and face-swap templates are processed securely on dedicated private pipelines. We never sell your personal media or share biometric face data with third parties.',
                ),
                SizedBox(height: 12.h),
                _buildPolicySection(
                  title: '2. Ownership of Generated Content',
                  content:
                      'You retain 100% intellectual property and commercial usage rights over any images, video face swaps, and 3D meshes created through your account.',
                ),
                SizedBox(height: 12.h),
                _buildPolicySection(
                  title: '3. Credits & Fair Usage',
                  content:
                      'AI credits are deducted per generation according to the displayed rate table. In the event of a pipeline failure or generation timeout, credits are automatically refunded to your wallet.',
                ),
                SizedBox(height: 12.h),
                _buildPolicySection(
                  title: '4. Responsible AI Usage',
                  content:
                      'Users agree not to generate explicit, deceptive, or non-consensual content. Violations may result in immediate suspension of account privileges.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ember,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Got It',
              style: AppTextStyles.buttonLabel(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection({required String title, required String content}) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelSmall(
              color: AppColors.bone,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            content,
            style: AppTextStyles.caption(color: AppColors.slate),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: AppColors.borderSubtle, width: 1.r),
        ),
        title: Text(
          'Sign Out',
          style: AppTextStyles.headingSmall(color: AppColors.bone),
        ),
        content: Text(
          'Are you sure you want to sign out of AI Studio?',
          style: AppTextStyles.bodyMedium(color: AppColors.slate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonLabel(color: AppColors.slate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              final authCtrl = Get.find<AuthController>();
              authCtrl.signOut();
            },
            child: Text(
              'Sign Out',
              style: AppTextStyles.buttonLabel(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final walletCtrl = Get.find<WalletController>();
    final user = authCtrl.currentUser.value;
    final displayName = user?.displayName ?? 'AI Creator';
    final email = user?.email ?? '';
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                children: [
                  // ── User Header Card ───────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color: AppColors.borderSubtle, width: 1.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 72.r,
                              height: 72.r,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.ember,
                                    AppColors.creditGoldIcon,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.ember.withAlpha(80),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _showEditNameDialog(context, displayName),
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceInput,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.borderSubtle, width: 1.r),
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 14.r,
                                  color: AppColors.ember,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: AppTextStyles.headingMedium(
                                    color: AppColors.bone),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.ember.withAlpha(30),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                    color: AppColors.ember.withAlpha(80)),
                              ),
                              child: Text(
                                'CREATOR',
                                style: AppTextStyles.caption(
                                  color: AppColors.ember,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          email,
                          style: AppTextStyles.bodySmall(color: AppColors.slate),
                        ),
                        if (uid.isNotEmpty) ...[
                          SizedBox(height: 10.h),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: uid));
                              _showDarkSnackBar(
                                context,
                                'User ID copied to clipboard',
                                isSuccess: true,
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceInput,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ID: ${uid.substring(0, uid.length > 8 ? 8 : uid.length)}...',
                                    style: AppTextStyles.caption(
                                        color: AppColors.slate),
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(Icons.copy_rounded,
                                      size: 12.r, color: AppColors.slate),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // ── Quick Wallet & Credits Summary Tile ───────────────────
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: AppColors.ember.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.ember,
                            size: 24.r,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Credit Balance',
                                style: AppTextStyles.caption(
                                    color: AppColors.slate),
                              ),
                              Obx(() => Text(
                                    '${walletCtrl.wallet.value?.balance ?? 0} Credits',
                                    style: AppTextStyles.headingSmall(
                                        color: AppColors.bone),
                                  )),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ember,
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          onPressed: () {
                            if (Get.isRegistered<HomeShellController>()) {
                              Get.find<HomeShellController>()
                                  .switchTab(2); // Wallet tab
                            }
                          },
                          child: Text(
                            'Top Up',
                            style:
                                AppTextStyles.buttonLabel(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // ── Settings Sections ─────────────────────────────────────
                  _buildSectionHeader('Account & Security'),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.badge_outlined,
                      title: 'Edit Display Name',
                      subtitle: displayName,
                      onTap: () => _showEditNameDialog(context, displayName),
                    ),
                    _buildSettingsTile(
                      icon: Icons.lock_reset_rounded,
                      title: 'Reset Password',
                      subtitle: 'Send password reset link to $email',
                      onTap: () => _sendPasswordReset(context, email),
                    ),
                  ]),

                  SizedBox(height: 16.h),

                  _buildSectionHeader('Preferences'),
                  _buildSettingsGroup([
                    _buildSwitchTile(
                      icon: Icons.vibration_rounded,
                      title: 'Haptic Feedback',
                      subtitle: 'Subtle vibration on taps and actions',
                      value: _hapticsEnabled,
                      onChanged: (val) {
                        setState(() => _hapticsEnabled = val);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Job Completion Alerts',
                      subtitle: 'Receive in-app popups when videos are ready',
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Appearance',
                      subtitle: 'Studio Dark (Active)',
                      trailing: Icon(Icons.check_circle_rounded,
                          color: AppColors.ember, size: 18.r),
                    ),
                  ]),

                  SizedBox(height: 16.h),

                  _buildSectionHeader('About & Support'),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Feedback',
                      subtitle: 'Reach out to support or report an issue',
                      onTap: () => _showHelpAndFeedbackDialog(context),
                    ),
                    _buildSettingsTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Privacy Policy & Terms',
                      subtitle: 'Read our data privacy and terms of service',
                      onTap: () => _showPrivacyAndTermsDialog(context),
                    ),
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      subtitle: 'v1.0.0 (Production Studio Build)',
                    ),
                  ]),

                  SizedBox(height: 24.h),

                  // ── Sign Out Button ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.statusError.withAlpha(120),
                            width: 1.r),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      onPressed: () => _confirmSignOut(context),
                      icon: Icon(Icons.logout_rounded,
                          color: AppColors.statusError, size: 20.r),
                      label: Text(
                        'Sign Out',
                        style: AppTextStyles.buttonLabel(
                            color: AppColors.statusError),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        title,
        style: AppTextStyles.labelSmall(
          color: AppColors.slate,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSubtle, width: 1.r),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: const BoxDecoration(
          color: AppColors.surfaceInput,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.ember, size: 18.r),
      ),
      title: Text(
        title,
        style: AppTextStyles.labelMedium(color: AppColors.bone),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.caption(color: AppColors.slate),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded,
                  color: AppColors.slate, size: 20.r)
              : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      splashRadius: 0,
      hoverColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      secondary: Container(
        padding: EdgeInsets.all(8.r),
        decoration: const BoxDecoration(
          color: AppColors.surfaceInput,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.ember, size: 18.r),
      ),
      title: Text(
        title,
        style: AppTextStyles.labelMedium(color: AppColors.bone),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption(color: AppColors.slate),
      ),
      value: value,
      activeTrackColor: AppColors.ember.withAlpha(140),
      activeThumbColor: AppColors.ember,
      onChanged: onChanged,
    );
  }
}

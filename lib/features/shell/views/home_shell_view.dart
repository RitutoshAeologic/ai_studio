import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../wallet/views/wallet_debug_view.dart';
import '../widgets/credit_badge_widget.dart';

/// Main application shell with persistent navigation header and tab bar.
/// Responsive layout using ScreenUtil, AppStrings, AppColors, and AppTextStyles per ui_ux.md.
class HomeShellView extends StatefulWidget {
  const HomeShellView({super.key});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _GenerateTabPlaceholder(),
    _GalleryTabPlaceholder(),
    _WalletTabPlaceholder(),
    _ProfileTabPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.bgApp,

      // ── Persistent Navigation Header ─────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                gradient: AppColors.aiActionGradient,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGlowSoft,
                    blurRadius: 8.r,
                    spreadRadius: 1.r,
                  )
                ],
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 16.r,
                color: Colors.white,
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
        actions: [
          // Persistent Credit Badge Widget
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: const CreditBadge(),
          ),

          // Debug-only wallet inspector modal
          if (kDebugMode)
            IconButton(
              icon: Icon(
                Icons.bug_report_outlined,
                color: AppColors.creditGoldIcon,
                size: 20.r,
              ),
              tooltip: AppStrings.walletDebugTitle,
              onPressed: () => WalletDebugView.show(context),
            ),

          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: AppColors.textMuted,
              size: 20.r,
            ),
            tooltip: AppStrings.signOut,
            onPressed: () => authCtrl.signOut(),
          ),
          SizedBox(width: 4.w),
        ],
      ),

      // ── Tab Body Container ────────────────────────────────────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // ── Bottom Navigation Bar ──────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(
            top: BorderSide(
              color: AppColors.borderSubtle,
              width: 1.r,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.surfaceCard,
          selectedItemColor: AppColors.primaryAction,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryAction,
          ),
          unselectedLabelStyle: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined, size: 20.r),
              activeIcon: Icon(Icons.auto_awesome_rounded,
                  size: 20.r, color: AppColors.primaryAction),
              label: AppStrings.tabGenerate,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined, size: 20.r),
              activeIcon: Icon(Icons.grid_view_rounded,
                  size: 20.r, color: AppColors.primaryAction),
              label: AppStrings.tabGallery,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined, size: 20.r),
              activeIcon: Icon(Icons.account_balance_wallet_rounded,
                  size: 20.r, color: AppColors.primaryAction),
              label: AppStrings.tabWallet,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 20.r),
              activeIcon: Icon(Icons.person_rounded,
                  size: 20.r, color: AppColors.primaryAction),
              label: AppStrings.tabProfile,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Placeholders ────────────────────────────────────────────────────────

class _GenerateTabPlaceholder extends StatelessWidget {
  const _GenerateTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              gradient: AppColors.aiActionGradient,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGlowSoft,
                  blurRadius: 16.r,
                  spreadRadius: 2.r,
                )
              ],
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 32.r,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            AppStrings.generationCanvasTitle,
            style: AppTextStyles.headingL,
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.generationCanvasSubtitle,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _GalleryTabPlaceholder extends StatelessWidget {
  const _GalleryTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_view_rounded, size: 48.r, color: AppColors.textMuted),
          SizedBox(height: 16.h),
          Text(
            AppStrings.tabGallery,
            style: AppTextStyles.headingL,
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.galleryTabSubtitle,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _WalletTabPlaceholder extends StatelessWidget {
  const _WalletTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_rounded,
              size: 48.r, color: AppColors.primaryAction),
          SizedBox(height: 16.h),
          Text(
            AppStrings.walletTitle,
            style: AppTextStyles.headingL,
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.walletTabSubtitle,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabPlaceholder extends StatelessWidget {
  const _ProfileTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60.r,
            height: 60.r,
            decoration: BoxDecoration(
              color: AppColors.surfaceInput,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle, width: 1.r),
            ),
            child: Icon(Icons.person_rounded,
                size: 32.r, color: AppColors.primaryAction),
          ),
          SizedBox(height: 16.h),
          Obx(() => Text(
                authCtrl.currentUser.value?.displayName ?? AppStrings.userProfile,
                style: AppTextStyles.headingL,
              )),
          SizedBox(height: 4.h),
          Obx(() => Text(
                authCtrl.currentUser.value?.email ?? '',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
              )),
        ],
      ),
    );
  }
}

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

import '../../generate/views/generation_studio_view.dart';
import 'gallery_tab_view.dart';

class HomeShellView extends StatefulWidget {
  const HomeShellView({super.key});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    GenerationStudioView(),
    GalleryTabView(),
    _WalletTabPlaceholder(),
    _ProfileTabPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.ink,

      // ── Persistent Header ──────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 28.r,
              height: 28.r,
              decoration: const BoxDecoration(
                color: AppColors.ember,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, size: 16.r, color: AppColors.bone),
            ),
            SizedBox(width: 8.w),
            Text(
              AppStrings.appName,
              style: AppTextStyles.headingSmall(),
            ),
          ],
        ),
        actions: [
          // Persistent Credit Badge Widget (Task F1.2)
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: const CreditBadge(),
          ),

          // Debug-only wallet inspector modal (Task F1.2)
          if (kDebugMode)
            IconButton(
              icon: Icon(Icons.bug_report_outlined,
                  color: AppColors.statusWarning, size: 20.r),
              tooltip: AppStrings.walletDebugTitle,
              onPressed: () => WalletDebugView.show(context),
            ),

          IconButton(
            icon: Icon(Icons.logout_outlined,
                color: AppColors.slate, size: 20.r),
            tooltip: 'Sign Out',
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

      // ── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.ember,
          unselectedItemColor: AppColors.slate,
          selectedLabelStyle: AppTextStyles.labelMedium(color: AppColors.ember),
          unselectedLabelStyle: AppTextStyles.labelMedium(color: AppColors.slate),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome, color: AppColors.ember),
              label: AppStrings.tabGenerate,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view, color: AppColors.ember),
              label: AppStrings.tabGallery,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon:
                  Icon(Icons.account_balance_wallet, color: AppColors.ember),
              label: AppStrings.tabWallet,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppColors.ember),
              label: AppStrings.tabProfile,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Placeholders ─────────────────────────────────────────────────────────

class _WalletTabPlaceholder extends StatelessWidget {
  const _WalletTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet,
              size: 48.r, color: AppColors.ember),
          SizedBox(height: 16.h),
          Text(
            AppStrings.walletTitle,
            style: AppTextStyles.headingMedium(),
          ),
          SizedBox(height: 8.h),
          Text(
            'Credit balance and transaction history',
            style: AppTextStyles.bodySmall(color: AppColors.slate),
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
          Icon(Icons.person, size: 48.r, color: AppColors.slate),
          SizedBox(height: 16.h),
          Obx(() => Text(
                authCtrl.currentUser.value?.displayName ?? 'User Profile',
                style: AppTextStyles.headingMedium(),
              )),
          SizedBox(height: 4.h),
          Obx(() => Text(
                authCtrl.currentUser.value?.email ?? '',
                style: AppTextStyles.bodySmall(color: AppColors.slate),
              )),
        ],
      ),
    );
  }
}

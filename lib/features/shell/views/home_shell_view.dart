import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/unfocus_on_tap.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../generate/views/generation_studio_view.dart';
import '../../profile/views/profile_tab_view.dart';
import '../../wallet/views/wallet_debug_view.dart';
import '../../wallet/views/wallet_tab_view.dart';
import '../controllers/home_shell_controller.dart';
import '../widgets/credit_badge_widget.dart';
import 'gallery_tab_view.dart';

class HomeShellView extends StatelessWidget {
  const HomeShellView({super.key});

  static const List<Widget> _pages = [
    GenerationStudioView(),
    GalleryTabView(),
    WalletTabView(),
    ProfileTabView(),
  ];

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final shellCtrl = Get.put(HomeShellController());

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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.ember, AppColors.creditGoldIcon],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 16.r, color: Colors.white),
            ),
            SizedBox(width: 8.w),
            Text(
              AppStrings.appName,
              style: AppTextStyles.headingM(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          // Persistent Credit Badge Widget (Tapping opens Wallet)
          GestureDetector(
            onTap: () => shellCtrl.switchTab(2),
            child: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: const CreditBadge(),
            ),
          ),

          // Debug-only wallet inspector modal
          if (kDebugMode)
            IconButton(
              icon: Icon(Icons.bug_report_outlined,
                  color: AppColors.creditGoldIcon, size: 20.r),
              tooltip: AppStrings.walletDebugTitle,
              onPressed: () => WalletDebugView.show(context),
            ),

          IconButton(
            icon: Icon(Icons.logout_rounded,
                color: AppColors.textMuted, size: 20.r),
            tooltip: AppStrings.signOut,
            onPressed: () => authCtrl.signOut(),
          ),
          SizedBox(width: 4.w),
        ],
      ),

      // ── Tab Body Container ────────────────────────────────────────────────
      body: UnfocusOnTap(
        child: Obx(() => IndexedStack(
              index: shellCtrl.currentIndex.value,
              children: _pages,
            )),
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
        child: Obx(
          () => BottomNavigationBar(
            currentIndex: shellCtrl.currentIndex.value,
            onTap: (index) {
              HapticFeedback.selectionClick();
              shellCtrl.switchTab(index);
            },
            backgroundColor: AppColors.surfaceCard,
            selectedItemColor: AppColors.ember,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: AppTextStyles.caption(
              fontWeight: FontWeight.w700,
              color: AppColors.ember,
            ),
            unselectedLabelStyle: AppTextStyles.caption(
              color: AppColors.textMuted,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined, size: 20.r),
                activeIcon: Icon(Icons.auto_awesome_rounded,
                    size: 20.r, color: AppColors.ember),
                label: AppStrings.tabGenerate,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined, size: 20.r),
                activeIcon: Icon(Icons.grid_view_rounded,
                    size: 20.r, color: AppColors.ember),
                label: AppStrings.tabGallery,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined, size: 20.r),
                activeIcon: Icon(Icons.account_balance_wallet_rounded,
                    size: 20.r, color: AppColors.ember),
                label: AppStrings.tabWallet,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded, size: 20.r),
                activeIcon: Icon(Icons.person_rounded,
                    size: 20.r, color: AppColors.ember),
                label: AppStrings.tabProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../wallet/views/wallet_debug_view.dart';
import '../widgets/credit_badge_widget.dart';

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
      backgroundColor: AppColors.ink,

      // ── Persistent Header ──────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.ember,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 14, color: AppColors.bone),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: AppTextStyles.headingSmall(),
            ),
          ],
        ),
        actions: [
          // Persistent Credit Badge Widget (Task F1.2)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: CreditBadge(),
          ),

          // Debug-only wallet inspector modal (Task F1.2)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined,
                  color: AppColors.statusWarning, size: 20),
              tooltip: AppStrings.walletDebugTitle,
              onPressed: () => WalletDebugView.show(context),
            ),

          IconButton(
            icon: const Icon(Icons.logout_outlined,
                color: AppColors.slate, size: 20),
            tooltip: 'Sign Out',
            onPressed: () => authCtrl.signOut(),
          ),
          const SizedBox(width: 4),
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

// ── Tab Placeholders (Dev #2 / Phase 2 will populate) ───────────────────────

class _GenerateTabPlaceholder extends StatelessWidget {
  const _GenerateTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 48, color: AppColors.ember),
          const SizedBox(height: 16),
          Text(
            'Generation Studio Canvas',
            style: AppTextStyles.headingMedium(),
          ),
          const SizedBox(height: 8),
          Text(
            'Flutter Dev #2 — Editor Canvas & Preset Library',
            style: AppTextStyles.bodySmall(color: AppColors.slate),
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
          const Icon(Icons.grid_view, size: 48, color: AppColors.slate),
          const SizedBox(height: 16),
          Text(
            AppStrings.tabGallery,
            style: AppTextStyles.headingMedium(),
          ),
          const SizedBox(height: 8),
          Text(
            'Your generated images and 3D models',
            style: AppTextStyles.bodySmall(color: AppColors.slate),
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
          const Icon(Icons.account_balance_wallet,
              size: 48, color: AppColors.ember),
          const SizedBox(height: 16),
          Text(
            AppStrings.walletTitle,
            style: AppTextStyles.headingMedium(),
          ),
          const SizedBox(height: 8),
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
          const Icon(Icons.person, size: 48, color: AppColors.slate),
          const SizedBox(height: 16),
          Obx(() => Text(
                authCtrl.currentUser.value?.displayName ?? 'User Profile',
                style: AppTextStyles.headingMedium(),
              )),
          const SizedBox(height: 4),
          Obx(() => Text(
                authCtrl.currentUser.value?.email ?? '',
                style: AppTextStyles.bodySmall(color: AppColors.slate),
              )),
        ],
      ),
    );
  }
}

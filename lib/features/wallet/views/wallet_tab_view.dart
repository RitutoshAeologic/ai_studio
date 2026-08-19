import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/aperture_indicator.dart';
import '../controllers/wallet_controller.dart';
import 'wallet_debug_view.dart';

class WalletTabView extends StatelessWidget {
  const WalletTabView({super.key});

  void _showPurchaseConfirmation(BuildContext context, CreditPackage pack) {
    HapticFeedback.mediumImpact();
    final walletCtrl = Get.find<WalletController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: AppColors.borderSubtle, width: 1.r),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.slate.withAlpha(80),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.ember.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ember.withAlpha(80), width: 1.5.r),
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: AppColors.ember,
                  size: 40.r,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                pack.title,
                style: AppTextStyles.headingSmall(color: AppColors.bone),
              ),
              SizedBox(height: 6.h),
              Text(
                'Receive ${pack.totalCredits} AI Credits instantly',
                style: AppTextStyles.bodyMedium(color: AppColors.slate),
              ),
              if (pack.bonusCredits > 0) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withAlpha(30),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.statusSuccess.withAlpha(80)),
                  ),
                  child: Text(
                    '🎉 Includes +${pack.bonusCredits} Bonus Credits',
                    style: AppTextStyles.caption(
                      color: AppColors.statusSuccess,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 24.h),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ember,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      onPressed: walletCtrl.isTopUpLoading.value
                          ? null
                          : () async {
                              final success = await walletCtrl.topUpPackage(pack);
                              if (context.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? '✅ Added ${pack.totalCredits} credits to your wallet!'
                                          : 'Failed to complete top-up',
                                      style: AppTextStyles.bodyMedium(
                                          color: AppColors.bone),
                                    ),
                                    backgroundColor: success
                                        ? AppColors.statusSuccess
                                        : AppColors.statusError,
                                  ),
                                );
                              }
                            },
                      child: walletCtrl.isTopUpLoading.value
                          ? const ApertureIndicator(size: 24, color: Colors.white)
                          : Text(
                              'Add Credits for ${pack.priceFormatted}',
                              style: AppTextStyles.buttonLabel(color: Colors.white),
                            ),
                    ),
                  )),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.buttonLabel(color: AppColors.slate),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletCtrl = Get.find<WalletController>();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Wallet Balance Card ──────────────────────────────
                  _buildBalanceHeroCard(context, walletCtrl),
                  SizedBox(height: 20.h),

                  // ── Credit Rate Guide ──────────────────────────────────────
                  _buildCostBreakdownSection(),
                  SizedBox(height: 24.h),

                  // ── Top-Up Credit Packs ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top-Up Packages',
                        style: AppTextStyles.headingSmall(color: AppColors.bone),
                      ),
                      Text(
                        'Instant Delivery',
                        style: AppTextStyles.caption(color: AppColors.ember),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  ...WalletController.creditPackages.map(
                    (pack) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _buildCreditPackCard(context, pack),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // ── Transaction & Usage History ────────────────────────────
                  Text(
                    'Recent Activity',
                    style: AppTextStyles.headingSmall(color: AppColors.bone),
                  ),
                  SizedBox(height: 12.h),
                  _buildActivityLedger(userId),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeroCard(BuildContext context, WalletController ctrl) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A1C14),
            AppColors.surface,
            Color(0xFF1B191E),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.ember.withAlpha(120),
          width: 1.5.r,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ember.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.ember.withAlpha(40),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.ember.withAlpha(100), width: 1.r),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.ember,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Available Credits',
                    style: AppTextStyles.labelMedium(color: AppColors.slate),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceInput,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: AppColors.statusSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Active Tier',
                      style: AppTextStyles.caption(
                        color: AppColors.bone,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Obx(() {
            final balance = ctrl.wallet.value?.balance ?? 0;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$balance',
                  style: TextStyle(
                    fontSize: 38.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Credits',
                  style: AppTextStyles.headingSmall(color: AppColors.ember),
                ),
              ],
            );
          }),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Synced with your profile in real-time',
                style: AppTextStyles.caption(color: AppColors.slate),
              ),
              GestureDetector(
                onTap: () => WalletDebugView.show(context),
                child: Text(
                  'Debug Inspector',
                  style: AppTextStyles.caption(
                    color: AppColors.ember,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdownSection() {
    final costs = [
      {'title': 'Image Gen', 'cost': '10 cr', 'icon': Icons.image_rounded},
      {'title': 'Face Swap', 'cost': '30 cr', 'icon': Icons.face_retouching_natural_rounded},
      {'title': 'AI Video', 'cost': '50 cr', 'icon': Icons.videocam_rounded},
      {'title': '3D Mesh', 'cost': '20 cr', 'icon': Icons.view_in_ar_rounded},
    ];

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSubtle, width: 1.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credit Costs Per Generation',
            style: AppTextStyles.labelSmall(
              color: AppColors.bone,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: costs.map((c) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    children: [
                      Icon(c['icon'] as IconData,
                          size: 16.r, color: AppColors.ember),
                      SizedBox(height: 4.h),
                      Text(
                        c['title'] as String,
                        style: AppTextStyles.caption(color: AppColors.slate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        c['cost'] as String,
                        style: AppTextStyles.caption(
                          color: AppColors.bone,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditPackCard(BuildContext context, CreditPackage pack) {
    return GestureDetector(
      onTap: () => _showPurchaseConfirmation(context, pack),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: pack.isPopular ? AppColors.ember : AppColors.borderSubtle,
            width: pack.isPopular ? 1.5.r : 1.r,
          ),
          boxShadow: pack.isPopular
              ? [
                  BoxShadow(
                    color: AppColors.ember.withAlpha(30),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: pack.isPopular
                    ? AppColors.ember.withAlpha(30)
                    : AppColors.surfaceInput,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.stars_rounded,
                color: pack.isPopular ? AppColors.ember : AppColors.slate,
                size: 24.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pack.title,
                        style: AppTextStyles.labelMedium(
                          color: AppColors.bone,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (pack.isPopular) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.ember,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'POPULAR',
                            style: AppTextStyles.caption(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    pack.bonusCredits > 0
                        ? '${pack.credits} Credits + ${pack.bonusCredits} Bonus'
                        : '${pack.credits} Credits',
                    style: AppTextStyles.caption(color: AppColors.slate),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: pack.isPopular ? AppColors.ember : AppColors.surfaceInput,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                pack.priceFormatted,
                style: AppTextStyles.buttonLabel(
                  color: pack.isPopular ? Colors.white : AppColors.bone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLedger(String userId) {
    if (userId.isEmpty) return const SizedBox.shrink();

    final txStream = FirebaseFirestore.instance
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: txStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Center(
              child: Text(
                'No transactions recorded yet.',
                style: AppTextStyles.caption(color: AppColors.slate),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] as String? ?? 'Credit Activity';
            final amount = data['amount'] as int? ?? 0;
            final type = data['type'] as String? ?? 'top_up';
            final isCredit = type == 'top_up' || amount > 0;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(
                    isCredit
                        ? Icons.add_circle_outline_rounded
                        : Icons.remove_circle_outline_rounded,
                    color: isCredit
                        ? AppColors.statusSuccess
                        : AppColors.statusError,
                    size: 20.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.labelSmall(color: AppColors.bone),
                    ),
                  ),
                  Text(
                    isCredit ? '+$amount cr' : '$amount cr',
                    style: AppTextStyles.labelSmall(
                      color: isCredit
                          ? AppColors.statusSuccess
                          : AppColors.statusError,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

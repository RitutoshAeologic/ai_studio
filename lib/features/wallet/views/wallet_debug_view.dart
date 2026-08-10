import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/repositories/wallet_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/wallet_controller.dart';

/// Debug-only wallet inspector modal — guarded by [kDebugMode] at call site.
/// Responsive layout using ScreenUtil, AppStrings, AppColors, and AppTextStyles per ui_ux.md.
class WalletDebugView extends StatelessWidget {
  const WalletDebugView({super.key});

  static void show(BuildContext context) {
    assert(kDebugMode, 'WalletDebugView must only be shown in debug builds');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => const WalletDebugView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletCtrl = Get.find<WalletController>();
    final authCtrl = Get.find<AuthController>();
    final walletRepo = Get.find<WalletRepository>();
    final isAdding = false.obs;
    final addResult = ''.obs;

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report_outlined,
                color: AppColors.creditGoldIcon,
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Text(
                AppStrings.walletDebugTitle,
                style: AppTextStyles.headingM.copyWith(
                  color: AppColors.creditGoldTitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Raw wallet document inspector
          Text(
            AppStrings.rawWalletDoc,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          SizedBox(height: 8.h),
          Obx(() {
            final w = walletCtrl.wallet.value;
            if (w == null) {
              return Text(
                'null',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              );
            }
            return Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.borderSubtle, width: 1.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('userId', w.userId),
                  _field('balance', '${w.balance}'),
                  _field('updatedAt', w.updatedAt.toIso8601String()),
                ],
              ),
            );
          }),

          SizedBox(height: 20.h),

          // Add test credits action
          Obx(() => ElevatedButton.icon(
                onPressed: isAdding.value
                    ? null
                    : () async {
                        final uid = authCtrl.currentUser.value?.uid;
                        if (uid == null) return;
                        isAdding.value = true;
                        addResult.value = '';
                        final result =
                            await walletRepo.debugAddCredits(uid, 100);
                        isAdding.value = false;
                        result.fold(
                          (_) => addResult.value =
                              '✓ ${AppStrings.creditsAdded}',
                          (f) => addResult.value = '✗ ${f.message}',
                        );
                      },
                icon: isAdding.value
                    ? SizedBox(
                        width: 14.r,
                        height: 14.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5.r,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.add_rounded, size: 16.r, color: Colors.white),
                label: Text(
                  isAdding.value
                      ? AppStrings.addingCredits
                      : AppStrings.addTestCredits,
                  style: AppTextStyles.buttonLabel.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAction,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              )),

          Obx(() => addResult.value.isNotEmpty
              ? Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Text(
                    addResult.value,
                    style: AppTextStyles.caption.copyWith(
                      color: addResult.value.startsWith('✓')
                          ? AppColors.creditGoldTitle
                          : AppColors.errorIndicator,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox.shrink()),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _field(String key, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$key: ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

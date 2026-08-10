import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../wallet/controllers/wallet_controller.dart';

/// Persistent header credit badge displaying live wallet balance with digit animation.
/// Responsive layout using AppColors, AppTextStyles, and ScreenUtil per ui_ux.md.
class CreditBadge extends StatelessWidget {
  const CreditBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final walletCtrl = Get.find<WalletController>();

    return Obx(() {
      final balance = walletCtrl.wallet.value?.balance;
      final isLoading = walletCtrl.isLoading.value;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColors.creditGoldBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.creditGoldBorder, width: 1.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              color: AppColors.creditGoldIcon,
              size: 14.r,
            ),
            SizedBox(width: 5.w),
            if (isLoading)
              SizedBox(
                width: 14.r,
                height: 14.r,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5.r,
                  color: AppColors.creditGoldIcon,
                ),
              )
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  key: ValueKey(balance),
                  '${balance ?? 0}',
                  style: AppTextStyles.buttonLabel(
                    color: AppColors.creditGoldTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

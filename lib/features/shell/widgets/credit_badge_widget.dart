import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../wallet/controllers/wallet_controller.dart';

/// Persistent header credit badge.
///
/// Shows live balance in JetBrains Mono ember-colored text.
/// Digit-roll animation fires when balance changes.
class CreditBadge extends StatelessWidget {
  const CreditBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final walletCtrl = Get.find<WalletController>();

    return Obx(() {
      final balance = walletCtrl.wallet.value?.balance;
      final isLoading = walletCtrl.isLoading.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.emberSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ember.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.ember, size: 14),
            const SizedBox(width: 5),
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.ember,
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
                  style: AppTextStyles.creditCounter(fontSize: 14),
                ),
              ),
          ],
        ),
      );
    });
  }
}

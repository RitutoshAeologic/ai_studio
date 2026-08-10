import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/repositories/wallet_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/wallet_controller.dart';

/// Debug-only wallet inspector modal — never shown in production builds.
/// guarded by [kDebugMode] at the call site (HomeShellView debug menu).
class WalletDebugView extends StatelessWidget {
  const WalletDebugView({super.key});

  static void show(BuildContext context) {
    assert(kDebugMode, 'WalletDebugView must only be shown in debug builds');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined,
                  color: AppColors.statusWarning, size: 18),
              const SizedBox(width: 8),
              Text(AppStrings.walletDebugTitle,
                  style: AppTextStyles.headingSmall(
                      color: AppColors.statusWarning)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Raw wallet doc ────────────────────────────────────────────────
          Text(AppStrings.rawWalletDoc,
              style: AppTextStyles.labelMedium(color: AppColors.slate)),
          const SizedBox(height: 8),
          Obx(() {
            final w = walletCtrl.wallet.value;
            if (w == null) {
              return Text('null',
                  style: AppTextStyles.dataLabel(color: AppColors.slate));
            }
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                borderRadius: BorderRadius.circular(8),
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

          const SizedBox(height: 20),

          // ── Add credits ───────────────────────────────────────────────────
          Obx(() => ElevatedButton.icon(
                onPressed: isAdding.value
                    ? null
                    : () async {
                        final uid =
                            authCtrl.currentUser.value?.uid;
                        if (uid == null) return;
                        isAdding.value = true;
                        addResult.value = '';
                        final result = await walletRepo
                            .debugAddCredits(uid, 100);
                        isAdding.value = false;
                        result.fold(
                          (_) => addResult.value =
                              '✓ ${AppStrings.creditsAdded}',
                          (f) => addResult.value = '✗ ${f.message}',
                        );
                      },
                icon: isAdding.value
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.bone),
                      )
                    : const Icon(Icons.add, size: 16, color: AppColors.bone),
                label: Text(
                  isAdding.value
                      ? AppStrings.addingCredits
                      : AppStrings.addTestCredits,
                  style: AppTextStyles.buttonLabel(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusWarning,
                  foregroundColor: AppColors.bone,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )),

          Obx(() => addResult.value.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(addResult.value,
                      style: AppTextStyles.dataLabel(
                          color: addResult.value.startsWith('✓')
                              ? AppColors.statusSuccess
                              : AppColors.statusError)),
                )
              : const SizedBox.shrink()),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _field(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$key: ',
              style: AppTextStyles.dataLabel(color: AppColors.slate)),
          Expanded(
            child: Text(value,
                style: AppTextStyles.dataLabel(color: AppColors.bone)),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:get/get.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/wallet_entity.dart';
import '../../../domain/repositories/wallet_repository.dart';

/// Reactive credit wallet controller.
///
/// Binds a Firestore real-time snapshot to [wallet] — no polling,
/// no manual refresh required anywhere in the UI layer.
class WalletController extends GetxController {
  final WalletRepository _walletRepository;

  WalletController({WalletRepository? walletRepository})
      : _walletRepository =
            walletRepository ?? Get.find<WalletRepository>();

  final Rxn<WalletEntity> wallet = Rxn<WalletEntity>();
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription? _subscription;

  /// Call once after auth — pass the authenticated userId.
  void startWatching(String userId) {
    _subscription?.cancel();
    isLoading.value = true;
    errorMessage.value = '';

    _subscription =
        _walletRepository.watchWallet(userId).listen((result) {
      isLoading.value = false;
      result.fold(
        (entity) {
          wallet.value = entity;
          Logger.d('Wallet balance updated: ${entity.balance}');
        },
        (failure) {
          errorMessage.value = ErrorHandler.map(failure);
          Logger.w('Wallet stream error: ${failure.message}');
        },
      );
    });
  }

  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
    wallet.value = null;
    isLoading.value = true;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

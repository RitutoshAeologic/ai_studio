import 'dart:async';
import 'package:ai_studio/core/error/error_handler.dart';
import 'package:ai_studio/core/utils/logger.dart';
import 'package:ai_studio/domain/entities/wallet_entity.dart';
import 'package:ai_studio/domain/repositories/wallet_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CreditPackage {
  final String id;
  final String title;
  final int credits;
  final int bonusCredits;
  final String priceFormatted;
  final bool isPopular;
  final String tag;

  const CreditPackage({
    required this.id,
    required this.title,
    required this.credits,
    this.bonusCredits = 0,
    required this.priceFormatted,
    this.isPopular = false,
    this.tag = '',
  });

  int get totalCredits => credits + bonusCredits;
}

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
  final RxBool isTopUpLoading = false.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription? _subscription;

  static const List<CreditPackage> creditPackages = [
    CreditPackage(
      id: 'pack_starter',
      title: 'Starter Pack',
      credits: 100,
      bonusCredits: 0,
      priceFormatted: '\$4.99',
      tag: 'Basic',
    ),
    CreditPackage(
      id: 'pack_creator',
      title: 'Pro Creator',
      credits: 500,
      bonusCredits: 50,
      priceFormatted: '\$19.99',
      isPopular: true,
      tag: 'Best Value',
    ),
    CreditPackage(
      id: 'pack_studio',
      title: 'Studio Ultimate',
      credits: 1500,
      bonusCredits: 250,
      priceFormatted: '\$49.99',
      tag: 'Maximum Savings',
    ),
  ];

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

  /// Tops up credits for the current user.
  Future<bool> topUpPackage(CreditPackage package) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      errorMessage.value = 'User not authenticated';
      return false;
    }

    try {
      isTopUpLoading.value = true;
      final result = await _walletRepository.topUpCredits(
        uid,
        package.totalCredits,
        '${package.title} (+${package.totalCredits} credits)',
      );

      return result.fold(
        (_) => true,
        (failure) {
          errorMessage.value = failure.message;
          return false;
        },
      );
    } finally {
      isTopUpLoading.value = false;
    }
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

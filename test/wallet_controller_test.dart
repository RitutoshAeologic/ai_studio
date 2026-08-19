import 'dart:async';
import 'package:ai_studio/core/error/failure.dart';
import 'package:ai_studio/core/error/result.dart';
import 'package:ai_studio/domain/entities/wallet_entity.dart';
import 'package:ai_studio/domain/repositories/wallet_repository.dart';
import 'package:ai_studio/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

// ── Stub implementation of WalletRepository ──────────────────────────────────

class _StubWalletRepository implements WalletRepository {
  final StreamController<Result<WalletEntity, Failure>> _controller =
      StreamController<Result<WalletEntity, Failure>>.broadcast();

  Stream<Result<WalletEntity, Failure>> get events => _controller.stream;

  void emit(WalletEntity entity) =>
      _controller.add(Success(entity));

  void emitFailure(Failure failure) =>
      _controller.add(Error(failure));

  @override
  Stream<Result<WalletEntity, Failure>> watchWallet(String userId) =>
      _controller.stream;

  @override
  Future<Result<void, Failure>> topUpCredits(
      String userId, int amount, String packName) async =>
      const Success(null);

  @override
  Future<Result<void, Failure>> debugAddCredits(String userId, int amount) async =>
      const Success(null);

  void dispose() => _controller.close();
}

WalletEntity _wallet({int balance = 100}) => WalletEntity(
      userId: 'u1',
      balance: balance,
      updatedAt: DateTime(2026, 1, 1),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _StubWalletRepository repo;
  late WalletController ctrl;

  setUp(() {
    Get.reset();
    repo = _StubWalletRepository();
    ctrl = WalletController(walletRepository: repo);
  });

  tearDown(() {
    ctrl.onClose();
    repo.dispose();
  });

  group('WalletController', () {
    test('startWatching — updates wallet.value when stream emits entity', () async {
      ctrl.startWatching('u1');
      repo.emit(_wallet(balance: 100));

      // Allow microtask to propagate stream event
      await Future.microtask(() {});

      expect(ctrl.wallet.value, isNotNull);
      expect(ctrl.wallet.value!.balance, 100);
      expect(ctrl.isLoading.value, false);
      expect(ctrl.errorMessage.value, '');
    });

    test('startWatching — sets errorMessage when stream emits failure', () async {
      ctrl.startWatching('u1');
      repo.emitFailure(const NetworkFailure('Firestore unavailable'));

      await Future.microtask(() {});

      expect(ctrl.errorMessage.value, isNotEmpty);
      expect(ctrl.isLoading.value, false);
    });

    test('stopWatching — resets wallet to null and isLoading to true', () async {
      ctrl.startWatching('u1');
      repo.emit(_wallet());
      await Future.microtask(() {});

      ctrl.stopWatching();

      expect(ctrl.wallet.value, isNull);
      expect(ctrl.isLoading.value, true);
    });

    test('balance update — reflects latest balance from stream', () async {
      ctrl.startWatching('u1');

      repo.emit(_wallet(balance: 100));
      await Future.microtask(() {});
      expect(ctrl.wallet.value!.balance, 100);

      repo.emit(_wallet(balance: 90));
      await Future.microtask(() {});
      expect(ctrl.wallet.value!.balance, 90);
    });
  });
}

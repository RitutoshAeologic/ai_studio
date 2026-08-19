import 'package:ai_studio/core/error/failure.dart';
import 'package:ai_studio/core/error/result.dart';
import 'package:ai_studio/domain/entities/wallet_entity.dart';

/// Abstract domain contract for the reactive credit wallet.
abstract class WalletRepository {
  /// Listens to real-time Firestore updates on wallets/{userId}.
  /// Emits Result.success on every valid snapshot, Result.error on failures.
  Stream<Result<WalletEntity, Failure>> watchWallet(String userId);

  /// Tops up credits for a user and logs the transaction.
  Future<Result<void, Failure>> topUpCredits(String userId, int amount, String packName);

  /// [Debug only] Adds `amount` credits directly to wallets/{userId} in Firestore.
  Future<Result<void, Failure>> debugAddCredits(String userId, int amount);
}

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/wallet_entity.dart';

/// Abstract domain contract for the reactive credit wallet.
abstract class WalletRepository {
  /// Listens to real-time Firestore updates on wallets/{userId}.
  /// Emits Result.success on every valid snapshot, Result.error on failures.
  Stream<Result<WalletEntity, Failure>> watchWallet(String userId);

  /// [Debug only] Adds `amount` credits directly to wallets/{userId} in Firestore.
  /// Must never be called in production builds — guarded by kDebugMode at the call site.
  Future<Result<void, Failure>> debugAddCredits(String userId, int amount);
}

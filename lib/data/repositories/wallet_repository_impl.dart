import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../models/wallet_model.dart';

/// Concrete wallet repository — listens to wallets/{userId} Firestore snapshots.
class WalletRepositoryImpl implements WalletRepository {
  final FirebaseFirestore? _providedFirestore;

  WalletRepositoryImpl({FirebaseFirestore? firestore})
      : _providedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  @override
  Stream<Result<WalletEntity, Failure>> watchWallet(String userId) {
    try {
      return _firestore
          .collection('wallets')
          .doc(userId)
          .snapshots()
          .map((snap) {
        if (!snap.exists) {
          Logger.w('Wallet document does not exist for user: $userId');
          return const Error(
              UnknownFailure('Wallet document not found'));
        }
        final model = WalletModel.fromFirestore(snap);
        Logger.d('Wallet updated: balance=${model.balance}');
        return Success(model);
      });
    } catch (e, stackTrace) {
      Logger.e('Failed to attach wallet listener', e, stackTrace);
      return Stream.value(const Error(UnknownFailure('Failed to watch wallet')));
    }
  }

  @override
  Future<Result<void, Failure>> debugAddCredits(
      String userId, int amount) async {
    try {
      await _firestore.collection('wallets').doc(userId).update({
        'balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.i('[DEBUG] Added $amount credits to wallet $userId');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.e('[DEBUG] Failed to add credits', e, stackTrace);
      return const Error(UnknownFailure('Failed to add credits'));
    }
  }
}

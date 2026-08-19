import 'package:ai_studio/data/models/wallet_model.dart';
import 'package:ai_studio/domain/entities/wallet_entity.dart';
import 'package:ai_studio/domain/repositories/wallet_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_studio/core/error/failure.dart';
import 'package:ai_studio/core/error/result.dart';
import 'package:ai_studio/core/utils/logger.dart';

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
          .asyncMap((snap) async {
        if (!snap.exists) {
          Logger.i('Wallet document missing for user $userId — auto-initializing wallet');
          try {
            await _firestore.collection('wallets').doc(userId).set({
              'balance': 100,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            await _firestore.collection('users').doc(userId).set({
              'creditBalance': 100,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (e) {
            Logger.w('Could not auto-create wallet doc: $e');
          }

          return Success(WalletModel(
            userId: userId,
            balance: 100,
            updatedAt: DateTime.now(),
          ));
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
  Future<Result<void, Failure>> topUpCredits(
      String userId, int amount, String packName) async {
    try {
      final batch = _firestore.batch();
      final walletRef = _firestore.collection('wallets').doc(userId);
      final userRef = _firestore.collection('users').doc(userId);
      final txRef = walletRef.collection('transactions').doc();

      batch.set(walletRef, {
        'balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(userRef, {
        'creditBalance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(txRef, {
        'id': txRef.id,
        'type': 'top_up',
        'title': packName,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      Logger.i('Successfully topped up $amount credits for $userId ($packName)');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.e('Failed to top up credits', e, stackTrace);
      return Error(UnknownFailure('Failed to top up credits: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> debugAddCredits(
      String userId, int amount) async {
    return topUpCredits(userId, amount, 'Developer Debug Credit Top-Up');
  }
}

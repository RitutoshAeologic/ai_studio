import 'package:ai_studio/domain/entities/wallet_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for wallets/{userId} Firestore document.
/// Handles conversion between Firestore snapshots and domain WalletEntity.
class WalletModel extends WalletEntity {
  const WalletModel({
    required super.userId,
    required super.balance,
    required super.updatedAt,
  });

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final updatedAtRaw = data['updatedAt'];
    DateTime updatedAt;
    if (updatedAtRaw is Timestamp) {
      updatedAt = updatedAtRaw.toDate();
    } else {
      updatedAt = DateTime.now();
    }
    return WalletModel(
      userId: doc.id,
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'balance': balance,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

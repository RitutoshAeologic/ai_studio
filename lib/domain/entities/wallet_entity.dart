/// Pure Dart domain entity representing the user's credit wallet.
class WalletEntity {
  final String userId;
  final int balance;
  final DateTime updatedAt;

  const WalletEntity({
    required this.userId,
    required this.balance,
    required this.updatedAt,
  });

  WalletEntity copyWith({
    String? userId,
    int? balance,
    DateTime? updatedAt,
  }) {
    return WalletEntity(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'WalletEntity(userId: $userId, balance: $balance, updatedAt: $updatedAt)';
}

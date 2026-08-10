/// Pure Dart domain entity representing an authenticated AI Studio user.
class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int creditBalance;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.creditBalance,
    required this.createdAt,
  });

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    int? creditBalance,
    DateTime? createdAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      creditBalance: creditBalance ?? this.creditBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

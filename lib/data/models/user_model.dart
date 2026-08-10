import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/user_entity.dart';

/// Data model representing user profile matching Firestore schema `users/{uid}`.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    required super.creditBalance,
    required super.createdAt,
  });

  /// Factory creating UserModel from Firebase Auth User and optional Firestore data.
  factory UserModel.fromFirebaseUser(
    fb.User firebaseUser, {
    int creditBalance = 100,
    Map<String, dynamic>? firestoreData,
  }) {
    final DateTime createdDate = firestoreData?['createdAt'] != null
        ? (firestoreData!['createdAt'] as Timestamp).toDate()
        : (firebaseUser.metadata.creationTime ?? DateTime.now());

    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firestoreData?['displayName'] as String? ??
          (firebaseUser.displayName?.isNotEmpty == true
              ? firebaseUser.displayName!
              : 'User'),
      photoUrl: firebaseUser.photoURL,
      creditBalance: firestoreData?['creditBalance'] as int? ?? creditBalance,
      createdAt: createdDate,
    );
  }

  /// Factory creating UserModel from Firestore Document Snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'User',
      photoUrl: data['photoUrl'] as String?,
      creditBalance: data['creditBalance'] as int? ?? 100,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Converts UserModel to Firestore JSON map for initial user creation.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'creditBalance': creditBalance,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

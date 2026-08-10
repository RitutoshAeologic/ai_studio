import 'package:ai_studio/core/constants/app_strings.dart';
import 'package:ai_studio/core/error/failure.dart';
import 'package:ai_studio/core/error/result.dart';
import 'package:ai_studio/core/utils/logger.dart';
import 'package:ai_studio/data/models/user_model.dart';
import 'package:ai_studio/domain/entities/user_entity.dart';
import 'package:ai_studio/domain/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Concrete implementation of AuthRepository connecting Firebase Auth & Cloud Firestore.
class AuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth? _providedFirebaseAuth;
  final FirebaseFirestore? _providedFirestore;

  AuthRepositoryImpl({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _providedFirebaseAuth = firebaseAuth,
        _providedFirestore = firestore;

  fb.FirebaseAuth get _firebaseAuth =>
      _providedFirebaseAuth ?? fb.FirebaseAuth.instance;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  @override
  UserEntity? get currentUser {
    try {
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser == null) return null;
      return UserModel.fromFirebaseUser(fbUser);
    } catch (_) {
      // Firebase not initialized in headless unit test environment
      return null;
    }
  }

  @override
  Stream<UserEntity?> watchAuthState() {
    try {
      return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
        if (fbUser == null) return null;
        try {
          final doc =
              await _firestore.collection('users').doc(fbUser.uid).get();
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          }
          return UserModel.fromFirebaseUser(fbUser);
        } catch (e, stackTrace) {
          Logger.e('Error fetching user document from Firestore', e, stackTrace);
          return UserModel.fromFirebaseUser(fbUser);
        }
      });
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  Future<Result<UserEntity, AuthFailure>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      Logger.i('Attempting Firebase email sign-in for: $email');
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        return const Error(AuthFailure(AppStrings.invalidEmailOrPassword));
      }

      UserModel userModel;
      try {
        // Attempt to fetch or sync user doc in Firestore (non-fatal if Firestore database doesn't exist yet)
        final userDocRef = _firestore.collection('users').doc(fbUser.uid);
        final docSnap = await userDocRef.get().timeout(const Duration(seconds: 4));

        if (docSnap.exists) {
          userModel = UserModel.fromFirestore(docSnap);
        } else {
          userModel = UserModel.fromFirebaseUser(fbUser);
          await userDocRef
              .set(userModel.toFirestore(), SetOptions(merge: true))
              .timeout(const Duration(seconds: 4));
        }
      } catch (e, stackTrace) {
        Logger.w('Firestore sync skipped or unavailable: $e', e, stackTrace);
        // Fall back gracefully to Firebase Auth user metadata
        userModel = UserModel.fromFirebaseUser(fbUser);
      }

      Logger.i('Successfully signed in user: ${userModel.uid}');
      return Success(userModel);
    } on fb.FirebaseAuthException catch (e, stackTrace) {
      Logger.e('FirebaseAuthException during sign-in: ${e.code}', e, stackTrace);
      return Error(AuthFailure(_mapFirebaseAuthError(e.code)));
    } catch (e, stackTrace) {
      Logger.e('Unexpected error during sign-in', e, stackTrace);
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity, AuthFailure>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      Logger.i('Attempting Firebase email sign-up for: $email');
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        return const Error(AuthFailure(AppStrings.signUpFailedEmailInUse));
      }

      // Update Firebase Auth Display Name
      await fbUser.updateDisplayName(name);

      final userModel = UserModel(
        uid: fbUser.uid,
        email: email,
        displayName: name,
        photoUrl: fbUser.photoURL,
        creditBalance: 100, // 100 Free Credits on Sign Up
        createdAt: DateTime.now(),
      );

      try {
        // Attempt to create user & wallet docs in Firestore with a timeout
        await _firestore
            .collection('users')
            .doc(fbUser.uid)
            .set(userModel.toFirestore())
            .timeout(const Duration(seconds: 4));

        await _firestore
            .collection('wallets')
            .doc(fbUser.uid)
            .set({'balance': 100, 'updatedAt': FieldValue.serverTimestamp()})
            .timeout(const Duration(seconds: 4));
      } catch (e, stackTrace) {
        Logger.w('Firestore user/wallet creation skipped or database unavailable: $e', e, stackTrace);
      }

      Logger.i('Successfully created user account: ${userModel.uid}');
      return Success(userModel);
    } on fb.FirebaseAuthException catch (e, stackTrace) {
      Logger.e('FirebaseAuthException during sign-up: ${e.code}', e, stackTrace);
      return Error(AuthFailure(_mapFirebaseAuthError(e.code)));
    } catch (e, stackTrace) {
      Logger.e('Unexpected error during sign-up', e, stackTrace);
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, AuthFailure>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      Logger.i('Successfully signed out');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.e('Error signing out', e, stackTrace);
      return Error(AuthFailure(e.toString()));
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.invalidEmailOrPassword;
      case 'email-already-in-use':
        return AppStrings.signUpFailedEmailInUse;
      case 'invalid-email':
        return AppStrings.emailInvalidError;
      case 'weak-password':
        return AppStrings.passwordLengthError;
      default:
        return AppStrings.unknownError;
    }
  }
}

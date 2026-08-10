import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../core/constants/app_strings.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

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

      // Fetch or sync user doc in Firestore
      final userDocRef = _firestore.collection('users').doc(fbUser.uid);
      final docSnap = await userDocRef.get();

      UserModel userModel;
      if (docSnap.exists) {
        userModel = UserModel.fromFirestore(docSnap);
      } else {
        userModel = UserModel.fromFirebaseUser(fbUser);
        await userDocRef.set(userModel.toFirestore(), SetOptions(merge: true));
      }

      Logger.i('Successfully signed in user: ${userModel.uid}');
      return Success(userModel);
    } on fb.FirebaseAuthException catch (e, stackTrace) {
      Logger.e('FirebaseAuthException during sign-in: ${e.code}', e, stackTrace);
      return Error(AuthFailure(_mapFirebaseAuthError(e.code)));
    } catch (e, stackTrace) {
      Logger.e('Unexpected error during sign-in', e, stackTrace);
      return const Error(AuthFailure(AppStrings.unknownError));
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

      // Create user document in Firestore `users/{uid}`
      await _firestore
          .collection('users')
          .doc(fbUser.uid)
          .set(userModel.toFirestore());

      // Create wallet document in Firestore `wallets/{uid}`
      await _firestore
          .collection('wallets')
          .doc(fbUser.uid)
          .set({'balance': 100, 'updatedAt': FieldValue.serverTimestamp()});

      Logger.i('Successfully created user account & wallet: ${userModel.uid}');
      return Success(userModel);
    } on fb.FirebaseAuthException catch (e, stackTrace) {
      Logger.e('FirebaseAuthException during sign-up: ${e.code}', e, stackTrace);
      return Error(AuthFailure(_mapFirebaseAuthError(e.code)));
    } catch (e, stackTrace) {
      Logger.e('Unexpected error during sign-up', e, stackTrace);
      return const Error(AuthFailure(AppStrings.unknownError));
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
      return const Error(AuthFailure(AppStrings.unknownError));
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

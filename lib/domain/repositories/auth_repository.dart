
import 'package:ai_studio/core/error/failure.dart';
import 'package:ai_studio/core/error/result.dart';
import 'package:ai_studio/domain/entities/user_entity.dart';

/// Abstract domain contract for authentication and user session management.
abstract class AuthRepository {
  /// Sign in with Firebase email and password.
  Future<Result<UserEntity, AuthFailure>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Register a new account with Firebase email and password, setting display name and initial credits.
  Future<Result<UserEntity, AuthFailure>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Sign out current Firebase user.
  Future<Result<void, AuthFailure>> signOut();

  /// Watch real-time Firebase Auth user state changes.
  Stream<UserEntity?> watchAuthState();

  /// Currently signed in user entity, or null.
  UserEntity? get currentUser;
}

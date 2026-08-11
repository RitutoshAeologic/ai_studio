import 'dart:async';
import 'package:ai_studio/app/routes/app_routes.dart';
import 'package:ai_studio/core/constants/app_strings.dart';
import 'package:ai_studio/core/error/error_handler.dart';
import 'package:ai_studio/core/services/fcm_service.dart';
import 'package:ai_studio/core/utils/logger.dart';
import 'package:ai_studio/domain/entities/user_entity.dart';
import 'package:ai_studio/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';



/// Controller for authentication flow.
/// Coordinates Firebase Auth repository operations and real-time form validation state management.
class AuthController extends GetxController {
  final AuthRepository _authRepository;

  AuthController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? Get.find<AuthRepository>();

  // TextEditingControllers
  final loginEmailCtrl = TextEditingController();
  final loginPasswordCtrl = TextEditingController();
  final signupNameCtrl = TextEditingController();
  final signupEmailCtrl = TextEditingController();
  final signupPasswordCtrl = TextEditingController();
  final signupConfirmPasswordCtrl = TextEditingController();
  final forgotPasswordEmailCtrl = TextEditingController();

  // Reactive Auth State
  final RxBool isLoginLoading = false.obs;
  final RxBool isSignupLoading = false.obs;
  final RxBool isForgotPasswordLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<UserEntity> currentUser = Rxn<UserEntity>();

  // Real-time Reactive Field Validation Errors
  final RxnString loginEmailError = RxnString();
  final RxnString loginPasswordError = RxnString();
  final RxnString signupNameError = RxnString();
  final RxnString signupEmailError = RxnString();
  final RxnString signupPasswordError = RxnString();
  final RxnString signupConfirmPasswordError = RxnString();
  final RxnString forgotPasswordEmailError = RxnString();

  // Forgot Password State
  final RxBool resetEmailSent = false.obs;
  final RxString resetEmailAddress = ''.obs;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _authRepository.currentUser;
    currentUser.bindStream(_authRepository.watchAuthState());
  }

  void clearError() {
    errorMessage.value = '';
  }

  // ─── Real-Time Validators ───────────────────────────────────────────
  String? validateLoginEmail(String? val) {
    if (val == null || val.trim().isEmpty) {
      loginEmailError.value = AppStrings.emailRequiredError;
    } else if (!GetUtils.isEmail(val.trim())) {
      loginEmailError.value = AppStrings.emailInvalidError;
    } else {
      loginEmailError.value = null;
    }
    return loginEmailError.value;
  }

  String? validateLoginPassword(String? val) {
    if (val == null || val.isEmpty) {
      loginPasswordError.value = AppStrings.passwordRequiredError;
    } else if (val.length < 6) {
      loginPasswordError.value = AppStrings.passwordLengthError;
    } else {
      loginPasswordError.value = null;
    }
    return loginPasswordError.value;
  }

  String? validateSignupName(String? val) {
    if (val == null || val.trim().isEmpty) {
      signupNameError.value = AppStrings.nameRequiredError;
    } else {
      signupNameError.value = null;
    }
    return signupNameError.value;
  }

  String? validateSignupEmail(String? val) {
    if (val == null || val.trim().isEmpty) {
      signupEmailError.value = AppStrings.emailRequiredError;
    } else if (!GetUtils.isEmail(val.trim())) {
      signupEmailError.value = AppStrings.emailInvalidError;
    } else {
      signupEmailError.value = null;
    }
    return signupEmailError.value;
  }

  String? validateSignupPassword(String? val) {
    if (val == null || val.isEmpty) {
      signupPasswordError.value = AppStrings.passwordRequiredError;
    } else if (val.length < 8) {
      signupPasswordError.value = AppStrings.passwordLengthError;
    } else {
      signupPasswordError.value = null;
    }
    return signupPasswordError.value;
  }

  String? validateSignupConfirmPassword(String? val, String password) {
    if (val == null || val.isEmpty) {
      signupConfirmPasswordError.value = AppStrings.confirmPasswordRequiredError;
    } else if (val != password) {
      signupConfirmPasswordError.value = AppStrings.passwordsDoNotMatchError;
    } else {
      signupConfirmPasswordError.value = null;
    }
    return signupConfirmPasswordError.value;
  }

  bool validateLoginForm(String email, String password) {
    final eErr = validateLoginEmail(email);
    final pErr = validateLoginPassword(password);
    return eErr == null && pErr == null;
  }

  bool validateSignupForm(
      String name, String email, String password, String confirmPassword) {
    final nErr = validateSignupName(name);
    final eErr = validateSignupEmail(email);
    final pErr = validateSignupPassword(password);
    final cErr = validateSignupConfirmPassword(confirmPassword, password);
    return nErr == null && eErr == null && pErr == null && cErr == null;
  }

  String? validateForgotPasswordEmail(String? val) {
    if (val == null || val.trim().isEmpty) {
      forgotPasswordEmailError.value = AppStrings.emailRequiredError;
    } else if (!GetUtils.isEmail(val.trim())) {
      forgotPasswordEmailError.value = AppStrings.emailInvalidError;
    } else {
      forgotPasswordEmailError.value = null;
    }
    return forgotPasswordEmailError.value;
  }

  // ─── Firebase Auth Actions ────────────────────────────────────────────
  Future<void> signInWithEmail(String email, String password) async {
    if (!validateLoginForm(email, password)) return;

    isLoginLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _authRepository.signInWithEmail(
        email: email.trim(),
        password: password,
      );

      result.fold(
        (user) {
          Logger.i('User signed in successfully: ${user.uid}');
          currentUser.value = user;
          // Initialize FCM after successful sign-in (fire-and-forget).
          unawaited(FcmService.instance.initialize(uid: user.uid));
          unawaited(Get.offAllNamed(AppRoutes.homeShell));
        },
        (failure) {
          Logger.w('Sign in failed: ${failure.message}');
          errorMessage.value = ErrorHandler.map(failure);
        },
      );
    } catch (e, stackTrace) {
      Logger.e('Unhandled error in signInWithEmail', e, stackTrace);
      errorMessage.value = AppStrings.unknownError;
    } finally {
      isLoginLoading.value = false;
    }
  }

  Future<void> signUpWithEmail(
      String name, String email, String password, String confirmPassword) async {
    if (!validateSignupForm(name, email, password, confirmPassword)) return;

    isSignupLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _authRepository.signUpWithEmail(
        name: name.trim(),
        email: email.trim(),
        password: password,
      );

      result.fold(
        (user) {
          Logger.i('User registered successfully: ${user.uid}');
          currentUser.value = user;
          // Initialize FCM after successful registration (fire-and-forget).
          unawaited(FcmService.instance.initialize(uid: user.uid));
          unawaited(Get.offAllNamed(AppRoutes.homeShell));
        },
        (failure) {
          Logger.w('Sign up failed: ${failure.message}');
          errorMessage.value = ErrorHandler.map(failure);
        },
      );
    } catch (e, stackTrace) {
      Logger.e('Unhandled error in signUpWithEmail', e, stackTrace);
      errorMessage.value = AppStrings.unknownError;
    } finally {
      isSignupLoading.value = false;
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    if (validateForgotPasswordEmail(email) != null) return;

    isForgotPasswordLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _authRepository.sendPasswordResetEmail(
        email: email.trim(),
      );

      result.fold(
        (_) {
          Logger.i('Password reset email dispatched for: $email');
          resetEmailAddress.value = email.trim();
          resetEmailSent.value = true;
        },
        (failure) {
          Logger.w('Password reset failed: ${failure.message}');
          errorMessage.value = ErrorHandler.map(failure);
        },
      );
    } catch (e, stackTrace) {
      Logger.e('Unhandled error in sendPasswordResetEmail', e, stackTrace);
      errorMessage.value = AppStrings.unknownError;
    } finally {
      isForgotPasswordLoading.value = false;
    }
  }

  Future<void> signOut() async {
    // Clean up FCM token before signing out.
    await FcmService.instance.onSignOut();
    final result = await _authRepository.signOut();
    result.fold(
      (_) {
        currentUser.value = null;
        unawaited(Get.offAllNamed(AppRoutes.login));
      },
      (failure) {
        errorMessage.value = ErrorHandler.map(failure);
      },
    );
  }

  void resetFormAndErrors() {
    loginEmailError.value = null;
    loginPasswordError.value = null;
    signupNameError.value = null;
    signupEmailError.value = null;
    signupPasswordError.value = null;
    signupConfirmPasswordError.value = null;
    forgotPasswordEmailError.value = null;
    resetEmailSent.value = false;
    resetEmailAddress.value = '';
    errorMessage.value = '';

    loginEmailCtrl.clear();
    loginPasswordCtrl.clear();
    signupNameCtrl.clear();
    signupEmailCtrl.clear();
    signupPasswordCtrl.clear();
    signupConfirmPasswordCtrl.clear();
    forgotPasswordEmailCtrl.clear();
  }

  @override
  void onClose() {
    loginEmailCtrl.dispose();
    loginPasswordCtrl.dispose();
    signupNameCtrl.dispose();
    signupEmailCtrl.dispose();
    signupPasswordCtrl.dispose();
    signupConfirmPasswordCtrl.dispose();
    forgotPasswordEmailCtrl.dispose();
    super.onClose();
  }
}

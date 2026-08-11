import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/repositories/auth_repository.dart';
import '../routes/app_routes.dart';

/// GetX middleware that guards routes requiring authentication.
/// Applied on [AppRoutes.homeShell] so unauthenticated users are redirected to /login.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      final authRepo = Get.find<AuthRepository>();
      final isAuthenticated = authRepo.currentUser != null;

      if (!isAuthenticated) {
        return const RouteSettings(name: AppRoutes.login);
      }
    } catch (_) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

/// GetX middleware that guards auth routes (/login, /signup).
/// If an authenticated user attempts to visit /login or /signup,
/// they are automatically redirected to /home-shell.
class GuestMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      final authRepo = Get.find<AuthRepository>();
      final isAuthenticated = authRepo.currentUser != null;

      if (isAuthenticated) {
        return const RouteSettings(name: AppRoutes.homeShell);
      }
    } catch (_) {}
    return null;
  }
}

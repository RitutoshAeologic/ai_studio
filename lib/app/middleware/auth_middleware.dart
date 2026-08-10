import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/repositories/auth_repository.dart';
import '../routes/app_routes.dart';

/// GetX middleware that guards routes requiring authentication.
///
/// Applied on [AppRoutes.homeShell] route so unauthenticated users are
/// redirected to /login and authenticated users are never sent back to /login.
/// No manual navigation calls in views — routing is handled entirely here.
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

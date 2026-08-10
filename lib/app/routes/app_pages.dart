import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/signup_view.dart';
import 'app_routes.dart';

/// GetPage route table mapping routes to views and bindings.
abstract class AppPages {
  static const String initial = AppRoutes.login;

  static final List<GetPage<dynamic>> pages = [
    // Splash placeholder
    GetPage(
      name: AppRoutes.splash,
      page: () => const Scaffold(
        backgroundColor: Color(0xFF0B0B10),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B5CFA)),
          ),
        ),
      ),
    ),

    // Auth
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // Home Shell (placeholder — will be replaced in Phase 1)
    GetPage(
      name: AppRoutes.homeShell,
      page: () => const Scaffold(
        backgroundColor: Color(0xFF0B0B10),
        body: Center(
          child: Text(
            'Home Shell — Coming in Phase 1',
            style: TextStyle(color: Color(0xFFF2F2F6)),
          ),
        ),
      ),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}

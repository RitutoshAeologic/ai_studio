import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/aperture_indicator.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/signup_view.dart';
import '../../features/shell/bindings/home_shell_binding.dart';
import '../../features/shell/views/home_shell_view.dart';
import '../middleware/auth_middleware.dart';
import 'app_routes.dart';

/// GetPage route table mapping routes to views and bindings.
abstract class AppPages {
  static const String initial = AppRoutes.login;

  static final List<GetPage<dynamic>> pages = [
    // Splash screen with signature ApertureIndicator loading widget
    GetPage(
      name: AppRoutes.splash,
      page: () => const Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(
          child: ApertureIndicator(
            size: 64,
            color: AppColors.ember,
            state: ApertureState.open,
          ),
        ),
      ),
    ),

    // Auth Routes
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // Home Shell Route (Guarded with AuthMiddleware & HomeShellBinding)
    GetPage(
      name: AppRoutes.homeShell,
      page: () => const HomeShellView(),
      binding: HomeShellBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}

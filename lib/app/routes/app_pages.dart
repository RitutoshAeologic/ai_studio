import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/aperture_indicator.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/signup_view.dart';
import '../../features/auth/views/forgot_password_view.dart';
import '../../features/shell/bindings/home_shell_binding.dart';
import '../../features/shell/views/home_shell_view.dart';
import '../../features/video_generation/presentation/screens/video_generation_screen.dart';
import '../../features/face_swap/presentation/screens/face_swap_screen.dart';
import '../../screens/lip_sync_screen.dart';
import '../middleware/auth_middleware.dart';
import 'app_routes.dart';

/// GetPage route table mapping routes to views, bindings, and auth guards.
abstract class AppPages {
  static const String initial = AppRoutes.splash;

  static final List<GetPage<dynamic>> pages = [
    // Splash screen evaluating persistent auth state on app startup
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
    ),

    // Auth Routes (Guarded with GuestMiddleware so logged-in users bypass to homeShell)
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      middlewares: [GuestMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
      middlewares: [GuestMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      middlewares: [GuestMiddleware()],
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

    // Video Generation Route
    GetPage(
      name: AppRoutes.videoGen,
      page: () => const VideoGenerationScreen(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // AI Video Face Swap Route
    GetPage(
      name: AppRoutes.faceSwap,
      page: () => const FaceSwapScreen(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // AI Video Lip-Sync Route
    GetPage(
      name: AppRoutes.lipSync,
      page: () => const LipSyncScreen(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
  ];
}

/// Initial splash screen evaluating auth persistence before redirecting.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final authRepo = Get.find<AuthRepository>();
        if (authRepo.currentUser != null) {
          Get.offAllNamed(AppRoutes.homeShell);
        } else {
          Get.offAllNamed(AppRoutes.login);
        }
      } catch (_) {
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Center(
        child: ApertureIndicator(
          size: 64.r,
          color: AppColors.primaryAction,
          state: ApertureState.open,
        ),
      ),
    );
  }
}

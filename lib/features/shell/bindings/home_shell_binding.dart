import 'package:ai_studio/core/services/api_service.dart';
import 'package:ai_studio/core/services/job_completion_notification_service.dart';
import 'package:ai_studio/data/repositories/job_repository_impl.dart';
import 'package:ai_studio/data/repositories/wallet_repository_impl.dart';
import 'package:ai_studio/domain/repositories/job_repository.dart';
import 'package:ai_studio/domain/repositories/wallet_repository.dart';
import 'package:ai_studio/features/auth/controllers/auth_controller.dart';
import 'package:ai_studio/features/jobs/controllers/job_controller.dart';
import 'package:ai_studio/features/shell/controllers/home_shell_controller.dart';
import 'package:ai_studio/features/wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';

/// Bindings injected when the HomeShell route is entered.
class HomeShellBinding extends Bindings {
  @override
  void dependencies() {
    // HomeShellController — manages active tab & deep linking
    Get.lazyPut<HomeShellController>(() => HomeShellController(), fenix: true);

    // ApiService — used by JobController
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);

    // WalletRepository — required by WalletController
    Get.lazyPut<WalletRepository>(() => WalletRepositoryImpl(), fenix: true);

    // JobRepository & JobController
    Get.lazyPut<JobRepository>(() => JobRepositoryImpl(), fenix: true);
    Get.lazyPut<JobController>(
      () => JobController(),
      fenix: true,
    );

    // WalletController — starts watching on auth state
    Get.lazyPut<WalletController>(() => WalletController(), fenix: true);

    // Start wallet listener & job notification listener for the authenticated user
    Future.microtask(() {
      final authCtrl = Get.find<AuthController>();
      final userId = authCtrl.currentUser.value?.uid;
      if (userId != null) {
        Get.find<WalletController>().startWatching(userId);
        JobCompletionNotificationService.instance.startListening(userId);
      }
    });
  }
}

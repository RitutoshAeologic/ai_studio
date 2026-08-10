import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/job_repository_impl.dart';
import '../../../data/repositories/wallet_repository_impl.dart';
import '../../../domain/repositories/job_repository.dart';
import '../../../domain/repositories/wallet_repository.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/jobs/controllers/job_controller.dart';
import '../../../features/wallet/controllers/wallet_controller.dart';

/// Bindings injected when the HomeShell route is entered.
/// Lazily creates WalletController and JobController — not instantiated globally.
class HomeShellBinding extends Bindings {
  @override
  void dependencies() {
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

    // Start wallet listener for the authenticated user
    Future.microtask(() {
      final authCtrl = Get.find<AuthController>();
      final userId = authCtrl.currentUser.value?.uid;
      if (userId != null) {
        Get.find<WalletController>().startWatching(userId);
      }
    });
  }
}

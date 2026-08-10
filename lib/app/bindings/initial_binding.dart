import 'package:get/get.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/job_repository_impl.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/job_repository.dart';
import '../../domain/repositories/wallet_repository.dart';

import '../../features/auth/controllers/auth_controller.dart';

/// Global initial bindings instantiated on app start.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(),
      fenix: true,
    );
    Get.lazyPut<WalletRepository>(
      () => WalletRepositoryImpl(),
      fenix: true,
    );
    Get.lazyPut<JobRepository>(
      () => JobRepositoryImpl(),
      fenix: true,
    );
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true,
    );
  }
}

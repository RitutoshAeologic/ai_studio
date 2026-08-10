import 'package:ai_studio/data/repositories/auth_repository_impl.dart';
import 'package:ai_studio/data/repositories/job_repository_impl.dart';
import 'package:ai_studio/data/repositories/storage_repository_impl.dart';
import 'package:ai_studio/data/repositories/wallet_repository_impl.dart';
import 'package:ai_studio/domain/repositories/auth_repository.dart';
import 'package:ai_studio/domain/repositories/job_repository.dart';
import 'package:ai_studio/domain/repositories/storage_repository.dart';
import 'package:ai_studio/domain/repositories/wallet_repository.dart';
import 'package:ai_studio/features/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';


/// Global initial bindings instantiated on app start.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(),
      fenix: true,
    );
    Get.lazyPut<StorageRepository>(
      () => StorageRepositoryImpl(),
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

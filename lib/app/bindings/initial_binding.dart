import 'package:get/get.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/storage_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/storage_repository.dart';

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
  }
}

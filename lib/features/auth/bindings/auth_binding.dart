import 'package:ai_studio/features/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';

/// Scoped binding for Auth feature — creates AuthController via lazyPut.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}

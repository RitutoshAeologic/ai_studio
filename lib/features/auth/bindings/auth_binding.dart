import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

/// Scoped binding for Auth feature — creates AuthController via lazyPut.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}

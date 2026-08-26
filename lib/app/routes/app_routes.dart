/// Centralized route name constants for GetX navigation.
// ignore_for_file: avoid_classes_with_only_static_members
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String homeShell = '/home';
  static const String imageTo3d = '/image-to-3d';
  static const String themeChange = '/theme-change';
  static const String backgroundChange = '/background-change';
  static const String videoGen = '/video-gen';
  static const String faceSwap = '/face-swap';
  static const String lipSync = '/lip-sync';
  static const String interviewSetup = '/interview-setup';
  static const String interactiveInterview = '/interactive-interview';
  static const String jobHistory = '/job-history';
}

/// Legacy alias — prefer AppRoutes.
typedef Routes = AppRoutes;

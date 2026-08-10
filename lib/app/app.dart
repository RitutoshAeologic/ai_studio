import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';

/// Root application widget for AI Studio with responsive ScreenUtilPlusInit.
class AiStudioApp extends StatelessWidget {
  const AiStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.lightTheme,
          themeMode: ThemeMode.light,
          initialBinding: InitialBinding(),
          initialRoute: AppPages.initial,
          getPages: AppPages.pages,
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 200),
        );
      },
    );
  }
}

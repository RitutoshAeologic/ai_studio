import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Spacing tokens according to ui_ux.md §4 with responsive ScreenUtil extensions.
abstract class AppSpacing {
  static double get xs => 4.r;
  static double get sm => 8.r;
  static double get md => 16.r;
  static double get lg => 24.r;
  static double get xl => 32.r;
  static double get xxl => 48.r;

  // EdgeInsets helpers
  static EdgeInsets get paddingScreen => EdgeInsets.all(16.r);
  static EdgeInsets get paddingCard => EdgeInsets.all(16.r);
  static EdgeInsets get paddingChip =>
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);

  // SizedBox helpers
  static SizedBox get gapXs => SizedBox(height: 4.h, width: 4.w);
  static SizedBox get gapSm => SizedBox(height: 8.h, width: 8.w);
  static SizedBox get gapMd => SizedBox(height: 16.h, width: 16.w);
  static SizedBox get gapLg => SizedBox(height: 24.h, width: 24.w);
  static SizedBox get gapXl => SizedBox(height: 32.h, width: 32.w);
}

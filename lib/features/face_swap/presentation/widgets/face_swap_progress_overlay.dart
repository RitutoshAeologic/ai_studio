import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/aperture_indicator.dart';

class FaceSwapProgressOverlay extends StatelessWidget {
  final String stageMessage;
  final double progressPercent;

  const FaceSwapProgressOverlay({
    super.key,
    required this.stageMessage,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final percentInt = (progressPercent * 100).toInt().clamp(0, 100);

    return Container(
      color: Colors.black.withAlpha(220),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.borderSubtle, width: 1.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(140),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Aperture Indicator
                ApertureIndicator(
                  size: 72.r,
                  color: AppColors.primaryAction,
                  state: ApertureState.opening,
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  'Generating Face-Swap Video',
                  style: AppTextStyles.headingSmall(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),

                // Active Stage Message
                Text(
                  stageMessage,
                  style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: progressPercent.clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceInput,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAction),
                    minHeight: 8.h,
                  ),
                ),
                SizedBox(height: 12.h),

                // Estimated Time & Percentage Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Est. processing: 20 - 45 seconds',
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                    Text(
                      '$percentInt%',
                      style: AppTextStyles.caption(
                        color: AppColors.primaryAction,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Model Tech Info Card
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primaryAction,
                        size: 18.r,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'InsightFace tracks 3D facial landmarks while Celery renders swapped video frames.',
                          style: AppTextStyles.caption(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/aperture_indicator.dart';

class VideoProgressOverlay extends StatelessWidget {
  final String stageMessage;
  final double progressPercent; // 0.0 to 1.0
  final int durationSec; // 10 or 15

  const VideoProgressOverlay({
    super.key,
    required this.stageMessage,
    required this.progressPercent,
    required this.durationSec,
  });

  @override
  Widget build(BuildContext context) {
    final estRange = durationSec == 15 ? '30 - 50 seconds' : '20 - 40 seconds';
    final percentInt = (progressPercent * 100).clamp(0, 100).toInt();

    return Container(
      color: AppColors.bgApp.withAlpha(240),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApertureIndicator(
                size: 72.r,
                color: AppColors.primaryAction,
                state: ApertureState.opening,
              ),
              SizedBox(height: 28.h),
              Text(
                'Generating Video Clip',
                style: AppTextStyles.headingM(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                stageMessage,
                style: AppTextStyles.bodyM(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: progressPercent.clamp(0.05, 1.0),
                  minHeight: 8.h,
                  backgroundColor: AppColors.surfaceCard,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAction),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Est. generation time: $estRange',
                    style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                  ),
                  Text(
                    '$percentInt%',
                    style: AppTextStyles.labelSmall(
                      color: AppColors.primaryAction,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18.r,
                      color: AppColors.creditGoldIcon,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Gemini Flash is expanding your prompt while Wan 2.2 renders fast video frames in parallel.',
                        style: AppTextStyles.caption(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

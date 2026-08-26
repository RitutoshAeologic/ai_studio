import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/interview_models.dart';

class InterviewHeader extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final InterviewSegment? currentSegment;
  final VoidCallback onExit;

  const InterviewHeader({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    this.currentSegment,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalQuestions > 0 ? (currentIndex + 1) / totalQuestions : 0.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.bgApp.withAlpha(210),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSubtle, width: 1.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryAction,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Question ${currentIndex + 1} of $totalQuestions',
                    style: AppTextStyles.headingSmall(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (currentSegment?.tag != null &&
                      currentSegment!.tag!.isNotEmpty)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.emberSoft,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.primaryAction.withAlpha(80),
                          width: 1.r,
                        ),
                      ),
                      child: Text(
                        currentSegment!.tag!,
                        style: AppTextStyles.caption(
                          color: AppColors.primaryAction,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: onExit,
                    child: CircleAvatar(
                      backgroundColor: AppColors.surfaceInput,
                      radius: 12.r,
                      child: Icon(
                        Icons.close_rounded,
                        size: 14.r,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4.h,
              backgroundColor: AppColors.surfaceInput,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryAction),
            ),
          ),
        ],
      ),
    );
  }
}

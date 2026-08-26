import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/interview_models.dart';

class QuestionOverlayCard extends StatelessWidget {
  final InterviewSegment? segment;
  final InterviewState state;
  final int answerTimerSeconds;
  final bool isLastQuestion;
  final VoidCallback onNextQuestion;

  const QuestionOverlayCard({
    super.key,
    this.segment,
    required this.state,
    required this.answerTimerSeconds,
    required this.isLastQuestion,
    required this.onNextQuestion,
  });

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isAnswering = state == InterviewState.candidateAnswering;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withAlpha(245),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isAnswering
              ? AppColors.statusSuccess
              : AppColors.primaryAction,
          width: 1.5.r,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(150),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status indicator row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: isAnswering
                      ? AppColors.statusSuccessSoft
                      : AppColors.emberSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAnswering ? Icons.mic_rounded : Icons.volume_up_rounded,
                  color: isAnswering
                      ? AppColors.statusSuccess
                      : AppColors.primaryAction,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                isAnswering
                    ? 'Your Turn to Answer (${_formatDuration(answerTimerSeconds)})'
                    : 'Interviewer Speaking...',
                style: AppTextStyles.bodyMedium(
                  color: isAnswering
                      ? AppColors.statusSuccess
                      : AppColors.primaryAction,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isAnswering)
                Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: const BoxDecoration(
                    color: AppColors.statusSuccess,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // 2. Question Text
          Text(
            segment?.questionText ?? 'Loading question text...',
            style: AppTextStyles.bodyM(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 18.h),

          // 3. Action Button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: isAnswering ? onNextQuestion : null,
              icon: Icon(
                isLastQuestion
                    ? Icons.check_circle_outline_rounded
                    : Icons.arrow_forward_rounded,
                size: 18.r,
              ),
              label: Text(
                isLastQuestion ? 'Finish Interview' : 'Next Question',
                style: AppTextStyles.labelMedium(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAnswering
                    ? AppColors.statusSuccess
                    : AppColors.surfaceInput,
                disabledBackgroundColor: AppColors.surfaceInput,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.textDisabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

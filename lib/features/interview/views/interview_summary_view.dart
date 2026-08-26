import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../models/interview_models.dart';

class InterviewSummaryView extends StatelessWidget {
  final InterviewCandidate candidate;
  final int completedQuestions;
  final int totalQuestions;
  final int totalDurationSeconds;

  const InterviewSummaryView({
    super.key,
    required this.candidate,
    required this.completedQuestions,
    required this.totalQuestions,
    required this.totalDurationSeconds,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),

              // 1. Success Trophy Icon
              Container(
                width: 90.r,
                height: 90.r,
                decoration: const BoxDecoration(
                  color: AppColors.statusSuccessSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.statusSuccess,
                  size: 54.r,
                ),
              ),
              SizedBox(height: 24.h),

              // 2. Title & Subtitle
              Text(
                'Interview Completed!',
                style: AppTextStyles.headingLarge(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'All interactive questions have been answered and recorded.',
                style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // 3. Candidate Summary Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.r),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Candidate', candidate.name, Icons.person_rounded),
                    Divider(color: AppColors.borderSubtle, height: 24.h),
                    _buildSummaryRow('Email', candidate.email, Icons.email_rounded),
                    Divider(color: AppColors.borderSubtle, height: 24.h),
                    _buildSummaryRow('Target Role', candidate.role, Icons.work_rounded),
                    Divider(color: AppColors.borderSubtle, height: 24.h),
                    _buildSummaryRow(
                      'Questions Completed',
                      '$completedQuestions / $totalQuestions',
                      Icons.format_list_numbered_rounded,
                      highlight: true,
                    ),
                    Divider(color: AppColors.borderSubtle, height: 24.h),
                    _buildSummaryRow(
                      'Total Duration',
                      _formatDuration(totalDurationSeconds),
                      Icons.timer_rounded,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),

              // 4. Action Buttons
              AppButton(
                label: 'Back to Home',
                onPressed: () => Get.offAllNamed(AppRoutes.homeShell),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Review Setup',
                  style: AppTextStyles.labelMedium(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: highlight ? AppColors.primaryAction : AppColors.textMuted, size: 18.r),
        SizedBox(width: 10.w),
        Text(
          label,
          style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium(
            color: highlight ? AppColors.primaryAction : AppColors.textPrimary,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

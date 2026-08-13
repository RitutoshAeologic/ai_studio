import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class DurationSelectorWidget extends StatelessWidget {
  final int selectedDuration; // 10 or 15
  final ValueChanged<int> onDurationChanged;

  const DurationSelectorWidget({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Video Duration',
              style: AppTextStyles.labelSmall(color: AppColors.textMuted),
            ),
            const Spacer(),
            Text(
              selectedDuration == 10 ? '40 Credits' : '50 Credits',
              style: AppTextStyles.labelSmall(
                color: AppColors.creditGoldTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildDurationCard(
                durationSec: 10,
                credits: 40,
                subtitle: 'Standard Clip',
                isSelected: selectedDuration == 10,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildDurationCard(
                durationSec: 15,
                credits: 50,
                subtitle: 'Extended Scene',
                isSelected: selectedDuration == 15,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationCard({
    required int durationSec,
    required int credits,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onDurationChanged(durationSec),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGlowSoft : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryAction : AppColors.borderSubtle,
            width: isSelected ? 1.5.r : 1.r,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18.r,
                  color: isSelected ? AppColors.primaryAction : AppColors.textMuted,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '${durationSec}s Video',
                    style: AppTextStyles.labelMedium(
                      color: isSelected ? AppColors.primaryAction : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.creditGoldBg,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 12.r,
                        color: AppColors.creditGoldIcon,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '$credits cr',
                        style: AppTextStyles.caption(
                          color: AppColors.creditGoldTitle,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

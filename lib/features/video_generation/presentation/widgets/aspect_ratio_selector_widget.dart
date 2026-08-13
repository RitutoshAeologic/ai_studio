import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class AspectRatioOption {
  final String ratio;
  final String label;
  final IconData icon;

  const AspectRatioOption({
    required this.ratio,
    required this.label,
    required this.icon,
  });
}

class AspectRatioSelectorWidget extends StatelessWidget {
  final String selectedRatio; // "16:9", "9:16", "1:1"
  final ValueChanged<String> onRatioChanged;

  static const List<AspectRatioOption> options = [
    AspectRatioOption(ratio: '16:9', label: '16:9 Widescreen', icon: Icons.crop_16_9_rounded),
    AspectRatioOption(ratio: '9:16', label: '9:16 Portrait / Reel', icon: Icons.crop_portrait_rounded),
    AspectRatioOption(ratio: '1:1', label: '1:1 Square', icon: Icons.crop_square_rounded),
  ];

  const AspectRatioSelectorWidget({
    super.key,
    required this.selectedRatio,
    required this.onRatioChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aspect Ratio',
          style: AppTextStyles.labelSmall(color: AppColors.textMuted),
        ),
        SizedBox(height: 8.h),
        Row(
          children: options.map((opt) {
            final isSelected = selectedRatio == opt.ratio;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: GestureDetector(
                  onTap: () => onRatioChanged(opt.ratio),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryAction : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryAction : AppColors.borderSubtle,
                        width: 1.r,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          opt.icon,
                          size: 20.r,
                          color: isSelected ? Colors.white : AppColors.textMuted,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          opt.ratio,
                          style: AppTextStyles.labelSmall(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

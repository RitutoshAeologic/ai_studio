import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/image_validator.dart';

class SourceFacePicker extends StatefulWidget {
  final File? selectedFaceFile;
  final ValueChanged<File?> onFaceSelected;

  const SourceFacePicker({
    super.key,
    required this.selectedFaceFile,
    required this.onFaceSelected,
  });

  @override
  State<SourceFacePicker> createState() => _SourceFacePickerState();
}

class _SourceFacePickerState extends State<SourceFacePicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    await HapticFeedback.lightImpact();
    final uploadService = ImageUploadService();
    final xFile = await uploadService.pickImage(source);
    if (xFile == null) return;

    final validation = await ImageValidator.validateImage(
      filePath: xFile.path,
      featureTarget: AiFeatureTarget.generalAi,
      imageSource: source,
    );

    if (!validation.isValid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              validation.errorMessage ?? 'Invalid face image file.',
              style: AppTextStyles.bodyM(color: Colors.white),
            ),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
      return;
    }

    await HapticFeedback.mediumImpact();
    widget.onFaceSelected(File(xFile.path));
  }

  void _showImageSourcePicker(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryAction),
                title: Text('Choose Face from Gallery', style: AppTextStyles.bodyM()),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryAction),
                title: Text('Take Face Photo with Camera', style: AppTextStyles.bodyM()),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFile = widget.selectedFaceFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '2. Attach Character Face Photo',
              style: AppTextStyles.labelSmall(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' *',
              style: AppTextStyles.labelSmall(color: AppColors.primaryAction),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        if (selectedFile == null) ...[
          // Empty State Picker Box
          GestureDetector(
            onTap: () => _showImageSourcePicker(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1.5.r,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26.r,
                    backgroundColor: AppColors.accentGlowSoft,
                    child: Icon(
                      Icons.face_retouching_natural_rounded,
                      color: AppColors.primaryAction,
                      size: 28.r,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Tap to upload face / character photo',
                    style: AppTextStyles.labelMedium(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Front-facing portrait with clear facial features gives the best result.',
                    style: AppTextStyles.caption(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Preview Selected Face Photo Card with Glowing Checkmark
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.statusSuccess, width: 1.5.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.statusSuccess.withAlpha(40),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                // Face Photo Thumbnail with pulsing checkmark badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Image.file(
                        selectedFile,
                        width: 72.r,
                        height: 72.r,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -4.r,
                      right: -4.r,
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: const BoxDecoration(
                            color: AppColors.statusSuccess,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12.r,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 14.w),

                // Info & Action Buttons
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 16.r),
                          SizedBox(width: 6.w),
                          Text(
                            'Face Photo Attached',
                            style: AppTextStyles.labelSmall(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Ready to swap onto the selected dance template.',
                        style: AppTextStyles.caption(color: AppColors.textMuted),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showImageSourcePicker(context),
                            child: Text(
                              'Change Photo',
                              style: AppTextStyles.caption(
                                color: AppColors.primaryAction,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onFaceSelected(null);
                            },
                            child: Text(
                              'Remove',
                              style: AppTextStyles.caption(
                                color: AppColors.statusError,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

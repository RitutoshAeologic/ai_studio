import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/image_crop_helper.dart';
import '../../../../core/utils/image_validator.dart';

/// Clean character face picker with smooth 16.r curves and clear status.
class SourceFacePicker extends StatefulWidget {
  final File? selectedFaceFile;
  final bool isProcessing;
  final ValueChanged<File?> onFaceSelected;

  const SourceFacePicker({
    super.key,
    required this.selectedFaceFile,
    this.isProcessing = false,
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
    if (widget.isProcessing) return;

    await HapticFeedback.lightImpact();
    final uploadService = ImageUploadService();
    final xFile = await uploadService.pickImage(source);
    if (xFile == null) return;

    final cleanSource = ImageCropHelper.normalizePath(xFile.path);

    // 1. Crop face portrait
    final croppedPath = await ImageCropHelper.cropImage(
      sourcePath: cleanSource,
    );
    if (croppedPath == null) return; // Cancelled

    final cleanCropped = ImageCropHelper.normalizePath(croppedPath);

    // 2. Validate face image
    final validation = await ImageValidator.validateImage(
      filePath: cleanCropped,
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
    widget.onFaceSelected(File(cleanCropped));
  }

  void _showImageSourcePicker(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.ember),
                title: Text('Choose Face from Gallery', style: AppTextStyles.bodyM(color: AppColors.bone)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.ember),
                title: Text('Take Face Photo with Camera', style: AppTextStyles.bodyM(color: AppColors.bone)),
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
    final isProcessing = widget.isProcessing;

    return IgnorePointer(
      ignoring: isProcessing,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isProcessing ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Upload Face Photo',
                  style: AppTextStyles.labelMedium(
                    color: AppColors.bone,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ' *',
                  style: AppTextStyles.labelMedium(
                    color: AppColors.ember,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            if (selectedFile == null) ...[
              // Clean Empty State Picker Box
              GestureDetector(
                onTap: isProcessing ? null : () => _showImageSourcePicker(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1.r,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: AppColors.emberSoft,
                        child: Icon(
                          Icons.face_retouching_natural_rounded,
                          color: AppColors.ember,
                          size: 26.r,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Choose Character Face Photo',
                        style: AppTextStyles.labelMedium(
                          color: AppColors.bone,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Front-facing portrait from gallery or camera',
                        style: AppTextStyles.caption(color: AppColors.slate),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Clean Selected Face Photo Card
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.statusSuccess, width: 1.5.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.statusSuccess.withAlpha(30),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Face Photo Thumbnail with checkmark badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.file(
                            selectedFile,
                            width: 68.r,
                            height: 68.r,
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
                                'Face Ready',
                                style: AppTextStyles.labelMedium(
                                  color: AppColors.statusSuccess,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Ready for high-definition face swap',
                            style: AppTextStyles.caption(color: AppColors.slate),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: isProcessing ? null : () => _showImageSourcePicker(context),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceInput,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cached_rounded, size: 12.r, color: AppColors.bone),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Change',
                                        style: AppTextStyles.caption(
                                          color: AppColors.bone,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: isProcessing
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        widget.onFaceSelected(null);
                                      },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusError.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: AppColors.statusError.withAlpha(60), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 12.r, color: AppColors.statusError),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Remove',
                                        style: AppTextStyles.caption(
                                          color: AppColors.statusError,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
        ),
      ),
    );
  }
}

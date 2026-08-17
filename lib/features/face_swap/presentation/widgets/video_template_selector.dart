import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/models/video_template.dart';
import 'template_preview_modal.dart';

/// Pure, clean Dance Template Selector with live looping video preview cards.
/// Completely free of distracting titles or badges, with prominent 20.r curves.
class VideoTemplateSelector extends StatelessWidget {
  final VideoTemplate selectedTemplate;
  final File? customVideoFile;
  final List<VideoTemplate>? templates;
  final ValueChanged<VideoTemplate> onTemplateSelected;
  final ValueChanged<File> onCustomVideoPicked;

  const VideoTemplateSelector({
    super.key,
    required this.selectedTemplate,
    this.customVideoFile,
    this.templates,
    required this.onTemplateSelected,
    required this.onCustomVideoPicked,
  });

  Future<void> _pickCustomVideo(BuildContext context, ImageSource source) async {
    await HapticFeedback.lightImpact();
    final uploadService = ImageUploadService();
    final xFile = await uploadService.pickVideo(source);
    if (xFile != null) {
      final file = File(xFile.path);
      final sizeMB = file.lengthSync() / (1024 * 1024);

      if (context.mounted && sizeMB > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Large video selected (${sizeMB.toStringAsFixed(1)} MB). Upload may take longer.',
              style: AppTextStyles.bodyM(color: Colors.white),
            ),
            backgroundColor: AppColors.statusWarning,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      onCustomVideoPicked(file);
    }
  }

  void _showCustomVideoSourcePicker(BuildContext context) {
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
                leading: const Icon(Icons.video_library_outlined, color: AppColors.ember),
                title: Text('Select Video from Gallery', style: AppTextStyles.bodyM(color: AppColors.bone)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCustomVideo(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: AppColors.ember),
                title: Text('Record Video with Camera', style: AppTextStyles.bodyM(color: AppColors.bone)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCustomVideo(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _previewTemplate(BuildContext context, VideoTemplate template) {
    TemplateVideoPreviewModal.show(
      context,
      template: template,
      onSelect: () => onTemplateSelected(template),
    );
  }

  void _previewCustomVideo(BuildContext context) {
    if (customVideoFile == null) return;
    TemplateVideoPreviewModal.show(
      context,
      template: selectedTemplate,
      customFile: customVideoFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateList = templates ?? VideoTemplate.catalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Video Template',
              style: AppTextStyles.labelMedium(
                color: AppColors.bone,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (selectedTemplate.isCustom)
              Text(
                'Custom Video',
                style: AppTextStyles.caption(
                  color: AppColors.ember,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        SizedBox(height: 12.h),

        SizedBox(
          height: 180.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templateList.length + 1, // Catalog items + Custom Upload Card
            separatorBuilder: (_, _) => SizedBox(width: 14.w),
            itemBuilder: (context, index) {
              // Custom Video Picker Card
              if (index == templateList.length) {
                final isCustomSelected = selectedTemplate.isCustom;
                final customFileSizeMB = customVideoFile != null
                    ? (customVideoFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(1)
                    : null;

                return GestureDetector(
                  onTap: () => _showCustomVideoSourcePicker(context),
                  child: Container(
                    width: 126.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161922),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isCustomSelected
                            ? AppColors.ember
                            : const Color(0xFF2C3240),
                        width: isCustomSelected ? 2.5.r : 1.5.r,
                      ),
                      boxShadow: [
                        if (isCustomSelected)
                          BoxShadow(
                            color: AppColors.ember.withAlpha(80),
                            blurRadius: 14,
                            spreadRadius: 1,
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 22.r,
                          backgroundColor: isCustomSelected
                              ? AppColors.emberSoft
                              : AppColors.surfaceInput,
                          child: Icon(
                            isCustomSelected ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                            color: isCustomSelected ? AppColors.ember : AppColors.slate,
                            size: 24.r,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          isCustomSelected ? 'Custom MP4' : 'Custom Video',
                          style: AppTextStyles.labelSmall(
                            color: isCustomSelected
                                ? AppColors.ember
                                : AppColors.bone,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isCustomSelected && customFileSizeMB != null
                              ? '$customFileSizeMB MB Ready'
                              : 'Upload',
                          style: AppTextStyles.caption(
                            color: isCustomSelected ? AppColors.statusSuccess : AppColors.slate,
                          ),
                        ),
                        if (isCustomSelected && customVideoFile != null) ...[
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: () => _previewCustomVideo(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.ember.withAlpha(40),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 14.r, color: AppColors.ember),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Preview',
                                    style: AppTextStyles.caption(
                                      color: AppColors.ember,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              // Preset Template Card with live looping video preview
              final item = templateList[index];
              final isSelected = selectedTemplate.id == item.id && !selectedTemplate.isCustom;

              return _TemplateVideoThumbnailCard(
                template: item,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTemplateSelected(item);
                },
                onPreview: () => _previewTemplate(context, item),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A memory-efficient template card that shows a static thumbnail image
/// instead of a live VideoPlayerController. Concurrent live video players
/// caused OOM crashes on low-RAM devices (iPhone 8, 2 GB). Tapping the
/// play icon opens the full TemplateVideoPreviewModal instead.
class _TemplateVideoThumbnailCard extends StatelessWidget {
  final VideoTemplate template;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  const _TemplateVideoThumbnailCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 126.w,
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.ember : const Color(0xFF2C3240),
            width: isSelected ? 2.5.r : 1.5.r,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.ember.withAlpha(90),
                blurRadius: 14,
                spreadRadius: 1.5,
              )
            else
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Static Thumbnail Image (memory-safe, no video decode)
              if (template.thumbnailUrl.isNotEmpty)
                AppNetworkImage(
                  imageUrl: template.thumbnailUrl,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E222D), Color(0xFF13151D)],
                    ),
                  ),
                ),

              // 2. Vignette Gradient for Depth
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(50),
                      Colors.transparent,
                      Colors.black.withAlpha(140),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // 3. Top-Right Selected Checkmark Badge
              if (isSelected)
                Positioned(
                  top: 8.r,
                  right: 8.r,
                  child: CircleAvatar(
                    radius: 12.r,
                    backgroundColor: AppColors.ember,
                    child: Icon(Icons.check_rounded, size: 14.r, color: Colors.white),
                  ),
                ),

              // 4. Center Play Button — opens full preview modal on tap
              Center(
                child: GestureDetector(
                  onTap: onPreview,
                  child: Container(
                    padding: EdgeInsets.all(9.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(90), width: 1.r),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22.r,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

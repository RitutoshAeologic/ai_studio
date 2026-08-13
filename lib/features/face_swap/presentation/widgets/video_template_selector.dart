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

class VideoTemplateSelector extends StatelessWidget {
  final VideoTemplate selectedTemplate;
  final File? customVideoFile;
  final ValueChanged<VideoTemplate> onTemplateSelected;
  final ValueChanged<File> onCustomVideoPicked;

  const VideoTemplateSelector({
    super.key,
    required this.selectedTemplate,
    this.customVideoFile,
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
              '⚠️ Notice: Large video selected (${sizeMB.toStringAsFixed(1)} MB). Videos over 50MB may take longer to upload.',
              style: AppTextStyles.bodyM(color: Colors.white),
            ),
            backgroundColor: AppColors.creditGoldTitle,
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
                leading: const Icon(Icons.video_library_outlined, color: AppColors.primaryAction),
                title: Text('Select Video from Gallery', style: AppTextStyles.bodyM()),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCustomVideo(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: AppColors.primaryAction),
                title: Text('Record Video with Camera', style: AppTextStyles.bodyM()),
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
    const templates = VideoTemplate.catalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1. Select Dance / Action Template',
              style: AppTextStyles.labelSmall(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              selectedTemplate.isCustom ? 'Custom Video' : selectedTemplate.title,
              style: AppTextStyles.caption(
                color: AppColors.primaryAction,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        SizedBox(
          height: 165.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length + 1, // Catalog items + Custom Upload Card
            separatorBuilder: (_, _) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              // Custom Video Picker Card
              if (index == templates.length) {
                final isCustomSelected = selectedTemplate.isCustom;
                final customFileSizeMB = customVideoFile != null
                    ? (customVideoFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(1)
                    : null;

                return GestureDetector(
                  onTap: () => _showCustomVideoSourcePicker(context),
                  child: Container(
                    width: 120.w,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isCustomSelected
                            ? AppColors.primaryAction
                            : AppColors.borderSubtle,
                        width: isCustomSelected ? 2.r : 1.r,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 22.r,
                          backgroundColor: isCustomSelected
                              ? AppColors.accentGlowSoft
                              : AppColors.surfaceInput,
                          child: Icon(
                            isCustomSelected ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                            color: isCustomSelected ? AppColors.primaryAction : AppColors.textMuted,
                            size: 24.r,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          isCustomSelected ? 'Custom MP4' : 'Upload',
                          style: AppTextStyles.labelSmall(
                            color: isCustomSelected
                                ? AppColors.primaryAction
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isCustomSelected && customFileSizeMB != null
                              ? '$customFileSizeMB MB Ready'
                              : 'Your Video',
                          style: AppTextStyles.caption(
                            color: isCustomSelected ? AppColors.statusSuccess : AppColors.textMuted,
                          ),
                        ),
                        if (isCustomSelected && customVideoFile != null) ...[
                          SizedBox(height: 6.h),
                          GestureDetector(
                            onTap: () => _previewCustomVideo(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAction.withAlpha(40),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 12.r, color: AppColors.primaryAction),
                                  Text(
                                    'Preview',
                                    style: AppTextStyles.caption(
                                      color: AppColors.primaryAction,
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

              // Preset Template Card
              final item = templates[index];
              final isSelected = selectedTemplate.id == item.id && !selectedTemplate.isCustom;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTemplateSelected(item);
                },
                child: Container(
                  width: 120.w,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryAction
                          : AppColors.borderSubtle,
                      width: isSelected ? 2.r : 1.r,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail Image
                      AppNetworkImage(
                        imageUrl: item.thumbnailUrl,
                        fit: BoxFit.cover,
                      ),

                      // Gradient Overlay for Text Readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(60),
                              Colors.transparent,
                              Colors.black.withAlpha(220),
                            ],
                            stops: const [0.0, 0.35, 1.0],
                          ),
                        ),
                      ),

                      // Top Badge
                      if (item.badge != null)
                        Positioned(
                          top: 8.r,
                          left: 8.r,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(180),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: Colors.white.withAlpha(40), width: 0.5),
                            ),
                            child: Text(
                              item.badge!,
                              style: AppTextStyles.caption(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Selected Checkmark Badge
                      if (isSelected)
                        Positioned(
                          top: 8.r,
                          right: 8.r,
                          child: CircleAvatar(
                            radius: 10.r,
                            backgroundColor: AppColors.primaryAction,
                            child: Icon(Icons.check, size: 12.r, color: Colors.white),
                          ),
                        ),

                      // Center Play Preview Button Overlay
                      Center(
                        child: GestureDetector(
                          onTap: () => _previewTemplate(context, item),
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withAlpha(60), width: 1.r),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22.r,
                            ),
                          ),
                        ),
                      ),

                      // Bottom Info Box
                      Positioned(
                        bottom: 8.r,
                        left: 8.r,
                        right: 8.r,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.labelSmall(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.category,
                                  style: AppTextStyles.caption(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '${item.durationSeconds}s',
                                  style: AppTextStyles.caption(
                                    color: AppColors.creditGoldIcon,
                                    fontWeight: FontWeight.w600,
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
              );
            },
          ),
        ),

        SizedBox(height: 8.h),

        // Helper Guidance Tip
        Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 14.r, color: AppColors.creditGoldIcon),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                'Tip: 5–15 second clips with clear, front-facing faces produce the best results.',
                style: AppTextStyles.caption(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

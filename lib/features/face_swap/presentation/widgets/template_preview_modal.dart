import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/storage_url_resolver.dart';
import '../../../../core/widgets/aperture_indicator.dart';
import '../../domain/models/video_template.dart';

class TemplateVideoPreviewModal extends StatefulWidget {
  final VideoTemplate template;
  final File? customFile;
  final VoidCallback? onSelect;

  const TemplateVideoPreviewModal({
    super.key,
    required this.template,
    this.customFile,
    this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required VideoTemplate template,
    File? customFile,
    VoidCallback? onSelect,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TemplateVideoPreviewModal(
        template: template,
        customFile: customFile,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<TemplateVideoPreviewModal> createState() => _TemplateVideoPreviewModalState();
}

class _TemplateVideoPreviewModalState extends State<TemplateVideoPreviewModal> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  Future<void> _initPreview() async {
    try {
      if (widget.customFile != null && await widget.customFile!.exists()) {
        _videoPlayerController = VideoPlayerController.file(widget.customFile!);
      } else {
        final resolvedUrl = await StorageUrlResolver.resolveUrl(widget.template.videoUrl);
        final target = resolvedUrl.isNotEmpty ? resolvedUrl : widget.template.videoUrl;

        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(target),
          httpHeaders: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
        );
      }

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: false,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryAction,
          handleColor: AppColors.primaryAction,
          backgroundColor: AppColors.surfaceCard,
          bufferedColor: AppColors.borderSubtle,
        ),
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      Logger.e('Error initializing template preview video', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not play template video preview: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: BoxDecoration(
        color: AppColors.bgApp,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.template.title,
                        style: AppTextStyles.headingSmall(fontWeight: FontWeight.w700),
                      ),
                      if (widget.template.badge != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.accentGlowSoft,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            widget.template.badge!,
                            style: AppTextStyles.caption(
                              color: AppColors.primaryAction,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Preview Choreography & Motion (${widget.template.durationSeconds}s)',
                    style: AppTextStyles.caption(color: AppColors.textMuted),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 22.r),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Video Player Box
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderSubtle, width: 1.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ApertureIndicator(size: 40.r, color: AppColors.primaryAction),
                          SizedBox(height: 12.h),
                          Text(
                            'Loading choreography preview...',
                            style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.r),
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.bodyM(color: AppColors.statusError),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Chewie(controller: _chewieController!),
            ),
          ),

          SizedBox(height: 16.h),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
                widget.onSelect?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAction,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.check_circle_outline_rounded, size: 20.r),
              label: Text(
                'Select this Template (30 Credits)',
                style: AppTextStyles.labelLarge(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

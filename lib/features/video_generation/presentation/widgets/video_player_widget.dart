import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/aperture_indicator.dart';
import '../../../../domain/entities/job_entity.dart';
import '../../../jobs/controllers/job_controller.dart';

/// Full-page high-resolution video result player (for Face Swap & Video Gen) with save, share & delete support.
class VideoPlayerModal extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? jobId;
  final JobEntity? job;
  final VoidCallback? onClose;
  final VoidCallback? onSwapAnother;
  final String? actionButtonText;

  const VideoPlayerModal({
    super.key,
    required this.videoUrl,
    this.title,
    this.jobId,
    this.job,
    this.onClose,
    this.onSwapAnother,
    this.actionButtonText,
  });

  /// Opens the video player in a dedicated full-page screen matching ImageResultModal.
  static void show(
    BuildContext context, {
    required String videoUrl,
    String? title,
    String? jobId,
    JobEntity? job,
    VoidCallback? onClose,
    VoidCallback? onSwapAnother,
    String? actionButtonText,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => VideoPlayerModal(
          videoUrl: videoUrl,
          title: title,
          jobId: jobId,
          job: job,
          onClose: onClose,
          onSwapAnother: onSwapAnother,
          actionButtonText: actionButtonText,
        ),
      ),
    );
  }

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSharing = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<String> _getResolvedUrl() async {
    if (widget.videoUrl.startsWith('/') || widget.videoUrl.startsWith('file://')) {
      return widget.videoUrl;
    }
    final resolved = await UrlHelper.resolveStorageUrl(widget.videoUrl);
    return resolved.isNotEmpty ? resolved : widget.videoUrl;
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final targetUrl = await _getResolvedUrl();
    Logger.i('Initializing video player with URL: $targetUrl');

    try {
      if (targetUrl.startsWith('/') || targetUrl.startsWith('file://')) {
        final filePath = targetUrl.replaceFirst('file://', '');
        _videoPlayerController = VideoPlayerController.file(File(filePath));
      } else {
        // 1. Try direct network streaming with bypass headers & User-Agent
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(targetUrl),
          httpHeaders: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            ...UrlHelper.ngrokHeaders,
          },
        );
      }
      await _videoPlayerController!.initialize();
    } catch (e) {
      Logger.w('Direct video stream playback failed ($e). Retrying with local file cache fallback...');
      try {
        final localFile = await _downloadVideoToTempFile();
        if (localFile != null && await localFile.exists()) {
          await _videoPlayerController?.dispose();
          _videoPlayerController = VideoPlayerController.file(localFile);
          await _videoPlayerController!.initialize();
        } else {
          throw Exception('Could not fetch video file for local playback.');
        }
      } catch (fallbackError) {
        Logger.e('Both network and local file video playback failed', fallbackError);
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load video stream: $fallbackError';
          });
        }
        return;
      }
    }

    try {
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0
            ? _videoPlayerController!.value.aspectRatio
            : 16 / 9,
        allowFullScreen: true,
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
      Logger.e('Error initializing ChewieController', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initialize video controls: $e';
        });
      }
    }
  }

  Future<File?> _downloadVideoToTempFile() async {
    try {
      final targetUrl = await _getResolvedUrl();
      if (targetUrl.startsWith('/') || targetUrl.startsWith('file://')) {
        return File(targetUrl.replaceFirst('file://', ''));
      }
      final response = await http.get(
        Uri.parse(targetUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          ...UrlHelper.ngrokHeaders,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        Logger.w('Video download failed with status ${response.statusCode} for URL: $targetUrl');
        return null;
      }
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/ai_studio_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      Logger.e('Failed to download video to temp file', e);
      return null;
    }
  }

  Future<void> _saveVideoToGallery() async {
    setState(() => _isSaving = true);
    try {
      final file = await _downloadVideoToTempFile();
      if (file == null) {
        throw Exception('Could not download video file from server.');
      }

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      await Gal.putVideo(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video saved to your device gallery!',
              style: AppTextStyles.bodyM(color: Colors.white),
            ),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      Logger.e('Error saving video to gallery', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save video: $e',
              style: AppTextStyles.bodyM(color: Colors.white),
            ),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareVideo() async {
    setState(() => _isSharing = true);
    try {
      final file = await _downloadVideoToTempFile();
      if (file != null) {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out my AI-generated video created with AI Studio!',
        );
      } else {
        // ignore: deprecated_member_use
        await Share.share(
          'Check out my AI-generated video: ${widget.videoUrl}',
        );
      }
    } catch (e) {
      Logger.e('Error sharing video', e);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _confirmAndDelete() {
    if (widget.job == null) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: AppColors.borderSubtle, width: 1.r),
        ),
        title: Text(
          AppStrings.deleteConfirmationTitle,
          style: AppTextStyles.headingSmall(color: AppColors.bone),
        ),
        content: Text(
          AppStrings.deleteConfirmationMessage,
          style: AppTextStyles.bodyMedium(color: AppColors.slate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              AppStrings.cancel,
              style: AppTextStyles.buttonLabel(color: AppColors.slate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop(); // Close dialog
              setState(() => _isDeleting = true);
              final jobCtrl = Get.find<JobController>();
              final success = await jobCtrl.deleteJob(widget.job!);
              if (mounted) {
                setState(() => _isDeleting = false);
                Navigator.of(context).pop(); // Close full page viewer
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? AppStrings.creationDeleted
                          : '${AppStrings.deleteFailed}Failed to delete',
                      style: AppTextStyles.bodyMedium(color: AppColors.bone),
                    ),
                    backgroundColor: success
                        ? AppColors.statusSuccess
                        : AppColors.statusError,
                  ),
                );
              }
            },
            child: Text(
              AppStrings.delete,
              style: AppTextStyles.buttonLabel(color: AppColors.bone),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.title ?? 'AI Video Creation';

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header Bar ─────────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle, width: 1.r),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                      size: 24.r,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onClose?.call();
                    },
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      titleText,
                      style: AppTextStyles.headingSmall(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.job != null)
                    IconButton(
                      icon: _isDeleting
                          ? SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.r,
                                color: AppColors.statusError,
                              ),
                            )
                          : Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.statusError,
                              size: 22.r,
                            ),
                      onPressed: _isDeleting ? null : _confirmAndDelete,
                    ),
                ],
              ),
            ),

            // ── Main Video Player View ─────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.r),
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
                              ApertureIndicator(
                                size: 48.r,
                                color: AppColors.primaryAction,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'Loading video stream...',
                                style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.r),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.statusError,
                                      size: 36.r,
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      _errorMessage!,
                                      style: AppTextStyles.bodyM(color: AppColors.statusError),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16.h),
                                    ElevatedButton.icon(
                                      onPressed: _initializePlayer,
                                      icon: Icon(Icons.refresh_rounded, size: 18.r),
                                      label: const Text('Retry Playback'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.surfaceCard,
                                        foregroundColor: AppColors.bone,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Chewie(controller: _chewieController!),
                ),
              ),
            ),

            // ── Bottom Action Controls ─────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Save to Gallery Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveVideoToGallery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAction,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          icon: _isSaving
                              ? SizedBox(
                                  width: 18.r,
                                  height: 18.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.download_rounded, size: 20.r),
                          label: Text(
                            _isSaving ? 'Saving Video...' : 'Save to Device',
                            style: AppTextStyles.labelMedium(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // Share Button
                      OutlinedButton.icon(
                        onPressed: _isSharing ? null : _shareVideo,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        icon: _isSharing
                            ? SizedBox(
                                width: 18.r,
                                height: 18.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : Icon(Icons.share_rounded, size: 20.r),
                        label: Text(
                          'Share',
                          style: AppTextStyles.labelMedium(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Optional Swap Another Face action button
                  if (widget.onSwapAnother != null) ...[
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onSwapAnother?.call();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryAction,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                        ),
                        icon: Icon(Icons.sync_rounded, size: 18.r),
                        label: Text(
                          widget.actionButtonText ?? 'Swap Another Character Face',
                          style: AppTextStyles.labelMedium(
                            color: AppColors.primaryAction,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

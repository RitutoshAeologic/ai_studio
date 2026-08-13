import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/url_helper.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/job_entity.dart';
import '../../jobs/controllers/job_controller.dart';

/// Fullscreen high-resolution result viewer for image outputs (IMAGE_GEN / BG_REMOVAL / THEME_CHANGE) with delete support.
class ImageResultModal extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final String? jobId;
  final JobEntity? job;

  const ImageResultModal({
    super.key,
    required this.imageUrl,
    this.title,
    this.jobId,
    this.job,
  });

  static void show(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? jobId,
    JobEntity? job,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageResultModal(
          imageUrl: imageUrl,
          title: title,
          jobId: jobId,
          job: job,
        ),
      ),
    );
  }

  @override
  State<ImageResultModal> createState() => _ImageResultModalState();
}

class _ImageResultModalState extends State<ImageResultModal> {
  bool _isSaving = false;
  bool _isSharing = false;
  bool _isDeleting = false;

  Future<File?> _downloadTempFile() async {
    try {
      final url = await UrlHelper.resolveStorageUrl(widget.imageUrl);
      if (url.isEmpty) {
        Logger.w('Download aborted: empty image URL');
        return null;
      }
      Logger.i('Downloading image for save/share from $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: UrlHelper.ngrokHeaders,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/ai_studio_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        Logger.w('Image download failed with HTTP ${response.statusCode}');
      }
    } catch (e, st) {
      Logger.e('Error downloading image file', e, st);
    }
    return null;
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final file = await _downloadTempFile();
      if (file != null) {
        final hasAccess = await Gal.hasAccess(toAlbum: true);
        if (!hasAccess) {
          await Gal.requestAccess(toAlbum: true);
        }
        await Gal.putImage(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.savedToGallery,
                style: AppTextStyles.bodyMedium(color: AppColors.bone),
              ),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.imageNotAvailableOnServer,
                style: AppTextStyles.bodyMedium(color: AppColors.bone),
              ),
              backgroundColor: AppColors.statusError,
            ),
          );
        }
      }
    } catch (e) {
      Logger.e('Failed to save to gallery', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.saveFailed}$e',
              style: AppTextStyles.bodyMedium(color: AppColors.bone),
            ),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareImage() async {
    setState(() => _isSharing = true);
    try {
      final file = await _downloadTempFile();
      if (file != null) {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/jpeg')],
          text: AppStrings.createdWithAiStudio,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.imageNotAvailableOnServer,
                style: AppTextStyles.bodyMedium(color: AppColors.bone),
              ),
              backgroundColor: AppColors.statusError,
            ),
          );
        }
      }
    } catch (e) {
      Logger.e('Failed to share image', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.shareFailed}$e',
              style: AppTextStyles.bodyMedium(color: AppColors.bone),
            ),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
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
              Navigator.of(dialogCtx).pop();
              setState(() => _isDeleting = true);
              final jobCtrl = Get.find<JobController>();
              final success = await jobCtrl.deleteJob(widget.job!);
              if (mounted) {
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
  Widget build(BuildContext context) {
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.title ?? AppStrings.generatedResult,
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

          // ── Main Image View ────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: AppNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // ── Action Buttons ──────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.borderSubtle, width: 1.r),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _saveToGallery,
                    icon: _isSaving
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.r,
                              color: AppColors.ember,
                            ),
                          )
                        : Icon(
                            Icons.file_download_outlined,
                            color: AppColors.ember,
                            size: 18.r,
                          ),
                    label: Text(
                      _isSaving
                          ? AppStrings.savingEllipsis
                          : AppStrings.saveToGallery,
                      style: AppTextStyles.labelMedium(
                        color: AppColors.ember,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: BorderSide(
                        color: AppColors.ember,
                        width: 1.5.r,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareImage,
                    icon: _isSharing
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.r,
                              color: AppColors.bone,
                            ),
                          )
                        : Icon(
                            Icons.share_outlined,
                            color: AppColors.bone,
                            size: 18.r,
                          ),
                    label: Text(
                      _isSharing
                          ? AppStrings.sharingEllipsis
                          : AppStrings.share,
                      style: AppTextStyles.buttonLabel(
                        color: AppColors.bone,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ember,
                      foregroundColor: AppColors.bone,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}


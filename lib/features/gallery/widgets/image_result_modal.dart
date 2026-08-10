import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/aperture_indicator.dart';

/// Fullscreen high-resolution result viewer for image outputs (IMAGE_GEN / BG_REMOVAL / THEME_CHANGE).
/// Responsive layout using ScreenUtil, AppStrings, AppColors, and AppTextStyles per ui_ux.md.
class ImageResultModal extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final String? jobId;

  const ImageResultModal({
    super.key,
    required this.imageUrl,
    this.title,
    this.jobId,
  });

  static void show(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? jobId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImageResultModal(
        imageUrl: imageUrl,
        title: title,
        jobId: jobId,
      ),
    );
  }

  @override
  State<ImageResultModal> createState() => _ImageResultModalState();
}

class _ImageResultModalState extends State<ImageResultModal> {
  bool _isSaving = false;
  bool _isSharing = false;

  Future<File?> _downloadTempFile() async {
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/ai_studio_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
    }
    return null;
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final file = await _downloadTempFile();
      if (file != null) {
        await Gal.putImage(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.savedToGallery,
                style: AppTextStyles.bodyM(color: Colors.white),
              ),
              backgroundColor: AppColors.successIndicator,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.saveFailed}$e',
              style: AppTextStyles.bodyM(color: Colors.white),
            ),
            backgroundColor: AppColors.errorIndicator,
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
          [XFile(file.path)],
          text: AppStrings.createdWithAiStudio,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.shareFailed}$e',
              style: AppTextStyles.bodyM(color: Colors.white),
            ),
            backgroundColor: AppColors.errorIndicator,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.bgApp,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // ── Header Bar ─────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle, width: 1.r),
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.title ?? AppStrings.generatedResult,
                  style: AppTextStyles.headingS(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 20.r,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
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
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: ApertureIndicator(
                        size: 48.r,
                        color: AppColors.primaryAction,
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.errorIndicator,
                        size: 48.r,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Action Buttons ──────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
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
                              color: AppColors.primaryAction,
                            ),
                          )
                        : Icon(
                            Icons.file_download_outlined,
                            color: AppColors.primaryAction,
                            size: 18.r,
                          ),
                    label: Text(
                      _isSaving
                          ? AppStrings.savingEllipsis
                          : AppStrings.saveToGallery,
                      style: AppTextStyles.labelMedium(
                        color: AppColors.primaryAction,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: BorderSide(
                        color: AppColors.primaryAction,
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
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 18.r,
                          ),
                    label: Text(
                      _isSharing
                          ? AppStrings.sharingEllipsis
                          : AppStrings.share,
                      style: AppTextStyles.buttonLabel(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAction,
                      foregroundColor: Colors.white,
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
    );
  }
}

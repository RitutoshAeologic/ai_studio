import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/glb_loader_helper.dart';
import '../../../core/utils/url_helper.dart';
import '../../../core/widgets/aperture_indicator.dart';

/// Interactive 3D Mesh Renderer modal utilizing `model_viewer_plus` for rendering .glb mesh files.
/// Responsive layout using ScreenUtil, AppStrings, AppColors, and AppTextStyles per ui_ux.md.
class MeshViewerModal extends StatefulWidget {
  final String meshUrl;
  final String? title;

  const MeshViewerModal({
    super.key,
    required this.meshUrl,
    this.title,
  });

  static void show(
    BuildContext context, {
    required String meshUrl,
    String? title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeshViewerModal(meshUrl: meshUrl, title: title),
      ),
    );
  }

  @override
  State<MeshViewerModal> createState() => _MeshViewerModalState();
}

class _MeshViewerModalState extends State<MeshViewerModal> {
  late Future<String> _resolvedMeshUrlFuture;

  @override
  void initState() {
    super.initState();
    _resolvedMeshUrlFuture = GlbLoaderHelper.loadGlb(widget.meshUrl);
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentGlowSoft,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppColors.primaryAction.withAlpha(100),
                        width: 1.r,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.view_in_ar_rounded,
                          size: 14.r,
                          color: AppColors.primaryAction,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          AppStrings.tag3dMesh,
                          style: AppTextStyles.labelSmall(
                            color: AppColors.primaryAction,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.title ?? AppStrings.meshModelTitle,
                      style: AppTextStyles.headingSmall(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // ── 3D Viewport ───────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<String>(
              future: _resolvedMeshUrlFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ApertureIndicator(
                          size: 56.r,
                          color: AppColors.primaryAction,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          AppStrings.loading3dAsset,
                          style: AppTextStyles.headingSmall(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Fetching 3D .glb mesh asset…',
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final resolvedUrl =
                    snapshot.data ?? UrlHelper.normalizeUrl(widget.meshUrl);

                if (resolvedUrl.isEmpty) {
                  return Center(
                    child: Text(
                      'Failed to load 3D mesh model (.glb)',
                      style: AppTextStyles.bodyMedium(color: AppColors.statusError),
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: ModelViewer(
                    src: resolvedUrl,
                    alt: widget.title ?? '3D Mesh Model',
                    ar: false,
                    autoRotate: true,
                    cameraControls: true,
                    backgroundColor: AppColors.surfaceCard,
                  ),
                );
              },
            ),
          ),




          // ── Controls Hint Bar ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border(
                top: BorderSide(color: AppColors.borderSubtle, width: 1.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 16.r,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      AppStrings.dragToRotate,
                      style: AppTextStyles.labelMedium(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.pinch_outlined,
                      size: 16.r,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      AppStrings.pinchToZoom,
                      style: AppTextStyles.labelMedium(
                        color: AppColors.textMuted,
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
}
}


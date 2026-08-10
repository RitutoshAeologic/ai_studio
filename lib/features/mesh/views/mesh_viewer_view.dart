import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:o3d/o3d.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/aperture_indicator.dart';

/// Interactive 3D Mesh Renderer modal utilizing `o3d` for rendering .glb mesh files.
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MeshViewerModal(meshUrl: meshUrl, title: title),
    );
  }

  @override
  State<MeshViewerModal> createState() => _MeshViewerModalState();
}

class _MeshViewerModalState extends State<MeshViewerModal> {
  final O3DController _controller = O3DController();
  bool _isLoading = true;
  double _loadProgress = 0.5;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadProgress = 1.0;
        });
      }
    });
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
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textMuted,
                    size: 20.r,
                  ),
                  tooltip: AppStrings.resetCamera,
                  onPressed: () => _controller.cameraOrbit(0, 75, 105),
                ),
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

          // ── 3D Viewport ───────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: O3D.network(
                    src: widget.meshUrl,
                    controller: _controller,
                    autoRotate: true,
                    cameraControls: true,
                    backgroundColor: AppColors.surfaceCard,
                  ),
                ),

                // Explicit Loading & Progress Indicator
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: AppColors.bgApp.withAlpha(220),
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
                            '${AppStrings.fetchingGlbMeshDataPrefix}${(_loadProgress * 100).toInt()}%)',
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: 200.w,
                            child: LinearProgressIndicator(
                              value: _loadProgress > 0 ? _loadProgress : null,
                              backgroundColor: AppColors.surfaceInput,
                              color: AppColors.primaryAction,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
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
    );
  }
}

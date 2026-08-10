import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/aperture_indicator.dart';

/// Interactive 3D Mesh Renderer modal utilizing `o3d` for rendering .glb mesh files.
class MeshViewerModal extends StatefulWidget {
  final String meshUrl;
  final String? title;

  const MeshViewerModal({
    super.key,
    required this.meshUrl,
    this.title,
  });

  static void show(BuildContext context, {required String meshUrl, String? title}) {
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
      decoration: const BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Header Bar ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.signalViolet.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.signalViolet.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.view_in_ar, size: 14, color: AppColors.signalViolet),
                      const SizedBox(width: 4),
                      Text('3D MESH', style: AppTextStyles.labelSmall(color: AppColors.signalViolet)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title ?? '3D Mesh Model',
                    style: AppTextStyles.headingSmall(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_outlined, color: AppColors.slate),
                  tooltip: 'Reset Camera',
                  onPressed: () => _controller.cameraOrbit(0, 75, 105),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.slate),
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
                  borderRadius: BorderRadius.circular(12),
                  child: O3D.network(
                    src: widget.meshUrl,
                    controller: _controller,
                    autoRotate: true,
                    cameraControls: true,
                    backgroundColor: AppColors.surface,
                  ),
                ),

                // Explicit Loading & Progress Indicator
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: AppColors.ink.withAlpha(220),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const ApertureIndicator(size: 56, color: AppColors.signalViolet),
                          const SizedBox(height: 20),
                          Text(
                            'Loading 3D Asset...',
                            style: AppTextStyles.headingSmall(color: AppColors.bone),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fetching .glb mesh data (${(_loadProgress * 100).toInt()}%)',
                            style: AppTextStyles.bodySmall(color: AppColors.slate),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              value: _loadProgress > 0 ? _loadProgress : null,
                              backgroundColor: AppColors.surface,
                              color: AppColors.signalViolet,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.slate),
                    const SizedBox(width: 6),
                    Text('Drag to Rotate', style: AppTextStyles.labelMedium(color: AppColors.slate)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.pinch_outlined, size: 16, color: AppColors.slate),
                    const SizedBox(width: 6),
                    Text('Pinch to Zoom', style: AppTextStyles.labelMedium(color: AppColors.slate)),
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

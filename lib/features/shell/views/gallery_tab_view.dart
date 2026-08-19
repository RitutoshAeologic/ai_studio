import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/storage_url_resolver.dart';
import '../../../core/widgets/aperture_indicator.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../data/models/job_model.dart';
import '../../../domain/entities/job_entity.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../gallery/widgets/image_result_modal.dart';
import '../../jobs/controllers/job_controller.dart';
import '../../mesh/views/mesh_viewer_view.dart';
import '../../video_generation/presentation/widgets/video_player_widget.dart';

enum GalleryCategoryFilter {
  all,
  videos,
  images,
  meshes,
}

/// Gallery view tab displaying completed, ready-to-view creations with category filtering.
class GalleryTabView extends StatefulWidget {
  final String? initialHighlightJobId;

  const GalleryTabView({
    super.key,
    this.initialHighlightJobId,
  });

  @override
  State<GalleryTabView> createState() => _GalleryTabViewState();
}

class _GalleryTabViewState extends State<GalleryTabView> {
  GalleryCategoryFilter _activeCategory = GalleryCategoryFilter.all;

  void _confirmAndDeleteJob(BuildContext context, JobEntity job) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
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
              final jobCtrl = Get.find<JobController>();
              final success = await jobCtrl.deleteJob(job);
              if (context.mounted) {
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

  Future<void> _cleanUpMissingJobs(
      BuildContext context, List<JobEntity> allJobs) async {
    final missingJobs = allJobs
        .where((job) =>
            job.outputUrl != null &&
            job.outputUrl!.isNotEmpty &&
            StorageUrlResolver.isMissing(job.outputUrl!))
        .toList();

    if (missingJobs.isEmpty) return;

    final jobCtrl = Get.find<JobController>();
    int deletedCount = 0;
    for (final job in missingJobs) {
      final success = await jobCtrl.deleteJob(job);
      if (success) deletedCount++;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cleaned up $deletedCount missing item(s)',
            style: AppTextStyles.bodyMedium(color: AppColors.bone),
          ),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
    }
  }

  bool _matchesCategory(JobEntity job, GalleryCategoryFilter filter) {
    final isVideo = job.type == JobType.videoGen ||
        job.type == JobType.videoFaceSwap ||
        (job.outputUrl != null &&
            (job.outputUrl!.toLowerCase().contains('.mp4') ||
                job.outputUrl!.toLowerCase().contains('.mov') ||
                job.outputUrl!.toLowerCase().contains('.webm')));

    final isMesh = job.type == JobType.meshGen ||
        (job.meshUrl != null && job.meshUrl!.isNotEmpty) ||
        (job.outputUrl != null && job.outputUrl!.toLowerCase().contains('.glb'));

    switch (filter) {
      case GalleryCategoryFilter.all:
        return true;
      case GalleryCategoryFilter.videos:
        return isVideo;
      case GalleryCategoryFilter.images:
        return !isVideo && !isMesh;
      case GalleryCategoryFilter.meshes:
        return isMesh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final userId = authCtrl.currentUser.value?.uid ?? '';

    if (userId.isEmpty) {
      return Center(
        child: Text(
          AppStrings.signInToViewGallery,
          style: AppTextStyles.bodyMedium(color: AppColors.slate),
        ),
      );
    }

    final jobsQuery = FirebaseFirestore.instance
        .collection('jobs')
        .where('userId', isEqualTo: userId);

    return StreamBuilder<QuerySnapshot>(
      stream: jobsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${AppStrings.failedToLoadGallery}${snapshot.error}',
              style: AppTextStyles.bodySmall(color: AppColors.statusError),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: ApertureIndicator(
              size: 48.r,
              color: AppColors.ember,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(hasMissingItems: false, allJobs: []);
        }

        final allJobs = docs.map((doc) => JobModel.fromFirestore(doc)).toList();
        allJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // STRICT FILTER: Only show completed jobs with ready output URLs
        final completedJobs = allJobs.where((job) {
          final isCompleted = job.status == JobStatus.completed &&
              job.outputUrl != null &&
              job.outputUrl!.trim().isNotEmpty;

          if (!isCompleted) return false;
          if (StorageUrlResolver.isMissing(job.outputUrl!)) return false;
          return true;
        }).toList();

        final hasMissingItems = allJobs.any((job) =>
            job.outputUrl != null &&
            job.outputUrl!.isNotEmpty &&
            StorageUrlResolver.isMissing(job.outputUrl!));

        final filteredJobs = completedJobs
            .where((job) => _matchesCategory(job, _activeCategory))
            .toList();

        return Column(
          children: [
            // ── Category Filter Pills ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(
                      label: 'All',
                      icon: Icons.grid_view_rounded,
                      filter: GalleryCategoryFilter.all,
                      count: completedJobs.length,
                    ),
                    SizedBox(width: 8.w),
                    _buildCategoryChip(
                      label: 'Videos',
                      icon: Icons.videocam_rounded,
                      filter: GalleryCategoryFilter.videos,
                      count: completedJobs
                          .where((j) => _matchesCategory(j, GalleryCategoryFilter.videos))
                          .length,
                    ),
                    SizedBox(width: 8.w),
                    _buildCategoryChip(
                      label: 'Images',
                      icon: Icons.image_rounded,
                      filter: GalleryCategoryFilter.images,
                      count: completedJobs
                          .where((j) => _matchesCategory(j, GalleryCategoryFilter.images))
                          .length,
                    ),
                    SizedBox(width: 8.w),
                    _buildCategoryChip(
                      label: '3D Meshes',
                      icon: Icons.view_in_ar_rounded,
                      filter: GalleryCategoryFilter.meshes,
                      count: completedJobs
                          .where((j) => _matchesCategory(j, GalleryCategoryFilter.meshes))
                          .length,
                    ),
                  ],
                ),
              ),
            ),

            if (hasMissingItems)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                color: AppColors.surfaceInput,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.ember,
                      size: 18.r,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Some items were deleted on the server.',
                        style: AppTextStyles.caption(color: AppColors.slate),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _cleanUpMissingJobs(context, allJobs),
                      child: Text(
                        AppStrings.cleanupMissingItems,
                        style: AppTextStyles.labelSmall(color: AppColors.ember),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Grid of Completed Creations ──────────────────────────────────
            Expanded(
              child: filteredJobs.isEmpty
                  ? _buildEmptyCategoryState()
                  : GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: filteredJobs.length,
                      itemBuilder: (context, index) {
                        final job = filteredJobs[index];
                        return _buildGalleryCard(context, job);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required GalleryCategoryFilter filter,
    required int count,
  }) {
    final isSelected = _activeCategory == filter;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeCategory = filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ember : AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.ember : AppColors.borderSubtle,
            width: 1.r,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.ember.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.r,
              color: isSelected ? Colors.white : AppColors.slate,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: AppTextStyles.labelSmall(
                color: isSelected ? Colors.white : AppColors.bone,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withAlpha(50)
                      : AppColors.surfaceInput,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.caption(
                    color: isSelected ? Colors.white : AppColors.slate,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool hasMissingItems,
    required List<JobEntity> allJobs,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 56.r,
            color: AppColors.slate.withAlpha(120),
          ),
          SizedBox(height: 16.h),
          Text(
            AppStrings.noCreationsYet,
            style: AppTextStyles.headingMedium(color: AppColors.bone),
          ),
          SizedBox(height: 8.h),
          Text(
            'Generate videos, face swaps, images, or 3D meshes to build your gallery.',
            style: AppTextStyles.bodySmall(color: AppColors.slate),
            textAlign: TextAlign.center,
          ),
          if (hasMissingItems) ...[
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _cleanUpMissingJobs(context, allJobs),
              icon: Icon(Icons.cleaning_services_rounded, size: 18.r),
              label: Text(
                AppStrings.cleanupMissingItems,
                style: AppTextStyles.buttonLabel(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ember,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCategoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_none_rounded,
            size: 48.r,
            color: AppColors.slate.withAlpha(100),
          ),
          SizedBox(height: 12.h),
          Text(
            'No ${_activeCategory.name} creations yet',
            style: AppTextStyles.labelMedium(color: AppColors.bone, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4.h),
          Text(
            'Completed items in this category will appear here.',
            style: AppTextStyles.caption(color: AppColors.slate),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryCard(BuildContext context, JobEntity job) {
    final isVideo = job.type == JobType.videoGen ||
        job.type == JobType.videoFaceSwap ||
        (job.outputUrl != null &&
            (job.outputUrl!.toLowerCase().contains('.mp4') ||
                job.outputUrl!.toLowerCase().contains('.mov') ||
                job.outputUrl!.toLowerCase().contains('.webm')));

    final isMesh = job.type == JobType.meshGen ||
        (job.meshUrl != null && job.meshUrl!.isNotEmpty) ||
        (job.outputUrl != null && job.outputUrl!.toLowerCase().contains('.glb'));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isMesh) {
          final targetUrl = job.meshUrl ?? job.outputUrl;
          if (targetUrl != null && targetUrl.isNotEmpty) {
            MeshViewerModal.show(context, meshUrl: targetUrl);
          }
        } else if (isVideo && job.outputUrl != null && job.outputUrl!.isNotEmpty) {
          VideoPlayerModal.show(
            context,
            videoUrl: job.outputUrl!,
            title: job.params.userPrompt ??
                (job.type == JobType.videoFaceSwap
                    ? 'AI Face Swap Video'
                    : 'AI Video Result'),
            job: job,
          );
        } else if (job.outputUrl != null && job.outputUrl!.isNotEmpty) {
          ImageResultModal.show(context, imageUrl: job.outputUrl!, job: job);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderSubtle, width: 1.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Stack(
          children: [
            // Preview Media
            if (isVideo)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF161922),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (job.params.imageUrl != null && job.params.imageUrl!.isNotEmpty)
                        Positioned.fill(
                          child: AppNetworkImage(
                            imageUrl: job.params.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Container(
                        color: Colors.black.withAlpha(60),
                      ),
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(80), width: 1.r),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 26.r,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isMesh)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF161922),
                  child: Center(
                    child: Icon(
                      Icons.view_in_ar_rounded,
                      size: 48.r,
                      color: AppColors.ember,
                    ),
                  ),
                ),
              )
            else if (job.outputUrl != null && job.outputUrl!.isNotEmpty)
              Positioned.fill(
                child: AppNetworkImage(
                  imageUrl: job.outputUrl!,
                  fit: BoxFit.cover,
                ),
              ),

            // Top Badge / Type Indicator
            Positioned(
              top: 8.r,
              left: 8.r,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(190),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.white.withAlpha(40), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVideo
                          ? (job.type == JobType.videoFaceSwap
                              ? Icons.face_retouching_natural_rounded
                              : Icons.videocam_rounded)
                          : isMesh
                              ? Icons.view_in_ar_rounded
                              : Icons.image_rounded,
                      size: 11.r,
                      color: AppColors.ember,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isVideo
                          ? (job.type == JobType.videoFaceSwap ? 'Face Swap' : 'Video')
                          : isMesh
                              ? '3D Mesh'
                              : 'Image',
                      style: AppTextStyles.caption(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Right Delete Overflow Button
            Positioned(
              top: 4.r,
              right: 4.r,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white70,
                    size: 18.r,
                  ),
                  onPressed: () => _confirmAndDeleteJob(context, job),
                  tooltip: AppStrings.delete,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),

            // Bottom Gradient Overlay & Title
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(220),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  job.params.userPrompt?.isNotEmpty == true
                      ? job.params.userPrompt!
                      : (job.type == JobType.videoFaceSwap
                          ? 'Dance Face Swap'
                          : 'AI Creation'),
                  style: AppTextStyles.caption(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

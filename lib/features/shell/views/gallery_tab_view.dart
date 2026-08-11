import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
import '../../jobs/widgets/job_status_chip.dart';
import '../../mesh/views/mesh_viewer_view.dart';

/// Gallery view tab displaying live history of generated assets with delete & auto-cleanup support.
class GalleryTabView extends StatelessWidget {
  const GalleryTabView({super.key});

  void _confirmAndDeleteJob(BuildContext context, JobEntity job) {
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

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final userId = authCtrl.currentUser.value?.uid ?? '';

    if (userId.isEmpty) {
      return Center(
        child: Text(
          AppStrings.signInToViewGallery,
          style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
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
              style: AppTextStyles.bodySmall(color: AppColors.errorIndicator),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: ApertureIndicator(
              size: 48.r,
              color: AppColors.primaryAction,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 56.r,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 16.h),
                Text(
                  AppStrings.noCreationsYet,
                  style: AppTextStyles.headingMedium(),
                ),
                SizedBox(height: 8.h),
                Text(
                  AppStrings.creationsSubtitle,
                  style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        final allJobs =
            docs.map((doc) => JobModel.fromFirestore(doc)).toList();
        allJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Filter out jobs whose storage asset has been confirmed missing (404)
        final jobs = allJobs.where((job) {
          if (job.outputUrl != null && job.outputUrl!.isNotEmpty) {
            return !StorageUrlResolver.isMissing(job.outputUrl!);
          }
          return true;
        }).toList();

        final hasMissingItems = allJobs.length > jobs.length;

        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 56.r,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 16.h),
                Text(
                  AppStrings.noCreationsYet,
                  style: AppTextStyles.headingMedium(),
                ),
                SizedBox(height: 8.h),
                Text(
                  AppStrings.creationsSubtitle,
                  style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                ),
                if (hasMissingItems) ...[
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () => _cleanUpMissingJobs(context, allJobs),
                    icon: Icon(Icons.cleaning_services_rounded, size: 18.r),
                    label: Text(
                      AppStrings.cleanupMissingItems,
                      style: AppTextStyles.buttonLabel(color: AppColors.bone),
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

        return Column(
          children: [
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
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16.r),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 0.85,
                ),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return _buildGalleryCard(context, job);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGalleryCard(BuildContext context, JobEntity job) {
    return GestureDetector(
      onTap: () {
        if (job.status == JobStatus.completed) {
          if (job.type == JobType.meshGen && job.meshUrl != null) {
            MeshViewerModal.show(context, meshUrl: job.meshUrl!);
          } else if (job.outputUrl != null) {
            ImageResultModal.show(context, imageUrl: job.outputUrl!, job: job);
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderSubtle, width: 1.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Preview Content
            if (job.outputUrl != null && job.outputUrl!.isNotEmpty)
              Positioned.fill(
                child: AppNetworkImage(
                  imageUrl: job.outputUrl!,
                  fit: BoxFit.cover,
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: AppColors.surfaceInput,
                  child: Center(
                    child: Icon(
                      job.type == JobType.meshGen
                          ? Icons.view_in_ar_rounded
                          : Icons.auto_awesome_rounded,
                      size: 36.r,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),

            // Top Status Chip Overlay
            Positioned(
              top: 8.h,
              left: 8.w,
              child: JobStatusChip(status: job.status),
            ),

            // Top-Right Delete Icon Button
            Positioned(
              top: 6.h,
              right: 6.w,
              child: GestureDetector(
                onTap: () => _confirmAndDeleteJob(context, job),
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: AppColors.bgApp.withAlpha(200),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.borderSubtle, width: 1.r),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.statusError,
                    size: 16.r,
                  ),
                ),
              ),
            ),

            // Bottom Type Title Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                color: AppColors.bgApp.withAlpha(220),
                child: Text(
                  job.type == JobType.meshGen
                      ? AppStrings.meshModelTitle
                      : job.params.userPrompt ?? AppStrings.aiCreationTitle,
                  style:
                      AppTextStyles.labelSmall(color: AppColors.textPrimary),
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

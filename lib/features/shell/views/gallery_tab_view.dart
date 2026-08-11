import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/url_helper.dart';
import '../../../core/widgets/aperture_indicator.dart';
import '../../../data/models/job_model.dart';
import '../../../domain/entities/job_entity.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../gallery/widgets/image_result_modal.dart';
import '../../jobs/widgets/job_status_chip.dart';
import '../../mesh/views/mesh_viewer_view.dart';

/// Gallery view tab displaying live history of generated assets.
/// Responsive layout using ScreenUtil, AppStrings, AppColors, and AppTextStyles per ui_ux.md.
class GalleryTabView extends StatelessWidget {
  const GalleryTabView({super.key});

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

        final jobs = docs.map((doc) => JobModel.fromFirestore(doc)).toList();
        jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return GridView.builder(
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
            ImageResultModal.show(context, imageUrl: job.outputUrl!);
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
                child: CachedNetworkImage(
                  imageUrl: UrlHelper.normalizeUrl(job.outputUrl!),
                  httpHeaders: UrlHelper.ngrokHeaders,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: ApertureIndicator(
                      size: 28.r,
                      color: AppColors.ember,
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.slate,
                      size: 32.r,
                    ),
                  ),
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

            // Bottom Type Title Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                color: AppColors.bgApp.withAlpha(220),
                child: Text(
                  job.type == JobType.meshGen
                      ? AppStrings.meshModelTitle
                      : job.params.userPrompt ?? AppStrings.aiCreationTitle,
                  style: AppTextStyles.labelSmall(color: AppColors.textPrimary),
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

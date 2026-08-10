import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/aperture_indicator.dart';
import '../../../data/models/job_model.dart';
import '../../../domain/entities/job_entity.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../gallery/widgets/image_result_modal.dart';
import '../../jobs/widgets/job_status_chip.dart';
import '../../mesh/views/mesh_viewer_view.dart';

/// Gallery view tab displaying live history of generated assets.
class GalleryTabView extends StatelessWidget {
  const GalleryTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final userId = authCtrl.currentUser.value?.uid ?? '';

    if (userId.isEmpty) {
      return Center(
        child: Text('Please sign in to view gallery', style: AppTextStyles.bodyMedium(color: AppColors.slate)),
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
            child: Text('Failed to load gallery: ${snapshot.error}', style: AppTextStyles.bodySmall(color: AppColors.statusError)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: ApertureIndicator(size: 48, color: AppColors.ember),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library_outlined, size: 56, color: AppColors.slate),
                const SizedBox(height: 16),
                Text('No Creations Yet', style: AppTextStyles.headingMedium()),
                const SizedBox(height: 8),
                Text(
                  'Your generated images and 3D models will appear here.',
                  style: AppTextStyles.bodySmall(color: AppColors.slate),
                ),
              ],
            ),
          );
        }

        final jobs = docs.map((doc) => JobModel.fromFirestore(doc)).toList();
        jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Preview Content
            if (job.outputUrl != null && job.outputUrl!.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: job.outputUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: ApertureIndicator(size: 28, color: AppColors.ember),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image, color: AppColors.slate),
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
                          ? Icons.view_in_ar
                          : Icons.auto_awesome,
                      size: 36,
                      color: AppColors.slate,
                    ),
                  ),
                ),
              ),

            // Top Status Chip Overlay
            Positioned(
              top: 8,
              left: 8,
              child: JobStatusChip(status: job.status),
            ),

            // Bottom Type Title Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: AppColors.ink.withAlpha(210),
                child: Text(
                  job.type == JobType.meshGen
                      ? '3D Mesh Model'
                      : job.params.userPrompt ?? 'AI Creation',
                  style: AppTextStyles.labelSmall(color: AppColors.bone),
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

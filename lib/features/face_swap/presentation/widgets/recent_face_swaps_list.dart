import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../data/models/job_model.dart';
import '../../../../domain/entities/job_entity.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../video_generation/presentation/widgets/video_player_widget.dart';

class RecentFaceSwapsList extends StatelessWidget {
  final VoidCallback? onSwapAnother;

  const RecentFaceSwapsList({
    super.key,
    this.onSwapAnother,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final userId = authCtrl.currentUser.value?.uid;

    if (userId == null || userId.isEmpty) {
      return const SizedBox.shrink();
    }

    final query = FirebaseFirestore.instance
        .collection('jobs')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: JobType.videoFaceSwap.firestoreValue);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final jobs = docs.map((d) => JobModel.fromFirestore(d)).toList();
        jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: AppColors.primaryAction,
                      size: 18.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Recent Face Swaps',
                      style: AppTextStyles.labelMedium(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '${jobs.length}',
                    style: AppTextStyles.caption(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            SizedBox(
              height: 110.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: jobs.length,
                separatorBuilder: (_, _) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  final isCompleted = job.status == JobStatus.completed &&
                      job.outputUrl != null &&
                      job.outputUrl!.isNotEmpty;
                  final isProcessing = job.status == JobStatus.processing ||
                      job.status == JobStatus.pending ||
                      job.status == JobStatus.queued;

                  return GestureDetector(
                    onTap: () {
                      if (isCompleted) {
                        HapticFeedback.lightImpact();
                        VideoPlayerModal.show(
                          context,
                          videoUrl: job.outputUrl!,
                          onSwapAnother: onSwapAnother,
                        );
                      }
                    },
                    child: Container(
                      width: 140.w,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.borderSubtle
                              : isProcessing
                                  ? AppColors.primaryAction
                                  : AppColors.statusError.withAlpha(120),
                          width: 1.r,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Image / Icon
                          if (job.params.imageUrl != null && job.params.imageUrl!.isNotEmpty)
                            AppNetworkImage(
                              imageUrl: job.params.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              color: AppColors.surfaceInput,
                              child: Center(
                                child: Icon(
                                  Icons.video_library_outlined,
                                  color: AppColors.textMuted,
                                  size: 28.r,
                                ),
                              ),
                            ),

                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withAlpha(40),
                                  Colors.transparent,
                                  Colors.black.withAlpha(210),
                                ],
                              ),
                            ),
                          ),

                          // Center Status or Play Icon
                          Center(
                            child: isProcessing
                                ? SizedBox(
                                    width: 22.r,
                                    height: 22.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primaryAction,
                                    ),
                                  )
                                : isCompleted
                                    ? Container(
                                        padding: EdgeInsets.all(6.r),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(160),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 18.r,
                                        ),
                                      )
                                    : Icon(
                                        Icons.error_outline_rounded,
                                        color: AppColors.statusError,
                                        size: 22.r,
                                      ),
                          ),

                          // Bottom Status & Time Label
                          Positioned(
                            bottom: 6.h,
                            left: 6.w,
                            right: 6.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    isCompleted
                                        ? 'Ready'
                                        : isProcessing
                                            ? 'Rendering'
                                            : 'Failed',
                                    style: AppTextStyles.caption(
                                      color: isCompleted
                                          ? AppColors.statusSuccess
                                          : isProcessing
                                              ? AppColors.primaryAction
                                              : AppColors.statusError,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  _formatTimeAgo(job.createdAt),
                                  style: AppTextStyles.caption(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

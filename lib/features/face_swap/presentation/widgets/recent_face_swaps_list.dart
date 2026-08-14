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

/// Renders a horizontal gallery of ONLY successfully generated and ready Face Swap videos.
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

        // Only include completed jobs with valid output video URLs
        final readyJobs = docs
            .map((d) => JobModel.fromFirestore(d))
            .where((j) =>
                j.status == JobStatus.completed &&
                j.outputUrl != null &&
                j.outputUrl!.trim().isNotEmpty)
            .toList();

        readyJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (readyJobs.isEmpty) {
          return const SizedBox.shrink();
        }

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
                      color: AppColors.ember,
                      size: 18.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Recent Face Swaps',
                      style: AppTextStyles.labelMedium(
                        color: AppColors.bone,
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
                    '${readyJobs.length}',
                    style: AppTextStyles.caption(
                      color: AppColors.slate,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            SizedBox(
              height: 120.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: readyJobs.length,
                separatorBuilder: (_, _) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final job = readyJobs[index];

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      VideoPlayerModal.show(
                        context,
                        videoUrl: job.outputUrl!,
                        onSwapAnother: onSwapAnother,
                      );
                    },
                    child: Container(
                      width: 130.w,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.r,
                        ),
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
                        fit: StackFit.expand,
                        children: [
                          // Background Image
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
                                  Icons.movie_creation_outlined,
                                  color: AppColors.slate,
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
                                  Colors.black.withAlpha(30),
                                  Colors.transparent,
                                  Colors.black.withAlpha(220),
                                ],
                              ),
                            ),
                          ),

                          // Center Play Icon
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(160),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withAlpha(80), width: 1.r),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20.r,
                              ),
                            ),
                          ),

                          // Bottom Ready & Time Tag
                          Positioned(
                            bottom: 8.h,
                            left: 8.w,
                            right: 8.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusSuccess.withAlpha(40),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(color: AppColors.statusSuccess.withAlpha(120), width: 0.5),
                                  ),
                                  child: Text(
                                    'Ready',
                                    style: AppTextStyles.caption(
                                      color: AppColors.statusSuccess,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
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

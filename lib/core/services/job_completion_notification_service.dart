import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../data/models/job_model.dart';
import '../../domain/entities/job_entity.dart';
import '../../features/shell/controllers/home_shell_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../utils/logger.dart';

class JobCompletionNotificationService {
  JobCompletionNotificationService._();
  static final JobCompletionNotificationService instance =
      JobCompletionNotificationService._();

  StreamSubscription? _jobsSubscription;
  final Set<String> _knownJobIds = {};
  final Set<String> _notifiedJobIds = {};
  bool _isInitialSnapshot = true;

  void startListening(String userId) {
    if (userId.isEmpty) return;
    stopListening();

    _isInitialSnapshot = true;
    _knownJobIds.clear();

    Logger.i('[JobNotification] Starting real-time job completion monitor for user: $userId');

    final jobsQuery = FirebaseFirestore.instance
        .collection('jobs')
        .where('userId', isEqualTo: userId);

    _jobsSubscription = jobsQuery.snapshots().listen((snapshot) {
      if (_isInitialSnapshot) {
        // Record all existing jobs so we don't spam notifications on app startup
        for (final doc in snapshot.docs) {
          _knownJobIds.add(doc.id);
        }
        _isInitialSnapshot = false;
        return;
      }

      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final jobId = change.doc.id;
        final statusStr = data['status'] as String? ?? '';
        final isCompleted = statusStr.toLowerCase() == 'completed';

        if (isCompleted && !_notifiedJobIds.contains(jobId)) {
          // If this was a newly added job or a modified job that reached completed
          final job = JobModel.fromFirestore(change.doc);
          _notifiedJobIds.add(jobId);
          _showJobCompletionNotification(job);
        }
      }
    }, onError: (e) {
      Logger.w('[JobNotification] Error monitoring jobs: $e');
    });
  }

  void stopListening() {
    _jobsSubscription?.cancel();
    _jobsSubscription = null;
    _knownJobIds.clear();
  }

  void _showJobCompletionNotification(JobEntity job) {
    HapticFeedback.heavyImpact();
    Logger.i('[JobNotification] Triggering completion notification for job: ${job.jobId}');

    final isVideo = job.type == JobType.videoGen ||
        job.type == JobType.videoFaceSwap ||
        (job.outputUrl != null &&
            (job.outputUrl!.toLowerCase().contains('.mp4') ||
                job.outputUrl!.toLowerCase().contains('.mov') ||
                job.outputUrl!.toLowerCase().contains('.webm')));

    final isMesh = job.type == JobType.meshGen ||
        (job.meshUrl != null && job.meshUrl!.isNotEmpty) ||
        (job.outputUrl != null && job.outputUrl!.toLowerCase().contains('.glb'));

    final title = isVideo
        ? (job.type == JobType.videoFaceSwap
            ? '✨ Your AI Dance Video is Ready!'
            : '✨ Your AI Video is Ready!')
        : isMesh
            ? '✨ Your 3D Mesh is Ready!'
            : '✨ Your AI Image is Ready!';

    final message = isVideo
        ? 'Tap to watch your generated video in the Gallery.'
        : 'Tap to view your new creation in the Gallery.';

    Get.rawSnackbar(
      titleText: Row(
        children: [
          Icon(
            isVideo
                ? Icons.videocam_rounded
                : isMesh
                    ? Icons.view_in_ar_rounded
                    : Icons.auto_awesome_rounded,
            color: AppColors.ember,
            size: 18.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.labelMedium(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      messageText: Text(
        message,
        style: AppTextStyles.caption(color: AppColors.bone),
      ),
      duration: const Duration(seconds: 6),
      backgroundColor: const Color(0xFF1E212B),
      snackStyle: SnackStyle.FLOATING,
      margin: EdgeInsets.all(16.r),
      borderRadius: 16.r,
      borderColor: AppColors.ember.withAlpha(120),
      borderWidth: 1.5.r,
      boxShadows: [
        BoxShadow(
          color: AppColors.ember.withAlpha(60),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
      mainButton: Container(
        margin: EdgeInsets.only(right: 8.w),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ember,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          onPressed: () {
            if (Get.isSnackbarOpen) {
              Get.back();
            }
            if (Get.isRegistered<HomeShellController>()) {
              Get.find<HomeShellController>().openJobInGallery(job);
            }
          },
          child: Text(
            isVideo ? 'Watch' : 'View',
            style: AppTextStyles.labelSmall(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      onTap: (_) {
        if (Get.isSnackbarOpen) {
          Get.back();
        }
        if (Get.isRegistered<HomeShellController>()) {
          Get.find<HomeShellController>().openJobInGallery(job);
        }
      },
    );
  }
}

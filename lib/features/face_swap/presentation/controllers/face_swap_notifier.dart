import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/storage_url_resolver.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../wallet/controllers/wallet_controller.dart';
import '../../data/models/face_swap_request.dart';
import '../../data/services/face_swap_api_service.dart';
import '../../domain/models/video_template.dart';

enum FaceSwapStatus {
  idle,
  checkingCredits,
  uploadingAssets,
  submitting,
  processing,
  completed,
  error,
}

class FaceSwapState {
  final FaceSwapStatus status;
  final VideoTemplate selectedTemplate;
  final File? customVideoFile;
  final File? sourceFaceFile;
  final int requiredCredits;
  final String? jobId;
  final String? activeStageMessage;
  final double progressPercent;
  final String? videoUrl;
  final String? errorMessage;

  const FaceSwapState({
    this.status = FaceSwapStatus.idle,
    required this.selectedTemplate,
    this.customVideoFile,
    this.sourceFaceFile,
    this.requiredCredits = 30,
    this.jobId,
    this.activeStageMessage,
    this.progressPercent = 0.0,
    this.videoUrl,
    this.errorMessage,
  });

  FaceSwapState copyWith({
    FaceSwapStatus? status,
    VideoTemplate? selectedTemplate,
    File? customVideoFile,
    bool clearCustomVideo = false,
    File? sourceFaceFile,
    bool clearSourceFace = false,
    int? requiredCredits,
    String? jobId,
    String? activeStageMessage,
    double? progressPercent,
    String? videoUrl,
    String? errorMessage,
  }) {
    return FaceSwapState(
      status: status ?? this.status,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      customVideoFile: clearCustomVideo ? null : (customVideoFile ?? this.customVideoFile),
      sourceFaceFile: clearSourceFace ? null : (sourceFaceFile ?? this.sourceFaceFile),
      requiredCredits: requiredCredits ?? this.requiredCredits,
      jobId: jobId ?? this.jobId,
      activeStageMessage: activeStageMessage ?? this.activeStageMessage,
      progressPercent: progressPercent ?? this.progressPercent,
      videoUrl: videoUrl ?? this.videoUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FaceSwapController extends GetxController {
  final FaceSwapApiService _apiService;
  final ImageUploadService _uploadService;

  late final Rx<FaceSwapState> state;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _jobSubscription;
  Timer? _estimatedProgressTimer;
  Timer? _pollingTimer;

  FaceSwapController({
    FaceSwapApiService? apiService,
    ImageUploadService? uploadService,
  })  : _apiService = apiService ?? FaceSwapApiService(),
        _uploadService = uploadService ?? ImageUploadService() {
    state = FaceSwapState(
      selectedTemplate: VideoTemplate.catalog.first,
    ).obs;
  }

  void selectTemplate(VideoTemplate template) {
    state.value = state.value.copyWith(
      selectedTemplate: template,
      clearCustomVideo: !template.isCustom,
    );
  }

  void setCustomVideo(File file) {
    final customTemplate = VideoTemplate(
      id: 'custom_video_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Custom Video',
      category: 'Custom',
      videoUrl: '',
      thumbnailUrl: '',
      isCustom: true,
      badge: '📁 Custom',
    );

    state.value = state.value.copyWith(
      selectedTemplate: customTemplate,
      customVideoFile: file,
    );
  }

  void setSourceFaceImage(File? file) {
    if (file == null) {
      state.value = state.value.copyWith(clearSourceFace: true);
    } else {
      state.value = state.value.copyWith(sourceFaceFile: file);
    }
  }

  void resetState() {
    _jobSubscription?.cancel();
    _estimatedProgressTimer?.cancel();
    _pollingTimer?.cancel();

    state.value = FaceSwapState(
      selectedTemplate: VideoTemplate.catalog.first,
    );
  }

  Future<void> submitFaceSwap() async {
    final currentState = state.value;
    if (currentState.sourceFaceFile == null) {
      state.value = currentState.copyWith(
        status: FaceSwapStatus.error,
        errorMessage: 'Please select a character face photo to swap.',
      );
      return;
    }

    if (currentState.selectedTemplate.isCustom && currentState.customVideoFile == null) {
      state.value = currentState.copyWith(
        status: FaceSwapStatus.error,
        errorMessage: 'Please choose or upload a custom video file.',
      );
      return;
    }

    // 1. Check Wallet Credits
    state.value = currentState.copyWith(
      status: FaceSwapStatus.checkingCredits,
      activeStageMessage: 'Validating credits & security...',
      progressPercent: 0.05,
    );

    final walletCtrl = Get.find<WalletController>();
    final balance = walletCtrl.wallet.value?.balance ?? 0;
    if (balance < currentState.requiredCredits) {
      state.value = currentState.copyWith(
        status: FaceSwapStatus.error,
        errorMessage: 'Insufficient balance: $balance credits available (${currentState.requiredCredits} credits required).',
      );
      return;
    }

    final authCtrl = Get.find<AuthController>();
    final userId = authCtrl.currentUser.value?.uid ?? 'anonymous_user';

    // 2. Upload Assets
    state.value = state.value.copyWith(
      status: FaceSwapStatus.uploadingAssets,
      activeStageMessage: 'Uploading character face photo to cloud...',
      progressPercent: 0.15,
    );

    String sourceFaceUrl = '';
    final faceUploadResult = await _uploadService.uploadImage(
      file: currentState.sourceFaceFile!,
      userId: userId,
    );

    faceUploadResult.fold(
      (success) => sourceFaceUrl = success.downloadUrl,
      (failure) {
        state.value = state.value.copyWith(
          status: FaceSwapStatus.error,
          errorMessage: 'Failed to upload face image: ${failure.message}',
        );
      },
    );

    if (sourceFaceUrl.isEmpty) return;

    // Upload custom video if user picked a local file
    String targetVideoUrl = currentState.selectedTemplate.videoUrl;
    if (currentState.selectedTemplate.isCustom && currentState.customVideoFile != null) {
      state.value = state.value.copyWith(
        activeStageMessage: 'Uploading custom target video...',
        progressPercent: 0.25,
      );

      final videoUploadResult = await _uploadService.uploadVideo(
        file: currentState.customVideoFile!,
        userId: userId,
      );

      videoUploadResult.fold(
        (success) => targetVideoUrl = success.downloadUrl,
        (failure) {
          state.value = state.value.copyWith(
            status: FaceSwapStatus.error,
            errorMessage: 'Failed to upload custom video: ${failure.message}',
          );
        },
      );

      if (targetVideoUrl.isEmpty) return;
    }

    // 3. Dispatch Job to Backend API
    state.value = state.value.copyWith(
      status: FaceSwapStatus.submitting,
      activeStageMessage: 'Dispatching face swap task to AI worker...',
      progressPercent: 0.35,
    );

    try {
      final request = FaceSwapRequest(
        targetVideoUrl: targetVideoUrl,
        sourceImageUrl: sourceFaceUrl,
        title: currentState.selectedTemplate.title,
      );

      final response = await _apiService.submitFaceSwapJob(request);

      state.value = state.value.copyWith(
        status: FaceSwapStatus.processing,
        jobId: response.jobId,
        activeStageMessage: 'Detecting facial landmarks & aligning face in video...',
        progressPercent: 0.40,
      );

      _subscribeToJobUpdates(response.jobId);
    } catch (e) {
      Logger.e('Error submitting face swap job', e);
      state.value = state.value.copyWith(
        status: FaceSwapStatus.error,
        errorMessage: _formatErrorMessage(e.toString()),
      );
    }
  }

  String _formatErrorMessage(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Face swap processing encountered an issue. Your credits have not been deducted. Please try again.';
    }
    final clean = raw.replaceAll('Exception: ', '').replaceAll('DioException [bad response]: ', '').trim();
    final lower = clean.toLowerCase();
    if (lower.contains('no face') ||
        lower.contains('face not detected') ||
        lower.contains('insightface') ||
        lower.contains('landmark')) {
      return 'No clear face found in photo/video. Please upload a well-lit, front-facing portrait.';
    }
    if (lower.contains('403') ||
        lower.contains('forbidden') ||
        lower.contains('404') ||
        lower.contains('not found') ||
        lower.contains('download') ||
        lower.contains('storage')) {
      return 'Unable to access template video ($clean). Please try uploading another video.';
    }
    if (lower.contains('insufficient') ||
        lower.contains('credit') ||
        lower.contains('balance')) {
      return 'Insufficient credits (30 credits required). Tap below to top up your balance.';
    }
    if (lower.contains('timeout') ||
        lower.contains('timed out')) {
      return 'Connection timed out. Your credits were not deducted. Please check your internet connection and try again.';
    }
    if (lower.contains('ffmpeg') || lower.contains('codec') || lower.contains('corrupted')) {
      return 'Video encoding issue: $clean';
    }
    if (clean.isNotEmpty && !clean.contains('Instance of')) {
      return clean;
    }
    return 'AI face swap failed. Your credits have not been deducted. Please try again.';
  }

  void _subscribeToJobUpdates(String jobId) {
    _jobSubscription?.cancel();
    _estimatedProgressTimer?.cancel();
    _pollingTimer?.cancel();

    // Start estimated smooth progress simulation (25-45s)
    int elapsed = 0;
    _estimatedProgressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsed++;
      if (state.value.status != FaceSwapStatus.processing) {
        timer.cancel();
        return;
      }

      final estProgress = (0.40 + (elapsed / 35) * 0.55).clamp(0.40, 0.95);
      state.value = state.value.copyWith(progressPercent: estProgress);
    });

    // 1. Live Firestore Realtime Stream
    _jobSubscription = _apiService.watchJobStatus(jobId).listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return;
        final data = snapshot.data()!;
        final statusStr = (data['status'] as String?) ?? 'pending';
        final outputUrl = data['outputUrl'] as String? ?? data['output_url'] as String? ?? data['videoUrl'] as String?;
        final errorMsg = data['error'] as String? ?? data['errorMessage'] as String?;
        final stage = data['stage'] as String? ?? data['stageMessage'] as String?;

        _handleJobStatusUpdate(
          statusStr: statusStr,
          outputUrl: outputUrl,
          stage: stage,
          errorMsg: errorMsg,
        );
      },
      onError: (e) {
        Logger.w('Firestore stream error in face swap, relying on REST polling: $e');
      },
    );

    // 2. Fallback REST Polling (Every 4 seconds)
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (state.value.status != FaceSwapStatus.processing) {
        timer.cancel();
        return;
      }

      try {
        final statusResp = await _apiService.pollJobStatus(jobId);
        _handleJobStatusUpdate(
          statusStr: statusResp.status,
          outputUrl: statusResp.outputUrl,
          stage: statusResp.stage,
          errorMsg: statusResp.error,
        );
      } catch (e) {
        Logger.w('Face swap REST polling error: $e');
      }
    });
  }

  void _handleJobStatusUpdate({
    required String statusStr,
    String? outputUrl,
    String? stage,
    String? errorMsg,
  }) {
    if (statusStr == 'pending') {
      state.value = state.value.copyWith(
        status: FaceSwapStatus.processing,
        activeStageMessage: stage ?? 'Job queued in AI face-swap worker...',
      );
    } else if (statusStr == 'processing') {
      state.value = state.value.copyWith(
        status: FaceSwapStatus.processing,
        activeStageMessage: stage ?? 'Rendering face-swapped video frames...',
      );
    } else if (statusStr == 'completed') {
      _jobSubscription?.cancel();
      _estimatedProgressTimer?.cancel();
      _pollingTimer?.cancel();

      final rawUrl = outputUrl ?? '';
      if (rawUrl.isEmpty) {
        state.value = state.value.copyWith(
          status: FaceSwapStatus.completed,
          progressPercent: 1.0,
          activeStageMessage: 'Face swap video completed!',
        );
        return;
      }

      state.value = state.value.copyWith(
        progressPercent: 1.0,
        activeStageMessage: 'Finalizing video player...',
      );

      StorageUrlResolver.resolveUrl(rawUrl).then((resolved) {
        final finalUrl = resolved.isNotEmpty ? resolved : rawUrl;
        state.value = state.value.copyWith(
          status: FaceSwapStatus.completed,
          progressPercent: 1.0,
          videoUrl: finalUrl,
          activeStageMessage: 'Face swap video completed!',
        );
      }).catchError((_) {
        state.value = state.value.copyWith(
          status: FaceSwapStatus.completed,
          progressPercent: 1.0,
          videoUrl: rawUrl,
          activeStageMessage: 'Face swap video completed!',
        );
      });
    } else if (statusStr == 'error' || statusStr == 'failed') {
      _jobSubscription?.cancel();
      _estimatedProgressTimer?.cancel();
      _pollingTimer?.cancel();

      state.value = state.value.copyWith(
        status: FaceSwapStatus.error,
        errorMessage: _formatErrorMessage(errorMsg),
      );
    }
  }

  @override
  void onClose() {
    _jobSubscription?.cancel();
    _estimatedProgressTimer?.cancel();
    _pollingTimer?.cancel();
    super.onClose();
  }
}

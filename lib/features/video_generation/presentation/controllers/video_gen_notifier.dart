import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/storage_url_resolver.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../wallet/controllers/wallet_controller.dart';
import '../../data/services/video_api_service.dart';

enum VideoGenStatus {
  idle,
  uploadingAssets,
  checkingCredits,
  submitting,
  processing,
  completed,
  error,
}

class VideoGenState {
  final VideoGenStatus status;
  final String? jobId;
  final String? activeStageMessage;
  final double progressPercent;
  final String? videoUrl;
  final String? errorMessage;
  final int selectedDuration; // 10 or 15
  final String selectedAspectRatio; // "16:9", "9:16", "1:1"
  final List<File> localImages;
  final List<String> uploadedImageUrls;

  VideoGenState({
    this.status = VideoGenStatus.idle,
    this.jobId,
    this.activeStageMessage,
    this.progressPercent = 0.0,
    this.videoUrl,
    this.errorMessage,
    this.selectedDuration = 10,
    this.selectedAspectRatio = '16:9',
    this.localImages = const [],
    this.uploadedImageUrls = const [],
  });

  VideoGenState copyWith({
    VideoGenStatus? status,
    String? jobId,
    String? activeStageMessage,
    double? progressPercent,
    String? videoUrl,
    String? errorMessage,
    int? selectedDuration,
    String? selectedAspectRatio,
    List<File>? localImages,
    List<String>? uploadedImageUrls,
  }) {
    return VideoGenState(
      status: status ?? this.status,
      jobId: jobId ?? this.jobId,
      activeStageMessage: activeStageMessage ?? this.activeStageMessage,
      progressPercent: progressPercent ?? this.progressPercent,
      videoUrl: videoUrl ?? this.videoUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      selectedAspectRatio: selectedAspectRatio ?? this.selectedAspectRatio,
      localImages: localImages ?? this.localImages,
      uploadedImageUrls: uploadedImageUrls ?? this.uploadedImageUrls,
    );
  }

  int get requiredCredits => selectedDuration == 15 ? 50 : 40;
}

class VideoGenController extends GetxController {
  final VideoApiService _apiService;
  final ImageUploadService _uploadService;

  VideoGenController({
    VideoApiService? apiService,
    ImageUploadService? uploadService,
  })  : _apiService = apiService ?? VideoApiService(),
        _uploadService = uploadService ?? ImageUploadService();

  final Rx<VideoGenState> state = VideoGenState().obs;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _jobSubscription;
  Timer? _estimatedProgressTimer;

  int get requiredCredits => state.value.requiredCredits;

  void setDuration(int duration) {
    if (duration == 10 || duration == 15) {
      state.value = state.value.copyWith(selectedDuration: duration);
    }
  }

  void setAspectRatio(String ratio) {
    state.value = state.value.copyWith(selectedAspectRatio: ratio);
  }

  void addLocalImage(File imageFile) {
    if (state.value.localImages.length < 3) {
      final updated = List<File>.from(state.value.localImages)..add(imageFile);
      state.value = state.value.copyWith(localImages: updated);
    }
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < state.value.localImages.length) {
      final updated = List<File>.from(state.value.localImages)..removeAt(index);
      state.value = state.value.copyWith(localImages: updated);
    }
  }

  void clearImages() {
    state.value = state.value.copyWith(localImages: [], uploadedImageUrls: []);
  }

  void resetState() {
    _jobSubscription?.cancel();
    _estimatedProgressTimer?.cancel();
    state.value = VideoGenState(
      selectedDuration: state.value.selectedDuration,
      selectedAspectRatio: state.value.selectedAspectRatio,
    );
  }

  Future<void> submitVideoJob(String sceneScript) async {
    if (sceneScript.trim().isEmpty) {
      state.value = state.value.copyWith(
        status: VideoGenStatus.error,
        errorMessage: 'Please enter a scene script or prompt.',
      );
      return;
    }

    final authCtrl = Get.find<AuthController>();
    final userId = authCtrl.currentUser.value?.uid ?? 'guest';

    // ── 1. Wallet Credit Pre-check ─────────────────────────────────────────
    state.value = state.value.copyWith(
      status: VideoGenStatus.checkingCredits,
      errorMessage: null,
      progressPercent: 0.05,
      activeStageMessage: 'Verifying wallet balance...',
    );

    final walletCtrl = Get.find<WalletController>();
    final currentBalance = walletCtrl.wallet.value?.balance ?? 0;
    if (currentBalance < requiredCredits) {
      state.value = state.value.copyWith(
        status: VideoGenStatus.error,
        errorMessage:
            'Insufficient credits. Required: $requiredCredits credits, Available: $currentBalance credits.',
      );
      return;
    }

    // ── 2. Upload Local Images to Firebase Storage ─────────────────────────
    List<String> finalUrls = [];
    if (state.value.localImages.isNotEmpty) {
      state.value = state.value.copyWith(
        status: VideoGenStatus.uploadingAssets,
        activeStageMessage: 'Uploading assets to cloud storage...',
        progressPercent: 0.15,
      );

      for (int i = 0; i < state.value.localImages.length; i++) {
        final file = state.value.localImages[i];
        final uploadRes = await _uploadService.uploadImage(file: file, userId: userId);
        
        bool isSuccess = false;
        uploadRes.fold(
          (result) {
            finalUrls.add(result.downloadUrl);
            isSuccess = true;
          },
          (failure) {
            state.value = state.value.copyWith(
              status: VideoGenStatus.error,
              errorMessage: failure.message,
            );
          },
        );

        if (!isSuccess) return;
      }
    }

    state.value = state.value.copyWith(uploadedImageUrls: finalUrls);

    // ── 3. Submit API Request ──────────────────────────────────────────────
    state.value = state.value.copyWith(
      status: VideoGenStatus.submitting,
      activeStageMessage: 'Submitting job to fast tier video worker...',
      progressPercent: 0.25,
    );

    try {
      final response = await _apiService.submitVideoJob(
        imageUrls: finalUrls,
        sceneScript: sceneScript.trim(),
        duration: state.value.selectedDuration,
        aspectRatio: state.value.selectedAspectRatio,
      );

      final jobId = response.jobId;
      state.value = state.value.copyWith(
        status: VideoGenStatus.processing,
        jobId: jobId,
        activeStageMessage: 'Job queued in fast tier worker...',
        progressPercent: 0.30,
      );

      _subscribeToJobUpdates(jobId);
    } catch (e) {
      Logger.e('Video job submission failed', e);
      state.value = state.value.copyWith(
        status: VideoGenStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _subscribeToJobUpdates(String jobId) {
    _jobSubscription?.cancel();
    _estimatedProgressTimer?.cancel();

    // Start estimated smooth progress simulation (20-40s for 10s, 30-50s for 15s)
    final totalEstSeconds = state.value.selectedDuration == 15 ? 40 : 30;
    int elapsed = 0;

    _estimatedProgressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsed++;
      if (state.value.status != VideoGenStatus.processing) {
        timer.cancel();
        return;
      }

      final estProgress = (0.30 + (elapsed / totalEstSeconds) * 0.65).clamp(0.30, 0.95);
      state.value = state.value.copyWith(progressPercent: estProgress);
    });

    _jobSubscription = _apiService.watchJobStatus(jobId).listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return;
        final data = snapshot.data()!;
        final statusStr = (data['status'] as String?) ?? 'pending';
        final outputUrl = data['outputUrl'] as String? ?? data['output_url'] as String?;
        final errorMsg = data['error'] as String? ?? data['errorMessage'] as String?;
        final stage = data['stage'] as String? ?? data['stageMessage'] as String?;

        if (statusStr == 'pending') {
          state.value = state.value.copyWith(
            status: VideoGenStatus.processing,
            activeStageMessage: stage ?? 'Job queued in fast tier worker...',
          );
        } else if (statusStr == 'processing') {
          const defaultStage = 'Structuring scene with Gemini Flash & generating video with Wan 2.2...';
          state.value = state.value.copyWith(
            status: VideoGenStatus.processing,
            activeStageMessage: stage ?? defaultStage,
          );
        } else if (statusStr == 'completed') {
          _jobSubscription?.cancel();
          _estimatedProgressTimer?.cancel();

          final rawUrl = outputUrl ?? '';
          StorageUrlResolver.resolveUrl(rawUrl).then((resolved) {
            final finalUrl = resolved.isNotEmpty ? resolved : rawUrl;
            state.value = state.value.copyWith(
              status: VideoGenStatus.completed,
              progressPercent: 1.0,
              videoUrl: finalUrl,
              activeStageMessage: 'Video generation completed!',
            );
          });
        } else if (statusStr == 'error') {
          _jobSubscription?.cancel();
          _estimatedProgressTimer?.cancel();

          state.value = state.value.copyWith(
            status: VideoGenStatus.error,
            errorMessage: errorMsg ?? 'Video generation failed. Credits auto-refunded.',
          );
        }
      },
      onError: (e) {
        Logger.e('Error watching Firestore job snapshot', e);
        _estimatedProgressTimer?.cancel();
        state.value = state.value.copyWith(
          status: VideoGenStatus.error,
          errorMessage: 'Lost connection to video generation service.',
        );
      },
    );
  }

  @override
  void onClose() {
    _jobSubscription?.cancel();
    _estimatedProgressTimer?.cancel();
    super.onClose();
  }
}

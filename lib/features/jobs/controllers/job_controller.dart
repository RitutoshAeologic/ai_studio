import 'dart:async';
import 'package:ai_studio/core/error/error_handler.dart';
import 'package:ai_studio/core/services/api_service.dart';
import 'package:ai_studio/core/utils/logger.dart';
import 'package:ai_studio/domain/entities/job_entity.dart';
import 'package:ai_studio/domain/repositories/job_repository.dart';
import 'package:get/get.dart';


/// Job state machine controller.
///
/// ── Public API for Flutter Dev #2 ──────────────────────────────────────────
/// Dev #2 consumes this controller directly. Never build your own Firestore
/// listener or API call — use these methods and reactive streams.
///
///   watchJob(jobId)     — start listening to a job by ID
///   stopWatching()      — cancel the current listener
///   submitJob(request)  — submit a new job via ApiService (returns jobId)
///   `status`              — `Rx<JobStatus>` reactive status
///   `currentJob`          — `Rxn<JobEntity>` full job entity
///   jobError            — RxString verbatim error from Firestore
///   isCompleted         — RxBool
///   isProcessing        — RxBool
///   isError             — RxBool
///   outputUrl           — String? for flat image result (IMAGE_GEN / THEME_CHANGE / BG_REMOVAL)
///   meshUrl             — String? for 3D .glb result (MESH_GEN)
class JobController extends GetxController {
  final JobRepository _jobRepository;
  final ApiService _apiService;

  JobController({
    JobRepository? jobRepository,
    ApiService? apiService,
  })  : _jobRepository = jobRepository ?? Get.find<JobRepository>(),
        _apiService = apiService ?? Get.find<ApiService>();

  // ── Reactive state ─────────────────────────────────────────────────────────
  final Rx<JobStatus> status = JobStatus.idle.obs;
  final Rxn<JobEntity> currentJob = Rxn<JobEntity>();

  /// Verbatim error string from Firestore `jobs/{jobId}.error`.
  /// NEVER replaced with a generic message — the user needs the real failure.
  final RxString jobError = ''.obs;

  final RxBool isCompleted = false.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isError = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString submissionError = ''.obs;

  StreamSubscription? _jobSubscription;

  final RxInt lastJobCost = 0.obs;

  // ── Public methods ─────────────────────────────────────────────────────────

  /// Submit a new job. Returns the jobId on success or null on failure.
  /// [submissionError] is set with the verbatim failure reason on error.
  Future<String?> submitJob(GenerateJobRequest request) async {
    isSubmitting.value = true;
    submissionError.value = '';

    final result = await _apiService.generateJob(request);

    isSubmitting.value = false;

    return result.fold(
      (response) {
        lastJobCost.value = response.cost;
        Logger.i('Job submitted: ${response.jobId}, cost: ${response.cost}');
        return response.jobId;
      },
      (failure) {
        submissionError.value = ErrorHandler.map(failure);
        Logger.w('Job submission failed: ${failure.message}');
        return null;
      },
    );
  }

  /// Attach a Firestore real-time listener on jobs/{jobId}.
  /// Replaces any existing listener — call this once per job.
  void watchJob(String jobId) {
    _jobSubscription?.cancel();
    _resetState();

    _jobSubscription = _jobRepository.watchJob(jobId).listen((result) {
      result.fold(
        (job) {
          currentJob.value = job;
          status.value = job.status;
          isCompleted.value = job.status == JobStatus.completed;
          isProcessing.value = job.status == JobStatus.processing;
          isError.value = job.status == JobStatus.error;

          // Always propagate verbatim error — never genericise it.
          if (job.status == JobStatus.error) {
            jobError.value = job.error ?? 'unknown error';
          }
          Logger.d('Job $jobId → ${job.status.firestoreValue}');
        },
        (failure) {
          isError.value = true;
          jobError.value = failure.message;
          Logger.w('Job stream error for $jobId: ${failure.message}');
        },
      );
    });
  }

  /// Cancel the current job listener and reset all state to idle.
  void stopWatching() {
    _jobSubscription?.cancel();
    _jobSubscription = null;
    _resetState();
  }

  /// Delete a job document from Firestore and remove its associated storage files.
  Future<bool> deleteJob(JobEntity job) async {
    final result = await _jobRepository.deleteJob(
      job.jobId,
      outputUrl: job.outputUrl,
      inputImageUrl: job.params.imageUrl,
      meshUrl: job.meshUrl,
    );
    return result.isSuccess;
  }

  // ── Convenience accessors for Dev #2 ──────────────────────────────────────

  /// Flat image URL — available when status == completed for IMAGE_GEN / THEME_CHANGE / BG_REMOVAL.
  String? get outputUrl => currentJob.value?.outputUrl;

  /// 3D mesh .glb URL — available when status == completed for MESH_GEN.
  String? get meshUrl => currentJob.value?.meshUrl;

  // ── Internal ───────────────────────────────────────────────────────────────
  void _resetState() {
    status.value = JobStatus.idle;
    currentJob.value = null;
    jobError.value = '';
    isCompleted.value = false;
    isProcessing.value = false;
    isError.value = false;
  }

  @override
  void onClose() {
    _jobSubscription?.cancel();
    super.onClose();
  }
}

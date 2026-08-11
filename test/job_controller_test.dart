import 'dart:async';
import 'package:ai_studio/core/error/failure.dart';
import 'package:ai_studio/core/error/result.dart';
import 'package:ai_studio/core/services/api_service.dart';
import 'package:ai_studio/domain/entities/job_entity.dart';
import 'package:ai_studio/domain/repositories/job_repository.dart';
import 'package:ai_studio/features/jobs/controllers/job_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

// ── Stub: JobRepository ───────────────────────────────────────────────────────

class _StubJobRepository implements JobRepository {
  final StreamController<Result<JobEntity, Failure>> _controller =
      StreamController<Result<JobEntity, Failure>>.broadcast();

  void emit(JobEntity job) => _controller.add(Success(job));
  void emitFailure(Failure failure) => _controller.add(Error(failure));

  @override
  Stream<Result<JobEntity, Failure>> watchJob(String jobId) =>
      _controller.stream;

  @override
  Future<Result<void, Failure>> deleteJob(
    String jobId, {
    String? outputUrl,
    String? inputImageUrl,
    String? meshUrl,
  }) async =>
      const Success(null);

  void close() => _controller.close();
}

// ── Stub: ApiService ──────────────────────────────────────────────────────────

class _StubApiService implements ApiService {
  Result<GenerateJobResponse, Failure> nextResult = Success(
    GenerateJobResponse(
      jobId: 'job_001',
      status: 'pending',
      cost: 10,
      createdAt: DateTime(2026, 1, 1),
    ),
  );

  @override
  Future<Result<GenerateJobResponse, Failure>> generateJob(
      GenerateJobRequest request) async {
    await Future.delayed(const Duration(milliseconds: 5));
    return nextResult;
  }

  // Ignore unimplemented Dio internals — not used in unit tests.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

JobEntity _job({
  String jobId = 'job_001',
  JobStatus status = JobStatus.pending,
  String? outputUrl,
  String? meshUrl,
  String? error,
}) =>
    JobEntity(
      jobId: jobId,
      userId: 'u1',
      type: JobType.imageGen,
      tier: 'FAST',
      status: status,
      cost: 10,
      params: const JobParams(userPrompt: 'test prompt'),
      outputUrl: outputUrl,
      meshUrl: meshUrl,
      error: error,
      createdAt: DateTime(2026, 1, 1),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _StubJobRepository repo;
  late _StubApiService api;
  late JobController ctrl;

  setUp(() {
    Get.reset();
    repo = _StubJobRepository();
    api = _StubApiService();
    ctrl = JobController(jobRepository: repo, apiService: api);
  });

  tearDown(() {
    ctrl.onClose();
    repo.close();
  });

  group('JobController — submitJob', () {
    test('success — lastJobCost set, non-null jobId returned', () async {
      api.nextResult = Success(GenerateJobResponse(
        jobId: 'job_abc',
        status: 'pending',
        cost: 25,
        createdAt: DateTime(2026, 1, 1),
      ));

      final jobId = await ctrl.submitJob(const GenerateJobRequest(
        jobType: JobType.imageGen,
        params: JobParams(userPrompt: 'Cyberpunk city'),
      ));

      expect(jobId, 'job_abc');
      expect(ctrl.lastJobCost.value, 25);
      expect(ctrl.submissionError.value, '');
      expect(ctrl.isSubmitting.value, false);
    });

    test('failure — submissionError set, null returned', () async {
      api.nextResult = const Error(NetworkFailure('Server unreachable'));

      final jobId = await ctrl.submitJob(const GenerateJobRequest(
        jobType: JobType.imageGen,
        params: JobParams(userPrompt: 'test'),
      ));

      expect(jobId, isNull);
      expect(ctrl.submissionError.value, isNotEmpty);
      expect(ctrl.isSubmitting.value, false);
    });

    test('InsufficientCreditsFailure — correct message shown', () async {
      api.nextResult = const Error(InsufficientCreditsFailure());

      final jobId = await ctrl.submitJob(const GenerateJobRequest(
        jobType: JobType.imageGen,
        params: JobParams(userPrompt: 'test'),
      ));

      expect(jobId, isNull);
      expect(ctrl.submissionError.value, isNotEmpty);
    });
  });

  group('JobController — watchJob state machine', () {
    test('transitions pending → processing → completed', () async {
      ctrl.watchJob('job_001');

      repo.emit(_job(status: JobStatus.pending));
      await Future.microtask(() {});
      expect(ctrl.status.value, JobStatus.pending);

      repo.emit(_job(status: JobStatus.processing));
      await Future.microtask(() {});
      expect(ctrl.status.value, JobStatus.processing);
      expect(ctrl.isProcessing.value, true);

      repo.emit(_job(status: JobStatus.completed, outputUrl: 'https://cdn.example.com/img.jpg'));
      await Future.microtask(() {});
      expect(ctrl.status.value, JobStatus.completed);
      expect(ctrl.isCompleted.value, true);
      expect(ctrl.isProcessing.value, false);
    });

    test('error transition — isError set, jobError populated verbatim', () async {
      ctrl.watchJob('job_001');

      repo.emit(_job(status: JobStatus.error, error: 'WORKER_OOM: out of GPU memory'));
      await Future.microtask(() {});

      expect(ctrl.isError.value, true);
      expect(ctrl.isCompleted.value, false);
      expect(ctrl.jobError.value, 'WORKER_OOM: out of GPU memory');
    });

    test('stream failure — isError set with failure message', () async {
      ctrl.watchJob('job_001');

      repo.emitFailure(const NetworkFailure('Firestore read failed'));
      await Future.microtask(() {});

      expect(ctrl.isError.value, true);
      expect(ctrl.jobError.value, isNotEmpty);
    });

    test('stopWatching — resets all state to idle', () async {
      ctrl.watchJob('job_001');
      repo.emit(_job(status: JobStatus.processing));
      await Future.microtask(() {});

      ctrl.stopWatching();

      expect(ctrl.status.value, JobStatus.idle);
      expect(ctrl.currentJob.value, isNull);
      expect(ctrl.isCompleted.value, false);
      expect(ctrl.isProcessing.value, false);
      expect(ctrl.isError.value, false);
      expect(ctrl.jobError.value, '');
    });
  });

  group('JobController — accessors', () {
    test('outputUrl returns flat image URL from currentJob', () async {
      ctrl.watchJob('job_001');
      repo.emit(_job(
        status: JobStatus.completed,
        outputUrl: 'https://cdn.example.com/output.jpg',
      ));
      await Future.microtask(() {});

      expect(ctrl.outputUrl, 'https://cdn.example.com/output.jpg');
      expect(ctrl.meshUrl, isNull);
    });

    test('meshUrl returns .glb URL from currentJob for MESH_GEN', () async {
      final meshJob = JobEntity(
        jobId: 'job_mesh',
        userId: 'u1',
        type: JobType.meshGen,
        tier: 'FAST',
        status: JobStatus.completed,
        cost: 20,
        params: const JobParams(userPrompt: '3D chair'),
        meshUrl: 'https://cdn.example.com/model.glb',
        createdAt: DateTime(2026, 1, 1),
      );

      ctrl.watchJob('job_mesh');
      repo.emit(meshJob);
      await Future.microtask(() {});

      expect(ctrl.meshUrl, 'https://cdn.example.com/model.glb');
      expect(ctrl.outputUrl, isNull);
    });
  });
}

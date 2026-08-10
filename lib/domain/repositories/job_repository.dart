import 'package:ai_studio/core/error/failure.dart';
import 'package:ai_studio/core/error/result.dart';
import 'package:ai_studio/domain/entities/job_entity.dart';

/// Abstract domain contract for the job state stream.
/// Flutter Dev #2 consumes JobController's public API — they never touch this directly.
abstract class JobRepository {
  /// Listens to real-time Firestore updates on jobs/{jobId}.
  /// Emits Result.success on every valid snapshot, Result.error on failures.
  Stream<Result<JobEntity, Failure>> watchJob(String jobId);
}

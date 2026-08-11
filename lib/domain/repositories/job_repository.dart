import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/job_entity.dart';

/// Abstract domain contract for job state operations and deletions.
abstract class JobRepository {
  /// Listens to real-time Firestore updates on jobs/{jobId}.
  /// Emits Result.success on every valid snapshot, Result.error on failures.
  Stream<Result<JobEntity, Failure>> watchJob(String jobId);

  /// Deletes a job document from Firestore and removes associated Firebase Storage assets.
  Future<Result<void, Failure>> deleteJob(
    String jobId, {
    String? outputUrl,
    String? inputImageUrl,
    String? meshUrl,
  });
}

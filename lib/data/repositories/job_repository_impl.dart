import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/repositories/job_repository.dart';
import '../models/job_model.dart';

/// Concrete job repository — listens to jobs/{jobId} Firestore snapshots.
class JobRepositoryImpl implements JobRepository {
  final FirebaseFirestore? _providedFirestore;

  JobRepositoryImpl({FirebaseFirestore? firestore})
      : _providedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  @override
  Stream<Result<JobEntity, Failure>> watchJob(String jobId) {
    try {
      return _firestore
          .collection('jobs')
          .doc(jobId)
          .snapshots()
          .map((snap) {
        if (!snap.exists) {
          Logger.w('Job document does not exist: $jobId');
          return const Error(UnknownFailure('Job not found'));
        }
        final model = JobModel.fromFirestore(snap);
        Logger.d('Job update: $jobId → ${model.status.firestoreValue}');
        return Success(model);
      });
    } catch (e, stackTrace) {
      Logger.e('Failed to attach job listener for $jobId', e, stackTrace);
      return Stream.value(const Error(UnknownFailure('Failed to watch job')));
    }
  }
}

import 'package:ai_studio/domain/entities/job_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for jobs/{jobId} Firestore document.
/// Handles bidirectional conversion with the shared Firestore schema.
class JobModel extends JobEntity {
  const JobModel({
    required super.jobId,
    required super.userId,
    required super.type,
    required super.tier,
    required super.status,
    required super.cost,
    required super.params,
    super.outputUrl,
    super.meshUrl,
    super.error,
    required super.createdAt,
  });

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final paramsRaw = data['params'] as Map<String, dynamic>? ?? {};

    return JobModel(
      jobId: data['jobId'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      type: JobType.fromString(data['type'] as String? ?? ''),
      tier: data['tier'] as String? ?? 'FAST',
      status: JobStatus.fromString(data['status'] as String? ?? 'idle'),
      cost: (data['cost'] as num?)?.toInt() ?? 0,
      params: JobParams.fromJson(paramsRaw),
      outputUrl: data['outputUrl'] as String?,
      meshUrl: data['meshUrl'] as String?,
      error: data['error'] as String?,
      createdAt: createdAt,
    );
  }

  /// Used only for creating the initial job document — Flutter client creates this doc.
  Map<String, dynamic> toFirestore() => {
        'jobId': jobId,
        'userId': userId,
        'type': type.firestoreValue,
        'tier': tier,
        'status': JobStatus.pending.firestoreValue,
        'cost': cost,
        'params': params.toJson(),
        'outputUrl': null,
        'meshUrl': null,
        'error': null,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

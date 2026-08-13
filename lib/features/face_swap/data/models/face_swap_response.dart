/// Response model returned by `POST /v1/generateFaceSwapJob`.
class FaceSwapJobResponse {
  final String jobId;
  final String status;
  final int cost;
  final DateTime createdAt;
  final String? message;

  const FaceSwapJobResponse({
    required this.jobId,
    required this.status,
    required this.cost,
    required this.createdAt,
    this.message,
  });

  factory FaceSwapJobResponse.fromJson(Map<String, dynamic> json) {
    return FaceSwapJobResponse(
      jobId: json['jobId'] as String? ?? json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      cost: json['cost'] as int? ?? 30,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      message: json['message'] as String?,
    );
  }
}

/// Response model returned by `GET /v1/faceSwapJob/:jobId`.
class FaceSwapJobStatusResponse {
  final String jobId;
  final String status;
  final String? outputUrl;
  final String? stage;
  final String? error;
  final int? cost;

  const FaceSwapJobStatusResponse({
    required this.jobId,
    required this.status,
    this.outputUrl,
    this.stage,
    this.error,
    this.cost,
  });

  factory FaceSwapJobStatusResponse.fromJson(Map<String, dynamic> json) {
    return FaceSwapJobStatusResponse(
      jobId: json['jobId'] as String? ?? json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      outputUrl: json['outputUrl'] as String? ?? json['output_url'] as String? ?? json['videoUrl'] as String?,
      stage: json['stage'] as String? ?? json['stageMessage'] as String?,
      error: json['error'] as String? ?? json['errorMessage'] as String?,
      cost: json['cost'] as int?,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'error' || status == 'failed';
}

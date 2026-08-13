/// Job type — mirrors Firestore `type` field strings exactly.
enum JobType {
  imageGen('IMAGE_GEN'),
  meshGen('IMAGE_3D'),
  bgRemoval('BG_REMOVAL'),
  themeChange('THEME_CHANGE'),
  videoGen('VIDEO_GEN'),
  videoFaceSwap('VIDEO_FACE_SWAP');

  const JobType(this.firestoreValue);
  final String firestoreValue;

  static JobType fromString(String value) {
    if (value == 'IMAGE_3D' || value == 'MESH_GEN') {
      return JobType.meshGen;
    }
    return JobType.values.firstWhere(
      (t) => t.firestoreValue == value,
      orElse: () => JobType.imageGen,
    );
  }
}

/// Job status — mirrors Firestore `status` field strings exactly.
/// State machine: idle → pending → deducting_credits → queued → processing → completed | error
enum JobStatus {
  idle('idle'),
  pending('pending'),
  deductingCredits('deducting_credits'),
  queued('queued'),
  processing('processing'),
  completed('completed'),
  error('error');

  const JobStatus(this.firestoreValue);
  final String firestoreValue;

  bool get isTerminal => this == completed || this == error;
  bool get isActive =>
      this == pending ||
      this == deductingCredits ||
      this == queued ||
      this == processing;

  static JobStatus fromString(String value) {
    return JobStatus.values.firstWhere(
      (s) => s.firestoreValue == value,
      orElse: () => JobStatus.idle,
    );
  }
}

/// Job parameters sent with the job submission.
class JobParams {
  /// Free-text path — user typed a prompt. Mutually exclusive with [themeId].
  final String? userPrompt;

  /// Cheap path — integer ID into the server-side prompt library. Mutually exclusive with [userPrompt].
  final int? themeId;

  /// Storage download URL for input image (BG removal, theme change, or image reference).
  final String? imageUrl;

  const JobParams({this.userPrompt, this.themeId, this.imageUrl});

  Map<String, dynamic> toJson() => {
        'userPrompt': userPrompt,
        'themeId': themeId,
        'imageUrl': imageUrl,
      };

  factory JobParams.fromJson(Map<String, dynamic> json) => JobParams(
        userPrompt: json['userPrompt'] as String?,
        themeId: json['themeId'] as int?,
        imageUrl: json['imageUrl'] as String? ??
            json['sourceImageUrl'] as String? ??
            json['image_url'] as String?,
      );
}

/// Pure Dart domain entity matching the shared Firestore jobs/{jobId} schema.
class JobEntity {
  final String jobId;
  final String userId;
  final JobType type;
  final String tier;
  final JobStatus status;
  final int cost;
  final JobParams params;
  final String? outputUrl;
  final String? meshUrl;

  /// Verbatim error string from Firestore — never replaced by a generic message.
  final String? error;

  final DateTime createdAt;

  const JobEntity({
    required this.jobId,
    required this.userId,
    required this.type,
    required this.tier,
    required this.status,
    required this.cost,
    required this.params,
    this.outputUrl,
    this.meshUrl,
    this.error,
    required this.createdAt,
  });

  JobEntity copyWith({
    JobStatus? status,
    String? outputUrl,
    String? meshUrl,
    String? error,
  }) {
    return JobEntity(
      jobId: jobId,
      userId: userId,
      type: type,
      tier: tier,
      status: status ?? this.status,
      cost: cost,
      params: params,
      outputUrl: outputUrl ?? this.outputUrl,
      meshUrl: meshUrl ?? this.meshUrl,
      error: error ?? this.error,
      createdAt: createdAt,
    );
  }
}

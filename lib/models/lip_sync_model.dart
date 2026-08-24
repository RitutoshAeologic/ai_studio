/// Available Voice Options
enum VoiceOption {
  usMale('en-US-GuyNeural', '👨 US Male (Guy)'),
  usFemale('en-US-JennyNeural', '👩 US Female (Jenny)');

  final String code;
  final String displayName;
  const VoiceOption(this.code, this.displayName);
}

/// Input Media Type for Lip-Sync / Talking Video
enum InputMediaType {
  image('IMAGE', '🖼️ Avatar Photo'),
  video('VIDEO', '🎥 Character Video');

  final String code;
  final String displayName;
  const InputMediaType(this.code, this.displayName);
}

/// Request Params Payload (Supports passing either imageUrl or videoUrl)
class LipSyncParams {
  final String? imageUrl;
  final String? videoUrl;
  final String paragraphText;
  final String voice;

  LipSyncParams({
    this.imageUrl,
    this.videoUrl,
    required this.paragraphText,
    this.voice = 'en-US-GuyNeural',
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'paragraphText': paragraphText,
      'voice': voice,
    };
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      data['imageUrl'] = imageUrl;
    }
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      data['videoUrl'] = videoUrl;
    }
    return data;
  }
}

/// Request Payload for POST /v1/video/lip-sync
class LipSyncJobRequest {
  final String jobType;
  final String tier;
  final LipSyncParams params;

  LipSyncJobRequest({
    this.jobType = 'LIP_SYNC',
    this.tier = 'FAST',
    required this.params,
  });

  Map<String, dynamic> toJson() {
    return {
      'jobType': jobType,
      'tier': tier,
      'params': params.toJson(),
    };
  }
}

/// Alias for backward compatibility
typedef LipSyncRequest = LipSyncJobRequest;

/// Initial Response from POST /v1/video/lip-sync
class LipSyncJobResponse {
  final String jobId;
  final String status;
  final int cost;
  final String createdAt;

  LipSyncJobResponse({
    required this.jobId,
    required this.status,
    required this.cost,
    required this.createdAt,
  });

  factory LipSyncJobResponse.fromJson(Map<String, dynamic> json) {
    return LipSyncJobResponse(
      jobId: json['jobId'] ?? '',
      status: json['status'] ?? 'pending',
      cost: json['cost'] ?? 50,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

/// Polled Status Response from GET /v1/videoJob/{job_id}
class LipSyncStatusResponse {
  final String jobId;
  final String status; // pending | processing | completed | error
  final String? outputUrl;
  final String? error;

  LipSyncStatusResponse({
    required this.jobId,
    required this.status,
    this.outputUrl,
    this.error,
  });

  factory LipSyncStatusResponse.fromJson(Map<String, dynamic> json) {
    return LipSyncStatusResponse(
      jobId: json['jobId'] ?? '',
      status: json['status'] ?? 'pending',
      outputUrl: json['outputUrl'],
      error: json['error'],
    );
  }
}

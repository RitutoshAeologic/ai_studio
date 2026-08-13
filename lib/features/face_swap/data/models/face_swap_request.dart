/// Request model sent to `POST /v1/generateFaceSwapJob`.
class FaceSwapRequest {
  final String targetVideoUrl;
  final String sourceImageUrl;
  final String? title;

  const FaceSwapRequest({
    required this.targetVideoUrl,
    required this.sourceImageUrl,
    this.title,
  });

  Map<String, dynamic> toJson() => {
        'targetVideoUrl': targetVideoUrl,
        'sourceImageUrl': sourceImageUrl,
        'target_video_url': targetVideoUrl,
        'source_image_url': sourceImageUrl,
        if (title != null && title!.isNotEmpty) 'title': title,
        'jobType': 'VIDEO_FACE_SWAP',
        'job_type': 'VIDEO_FACE_SWAP',
        'tier': 'FAST',
        'params': {
          'targetVideoUrl': targetVideoUrl,
          'sourceImageUrl': sourceImageUrl,
          'target_video_url': targetVideoUrl,
          'source_image_url': sourceImageUrl,
          'imageUrl': sourceImageUrl,
          'image_url': sourceImageUrl,
          if (title != null && title!.isNotEmpty) 'title': title,
        },
      };

  factory FaceSwapRequest.fromJson(Map<String, dynamic> json) {
    final params = json['params'] as Map<String, dynamic>? ?? json;
    return FaceSwapRequest(
      targetVideoUrl: params['targetVideoUrl'] as String? ?? '',
      sourceImageUrl: params['sourceImageUrl'] as String? ?? '',
      title: params['title'] as String?,
    );
  }
}

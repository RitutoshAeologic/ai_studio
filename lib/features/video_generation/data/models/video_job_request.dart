class GenerateVideoJobRequest {
  final String jobType;
  final String tier;
  final int duration; // 10 or 15
  final String aspectRatio; // "16:9", "9:16", "1:1"
  final VideoJobParams params;

  GenerateVideoJobRequest({
    this.jobType = 'VIDEO_GEN',
    this.tier = 'FAST',
    required this.duration,
    required this.aspectRatio,
    required this.params,
  });

  Map<String, dynamic> toJson() => {
        'jobType': jobType,
        'tier': tier,
        'duration': duration,
        'aspectRatio': aspectRatio,
        'params': params.toJson(),
      };
}

class VideoJobParams {
  final List<String> images;
  final String sceneScript;

  VideoJobParams({
    required this.images,
    required this.sceneScript,
  });

  Map<String, dynamic> toJson() => {
        'images': images,
        'sceneScript': sceneScript,
      };
}

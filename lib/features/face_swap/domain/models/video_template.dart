/// Dance & Action Video Template entity for AI Video Face Swap.
class VideoTemplate {
  final String id;
  final String title;
  final String category;
  final String videoUrl;
  final String thumbnailUrl;
  final String? badge;
  final int durationSeconds;
  final bool isCustom;

  const VideoTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.badge,
    this.durationSeconds = 10,
    this.isCustom = false,
  });

  VideoTemplate copyWith({
    String? id,
    String? title,
    String? category,
    String? videoUrl,
    String? thumbnailUrl,
    String? badge,
    int? durationSeconds,
    bool? isCustom,
  }) {
    return VideoTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      badge: badge ?? this.badge,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  /// Built-in catalog matching the templates stored in Firebase Storage (`templates/dance/`).
  static const List<VideoTemplate> catalog = [
    VideoTemplate(
      id: '101066-video-720',
      title: 'Street Pop',
      category: 'Dance',
      badge: '720p',
      durationSeconds: 10,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/101066-video-720.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=500&auto=format&fit=crop&q=80',
    ),
    VideoTemplate(
      id: '6952251-uhd_3840_2160_25fps',
      title: 'Urban Groove',
      category: 'Dance',
      badge: '4K UHD',
      durationSeconds: 12,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/6952251-uhd_3840_2160_25fps.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=500&auto=format&fit=crop&q=80',
    ),
    VideoTemplate(
      id: '7413805-hd_1080_1920_24fps',
      title: 'Choreography',
      category: 'Dance',
      badge: '1080p',
      durationSeconds: 10,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/7413805-hd_1080_1920_24fps.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
    ),
    VideoTemplate(
      id: '8246857-uhd_2160_3840_25fps',
      title: 'Studio Solo',
      category: 'Dance',
      badge: '4K UHD',
      durationSeconds: 15,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/8246857-uhd_2160_3840_25fps.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80',
    ),
    VideoTemplate(
      id: '8873238-hd_1080_1920_25fps',
      title: 'Rhythm Dance',
      category: 'Dance',
      badge: '1080p',
      durationSeconds: 12,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/8873238-hd_1080_1920_25fps.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
    ),
  ];

  static String getFallbackThumbnailFor(String name) {
    if (name.contains('6952251')) {
      return 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=500&auto=format&fit=crop&q=80';
    }
    if (name.contains('7413805')) {
      return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80';
    }
    if (name.contains('8246857')) {
      return 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80';
    }
    if (name.contains('8873238')) {
      return 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80';
    }
    return 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=500&auto=format&fit=crop&q=80';
  }
}

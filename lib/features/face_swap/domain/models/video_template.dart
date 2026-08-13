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

  /// Built-in catalog of production-ready dance & action video templates.
  static const List<VideoTemplate> catalog = [
    VideoTemplate(
      id: 'hip_hop_dance',
      title: 'Hip-Hop Groove',
      category: 'Dance',
      badge: '🔥 Hot',
      durationSeconds: 10,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/hip_hop_dance.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=500&auto=format&fit=crop&q=60',
    ),
    VideoTemplate(
      id: 'shuffle_dance',
      title: 'Neon Shuffle',
      category: 'Dance',
      badge: '✨ Popular',
      durationSeconds: 10,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/shuffle_dance.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=60',
    ),
    VideoTemplate(
      id: 'ballet_spin',
      title: 'Ballet Grace',
      category: 'Classical',
      badge: '🩰 Elegant',
      durationSeconds: 10,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/ballet_spin.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=60',
    ),
    VideoTemplate(
      id: 'breakdance_power',
      title: 'Breakdance Windmill',
      category: 'Action',
      badge: '⚡ Epic',
      durationSeconds: 10,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/breakdance_power.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop&q=60',
    ),
    VideoTemplate(
      id: 'kpop_stage',
      title: 'K-Pop Center Stage',
      category: 'K-Pop',
      badge: '🌟 Trending',
      durationSeconds: 12,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/kpop_stage.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=60',
    ),
    VideoTemplate(
      id: 'salsa_fiesta',
      title: 'Salsa Fiesta',
      category: 'Latin',
      badge: '💃 Rhythm',
      durationSeconds: 10,
      videoUrl: 'https://storage.googleapis.com/ai-studio-637ab.firebasestorage.app/templates/dance/salsa_fiesta.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=60',
    ),
  ];

}

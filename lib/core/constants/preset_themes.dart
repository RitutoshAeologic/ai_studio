import 'package:flutter/material.dart';

/// Preset prompt item in the Darkroom prompt library.
class PresetTheme {
  final int themeId;
  final String title;
  final String category;
  final String description;
  final IconData icon;

  const PresetTheme({
    required this.themeId,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
  });
}

/// Curated preset themes — Theme IDs match backend lookup table.
abstract class PresetThemes {
  static const List<PresetTheme> list = [
    PresetTheme(
      themeId: 1,
      title: 'Cyberpunk Neon',
      category: 'Futuristic',
      description: 'High-contrast futuristic city with glowing neon blues & ambers',
      icon: Icons.electric_bolt_outlined,
    ),
    PresetTheme(
      themeId: 2,
      title: 'Cinematic Darkroom',
      category: 'Photography',
      description: 'Analog film texture, moody shadows, and 35mm grain aesthetics',
      icon: Icons.camera_roll_outlined,
    ),
    PresetTheme(
      themeId: 3,
      title: 'Studio Lighting',
      category: 'Portrait',
      description: 'Clean dramatic key light with soft volumetric fill shadows',
      icon: Icons.wb_incandescent_outlined,
    ),
    PresetTheme(
      themeId: 4,
      title: 'Vaporwave Sunset',
      category: 'Retro',
      description: '80s retro-futurism with palm silhouettes and magenta gradients',
      icon: Icons.wb_twilight_outlined,
    ),
    PresetTheme(
      themeId: 5,
      title: 'Monochrome Noir',
      category: 'Classic',
      description: 'Deep shadows, harsh highlights, and vintage film noir contrast',
      icon: Icons.contrast_outlined,
    ),
    PresetTheme(
      themeId: 6,
      title: 'Surreal Claymation',
      category: '3D Render',
      description: 'Playful tactile clay textures with soft ambient occlusion',
      icon: Icons.category_outlined,
    ),
    PresetTheme(
      themeId: 7,
      title: 'Architectural Blueprint',
      category: 'Technical',
      description: 'Precise isometric lines on cobalt architectural blue background',
      icon: Icons.architecture_outlined,
    ),
    PresetTheme(
      themeId: 8,
      title: 'Emerald Gothic',
      category: 'Fantasy',
      description: 'Ornate gothic arches surrounded by glowing emerald mist',
      icon: Icons.auto_awesome_mosaic_outlined,
    ),
  ];
}

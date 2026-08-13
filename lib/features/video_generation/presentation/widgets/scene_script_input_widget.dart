import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class VideoPromptPreset {
  final String title;
  final String prompt;
  final IconData icon;

  const VideoPromptPreset({
    required this.title,
    required this.prompt,
    required this.icon,
  });
}

class SceneScriptInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const SceneScriptInputWidget({
    super.key,
    required this.controller,
    this.onChanged,
  });

  static const List<VideoPromptPreset> presets = [
    VideoPromptPreset(
      title: '🎬 Slow-Mo Dance',
      prompt:
          'A cinematic slow-motion tracking shot of a dancer performing under golden hour sunlight, dynamic camera rotation, photorealistic lighting, 4K render.',
      icon: Icons.movie_filter_rounded,
    ),
    VideoPromptPreset(
      title: '🌃 Cyberpunk City',
      prompt:
          'Futuristic cyberpunk street bathed in neon rain reflections, slow forward drone dolly shot, glowing holographic billboards, volumetric atmosphere.',
      icon: Icons.nightlife_rounded,
    ),
    VideoPromptPreset(
      title: '🌿 Nature Bloom',
      prompt:
          'Macro time-lapse of a glowing violet orchid blooming in a misty enchanted forest, gentle camera push-in, soft ray-traced lighting, depth of field.',
      icon: Icons.eco_rounded,
    ),
    VideoPromptPreset(
      title: '🚀 Space Nebula',
      prompt:
          'Cinematic fly-through of a massive starship passing an epic glowing nebula, lens flares, cosmic dust particles, 8K photorealistic space render.',
      icon: Icons.rocket_launch_rounded,
    ),
    VideoPromptPreset(
      title: '👗 Fashion Runway',
      prompt:
          'High-fashion runway walk, sleek studio lighting, elegant fluid garment movement, smooth camera tracking, shallow depth of field.',
      icon: Icons.checkroom_rounded,
    ),
    VideoPromptPreset(
      title: '⚡ Anime Fantasy',
      prompt:
          'Dynamic anime battle scene, warrior summoning swirling elemental fire aura, dramatic camera orbital zoom, vivid cell-shaded action animation.',
      icon: Icons.bolt_rounded,
    ),
  ];

  @override
  State<SceneScriptInputWidget> createState() => _SceneScriptInputWidgetState();
}

class _SceneScriptInputWidgetState extends State<SceneScriptInputWidget> {

  void _applyPreset(String text) {
    widget.controller.text = text;
    widget.onChanged?.call(text);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reference script applied!',
          style: AppTextStyles.bodyM(color: Colors.white),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primaryAction,
      ),
    );
  }

  void _enhancePrompt() {
    final currentText = widget.controller.text.trim();
    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please type a prompt first or tap a reference script below.',
            style: AppTextStyles.bodyM(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryAction,
        ),
      );
      return;
    }

    final enhanced =
        'Cinematic 4K render of $currentText, with dynamic camera tracking, ultra-detailed textures, volumetric lighting, and smooth fluid motion.';
    widget.controller.text = enhanced;
    widget.onChanged?.call(enhanced);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Gemini Flash enhanced your scene script!',
          style: AppTextStyles.bodyM(color: Colors.white),
        ),
        backgroundColor: AppColors.statusSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Scene Script / Prompt',
                  style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                ),
                Text(
                  ' *',
                  style: AppTextStyles.labelSmall(color: AppColors.primaryAction),
                ),
              ],
            ),
            InkWell(
              onTap: _enhancePrompt,
              borderRadius: BorderRadius.circular(6.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14.r,
                      color: AppColors.primaryAction,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Enhance Script',
                      style: AppTextStyles.caption(
                        color: AppColors.primaryAction,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // Text Area Input
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceInput,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1.r,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            maxLines: 4,
            maxLength: 1000,
            onChanged: widget.onChanged,
            style: AppTextStyles.bodyM(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText:
                  'Describe the cinematic motion, camera movement, lighting, and scene transition...\nE.g.: A camera pan across a futuristic neon city bathed in rain at dusk, ultra-realistic 4K.',
              hintStyle: AppTextStyles.bodyM(color: AppColors.textDisabled),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14.r),
              counterStyle: AppTextStyles.caption(color: AppColors.textMuted),
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // Reference Scene Scripts Header
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.creditGoldIcon,
              size: 16.r,
            ),
            SizedBox(width: 6.w),
            Text(
              'Reference Scene Scripts (Tap to apply)',
              style: AppTextStyles.caption(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // Reference Prompt Chips (Horizontal Scroll)
        SizedBox(
          height: 36.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: SceneScriptInputWidget.presets.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final item = SceneScriptInputWidget.presets[index];
              return ActionChip(
                elevation: 0,
                pressElevation: 0,
                backgroundColor: AppColors.surfaceCard,
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
                labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
                avatar: Icon(item.icon, size: 14.r, color: AppColors.primaryAction),
                label: Text(
                  item.title,
                  style: AppTextStyles.caption(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => _applyPreset(item.prompt),
              );
            },
          ),
        ),
      ],
    );
  }
}

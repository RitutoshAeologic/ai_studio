import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/widgets/aperture_indicator.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/unfocus_on_tap.dart';
import '../features/wallet/controllers/wallet_controller.dart';
import '../models/lip_sync_model.dart';
import '../services/lip_sync_service.dart';

class LipSyncScreen extends StatefulWidget {
  const LipSyncScreen({super.key});

  @override
  State<LipSyncScreen> createState() => _LipSyncScreenState();
}

class _LipSyncScreenState extends State<LipSyncScreen> {
  InputMediaType _selectedInputType = InputMediaType.image;
  File? _selectedImageFile;
  File? _selectedVideoFile;
  final TextEditingController _textController = TextEditingController();
  VoiceOption _selectedVoice = VoiceOption.usMale;
  bool _isUploading = false;
  bool _isProcessing = false;
  String _statusText = '';
  String? _outputVideoUrl;
  VideoPlayerController? _resultPlayerController;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia() async {
    if (_selectedInputType == InputMediaType.image) {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _outputVideoUrl = null;
        });
      }
    } else {
      final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedVideoFile = File(pickedFile.path);
          _outputVideoUrl = null;
        });
      }
    }
  }

  void _clearSelectedMedia() {
    setState(() {
      _selectedImageFile = null;
      _selectedVideoFile = null;
      _outputVideoUrl = null;
    });
  }

  Future<void> _startLipSyncGeneration() async {
    if (_selectedInputType == InputMediaType.image && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select an Avatar Photo (.jpg/.png) first.',
            style: AppTextStyles.bodyM(color: AppColors.creditGoldTitle),
          ),
          backgroundColor: AppColors.creditGoldBg,
        ),
      );
      return;
    }

    if (_selectedInputType == InputMediaType.video && _selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a Character Video (.mp4) first.',
            style: AppTextStyles.bodyM(color: AppColors.creditGoldTitle),
          ),
          backgroundColor: AppColors.creditGoldBg,
        ),
      );
      return;
    }

    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a paragraph of text to speak.',
            style: AppTextStyles.bodyM(color: AppColors.creditGoldTitle),
          ),
          backgroundColor: AppColors.creditGoldBg,
        ),
      );
      return;
    }

    await HapticFeedback.mediumImpact();

    setState(() {
      _isUploading = true;
      _statusText = _selectedInputType == InputMediaType.image
          ? 'Uploading Avatar Photo...'
          : 'Uploading Character Video...';
    });

    try {
      String? imageUrl;
      String? videoUrl;

      // Step 1: Upload Selected Asset to Firebase Storage
      if (_selectedInputType == InputMediaType.image) {
        imageUrl = await LipSyncService.uploadImageToFirebase(_selectedImageFile!);
      } else {
        videoUrl = await LipSyncService.uploadVideoToFirebase(_selectedVideoFile!);
      }

      setState(() {
        _isUploading = false;
        _isProcessing = true;
        _statusText = 'Deducting 50 credits & submitting job...';
      });

      // Step 2: Submit Lip Sync / Talking Avatar Job
      final jobResponse = await LipSyncService.submitLipSyncJob(
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        paragraphText: _textController.text.trim(),
        voiceCode: _selectedVoice.code,
      );

      setState(() {
        _statusText = _selectedInputType == InputMediaType.image
            ? 'AI LivePortrait is animating avatar & generating speech video...'
            : 'AI is syncing lip movements with voice speech...';
      });

      // Step 3: Poll status
      final finalResult = await LipSyncService.pollJobStatusUntilComplete(jobResponse.jobId);
      if (finalResult.status == 'completed' && finalResult.outputUrl != null) {
        setState(() {
          _outputVideoUrl = finalResult.outputUrl;
          _isProcessing = false;
          _statusText = 'Completed successfully!';
        });
        _initResultPlayer(finalResult.outputUrl!);
      } else {
        throw Exception(finalResult.error ?? 'Generation failed.');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isProcessing = false;
        _statusText = '';
      });
      if (mounted) {
        final errStr = e.toString();
        String displayError = errStr.replaceFirst('Exception: ', '');
        if (errStr.contains('Cannot read image') || errStr.contains('avatar.mp4')) {
          displayError = 'The AI model requires a static Avatar Photo (.jpg/.png). Please switch to the "Avatar Photo" tab.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              displayError,
              style: AppTextStyles.bodyMedium(color: Colors.white),
            ),
            backgroundColor: AppColors.statusError,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _initResultPlayer(String url) {
    _resultPlayerController?.dispose();
    _resultPlayerController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _resultPlayerController?.play();
        }
      });
  }

  @override
  void dispose() {
    _textController.dispose();
    _resultPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isUploading || _isProcessing;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'AI Avatar & Lip-Sync',
          style: AppTextStyles.headingM(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22.r),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (Get.isRegistered<WalletController>())
            Obx(() {
              final walletCtrl = Get.find<WalletController>();
              final balance = walletCtrl.wallet.value?.balance ?? 0;
              return Container(
                margin: EdgeInsets.only(right: 16.w),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.creditGoldBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.creditGoldIcon, width: 1.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: AppColors.creditGoldIcon, size: 16.r),
                    SizedBox(width: 4.w),
                    Text(
                      '$balance Credits',
                      style: AppTextStyles.caption(
                        color: AppColors.creditGoldTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Container(
              margin: EdgeInsets.only(right: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.creditGoldBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.creditGoldIcon, width: 1.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.creditGoldIcon, size: 16.r),
                  SizedBox(width: 4.w),
                  Text(
                    '50 Credits',
                    style: AppTextStyles.caption(
                      color: AppColors.creditGoldTitle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: UnfocusOnTap(
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: isBusy,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isBusy ? 0.55 : 1.0,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Input Type Mode Switcher (Avatar Photo vs Video)
                      Text(
                        'INPUT MEDIA SOURCE',
                        style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: InputMediaType.values.map((type) {
                          final isSelected = _selectedInputType == type;
                          return Expanded(
                            child: GestureDetector(
                              onTap: isBusy
                                  ? null
                                  : () {
                                      if (_selectedInputType != type) {
                                        setState(() {
                                          _selectedInputType = type;
                                        });
                                      }
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: EdgeInsets.only(
                                  right: type == InputMediaType.values.last ? 0 : 8.w,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryAction
                                      : AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryAction
                                        : AppColors.borderSubtle,
                                    width: 1.r,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    type.displayName,
                                    style: AppTextStyles.labelMedium(
                                      color: isSelected ? Colors.white : AppColors.textMuted,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _selectedInputType == InputMediaType.image
                            ? '💡 LivePortrait/SadTalker animates face expressions and syncs lips from a static photo.'
                            : '💡 Syncs lip movements directly on your character video.',
                        style: AppTextStyles.caption(color: AppColors.textMuted),
                      ),
                      SizedBox(height: 16.h),

                      // 2. Input Asset Container Box
                      Row(
                        children: [
                          Text(
                            _selectedInputType == InputMediaType.image
                                ? 'AVATAR PHOTO (.JPG/.PNG)'
                                : 'CHARACTER VIDEO (.MP4)',
                            style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                          ),
                          Text(
                            ' *',
                            style: AppTextStyles.labelSmall(color: AppColors.primaryAction),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: isBusy ? null : _pickMedia,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 170.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: (_selectedInputType == InputMediaType.image
                                          ? _selectedImageFile
                                          : _selectedVideoFile) !=
                                      null
                                  ? AppColors.primaryAction
                                  : AppColors.borderSubtle,
                              width: 1.r,
                            ),
                          ),
                          child: _buildMediaPickerContent(),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // 3. Paragraph Text Input
                      Row(
                        children: [
                          Text(
                            'SPEECH PARAGRAPH TO SPEAK',
                            style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                          ),
                          Text(
                            ' *',
                            style: AppTextStyles.labelSmall(color: AppColors.primaryAction),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
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
                          controller: _textController,
                          enabled: !isBusy,
                          maxLines: 4,
                          maxLength: 500,
                          style: AppTextStyles.bodyM(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Enter the exact speech paragraph for the character to speak...',
                            hintStyle: AppTextStyles.bodyM(color: AppColors.textDisabled),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14.r),
                            counterStyle: AppTextStyles.caption(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // 4. AI Voice Selector
                      Text(
                        'SELECT AI VOICE CHARACTER',
                        style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: VoiceOption.values.map((option) {
                          final isSelected = _selectedVoice == option;
                          return Expanded(
                            child: GestureDetector(
                              onTap: isBusy ? null : () => setState(() => _selectedVoice = option),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: EdgeInsets.only(
                                  right: option == VoiceOption.values.last ? 0 : 8.w,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryAction
                                      : AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryAction
                                        : AppColors.borderSubtle,
                                    width: 1.r,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    option.displayName,
                                    style: AppTextStyles.labelMedium(
                                      color: isSelected ? Colors.white : AppColors.textMuted,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 32.h),

                      // 5. Action Button
                      Column(
                        children: [
                          AppButton(
                            label: isBusy
                                ? 'Processing AI Task...'
                                : _selectedInputType == InputMediaType.image
                                    ? 'Generate Talking Avatar Video'
                                    : 'Generate Lip-Sync Video',
                            isLoading: isBusy,
                            onPressed: isBusy ? null : _startLipSyncGeneration,
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 14.r,
                                color: AppColors.creditGoldIcon,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Estimated cost: 50 Credits',
                                style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 6. Output Result Video Card
                      if (_outputVideoUrl != null &&
                          _resultPlayerController != null &&
                          _resultPlayerController!.value.isInitialized) ...[
                        SizedBox(height: 32.h),
                        Divider(color: AppColors.borderSubtle, height: 1.h),
                        SizedBox(height: 24.h),
                        Text(
                          'GENERATED OUTPUT VIDEO',
                          style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.primaryAction,
                              width: 1.r,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: AspectRatio(
                              aspectRatio: _resultPlayerController!.value.aspectRatio,
                              child: VideoPlayer(_resultPlayerController!),
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ),

            // Real-Time Processing Overlay with Darkroom theme
            if (isBusy)
              Container(
                color: AppColors.bgApp.withAlpha(235),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ApertureIndicator(
                          size: 64.r,
                          color: AppColors.primaryAction,
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          _statusText.isNotEmpty ? _statusText : 'Processing AI Lip-Sync...',
                          style: AppTextStyles.headingSmall(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _selectedInputType == InputMediaType.image
                              ? 'AI LivePortrait is animating avatar facial expressions & speech audio.'
                              : 'AI is synthesizing speech audio and generating lip-synced video frames.',
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPickerContent() {
    final activeFile = _selectedInputType == InputMediaType.image
        ? _selectedImageFile
        : _selectedVideoFile;

    if (activeFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: const BoxDecoration(
              color: AppColors.emberSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedInputType == InputMediaType.image
                  ? Icons.photo_library_rounded
                  : Icons.video_library_rounded,
              size: 22.r,
              color: AppColors.primaryAction,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            _selectedInputType == InputMediaType.image
                ? 'Tap to select AI Avatar Photo'
                : 'Tap to select Character Video',
            style: AppTextStyles.bodyM(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _selectedInputType == InputMediaType.image
                ? 'Supports JPG or PNG images with a clear face'
                : 'Supports MP4 videos with clear facial movement',
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
        ],
      );
    }

    if (_selectedInputType == InputMediaType.image) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(
              _selectedImageFile!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: CircleAvatar(
              backgroundColor: AppColors.bgApp.withAlpha(200),
              radius: 14.r,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.close_rounded,
                  size: 14.r,
                  color: AppColors.textPrimary,
                ),
                onPressed: _clearSelectedMedia,
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 36.r,
                color: AppColors.statusSuccess,
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  _selectedVideoFile!.path.split('/').last,
                  style: AppTextStyles.bodyM(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Tap to change sample video',
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8.h,
          right: 8.w,
          child: CircleAvatar(
            backgroundColor: AppColors.bgApp,
            radius: 14.r,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.close_rounded,
                size: 14.r,
                color: AppColors.textPrimary,
              ),
              onPressed: _clearSelectedMedia,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/image_validator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/unfocus_on_tap.dart';
import '../../../wallet/controllers/wallet_controller.dart';
import '../controllers/video_gen_notifier.dart';
import '../widgets/aspect_ratio_selector_widget.dart';
import '../widgets/duration_selector_widget.dart';
import '../widgets/scene_script_input_widget.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/video_progress_overlay.dart';

class VideoGenerationScreen extends StatefulWidget {
  const VideoGenerationScreen({super.key});

  @override
  State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  late final VideoGenController _controller;
  final TextEditingController _scriptCtrl = TextEditingController();
  final ImageUploadService _uploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<VideoGenController>()) {
      _controller = Get.find<VideoGenController>();
    } else {
      _controller = Get.put(VideoGenController());
    }
  }

  @override
  void dispose() {
    _scriptCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _uploadService.pickImage(source);
    if (xFile == null) return;

    final validation = await ImageValidator.validateImage(
      filePath: xFile.path,
      featureTarget: AiFeatureTarget.generalAi,
      imageSource: source,
    );

    if (!validation.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              validation.errorMessage ?? 'Invalid image file.',
              style: AppTextStyles.bodyM(color: Colors.white),
            ),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
      return;
    }

    _controller.addLocalImage(File(xFile.path));
  }

  void _showImageSourcePicker() {
    if (_controller.state.value.localImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum of 3 reference images allowed.',
            style: AppTextStyles.bodyM(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryAction,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryAction),
                title: Text('Choose from Gallery', style: AppTextStyles.bodyM()),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryAction),
                title: Text('Take Photo', style: AppTextStyles.bodyM()),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitJob() {
    _controller.submitVideoJob(_scriptCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final walletCtrl = Get.find<WalletController>();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Fast Video Generator',
          style: AppTextStyles.headingM(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22.r),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: UnfocusOnTap(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Obx(() {
                final state = _controller.state.value;
                final walletBalance = walletCtrl.wallet.value?.balance ?? 0;
                final hasEnoughCredits = walletBalance >= state.requiredCredits;
                final isProcessing = state.status == VideoGenStatus.submitting ||
                    state.status == VideoGenStatus.uploadingAssets ||
                    state.status == VideoGenStatus.checkingCredits ||
                    state.status == VideoGenStatus.processing;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Description Card
                    Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.accentGlowSoft,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.videocam_rounded,
                              color: AppColors.primaryAction,
                              size: 24.r,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fast Tier Wan 2.2 Model',
                                  style: AppTextStyles.labelMedium(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Generate motion videos from text scripts & optional reference images.',
                                  style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Scene Script Text Area
                    SceneScriptInputWidget(
                      controller: _scriptCtrl,
                      onChanged: (_) => setState(() {}),
                    ),

                    SizedBox(height: 20.h),

                    // Reference Images Section (0 to 3 images)
                    Row(
                      children: [
                        Text(
                          'Reference Images (Optional, 0-3)',
                          style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        Text(
                          '${state.localImages.length}/3',
                          style: AppTextStyles.caption(color: AppColors.primaryAction),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 90.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.localImages.length < 3
                            ? state.localImages.length + 1
                            : state.localImages.length,
                        separatorBuilder: (_, _) => SizedBox(width: 10.w),
                        itemBuilder: (context, index) {
                          if (index < state.localImages.length) {
                            final file = state.localImages[index];
                            return Stack(
                              children: [
                                Container(
                                  width: 90.r,
                                  height: 90.r,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: AppColors.primaryAction, width: 1.r),
                                    image: DecorationImage(
                                      image: FileImage(file),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4.r,
                                  right: 4.r,
                                  child: GestureDetector(
                                    onTap: () => _controller.removeImageAt(index),
                                    child: CircleAvatar(
                                      radius: 12.r,
                                      backgroundColor: Colors.black.withAlpha(180),
                                      child: Icon(Icons.close_rounded, size: 14.r, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          // Add Button Box
                          return GestureDetector(
                            onTap: _showImageSourcePicker,
                            child: Container(
                              width: 90.r,
                              height: 90.r,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: AppColors.borderSubtle, width: 1.r),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, color: AppColors.primaryAction, size: 24.r),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Add Image',
                                    style: AppTextStyles.caption(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Duration Toggle: 10s (40 Credits) | 15s (50 Credits)
                    DurationSelectorWidget(
                      selectedDuration: state.selectedDuration,
                      onDurationChanged: (d) => _controller.setDuration(d),
                    ),

                    SizedBox(height: 24.h),

                    // Aspect Ratio Selector: 16:9 | 9:16 | 1:1
                    AspectRatioSelectorWidget(
                      selectedRatio: state.selectedAspectRatio,
                      onRatioChanged: (r) => _controller.setAspectRatio(r),
                    ),

                    SizedBox(height: 32.h),

                    // Wallet Warning Banner if low balance
                    if (!hasEnoughCredits) ...[
                      Container(
                        padding: EdgeInsets.all(12.r),
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.creditGoldBg,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: AppColors.creditGoldIcon, width: 1.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.creditGoldIcon, size: 20.r),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Insufficient wallet balance ($walletBalance credits available). You need ${state.requiredCredits} credits.',
                                style: AppTextStyles.bodySmall(color: AppColors.creditGoldTitle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Generate Button
                    AppButton(
                      label: 'Generate Video (${state.requiredCredits} Credits)',
                      isLoading: isProcessing,
                      onPressed: (!hasEnoughCredits || isProcessing || _scriptCtrl.text.trim().isEmpty)
                          ? null
                          : _submitJob,
                    ),

                    SizedBox(height: 32.h),
                  ],
                );
              }),
            ),

            // Live Progress Overlay Listener
            Obx(() {
              final state = _controller.state.value;

              if (state.status == VideoGenStatus.submitting ||
                  state.status == VideoGenStatus.uploadingAssets ||
                  state.status == VideoGenStatus.checkingCredits ||
                  state.status == VideoGenStatus.processing) {
                return VideoProgressOverlay(
                  stageMessage: state.activeStageMessage ?? 'Processing video generation...',
                  progressPercent: state.progressPercent,
                  durationSec: state.selectedDuration,
                );
              }

              // Terminal Error Popup Banner
              if (state.status == VideoGenStatus.error &&
                  state.errorMessage != null &&
                  state.errorMessage!.isNotEmpty) {
                return Positioned(
                  bottom: 20.h,
                  left: 20.w,
                  right: 20.w,
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.errorIndicatorSoft,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.errorIndicator, width: 1.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: AppColors.errorIndicator, size: 20.r),
                            SizedBox(width: 8.w),
                            Text(
                              'Generation Failed',
                              style: AppTextStyles.headingSmall(
                                color: AppColors.errorIndicator,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: AppColors.errorIndicator, size: 18.r),
                              onPressed: () => _controller.resetState(),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          state.errorMessage!,
                          style: AppTextStyles.bodySmall(color: AppColors.errorIndicator),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Terminal Success State -> Open Video Player Modal
              if (state.status == VideoGenStatus.completed &&
                  state.videoUrl != null &&
                  state.videoUrl!.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final url = state.videoUrl!;
                  _controller.resetState();
                  VideoPlayerModal.show(context, videoUrl: url);
                });
              }

              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}

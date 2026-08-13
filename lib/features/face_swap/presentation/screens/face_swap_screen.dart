import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/unfocus_on_tap.dart';
import '../../../video_generation/presentation/widgets/video_player_widget.dart';
import '../../../wallet/controllers/wallet_controller.dart';
import '../controllers/face_swap_notifier.dart';
import '../widgets/face_swap_progress_overlay.dart';
import '../widgets/recent_face_swaps_list.dart';
import '../widgets/source_face_picker.dart';
import '../widgets/video_template_selector.dart';

class FaceSwapScreen extends StatefulWidget {
  const FaceSwapScreen({super.key});

  @override
  State<FaceSwapScreen> createState() => _FaceSwapScreenState();
}

class _FaceSwapScreenState extends State<FaceSwapScreen> {
  late final FaceSwapController _controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<FaceSwapController>()) {
      _controller = Get.find<FaceSwapController>();
    } else {
      _controller = Get.put(FaceSwapController());
    }
  }

  void _submitJob() {
    HapticFeedback.mediumImpact();
    _controller.submitFaceSwap();
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
          'AI Video Face Swap',
          style: AppTextStyles.headingM(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22.r),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          Obx(() {
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
                  Icon(Icons.monetization_on_rounded, color: AppColors.creditGoldIcon, size: 16.r),
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
          }),
        ],
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
                final isProcessing = state.status == FaceSwapStatus.submitting ||
                    state.status == FaceSwapStatus.uploadingAssets ||
                    state.status == FaceSwapStatus.checkingCredits ||
                    state.status == FaceSwapStatus.processing;

                final canSubmit = hasEnoughCredits &&
                    !isProcessing &&
                    state.sourceFaceFile != null &&
                    (!state.selectedTemplate.isCustom || state.customVideoFile != null);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Header Card
                    Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.accentGlowSoft,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.face_retouching_natural_rounded,
                              color: AppColors.primaryAction,
                              size: 26.r,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Dance & Action Face Swap',
                                  style: AppTextStyles.labelMedium(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Swap any character face onto dance templates or your custom video.',
                                  style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // 1. Dance / Action Template Selector
                    VideoTemplateSelector(
                      selectedTemplate: state.selectedTemplate,
                      customVideoFile: state.customVideoFile,
                      onTemplateSelected: (template) => _controller.selectTemplate(template),
                      onCustomVideoPicked: (file) => _controller.setCustomVideo(file),
                    ),

                    SizedBox(height: 24.h),

                    // 2. Character Face Photo Picker
                    SourceFacePicker(
                      selectedFaceFile: state.sourceFaceFile,
                      onFaceSelected: (file) => _controller.setSourceFaceImage(file),
                    ),

                    SizedBox(height: 28.h),

                    // Wallet Warning Banner
                    if (!hasEnoughCredits) ...[
                      Container(
                        padding: EdgeInsets.all(12.r),
                        margin: EdgeInsets.only(bottom: 14.h),
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
                                'Insufficient wallet balance ($walletBalance credits available). Face Swap requires ${state.requiredCredits} credits.',
                                style: AppTextStyles.bodySmall(color: AppColors.creditGoldTitle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Error Notice Banner (Inline)
                    if (state.status == FaceSwapStatus.error &&
                        state.errorMessage != null &&
                        state.errorMessage!.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.all(16.r),
                        margin: EdgeInsets.only(bottom: 16.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF221115),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: AppColors.statusError.withAlpha(160), width: 1.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 20.r),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    'Face Swap Notice',
                                    style: AppTextStyles.headingSmall(
                                      color: AppColors.statusError,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: AppColors.slate, size: 18.r),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _controller.resetState(),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              state.errorMessage!,
                              style: AppTextStyles.bodySmall(color: AppColors.bone),
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (state.errorMessage!.toLowerCase().contains('credit') ||
                                    state.errorMessage!.toLowerCase().contains('balance')) ...[
                                  TextButton(
                                    onPressed: () {
                                      _controller.resetState();
                                      Get.toNamed(AppRoutes.homeShell);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.statusWarning,
                                    ),
                                    child: const Text('Top Up Balance'),
                                  ),
                                  SizedBox(width: 8.w),
                                ],
                                ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _controller.resetState();
                                    _submitJob();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.ember,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  child: Text(
                                    'Try Again',
                                    style: AppTextStyles.caption(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Submit Action Button
                    AppButton(
                      label: 'Swap Face & Generate Video (${state.requiredCredits} Credits)',
                      isLoading: isProcessing,
                      onPressed: canSubmit ? _submitJob : null,
                    ),

                    SizedBox(height: 28.h),

                    // 3. Recent Face Swaps History Section
                    RecentFaceSwapsList(
                      onSwapAnother: () => _controller.setSourceFaceImage(null),
                    ),

                    SizedBox(height: 32.h),
                  ],
                );
              }),
            ),

            // Live Progress Overlay
            Obx(() {
              final state = _controller.state.value;

              if (state.status == FaceSwapStatus.submitting ||
                  state.status == FaceSwapStatus.uploadingAssets ||
                  state.status == FaceSwapStatus.checkingCredits ||
                  state.status == FaceSwapStatus.processing) {
                return FaceSwapProgressOverlay(
                  stageMessage: state.activeStageMessage ?? 'Processing face swap video...',
                  progressPercent: state.progressPercent,
                );
              }

              // Terminal Success State -> Automatically Show VideoPlayerModal
              if (state.status == FaceSwapStatus.completed &&
                  state.videoUrl != null &&
                  state.videoUrl!.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final url = state.videoUrl!;
                  _controller.resetState();
                  VideoPlayerModal.show(
                    context,
                    videoUrl: url,
                    onSwapAnother: () {
                      _controller.setSourceFaceImage(null);
                    },
                  );
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

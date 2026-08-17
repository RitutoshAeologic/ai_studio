import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/preset_themes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/utils/image_crop_helper.dart';
import '../../../core/utils/image_validator.dart';
import '../../../core/widgets/aperture_indicator.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/entities/job_entity.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../gallery/widgets/image_result_modal.dart';
import '../../jobs/controllers/job_controller.dart';
import '../../mesh/views/mesh_viewer_view.dart';

/// Task F2.1 — Generation Studio Canvas
/// Interactive editor screen powering the Generate tab in HomeShellView.
/// Responsive layout using ScreenUtil, AppStrings, AppColors, and AppTextStyles per ui_ux.md.
class GenerationStudioView extends StatefulWidget {
  const GenerationStudioView({super.key});

  @override
  State<GenerationStudioView> createState() => _GenerationStudioViewState();
}

class _GenerationStudioViewState extends State<GenerationStudioView> {
  final _promptCtrl = TextEditingController();
  final _imageUploadService = ImageUploadService();

  JobType _selectedJobType = JobType.imageGen;
  int? _selectedThemeId;
  bool _isUsingCustomPrompt = true;

  File? _selectedImageFile;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  bool _isLocallySubmitting = false;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  void _selectMode(JobType type, bool isBusy) {
    if (isBusy) return;
    if (type == JobType.videoFaceSwap) {
      Get.toNamed(AppRoutes.faceSwap);
      return;
    }
    if (type == JobType.videoGen) {
      Get.toNamed(AppRoutes.videoGen);
      return;
    }
    setState(() {
      _selectedJobType = type;
      if (type == JobType.meshGen) {
        _isUsingCustomPrompt = false;
        if (_selectedThemeId == null && PresetThemes.list.isNotEmpty) {
          _selectedThemeId = PresetThemes.list.first.themeId;
        }
      } else if (type == JobType.bgRemoval) {
        _selectedThemeId = null;
      }
    });
  }

  void _selectTheme(int themeId, bool isBusy) {
    if (isBusy) return;
    setState(() {
      if (_selectedThemeId == themeId) {
        _selectedThemeId = null;
      } else {
        _selectedThemeId = themeId;
        _isUsingCustomPrompt = false;
        _promptCtrl.clear();
      }
    });
  }

  void _resetThemeSelection(bool isBusy) {
    if (isBusy) return;
    setState(() {
      _selectedThemeId = null;
    });
  }

  void _switchToCustomPrompt(bool isBusy) {
    if (isBusy) return;
    setState(() {
      _isUsingCustomPrompt = true;
      _selectedThemeId = null;
    });
  }

  void _switchToPresetGrid(bool isBusy) {
    if (isBusy) return;
    setState(() {
      _isUsingCustomPrompt = false;
      if (_selectedThemeId == null && PresetThemes.list.isNotEmpty) {
        _selectedThemeId = PresetThemes.list.first.themeId;
      }
    });
  }

  Future<void> _pickInputImage(ImageSource source) async {
    if (_isUploadingImage || _isLocallySubmitting) return;

    final xFile = await _imageUploadService.pickImage(source);
    if (xFile == null) return;

    // 1. Crop image with themed cropper UI
    final croppedPath = await ImageCropHelper.cropImage(sourcePath: xFile.path);
    if (croppedPath == null) return; // User cancelled cropping

    final featureTarget = _selectedJobType == JobType.meshGen
        ? AiFeatureTarget.imageTo3d
        : _selectedJobType == JobType.bgRemoval
            ? AiFeatureTarget.backgroundReplacement
            : _selectedJobType == JobType.themeChange
                ? AiFeatureTarget.themeChange
                : AiFeatureTarget.generalAi;

    // 2. Validate cropped image
    final validation = await ImageValidator.validateImage(
      filePath: croppedPath,
      featureTarget: featureTarget,
      imageSource: source,
    );

    if (!validation.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              validation.errorMessage ?? AppStrings.imageCorrupted,
              style: AppTextStyles.bodyMedium(color: AppColors.bone),
            ),
            backgroundColor: AppColors.statusError,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final file = File(croppedPath);
    setState(() {
      _selectedImageFile = file;
      _isUploadingImage = true;
    });

    final authCtrl = Get.find<AuthController>();
    final userId = authCtrl.currentUser.value?.uid ?? 'guest';

    final result = await _imageUploadService.uploadImage(
      file: file,
      userId: userId,
    );

    result.fold(
      (uploadResult) {
        if (mounted) {
          setState(() {
            _uploadedImageUrl = uploadResult.downloadUrl;
            _isUploadingImage = false;
          });
        }
      },
      (failure) {
        if (mounted) {
          setState(() => _isUploadingImage = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppStrings.imageUploadFailedNotice}${failure.message}',
                style: AppTextStyles.bodyMedium(color: Colors.white),
              ),
              backgroundColor: AppColors.statusError,
            ),
          );
        }
      },
    );
  }

  void _clearSelectedImage() {
    if (_isUploadingImage || _isLocallySubmitting) return;
    setState(() {
      _selectedImageFile = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _submitJob() async {
    final jobCtrl = Get.find<JobController>();

    if ((_selectedJobType == JobType.bgRemoval ||
            _selectedJobType == JobType.meshGen ||
            _selectedJobType == JobType.themeChange) &&
        _uploadedImageUrl == null &&
        _selectedImageFile == null) {
      final notice = _selectedJobType == JobType.meshGen
          ? AppStrings.selectInputImageMeshNotice
          : _selectedJobType == JobType.themeChange
              ? AppStrings.selectInputImageThemeChangeNotice
              : AppStrings.selectInputImageBgRemovalNotice;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notice,
            style: AppTextStyles.bodyM(color: AppColors.creditGoldTitle),
          ),
          backgroundColor: AppColors.creditGoldBg,
        ),
      );
      return;
    }

    if (_isUsingCustomPrompt &&
        _promptCtrl.text.trim().isEmpty &&
        _selectedJobType != JobType.bgRemoval &&
        _selectedJobType != JobType.meshGen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.enterDescriptionNotice,
            style: AppTextStyles.bodyM(color: AppColors.creditGoldTitle),
          ),
          backgroundColor: AppColors.creditGoldBg,
        ),
      );
      return;
    }

    final params = JobParams(
      userPrompt: _isUsingCustomPrompt && _promptCtrl.text.trim().isNotEmpty
          ? _promptCtrl.text.trim()
          : null,
      themeId: !_isUsingCustomPrompt ? _selectedThemeId : null,
      imageUrl: _uploadedImageUrl,
    );

    final request = GenerateJobRequest(
      jobType: _selectedJobType,
      tier: 'FAST',
      params: params,
    );

    setState(() {
      _isLocallySubmitting = true;
    });

    try {
      final jobId = await jobCtrl.submitJob(request);
      if (jobId != null) {
        jobCtrl.watchJob(jobId);
      } else {
        final error = jobCtrl.submissionError.value;
        if (mounted && error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error,
                style: AppTextStyles.bodyMedium(color: Colors.white),
              ),
              backgroundColor: AppColors.statusError,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocallySubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobCtrl = Get.find<JobController>();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
              final status = jobCtrl.status.value;
              final isSubmitting = jobCtrl.isSubmitting.value;
              final isProcessing = jobCtrl.isProcessing.value;
              final isBusy = isSubmitting ||
                  isProcessing ||
                  status.isActive ||
                  _isUploadingImage ||
                  _isLocallySubmitting;

              return IgnorePointer(
                ignoring: isBusy,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isBusy ? 0.55 : 1.0,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mode Selection Bar
                        Text(
                          AppStrings.studioMode,
                          style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                        ),
                        SizedBox(height: 8.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildModeChip(
                                JobType.imageGen,
                                AppStrings.imageGenTab,
                                Icons.auto_awesome_rounded,
                                isBusy,
                              ),
                              SizedBox(width: 8.w),
                              _buildModeChip(
                                JobType.meshGen,
                                AppStrings.mesh3dTab,
                                Icons.view_in_ar_rounded,
                                isBusy,
                              ),
                              SizedBox(width: 8.w),
                              _buildModeChip(
                                JobType.bgRemoval,
                                AppStrings.bgRemovalTab,
                                Icons.content_cut_rounded,
                                isBusy,
                              ),
                              SizedBox(width: 8.w),
                              _buildModeChip(
                                JobType.themeChange,
                                AppStrings.themeChangeTab,
                                Icons.style_rounded,
                                isBusy,
                              ),
                              SizedBox(width: 8.w),
                              _buildModeChip(
                                JobType.videoFaceSwap,
                                'Face Swap',
                                Icons.face_retouching_natural_rounded,
                                isBusy,
                              ),
                              SizedBox(width: 8.w),
                              _buildModeChip(
                                JobType.videoGen,
                                'Video Gen',
                                Icons.videocam_rounded,
                                isBusy,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Image Input Picker Section
                        if (_selectedJobType == JobType.bgRemoval ||
                            _selectedJobType == JobType.meshGen ||
                            _selectedJobType == JobType.themeChange ||
                            _selectedJobType == JobType.imageGen) ...[
                          Row(
                            children: [
                              Text(
                                AppStrings.inputImageLabel,
                                style: AppTextStyles.labelSmall(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (_selectedJobType == JobType.bgRemoval ||
                                  _selectedJobType == JobType.meshGen ||
                                  _selectedJobType == JobType.themeChange)
                                Text(
                                  AppStrings.requiredTag,
                                  style: AppTextStyles.labelSmall(
                                    color: AppColors.primaryAction,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          _buildImagePickerBox(isBusy),
                          SizedBox(height: 24.h),
                        ],

                        // Prompt & Theme Section for Image Gen & Theme Change
                        if (_selectedJobType == JobType.imageGen ||
                            _selectedJobType == JobType.themeChange) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.promptAndThemeLabel,
                                style: AppTextStyles.labelSmall(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _switchToCustomPrompt(isBusy),
                                    child: Text(
                                      AppStrings.customPromptTab,
                                      style: AppTextStyles.labelSmall(
                                        color: _isUsingCustomPrompt
                                            ? AppColors.primaryAction
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  GestureDetector(
                                    onTap: () => _switchToPresetGrid(isBusy),
                                    child: Text(
                                      AppStrings.presetGridTab,
                                      style: AppTextStyles.labelSmall(
                                        color: !_isUsingCustomPrompt
                                            ? AppColors.primaryAction
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),

                          if (_isUsingCustomPrompt) ...[
                            // Custom Prompt Input
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
                                controller: _promptCtrl,
                                enabled: !isBusy,
                                maxLines: 4,
                                style: AppTextStyles.bodyM(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppStrings.genPromptHint,
                                  hintStyle: AppTextStyles.bodyM(
                                    color: AppColors.textDisabled,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(14.r),
                                ),
                              ),
                            ),
                          ] else ...[
                            _buildPresetGrid(isBusy),
                          ],
                        ],

                        // Preset Grid Section for 3D Mesh Mode
                        if (_selectedJobType == JobType.meshGen) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.presetGridTab.toUpperCase(),
                                style: AppTextStyles.labelSmall(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (_selectedThemeId != null)
                                GestureDetector(
                                  onTap: () => _resetThemeSelection(isBusy),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.restart_alt_rounded,
                                        size: 14.r,
                                        color: AppColors.ember,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        AppStrings.resetSelection,
                                        style: AppTextStyles.labelSmall(
                                          color: AppColors.ember,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          _buildPresetGrid(isBusy),
                        ],

                        SizedBox(height: 32.h),

                        // Generate Action Button
                        Column(
                          children: [
                            AppButton(
                              label: _isUploadingImage
                                  ? AppStrings.uploadingImageEllipsis
                                  : isBusy
                                      ? 'Processing AI Task...'
                                      : AppStrings.generateCreation,
                              isLoading: isBusy,
                              onPressed: isBusy ? null : _submitJob,
                            ),
                            if (jobCtrl.lastJobCost.value > 0) ...[
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
                                    '${AppStrings.estimatedCostPrefix}${jobCtrl.lastJobCost.value}${AppStrings.estimatedCostSuffix}',
                                    style: AppTextStyles.bodySmall(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Realtime Job Status Processing Overlay — Shows with ZERO time gap
            Obx(() {
              final status = jobCtrl.status.value;
              final isSubmitting = jobCtrl.isSubmitting.value;
              final isProcessing = jobCtrl.isProcessing.value;
              final showOverlay = isSubmitting ||
                  isProcessing ||
                  status.isActive ||
                  _isLocallySubmitting;

              if (showOverlay) {
                return Container(
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
                            status == JobStatus.pending
                                ? AppStrings.initializingJob
                                : status == JobStatus.deductingCredits
                                    ? AppStrings.verifyingCredits
                                    : status == JobStatus.queued
                                        ? AppStrings.queuedOnServer
                                        : AppStrings.processingCreation,
                            style: AppTextStyles.headingSmall(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            AppStrings.generativeAiWorkingNotice,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Terminal Error State Notification
              final errorMsg = jobCtrl.jobError.value;
              if (jobCtrl.isError.value && errorMsg.isNotEmpty) {
                return Positioned(
                  bottom: 20.h,
                  left: 20.w,
                  right: 20.w,
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.errorIndicatorSoft,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.errorIndicator,
                        width: 1.r,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.errorIndicator,
                              size: 20.r,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              AppStrings.generationErrorTitle,
                              style: AppTextStyles.headingSmall(
                                color: AppColors.errorIndicator,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppColors.errorIndicator,
                                size: 18.r,
                              ),
                              onPressed: () => jobCtrl.stopWatching(),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          errorMsg,
                          style: AppTextStyles.bodySmall(
                            color: AppColors.errorIndicator,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Terminal Success State Trigger
              if (jobCtrl.isCompleted.value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final outputUrl = jobCtrl.outputUrl;
                  final meshUrl = jobCtrl.meshUrl;
                  jobCtrl.stopWatching();

                  final effectiveMesh = (meshUrl != null && meshUrl.isNotEmpty)
                      ? meshUrl
                      : (outputUrl != null && outputUrl.contains('.glb'))
                          ? outputUrl
                          : null;

                  if (effectiveMesh != null) {
                    MeshViewerModal.show(context, meshUrl: effectiveMesh);
                  } else if (outputUrl != null && outputUrl.isNotEmpty) {
                    ImageResultModal.show(context, imageUrl: outputUrl);
                  }
                });
              }

              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(JobType type, String label, IconData icon, bool isBusy) {
    final isSelected = _selectedJobType == type;

    return GestureDetector(
      onTap: () => _selectMode(type, isBusy),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.r,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: AppTextStyles.labelMedium(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerBox(bool isBusy) {
    if (_selectedImageFile != null) {
      return Stack(
        children: [
          Container(
            height: 160.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primaryAction,
                width: 1.5.r,
              ),
              image: DecorationImage(
                image: FileImage(_selectedImageFile!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (_isUploadingImage)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgApp.withAlpha(180),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAction,
                  ),
                ),
              ),
            ),
          if (!isBusy)
            Positioned(
              top: 8.h,
              right: 8.w,
              child: CircleAvatar(
                backgroundColor: AppColors.bgApp,
                radius: 16.r,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16.r,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: _clearSelectedImage,
                ),
              ),
            ),
        ],
      );
    }

    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderSubtle, width: 1.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: isBusy ? null : () => _pickInputImage(ImageSource.gallery),
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primaryAction,
                    size: 28.r,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    AppStrings.pickFromGallery,
                    style: AppTextStyles.labelMedium(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1.w,
            height: 40.h,
            color: AppColors.borderSubtle,
          ),
          InkWell(
            onTap: isBusy ? null : () => _pickInputImage(ImageSource.camera),
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primaryAction,
                    size: 28.r,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    AppStrings.takePhoto,
                    style: AppTextStyles.labelMedium(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetGrid(bool isBusy) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
      ),
      itemCount: PresetThemes.list.length,
      itemBuilder: (context, index) {
        final theme = PresetThemes.list[index];
        final isSelected = _selectedThemeId == theme.themeId;

        return GestureDetector(
          onTap: () => _selectTheme(theme.themeId, isBusy),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accentGlowSoft
                  : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryAction
                    : AppColors.borderSubtle,
                width: isSelected ? 1.5.r : 1.r,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  theme.icon,
                  color: isSelected
                      ? AppColors.primaryAction
                      : AppColors.textMuted,
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        theme.title,
                        style: AppTextStyles.labelMedium(
                          color: isSelected
                              ? AppColors.primaryAction
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        theme.category,
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

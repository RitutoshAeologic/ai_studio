import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/preset_themes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/widgets/aperture_indicator.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/entities/job_entity.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../gallery/widgets/image_result_modal.dart';
import '../../jobs/controllers/job_controller.dart';
import '../../mesh/views/mesh_viewer_view.dart';

/// Task F2.1 — Generation Studio Canvas
/// Interactive editor screen powering the Generate tab in HomeShellView.
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

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  void _selectMode(JobType type) {
    setState(() {
      _selectedJobType = type;
      // BG_REMOVAL doesn't need prompt or theme
      if (type == JobType.bgRemoval) {
        _selectedThemeId = null;
      }
    });
  }

  void _selectTheme(int themeId) {
    setState(() {
      _selectedThemeId = themeId;
      _isUsingCustomPrompt = false;
      _promptCtrl.clear();
    });
  }

  void _switchToCustomPrompt() {
    setState(() {
      _isUsingCustomPrompt = true;
      _selectedThemeId = null;
    });
  }

  Future<void> _pickInputImage(ImageSource source) async {
    final xFile = await _imageUploadService.pickImage(source);
    if (xFile == null) return;

    final file = File(xFile.path);
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
      (url) {
        setState(() {
          _uploadedImageUrl = url;
          _isUploadingImage = false;
        });
      },
      (failure) {
        setState(() => _isUploadingImage = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image upload failed: ${failure.message}'),
              backgroundColor: AppColors.statusError,
            ),
          );
        }
      },
    );
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageFile = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _submitJob() async {
    final jobCtrl = Get.find<JobController>();

    // Validate requirements per job type
    if (_selectedJobType == JobType.bgRemoval && _uploadedImageUrl == null && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an input image for background removal.'),
          backgroundColor: AppColors.statusWarning,
        ),
      );
      return;
    }

    if (_isUsingCustomPrompt && _promptCtrl.text.trim().isEmpty && _selectedJobType != JobType.bgRemoval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description or pick a theme preset.'),
          backgroundColor: AppColors.statusWarning,
        ),
      );
      return;
    }

    // Build payload matching server schema requirements
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

    final jobId = await jobCtrl.submitJob(request);
    if (jobId != null) {
      jobCtrl.watchJob(jobId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobCtrl = Get.find<JobController>();

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Mode Selection Bar ─────────────────────────────────────
                  Text('STUDIO MODE', style: AppTextStyles.labelSmall(color: AppColors.slate)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildModeChip(JobType.imageGen, 'Image Gen', Icons.auto_awesome),
                        const SizedBox(width: 8),
                        _buildModeChip(JobType.meshGen, '3D Mesh', Icons.view_in_ar),
                        const SizedBox(width: 8),
                        _buildModeChip(JobType.bgRemoval, 'BG Removal', Icons.content_cut),
                        const SizedBox(width: 8),
                        _buildModeChip(JobType.themeChange, 'Theme Change', Icons.style),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Image Input Picker Section ─────────────────────────────
                  if (_selectedJobType == JobType.bgRemoval ||
                      _selectedJobType == JobType.themeChange ||
                      _selectedJobType == JobType.imageGen) ...[
                    Row(
                      children: [
                        Text('INPUT IMAGE', style: AppTextStyles.labelSmall(color: AppColors.slate)),
                        if (_selectedJobType == JobType.bgRemoval)
                          Text(' (REQUIRED)', style: AppTextStyles.labelSmall(color: AppColors.ember)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildImagePickerBox(),
                    const SizedBox(height: 24),
                  ],

                  // ── Prompt / Theme Section ──────────────────────────────────
                  if (_selectedJobType != JobType.bgRemoval) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PROMPT & THEME', style: AppTextStyles.labelSmall(color: AppColors.slate)),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _switchToCustomPrompt,
                              child: Text(
                                'Custom Prompt',
                                style: AppTextStyles.labelSmall(
                                  color: _isUsingCustomPrompt ? AppColors.ember : AppColors.slate,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                if (_selectedThemeId == null && PresetThemes.list.isNotEmpty) {
                                  _selectTheme(PresetThemes.list.first.themeId);
                                }
                              },
                              child: Text(
                                'Preset Grid',
                                style: AppTextStyles.labelSmall(
                                  color: !_isUsingCustomPrompt ? AppColors.ember : AppColors.slate,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_isUsingCustomPrompt) ...[
                      // Custom Prompt Input
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: TextField(
                          controller: _promptCtrl,
                          maxLines: 4,
                          style: AppTextStyles.bodyMedium(),
                          decoration: InputDecoration(
                            hintText: _selectedJobType == JobType.meshGen
                                ? 'Describe the 3D model you want to generate (e.g., "A futuristic cyberpunk helmet with glowing visor")...'
                                : 'Describe what you want to create or modify...',
                            hintStyle: AppTextStyles.bodyMedium(color: AppColors.textDisabled),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Theme Preset Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: PresetThemes.list.length,
                        itemBuilder: (context, index) {
                          final theme = PresetThemes.list[index];
                          final isSelected = _selectedThemeId == theme.themeId;

                          return GestureDetector(
                            onTap: () => _selectTheme(theme.themeId),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.emberSoft : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.ember : AppColors.borderSubtle,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    theme.icon,
                                    color: isSelected ? AppColors.ember : AppColors.slate,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          theme.title,
                                          style: AppTextStyles.labelMedium(
                                            color: isSelected ? AppColors.ember : AppColors.bone,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          theme.category,
                                          style: AppTextStyles.bodySmall(color: AppColors.slate),
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
                      ),
                    ],
                  ],

                  const SizedBox(height: 32),

                  // ── Generate Action Button ─────────────────────────────────
                  Obx(() {
                    final cost = jobCtrl.lastJobCost.value;
                    final isBusy = jobCtrl.isSubmitting.value || jobCtrl.isProcessing.value || _isUploadingImage;

                    return Column(
                      children: [
                        AppButton(
                          label: _isUploadingImage
                              ? 'Uploading Image...'
                              : 'Generate Creation',
                          isLoading: isBusy,
                          onPressed: isBusy ? null : _submitJob,
                        ),
                        if (cost > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 14, color: AppColors.ember),
                              const SizedBox(width: 4),
                              Text(
                                'Estimated cost: $cost credits (Fast Tier)',
                                style: AppTextStyles.bodySmall(color: AppColors.slate),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  }),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // ── Realtime Job Status Processing Overlay ───────────────────────
            Obx(() {
              final status = jobCtrl.status.value;
              final errorMsg = jobCtrl.jobError.value;

              if (status.isActive || jobCtrl.isSubmitting.value) {
                return Container(
                  color: AppColors.ink.withAlpha(235),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ApertureIndicator(size: 64, color: AppColors.ember),
                          const SizedBox(height: 24),
                          Text(
                            status == JobStatus.pending
                                ? 'Initializing Job...'
                                : status == JobStatus.deductingCredits
                                    ? 'Verifying Credits...'
                                    : status == JobStatus.queued
                                        ? 'Queued on Studio Server...'
                                        : 'Processing Creation...',
                            style: AppTextStyles.headingSmall(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generative AI models at work — please hold on',
                            style: AppTextStyles.bodySmall(color: AppColors.slate),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Terminal Error State Notification
              if (jobCtrl.isError.value && errorMsg.isNotEmpty) {
                return Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.statusErrorSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.statusError),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.statusError, size: 20),
                            const SizedBox(width: 8),
                            Text('Generation Error', style: AppTextStyles.headingSmall(color: AppColors.statusError)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.statusError, size: 18),
                              onPressed: () => jobCtrl.stopWatching(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          errorMsg,
                          style: AppTextStyles.bodySmall(color: AppColors.statusError),
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

                  if (meshUrl != null && meshUrl.isNotEmpty) {
                    MeshViewerModal.show(context, meshUrl: meshUrl);
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

  Widget _buildModeChip(JobType type, String label, IconData icon) {
    final isSelected = _selectedJobType == type;

    return GestureDetector(
      onTap: () => _selectMode(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ember : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.ember : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.bone : AppColors.slate,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium(
                color: isSelected ? AppColors.bone : AppColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerBox() {
    if (_selectedImageFile != null) {
      return Stack(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ember),
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
                  color: AppColors.ink.withAlpha(180),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.ember),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: AppColors.ink,
              radius: 16,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 16, color: AppColors.bone),
                onPressed: _clearSelectedImage,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () => _pickInputImage(ImageSource.gallery),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined, color: AppColors.ember, size: 28),
                  const SizedBox(height: 6),
                  Text('Pick from Gallery', style: AppTextStyles.labelMedium(color: AppColors.bone)),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.borderSubtle),
          InkWell(
            onTap: () => _pickInputImage(ImageSource.camera),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: AppColors.ember, size: 28),
                  const SizedBox(height: 6),
                  Text('Take Photo', style: AppTextStyles.labelMedium(color: AppColors.bone)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

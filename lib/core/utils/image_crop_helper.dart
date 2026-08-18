import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../constants/app_colors.dart';
import 'logger.dart';

/// Centralized image cropping helper with app-themed dark styling.
abstract class ImageCropHelper {
  /// Launches the native image cropper for [sourcePath].
  /// Returns the cropped file path on success, or `null` if user cancelled.
  static Future<String?> cropImage({
    required String sourcePath,
    CropAspectRatio? aspectRatio,
    List<CropAspectRatioPreset>? uiPresets,
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop & Adjust Image',
            toolbarColor: AppColors.bgApp,
            toolbarWidgetColor: Colors.white,
            backgroundColor: AppColors.bgApp,
            activeControlsWidgetColor: AppColors.ember,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: uiPresets ??
                [
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9,
                ],
          ),
          IOSUiSettings(
            title: 'Crop & Adjust Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            aspectRatioPresets: uiPresets ??
                [
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9,
                ],
          ),
        ],
      );

      return croppedFile?.path;
    } catch (e) {
      Logger.w('Image cropping error or skipped: $e');
      return null;
    }
  }
}

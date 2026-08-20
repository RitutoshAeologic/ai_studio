import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../constants/app_colors.dart';
import 'logger.dart';

/// Centralized image cropping helper with app-themed dark styling.
///
/// Uses [image_cropper] v12+ which on iOS:
///  - Finds the FlutterViewController's window separately from the camera's
///    keyWindow (UISceneDelegate-aware)
///  - Properly waits for the camera VC's dismiss animation to complete before
///    presenting TOCropViewController via a UIKit completion block
/// This makes the helper fully race-condition-free on iOS — no timing hacks needed.
abstract class ImageCropHelper {
  /// Cleans and normalizes file paths by stripping 'file://' prefixes.
  static String normalizePath(String path) {
    if (path.startsWith('file://')) {
      try {
        return Uri.parse(path).toFilePath();
      } catch (_) {
        return path.replaceFirst('file://', '');
      }
    }
    return path;
  }

  /// Launches the native image cropper for [sourcePath].
  ///
  /// Returns the cropped file path on success, or `null` if the user cancelled.
  static Future<String?> cropImage({
    required String sourcePath,
    CropAspectRatio? aspectRatio,
    List<CropAspectRatioPreset>? uiPresets,
  }) async {
    final cleanSource = normalizePath(sourcePath);
    if (!File(cleanSource).existsSync()) {
      Logger.w('ImageCropHelper: source file does not exist: $cleanSource');
      return null;
    }

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: cleanSource,
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

      if (croppedFile != null) {
        final resultPath = normalizePath(croppedFile.path);
        if (File(resultPath).existsSync()) {
          return resultPath;
        }
      }
      return null;
    } catch (e) {
      Logger.w('Image cropping error: $e');
      return null;
    }
  }
}



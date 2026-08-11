import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/image_validation_result.dart';
import '../constants/app_strings.dart';
import 'logger.dart';

/// Target AI generation pipeline feature for feature-dependent validation.
enum AiFeatureTarget {
  imageTo3d,
  characterConsistency,
  backgroundReplacement,
  themeChange,
  generalAi,
}

/// High-performance Frontend Image Validation Pipeline.
///
/// Uses a HYBRID approach based on the image source:
/// - [ImageSource.gallery]: Only validates file integrity (size, format, decode).
///   Gallery images are already OS-processed and guaranteed to be valid content.
/// - [ImageSource.camera]: Adds blur detection on top of integrity checks.
///   Live camera captures can be blurry due to hand shake or covered lens.
abstract class ImageValidator {
  static const int minFileSizeBytes = 512; // 0.5 KB
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20 MB

  /// Main entrypoint: Validates an image file for a given AI feature target.
  ///
  /// Pass [imageSource] to apply the correct validation strategy:
  /// - [ImageSource.gallery] → integrity checks only (no pixel heuristics)
  /// - [ImageSource.camera]  → integrity checks + blur detection
  static Future<ImageValidationResult> validateImage({
    required String filePath,
    required AiFeatureTarget featureTarget,
    ImageSource imageSource = ImageSource.gallery,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return ImageValidationResult.failure(AppStrings.imageCorrupted);
      }

      // 1. File Size Check (applies to both sources)
      final fileSizeBytes = file.lengthSync();
      if (fileSizeBytes < minFileSizeBytes) {
        return ImageValidationResult.failure(AppStrings.imageTooSmall);
      }
      if (fileSizeBytes > maxFileSizeBytes) {
        return ImageValidationResult.failure(AppStrings.imageTooLarge);
      }

      // 2. Format / Extension Check (applies to both sources)
      final ext = filePath.toLowerCase();
      final isSupportedExt = ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.png') ||
          ext.endsWith('.webp') ||
          ext.endsWith('.heic');
      if (!isSupportedExt) {
        return ImageValidationResult.failure(AppStrings.imageInvalidFormat);
      }

      // 3. Offload pixel analysis to background isolate for zero UI jank
      final bytes = await file.readAsBytes();
      return await compute(
        _analyzeImageBytes,
        _ValidationParams(
          bytes: bytes,
          fileSizeBytes: fileSizeBytes,
          featureTarget: featureTarget,
          // Camera photos need blur check; gallery images do not.
          isFromCamera: imageSource == ImageSource.camera,
        ),
      );
    } catch (e, stackTrace) {
      Logger.e('Error validating image', e, stackTrace);
      return ImageValidationResult.failure(AppStrings.imageCorrupted);
    }
  }
}

class _ValidationParams {
  final Uint8List bytes;
  final int fileSizeBytes;
  final AiFeatureTarget featureTarget;
  final bool isFromCamera;

  _ValidationParams({
    required this.bytes,
    required this.fileSizeBytes,
    required this.featureTarget,
    required this.isFromCamera,
  });
}

/// Isolated worker function for image decoding & pixel matrix analysis.
ImageValidationResult _analyzeImageBytes(_ValidationParams params) {
  // Decode image — rejects corrupt/unreadable files regardless of source
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) {
    return ImageValidationResult.failure(AppStrings.imageCorrupted);
  }

  final width = decoded.width;
  final height = decoded.height;

  // --- GALLERY PATH ---
  // Gallery images are OS-processed (saved by the photo library, already valid).
  // We only verify the bitmap decoded successfully above and return immediately.
  if (!params.isFromCamera) {
    return ImageValidationResult.success(
      width: width,
      height: height,
      fileSizeBytes: params.fileSizeBytes,
      brightness: 0.5,
      contrastScore: 1.0,
      blurScore: 100.0,
      subjectFocusScore: 1.0,
    );
  }

  // --- CAMERA PATH ---
  // Live camera captures can be blurry (hand-shake, covered lens, etc.).
  // Downsample for fast pixel analysis.
  final sample = img.copyResize(decoded, width: 64, height: 64);
  final sampleWidth = sample.width;
  final sampleHeight = sample.height;
  final totalPixels = sampleWidth * sampleHeight;

  // Build luminance map
  double sumLuminance = 0.0;
  final List<double> luminances = List<double>.filled(totalPixels, 0.0);
  int idx = 0;

  for (int y = 0; y < sampleHeight; y++) {
    for (int x = 0; x < sampleWidth; x++) {
      final pixel = sample.getPixel(x, y);
      final r = pixel.r / 255.0;
      final g = pixel.g / 255.0;
      final b = pixel.b / 255.0;
      final lum = 0.299 * r + 0.587 * g + 0.114 * b;
      luminances[idx++] = lum;
      sumLuminance += lum;
    }
  }

  final meanLuminance = sumLuminance / totalPixels;

  // Standard deviation — rejects flat/blank/covered camera lens
  double sumSqDiff = 0.0;
  for (int i = 0; i < totalPixels; i++) {
    final diff = luminances[i] - meanLuminance;
    sumSqDiff += diff * diff;
  }
  final stdDevLuminance = sqrt(sumSqDiff / totalPixels);

  // Camera-specific: Reject covered lens (pitch black) or lens cap / pointed at
  // a wall (all-white flash). stdDev < 0.015 means near-zero variation in any
  // live capture — indicates a covered or blank real-world scene.
  if (stdDevLuminance < 0.015) {
    return ImageValidationResult.failure(
        AppStrings.imageBlankOrExtremeBrightness);
  }

  // Laplacian edge variance — rejects severely out-of-focus / motion-blurred captures
  double sumLaplacian = 0.0;
  final List<double> laplacians = [];

  for (int y = 1; y < sampleHeight - 1; y++) {
    for (int x = 1; x < sampleWidth - 1; x++) {
      final c = luminances[y * sampleWidth + x];
      final t = luminances[(y - 1) * sampleWidth + x];
      final b = luminances[(y + 1) * sampleWidth + x];
      final l = luminances[y * sampleWidth + (x - 1)];
      final r = luminances[y * sampleWidth + (x + 1)];
      final lap = (4 * c - t - b - l - r).abs();
      laplacians.add(lap);
      sumLaplacian += lap;
    }
  }

  double laplacianVariance = 0.0;
  if (laplacians.isNotEmpty) {
    final meanLap = sumLaplacian / laplacians.length;
    double sumSqLap = 0.0;
    for (final l in laplacians) {
      final diff = l - meanLap;
      sumSqLap += diff * diff;
    }
    laplacianVariance = (sumSqLap / laplacians.length) * 10000.0;
  }

  // Threshold calibrated for live camera captures (not vector art / screenshots)
  if (laplacianVariance < 2.0) {
    return ImageValidationResult.failure(AppStrings.imageTooBlurry);
  }

  return ImageValidationResult.success(
    width: width,
    height: height,
    fileSizeBytes: params.fileSizeBytes,
    brightness: meanLuminance,
    contrastScore: stdDevLuminance,
    blurScore: laplacianVariance,
    subjectFocusScore: 1.0,
  );
}

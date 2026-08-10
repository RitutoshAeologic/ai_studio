import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

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
/// Analyzes image files before uploading to backend/GPU pipelines to save resource costs.
abstract class ImageValidator {
  static const int minFileSizeBytes = 512; // 0.5 KB
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20 MB
  static const int minDimensionPx = 256;
  static const int maxDimensionPx = 4096;

  /// Main entrypoint: Validates an image file for a given AI feature target.
  static Future<ImageValidationResult> validateImage({
    required String filePath,
    required AiFeatureTarget featureTarget,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return ImageValidationResult.failure(AppStrings.imageCorrupted);
      }

      // 1. File Size Check
      final fileSizeBytes = file.lengthSync();
      if (fileSizeBytes < minFileSizeBytes) {
        return ImageValidationResult.failure(AppStrings.imageTooSmall);
      }
      if (fileSizeBytes > maxFileSizeBytes) {
        return ImageValidationResult.failure(AppStrings.imageTooLarge);
      }

      // 2. Format / Extension Check
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

  _ValidationParams({
    required this.bytes,
    required this.fileSizeBytes,
    required this.featureTarget,
  });
}

/// Isolated worker function for fast image decoding & pixel matrix analysis.
ImageValidationResult _analyzeImageBytes(_ValidationParams params) {
  // Decode image
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) {
    return ImageValidationResult.failure(AppStrings.imageCorrupted);
  }

  final width = decoded.width;
  final height = decoded.height;

  // Resolution Check
  if (width < ImageValidator.minDimensionPx ||
      height < ImageValidator.minDimensionPx) {
    return ImageValidationResult.failure(AppStrings.imageLowResolution);
  }
  if (width > ImageValidator.maxDimensionPx ||
      height > ImageValidator.maxDimensionPx) {
    return ImageValidationResult.failure(AppStrings.imageHighResolution);
  }

  // Downsample to 128x128 grid for ultra-fast stats calculation
  final sample = img.copyResize(decoded, width: 128, height: 128);
  final sampleWidth = sample.width;
  final sampleHeight = sample.height;
  final totalPixels = sampleWidth * sampleHeight;

  // Calculate Luminance Distribution
  double sumLuminance = 0.0;
  final List<double> luminances = List<double>.filled(totalPixels, 0.0);
  int idx = 0;

  for (int y = 0; y < sampleHeight; y++) {
    for (int x = 0; x < sampleWidth; x++) {
      final pixel = sample.getPixel(x, y);
      final r = pixel.r / 255.0;
      final g = pixel.g / 255.0;
      final b = pixel.b / 255.0;

      // Relative luminance
      final lum = 0.299 * r + 0.587 * g + 0.114 * b;
      luminances[idx++] = lum;
      sumLuminance += lum;
    }
  }

  final meanLuminance = sumLuminance / totalPixels;

  // Calculate Luminance Variance & Standard Deviation
  double sumSqDiff = 0.0;
  for (int i = 0; i < totalPixels; i++) {
    final diff = luminances[i] - meanLuminance;
    sumSqDiff += diff * diff;
  }
  final varianceLuminance = sumSqDiff / totalPixels;
  final stdDevLuminance = sqrt(varianceLuminance);

  // Blank / Black / White Screen Check
  // If mean is > 0.96 (almost pure white) or < 0.04 (almost pure black) or stdDev < 0.02 (monochrome)
  if (meanLuminance > 0.96 || meanLuminance < 0.04 || stdDevLuminance < 0.025) {
    return ImageValidationResult.failure(
        AppStrings.imageBlankOrExtremeBrightness);
  }

  // Contrast Check
  if (stdDevLuminance < 0.04) {
    return ImageValidationResult.failure(AppStrings.imageLowContrast);
  }

  // Blur / Quality Check (Laplacian Edge Variance)
  double laplacianVariance = 0.0;
  double sumLaplacian = 0.0;
  final List<double> laplacians = [];

  for (int y = 1; y < sampleHeight - 1; y++) {
    for (int x = 1; x < sampleWidth - 1; x++) {
      final center = luminances[y * sampleWidth + x];
      final top = luminances[(y - 1) * sampleWidth + x];
      final bottom = luminances[(y + 1) * sampleWidth + x];
      final left = luminances[y * sampleWidth + (x - 1)];
      final right = luminances[y * sampleWidth + (x + 1)];

      // Discrete 2D Laplacian operator: (4 * center - top - bottom - left - right)
      final lap = (4 * center - top - bottom - left - right).abs();
      laplacians.add(lap);
      sumLaplacian += lap;
    }
  }

  if (laplacians.isNotEmpty) {
    final meanLap = sumLaplacian / laplacians.length;
    double sumSqLap = 0.0;
    for (final l in laplacians) {
      final diff = l - meanLap;
      sumSqLap += diff * diff;
    }
    laplacianVariance = (sumSqLap / laplacians.length) * 10000.0;
  }

  if (laplacianVariance < 5.0) {
    return ImageValidationResult.failure(AppStrings.imageTooBlurry);
  }

  // Feature-Dependent Object / Subject Detection
  double centerVariance = 0.0;
  double borderVariance = 0.0;

  // Calculate detail variance in central 50% box vs outer border
  final cXMin = (sampleWidth * 0.25).toInt();
  final cXMax = (sampleWidth * 0.75).toInt();
  final cYMin = (sampleHeight * 0.25).toInt();
  final cYMax = (sampleHeight * 0.75).toInt();

  final List<double> centerLums = [];
  final List<double> borderLums = [];

  for (int y = 0; y < sampleHeight; y++) {
    for (int x = 0; x < sampleWidth; x++) {
      final lum = luminances[y * sampleWidth + x];
      if (x >= cXMin && x <= cXMax && y >= cYMin && y <= cYMax) {
        centerLums.add(lum);
      } else {
        borderLums.add(lum);
      }
    }
  }

  double calcVariance(List<double> list) {
    if (list.isEmpty) return 0.0;
    final mean = list.reduce((a, b) => a + b) / list.length;
    double sqDiff = 0.0;
    for (final v in list) {
      final d = v - mean;
      sqDiff += d * d;
    }
    return sqDiff / list.length;
  }

  centerVariance = calcVariance(centerLums);
  borderVariance = calcVariance(borderLums);
  final subjectFocusScore = centerVariance / (borderVariance + 0.001);

  // Apply Feature-Specific Checks
  if (params.featureTarget == AiFeatureTarget.imageTo3d ||
      params.featureTarget == AiFeatureTarget.characterConsistency ||
      params.featureTarget == AiFeatureTarget.backgroundReplacement) {
    // Requires a distinct foreground subject or clear object in central area
    if (centerVariance < 0.01 || subjectFocusScore < 0.15) {
      return ImageValidationResult.failure(AppStrings.imageNoSubjectDetected);
    }
  }

  return ImageValidationResult.success(
    width: width,
    height: height,
    fileSizeBytes: params.fileSizeBytes,
    brightness: meanLuminance,
    contrastScore: stdDevLuminance,
    blurScore: laplacianVariance,
    subjectFocusScore: subjectFocusScore,
  );
}

/// Represents the result of frontend image validation checks.
class ImageValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int width;
  final int height;
  final int fileSizeBytes;
  final double brightness; // 0.0 (pitch black) to 1.0 (pure white)
  final double contrastScore; // Variance of luminance
  final double blurScore; // Variance of Laplacian gradient
  final double subjectFocusScore; // Ratio of central detail to background

  const ImageValidationResult({
    required this.isValid,
    this.errorMessage,
    this.width = 0,
    this.height = 0,
    this.fileSizeBytes = 0,
    this.brightness = 0.0,
    this.contrastScore = 0.0,
    this.blurScore = 0.0,
    this.subjectFocusScore = 0.0,
  });

  factory ImageValidationResult.success({
    required int width,
    required int height,
    required int fileSizeBytes,
    required double brightness,
    required double contrastScore,
    required double blurScore,
    required double subjectFocusScore,
  }) {
    return ImageValidationResult(
      isValid: true,
      width: width,
      height: height,
      fileSizeBytes: fileSizeBytes,
      brightness: brightness,
      contrastScore: contrastScore,
      blurScore: blurScore,
      subjectFocusScore: subjectFocusScore,
    );
  }

  factory ImageValidationResult.failure(String errorMessage) {
    return ImageValidationResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

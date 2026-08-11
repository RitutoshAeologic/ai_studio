import 'dart:io';
import 'package:ai_studio/core/constants/app_strings.dart';
import 'package:ai_studio/core/utils/image_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

void main() {
  late String tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('image_val_test').path;
  });

  tearDownAll(() {
    Directory(tempDir).deleteSync(recursive: true);
  });

  test('Rejects non-existent or corrupted image file', () async {
    final result = await ImageValidator.validateImage(
      filePath: '$tempDir/non_existent.png',
      featureTarget: AiFeatureTarget.generalAi,
    );

    expect(result.isValid, false);
    expect(result.errorMessage, AppStrings.imageCorrupted);
  });

  test('Rejects image file smaller than minimum byte threshold', () async {
    final tinyFile = File('$tempDir/tiny.jpg');
    await tinyFile.writeAsBytes(List.generate(50, (i) => 0));

    final result = await ImageValidator.validateImage(
      filePath: tinyFile.path,
      featureTarget: AiFeatureTarget.generalAi,
    );

    expect(result.isValid, false);
    expect(result.errorMessage, AppStrings.imageTooSmall);
  });

  test('GALLERY: Validates a sharp image with clear subject for Image to 3D',
      () async {
    final image = img.Image(width: 512, height: 512);
    // Draw high-contrast central subject with detailed pattern
    for (int y = 0; y < 512; y++) {
      for (int x = 0; x < 512; x++) {
        final val = (x + y) % 2 == 0 ? 50 : 200;
        image.setPixel(x, y, img.ColorRgb8(val, val, val));
      }
    }

    final pngBytes = img.encodePng(image);
    final validFile = File('$tempDir/valid_subject.png');
    await validFile.writeAsBytes(pngBytes);

    // Gallery source → only integrity check, no blur/blank pixel math
    final result = await ImageValidator.validateImage(
      filePath: validFile.path,
      featureTarget: AiFeatureTarget.imageTo3d,
      imageSource: ImageSource.gallery,
    );

    expect(result.isValid, true);
    expect(result.errorMessage, null);
    expect(result.width, 512);
    expect(result.height, 512);
  });

  test('GALLERY: Accepts UI screenshots, illustrations, and vector artwork',
      () async {
    final image = img.Image(width: 300, height: 300);
    // Flat-color center (simulates a UI card/vector illustration)
    for (int y = 0; y < 300; y++) {
      for (int x = 0; x < 300; x++) {
        if (x < 75 || x > 225 || y < 75 || y > 225) {
          final val = (x * y) % 255;
          image.setPixel(x, y, img.ColorRgb8(val, 255 - val, 100));
        } else {
          image.setPixel(x, y, img.ColorRgb8(120, 120, 120));
        }
      }
    }

    final pngBytes = img.encodePng(image);
    final uiFile = File('$tempDir/ui_screenshot.png');
    await uiFile.writeAsBytes(pngBytes);

    // Gallery source → passes regardless of flat areas (no pixel heuristics)
    final result = await ImageValidator.validateImage(
      filePath: uiFile.path,
      featureTarget: AiFeatureTarget.imageTo3d,
      imageSource: ImageSource.gallery,
    );

    expect(result.isValid, true);
    expect(result.errorMessage, null);
  });

  test('CAMERA: Rejects completely blank/covered lens image', () async {
    final image = img.Image(width: 300, height: 300);
    img.fill(image, color: img.ColorRgb8(255, 255, 255)); // Pure white

    final pngBytes = img.encodePng(image);
    final blankFile = File('$tempDir/blank_white.png');
    await blankFile.writeAsBytes(pngBytes);

    // Camera source → pixel analysis runs, blank lens is rejected
    final result = await ImageValidator.validateImage(
      filePath: blankFile.path,
      featureTarget: AiFeatureTarget.generalAi,
      imageSource: ImageSource.camera,
    );

    expect(result.isValid, false);
    expect(result.errorMessage, AppStrings.imageBlankOrExtremeBrightness);
  });

  test('CAMERA: Accepts a sharp real-world camera capture', () async {
    final image = img.Image(width: 400, height: 400);
    for (int y = 0; y < 400; y++) {
      for (int x = 0; x < 400; x++) {
        final val = (x * y) % 255;
        image.setPixel(x, y, img.ColorRgb8(val, 255 - val, (x + y) % 200));
      }
    }

    final pngBytes = img.encodePng(image);
    final cameraFile = File('$tempDir/camera_capture.png');
    await cameraFile.writeAsBytes(pngBytes);

    // Camera source → sharp image passes both blank + blur checks
    final result = await ImageValidator.validateImage(
      filePath: cameraFile.path,
      featureTarget: AiFeatureTarget.imageTo3d,
      imageSource: ImageSource.camera,
    );

    expect(result.isValid, true);
    expect(result.errorMessage, null);
  });
}

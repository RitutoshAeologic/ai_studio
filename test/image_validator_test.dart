import 'dart:io';
import 'package:ai_studio/core/constants/app_strings.dart';
import 'package:ai_studio/core/utils/image_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

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

  test('Validates a sharp image with clear subject for Image to 3D', () async {
    final image = img.Image(width: 512, height: 512);
    // Draw background grid
    for (int y = 0; y < 512; y++) {
      for (int x = 0; x < 512; x++) {
        final val = (x + y) % 2 == 0 ? 50 : 70;
        image.setPixel(x, y, img.ColorRgb8(val, val, val));
      }
    }
    // Draw high-contrast central subject with detailed pattern
    for (int y = 150; y < 350; y++) {
      for (int x = 150; x < 350; x++) {
        final val = (x * y) % 255;
        image.setPixel(x, y, img.ColorRgb8(val, 255 - val, 200));
      }
    }

    final pngBytes = img.encodePng(image);
    final validFile = File('$tempDir/valid_subject.png');
    await validFile.writeAsBytes(pngBytes);

    final result = await ImageValidator.validateImage(
      filePath: validFile.path,
      featureTarget: AiFeatureTarget.imageTo3d,
    );

    expect(result.isValid, true);
    expect(result.errorMessage, null);
    expect(result.width, 512);
    expect(result.height, 512);
  });

  test('Rejects completely blank/monochrome image', () async {
    final image = img.Image(width: 300, height: 300);
    img.fill(image, color: img.ColorRgb8(255, 255, 255)); // Pure white

    final pngBytes = img.encodePng(image);
    final blankFile = File('$tempDir/blank_white.png');
    await blankFile.writeAsBytes(pngBytes);

    final result = await ImageValidator.validateImage(
      filePath: blankFile.path,
      featureTarget: AiFeatureTarget.generalAi,
    );

    expect(result.isValid, false);
    expect(result.errorMessage, AppStrings.imageBlankOrExtremeBrightness);
  });

  test('Rejects feature target requiring subject when image lacks central object focus',
      () async {
    final image = img.Image(width: 300, height: 300);
    // Draw high variance border but uniform flat center
    for (int y = 0; y < 300; y++) {
      for (int x = 0; x < 300; x++) {
        if (x < 75 || x > 225 || y < 75 || y > 225) {
          final val = (x * y) % 255;
          image.setPixel(x, y, img.ColorRgb8(val, 255 - val, 100));
        } else {
          image.setPixel(x, y, img.ColorRgb8(120, 120, 120)); // Flat center
        }
      }
    }

    final pngBytes = img.encodePng(image);
    final noSubjectFile = File('$tempDir/no_subject.png');
    await noSubjectFile.writeAsBytes(pngBytes);

    final result = await ImageValidator.validateImage(
      filePath: noSubjectFile.path,
      featureTarget: AiFeatureTarget.imageTo3d,
    );

    expect(result.isValid, false);
    expect(result.errorMessage, AppStrings.imageNoSubjectDetected);
  });
}

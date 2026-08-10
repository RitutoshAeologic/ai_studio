import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';

/// Handles client-side image selection, compression, and direct-to-Storage upload.
class ImageUploadService {
  final ImagePicker _picker;
  final FirebaseStorage _storage;

  ImageUploadService({
    ImagePicker? picker,
    FirebaseStorage? storage,
  })  : _picker = picker ?? ImagePicker(),
        _storage = storage ?? FirebaseStorage.instance;

  /// Pick image from gallery or camera.
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      return file;
    } catch (e) {
      Logger.w('Failed to pick image: $e');
      return null;
    }
  }

  /// Upload file directly to Firebase Storage and return its public HTTPS download URL.
  Future<Result<String, Failure>> uploadImage({
    required File file,
    required String userId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('user_inputs/$userId/$timestamp.jpg');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      Logger.i('Image uploaded successfully: $downloadUrl');
      return Success(downloadUrl);
    } catch (e, st) {
      Logger.e('Failed to upload image to Firebase Storage', e, st);
      return Error(NetworkFailure('Image upload failed: ${e.toString()}'));
    }
  }
}

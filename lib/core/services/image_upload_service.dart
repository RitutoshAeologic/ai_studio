import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';

/// Result of an image upload — includes download URL and upload statistics.
class ImageUploadResult {
  final String downloadUrl;
  final int bytesTransferred;

  const ImageUploadResult({
    required this.downloadUrl,
    required this.bytesTransferred,
  });
}

/// Handles client-side image selection, compression, and direct-to-Storage upload.
///
/// Upload flow is resilient:
/// 1. Checks network connectivity before attempting upload.
/// 2. Enforces a 60-second upload timeout.
/// 3. Emits progress (0.0–1.0) via [uploadProgress] stream.
/// 4. Never silently swallows a failure — always returns a typed [Failure].
class ImageUploadService {
  final ImagePicker _picker;
  final FirebaseStorage _storage;
  final Connectivity _connectivity;

  /// Broadcast stream of upload progress from 0.0 to 1.0.
  /// Listen before calling [uploadImage] to receive progress events.
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  Stream<double> get uploadProgress => _progressController.stream;

  ImageUploadService({
    ImagePicker? picker,
    FirebaseStorage? storage,
    Connectivity? connectivity,
  })  : _picker = picker ?? ImagePicker(),
        _storage = storage ?? FirebaseStorage.instance,
        _connectivity = connectivity ?? Connectivity();

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
  ///
  /// Returns [Result.error] immediately if:
  /// - Device has no internet connectivity.
  /// - Upload times out after 60 seconds.
  /// - Firebase Storage throws any exception.
  ///
  /// Does NOT call `generateJob` — credits are never deducted if this fails.
  Future<Result<ImageUploadResult, Failure>> uploadImage({
    required File file,
    required String userId,
  }) async {
    // ── 1. Connectivity pre-check ─────────────────────────────────────────────
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none) ||
        connectivityResult.isEmpty) {
      Logger.w('Upload aborted — no internet connection');
      return const Error(
        NetworkFailure('No internet connection — upload aborted. Your credits have not been deducted.'),
      );
    }

    // ── 2. Upload with timeout & progress ─────────────────────────────────────
    try {
      _progressController.add(0.0);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('user_inputs/$userId/$timestamp.jpg');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wire progress events to the broadcast stream.
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          _progressController.add(progress.clamp(0.0, 1.0));
        }
      });

      // Enforce a 60-second hard timeout.
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          uploadTask.cancel();
          throw TimeoutException('Upload timed out after 60 seconds');
        },
      );

      if (snapshot.state != TaskState.success) {
        Logger.w('Upload ended in non-success state: ${snapshot.state}');
        return Error(NetworkFailure(
            'Upload did not complete (state: ${snapshot.state}). Your credits have not been deducted.'));
      }

      final downloadUrl = await snapshot.ref.getDownloadURL();
      _progressController.add(1.0);

      Logger.i('Image uploaded: $downloadUrl (${snapshot.bytesTransferred} bytes)');
      return Success(ImageUploadResult(
        downloadUrl: downloadUrl,
        bytesTransferred: snapshot.bytesTransferred,
      ));
    } on TimeoutException catch (e) {
      Logger.w('Upload timeout: $e');
      return const Error(NetworkFailure(
          'Upload timed out — check your connection. Your credits have not been deducted.'));
    } catch (e, st) {
      Logger.e('Failed to upload image to Firebase Storage', e, st);
      return Error(NetworkFailure(
          'Image upload failed: ${e.toString()}. Your credits have not been deducted.'));
    }
  }

  void dispose() {
    _progressController.close();
  }
}

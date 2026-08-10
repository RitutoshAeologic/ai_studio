import 'dart:typed_data';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';

/// Abstract contract for Firebase Storage file upload & asset operations.
abstract class StorageRepository {
  /// Upload a local file by path to Firebase Storage and return its public download URL.
  Future<Result<String, Failure>> uploadFile({
    required String filePath,
    required String destinationPath,
  });

  /// Upload raw bytes to Firebase Storage and return its public download URL.
  Future<Result<String, Failure>> uploadBytes({
    required Uint8List bytes,
    required String destinationPath,
  });

  /// Delete a file from Firebase Storage given its URL or storage reference.
  Future<Result<void, Failure>> deleteFile(String fileUrl);
}

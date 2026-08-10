import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart' as fs;
import '../../core/constants/app_strings.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';
import '../../domain/repositories/storage_repository.dart';

/// Implementation of StorageRepository connecting Firebase Storage SDK.
class StorageRepositoryImpl implements StorageRepository {
  final fs.FirebaseStorage? _providedStorage;

  StorageRepositoryImpl({fs.FirebaseStorage? storage})
      : _providedStorage = storage;

  fs.FirebaseStorage get _storage =>
      _providedStorage ?? fs.FirebaseStorage.instance;

  @override
  Future<Result<String, Failure>> uploadFile({
    required String filePath,
    required String destinationPath,
  }) async {
    try {
      Logger.i('Uploading file to Firebase Storage: $destinationPath');
      final ref = _storage.ref().child(destinationPath);
      final uploadTask = await ref.putFile(File(filePath));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      Logger.i('File uploaded successfully. URL: $downloadUrl');
      return Success(downloadUrl);
    } catch (e, stackTrace) {
      Logger.e('Failed to upload file to Firebase Storage', e, stackTrace);
      return Error(UnknownFailure(AppStrings.unknownError, e));
    }
  }

  @override
  Future<Result<String, Failure>> uploadBytes({
    required Uint8List bytes,
    required String destinationPath,
  }) async {
    try {
      Logger.i('Uploading bytes to Firebase Storage: $destinationPath');
      final ref = _storage.ref().child(destinationPath);
      final uploadTask = await ref.putData(bytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      Logger.i('Bytes uploaded successfully. URL: $downloadUrl');
      return Success(downloadUrl);
    } catch (e, stackTrace) {
      Logger.e('Failed to upload bytes to Firebase Storage', e, stackTrace);
      return Error(UnknownFailure(AppStrings.unknownError, e));
    }
  }

  @override
  Future<Result<void, Failure>> deleteFile(String fileUrl) async {
    try {
      Logger.i('Deleting file from Firebase Storage: $fileUrl');
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.e('Failed to delete file from Firebase Storage', e, stackTrace);
      return Error(UnknownFailure(AppStrings.unknownError, e));
    }
  }
}

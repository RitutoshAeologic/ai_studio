import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../../core/constants/app_strings.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/job_entity.dart';

/// Request payload for POST /v1/generateJob.
class GenerateJobRequest {
  final JobType jobType;
  final String tier;
  final JobParams params;

  const GenerateJobRequest({
    required this.jobType,
    this.tier = 'FAST',
    required this.params,
  });

  Map<String, dynamic> toJson() => {
        'jobType': jobType.firestoreValue,
        'tier': tier,
        'params': params.toJson(),
      };
}

/// Single HTTP client for all backend API calls.
///
/// This is the ONLY place in the Flutter app that talks to the backend REST API.
/// Flutter Dev #2 calls this service via JobController — never directly.
///
/// NOTE: Base URL is a placeholder until the backend team delivers the Cloud Run endpoint.
/// Set [_useStub] to true for local development/testing without a live backend.
class ApiService {
  static const String _placeholderBaseUrl =
      'https://api.aistudio.example.com'; // ← Replace with real URL when backend delivers

  /// Toggle to true to return stub responses during development.
  static const bool _useStub = kDebugMode;

  final Dio _dio;
  final fb.FirebaseAuth _firebaseAuth;

  ApiService({fb.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _dio = Dio(BaseOptions(
          baseUrl: _placeholderBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
    ));
  }

  /// Returns a Firebase ID token for the Authorization header.
  Future<String?> _getIdToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken();
    } catch (e) {
      Logger.w('Failed to get Firebase ID token: $e');
      return null;
    }
  }

  /// POST /v1/generateJob
  ///
  /// Returns [Result.success] with the created jobId, or [Result.error] on failure.
  Future<Result<String, Failure>> generateJob(GenerateJobRequest request) async {
    if (_useStub) {
      // Stub: return a fake jobId for local development.
      Logger.w('[ApiService STUB] generateJob called — returning mock jobId');
      await Future.delayed(const Duration(milliseconds: 400));
      return const Success('stub_job_${0}');
    }

    try {
      final token = await _getIdToken();
      if (token == null) {
        return const Error(AuthFailure('Not authenticated'));
      }

      final response = await _dio.post(
        '/v1/generateJob',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final jobId = response.data['jobId'] as String?;
      if (jobId == null || jobId.isEmpty) {
        return const Error(NetworkFailure('Invalid server response: missing jobId'));
      }

      Logger.i('Job created: $jobId');
      return Success(jobId);
    } on DioException catch (e, st) {
      Logger.e('API error on generateJob', e, st);
      final msg = e.response?.data?['message'] as String?;
      if (e.response?.statusCode == 402) {
        return const Error(InsufficientCreditsFailure());
      }
      return Error(NetworkFailure(msg ?? AppStrings.networkError));
    } catch (e, st) {
      Logger.e('Unexpected error on generateJob', e, st);
      return const Error(UnknownFailure());
    }
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../../core/constants/app_strings.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/job_entity.dart';

/// Lean response payload from POST /v1/generateJob.
/// Server returns `{ jobId, status, cost, createdAt }`.
class GenerateJobResponse {
  final String jobId;
  final String status;
  final int cost;
  final DateTime? createdAt;

  const GenerateJobResponse({
    required this.jobId,
    required this.status,
    required this.cost,
    this.createdAt,
  });

  factory GenerateJobResponse.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        dt = DateTime.tryParse(json['createdAt'] as String);
      }
    }
    return GenerateJobResponse(
      jobId: json['jobId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      createdAt: dt,
    );
  }
}

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
/// **Base URL configuration**:
/// Override at build time without code changes:
///   `flutter run --dart-define=API_BASE_URL=https://your-cloud-run-url.run.app`
///   `flutter build apk --dart-define=API_BASE_URL=https://your-cloud-run-url.run.app`
/// Defaults to the ngrok dev tunnel when no dart-define is provided.
///
/// **SECURITY NOTE FOR BACKEND DEV**:
/// `GET /wallet/{user_id}` currently lacks authorization header verification on the live backend,
/// unlike `/v1/generateJob` and `/jobs` which both enforce Authorization Bearer tokens.
/// Any client can read any user's balance by probing a user_id path. Please add Authorization
/// header checking or rely purely on Firestore real-time security rules for wallet reads.
class ApiService {
  /// Build-time configurable base URL via `--dart-define=API_BASE_URL=url`.
  /// Falls back to the ngrok dev tunnel when no dart-define is provided.
  static const String _liveBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://recast-landmass-sedan.ngrok-free.dev',
  );

  /// Public getter for active backend base URL.
  static String get baseUrl => _liveBaseUrl;

  /// Set to false to interact directly with the live ngrok backend.
  static const bool _useStub = false;

  final Dio _dio;
  final fb.FirebaseAuth _firebaseAuth;

  ApiService({fb.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _dio = Dio(BaseOptions(
          baseUrl: _liveBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': '69420',
          },
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
  /// Returns [Result.success] with [GenerateJobResponse], or [Result.error] on failure.
  Future<Result<GenerateJobResponse, Failure>> generateJob(
      GenerateJobRequest request) async {
    if (_useStub) {
      Logger.w('[ApiService STUB] generateJob called — returning mock response');
      await Future.delayed(const Duration(milliseconds: 400));
      return Success(GenerateJobResponse(
        jobId: 'stub_job_${DateTime.now().millisecondsSinceEpoch}',
        status: 'pending',
        cost: 10,
        createdAt: DateTime.now(),
      ));
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

      final dynamic rawData = response.data;
      Map<String, dynamic>? data;
      if (rawData is Map<String, dynamic>) {
        data = rawData;
      } else if (rawData is String && rawData.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(rawData);
          data = decoded is Map<String, dynamic> ? decoded : null;
        } catch (_) {
          data = null;
        }
      } else {
        data = null;
      }

      if (data == null || data['jobId'] == null) {
        return const Error(
            NetworkFailure('Invalid server response: missing jobId'));
      }

      final jobResp = GenerateJobResponse.fromJson(data);
      Logger.i('Job created: ${jobResp.jobId}, cost: ${jobResp.cost}');
      return Success(jobResp);
    } on DioException catch (e, st) {
      Logger.e('API error on generateJob', e, st);
      if (e.response?.statusCode == 402) {
        return const Error(InsufficientCreditsFailure());
      }

      String? msg;
      final resData = e.response?.data;
      if (resData is Map) {
        msg = (resData['message'] ?? resData['detail'] ?? resData['error'])?.toString();
      } else if (resData is String && resData.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(resData);
          if (decoded is Map) {
            msg = (decoded['message'] ?? decoded['detail'] ?? decoded['error'])?.toString();
          } else {
            msg = resData.trim();
          }
        } catch (_) {
          if (resData.contains('ERR_NGROK') || resData.contains('offline')) {
            msg = 'AI server endpoint is currently offline or unreachable. Please verify server status.';
          } else {
            msg = resData.trim();
          }
        }
      }

      if (msg == null || msg.isEmpty) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          msg = 'Unable to connect to AI server. Please check your internet connection.';
        } else if (e.response?.statusCode == 404) {
          msg = 'AI server is currently offline or endpoint not found (404).';
        } else if (e.response?.statusCode == 500) {
          msg = 'AI server encountered an error processing your request.';
        } else {
          msg = e.message ?? AppStrings.networkError;
        }
      }

      return Error(NetworkFailure(msg));
    } catch (e, st) {
      Logger.e('Unexpected error on generateJob', e, st);
      return const Error(UnknownFailure());
    }
  }
}


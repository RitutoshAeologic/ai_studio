import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../models/video_job_response.dart';

class VideoApiService {
  final Dio _dio;
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  VideoApiService({
    Dio? dio,
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiService.baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              headers: {'Content-Type': 'application/json'},
            )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
    ));
  }

  Future<String?> _getIdToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken();
    } catch (e) {
      Logger.w('Failed to get Firebase ID token: $e');
      return null;
    }
  }

  /// Submit video generation job to backend API.
  /// Tries `/v1/generateVideoJob` first, falling back to `/v1/generateJob` if endpoint returns 404.
  Future<GenerateVideoJobResponse> submitVideoJob({
    required List<String> imageUrls,
    required String sceneScript,
    required int duration,
    required String aspectRatio,
  }) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('User is not authenticated. Please log in.');
    }

    final payload = {
      'jobType': 'VIDEO_GEN',
      'tier': 'FAST',
      'duration': duration,
      'aspectRatio': aspectRatio,
      'params': {
        'images': imageUrls,
        'sceneScript': sceneScript,
        'duration': duration,
        'aspectRatio': aspectRatio,
      },
    };

    try {
      Response response;
      try {
        response = await _dio.post(
          '/v1/generateVideoJob',
          data: payload,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          Logger.w('/v1/generateVideoJob returned 404. Falling back to /v1/generateJob...');
          response = await _dio.post(
            '/v1/generateJob',
            data: payload,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } else {
          rethrow;
        }
      }

      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data as Map<String, dynamic>;

      return GenerateVideoJobResponse.fromJson(data);
    } on DioException catch (e) {
      Logger.e('Error calling video job endpoint', e);
      dynamic detailData = e.response?.data?['detail'] ?? e.response?.data?['message'];
      String? errorMessage;
      if (detailData is List && detailData.isNotEmpty) {
        final firstItem = detailData.first;
        if (firstItem is Map && firstItem['msg'] != null) {
          errorMessage = firstItem['msg'].toString();
        } else {
          errorMessage = detailData.toString();
        }
      } else if (detailData != null) {
        errorMessage = detailData.toString();
      } else {
        errorMessage = e.message;
      }
      throw Exception(errorMessage ?? 'Failed to submit video generation job');
    } catch (e) {
      Logger.e('Unexpected error submitting video job', e);
      throw Exception(e.toString());
    }
  }

  /// Live stream updates from Firestore for real-time synchronization
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchJobStatus(String jobId) {
    return _firestore.collection('jobs').doc(jobId).snapshots();
  }
}

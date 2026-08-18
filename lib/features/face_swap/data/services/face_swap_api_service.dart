import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../models/face_swap_request.dart';
import '../models/face_swap_response.dart';

class FaceSwapApiService {
  final Dio _dio;
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FaceSwapApiService({
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
              headers: {
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': '69420',
              },
            )) {
    _dio.interceptors.add(LogInterceptor(
      request: false,
      requestHeader: false,
      requestBody: false,
      responseHeader: false,
      responseBody: false,
      error: true,
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

  /// Submit Face Swap Job to backend (`POST /v1/generateFaceSwapJob`)
  Future<FaceSwapJobResponse> submitFaceSwapJob(FaceSwapRequest request) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('User is not authenticated. Please log in.');
    }

    try {
      Response response;
      try {
        response = await _dio.post(
          '/v1/generateFaceSwapJob',
          data: request.toJson(),
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          Logger.w('/v1/generateFaceSwapJob returned 404. Falling back to /v1/generateJob...');
          response = await _dio.post(
            '/v1/generateJob',
            data: request.toJson(),
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } else {
          rethrow;
        }
      }

      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data as Map<String, dynamic>;

      return FaceSwapJobResponse.fromJson(data);
    } on DioException catch (e) {
      Logger.e('Error calling face swap job endpoint', e);
      dynamic detailData;
      final resData = e.response?.data;
      if (resData is Map) {
        detailData = resData['detail'] ?? resData['message'] ?? resData['error'];
      } else if (resData is String && resData.isNotEmpty) {
        try {
          final decoded = jsonDecode(resData);
          if (decoded is Map) {
            detailData = decoded['detail'] ?? decoded['message'] ?? decoded['error'];
          } else {
            detailData = resData;
          }
        } catch (_) {
          detailData = resData;
        }
      }

      final statusCode = e.response?.statusCode;
      if (statusCode == 502) {
        throw Exception('Backend server is unreachable (502 Bad Gateway). Please make sure your backend is running on port 8000.');
      } else if (statusCode == 503 || statusCode == 504) {
        throw Exception('Backend server is temporarily unavailable ($statusCode). Please try again shortly.');
      }

      String? errorMessage;
      if (detailData is List && detailData.isNotEmpty) {
        final firstItem = detailData.first;
        if (firstItem is Map && firstItem['msg'] != null) {
          errorMessage = firstItem['msg'].toString();
        } else {
          errorMessage = detailData.toString();
        }
      } else if (detailData != null && detailData is String) {
        if (detailData.contains('<html') || detailData.contains('<!DOCTYPE')) {
          errorMessage = 'Server returned an invalid HTML response ($statusCode).';
        } else {
          errorMessage = detailData;
        }
      } else if (detailData != null) {
        errorMessage = detailData.toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot connect to backend server. Please check your network and server status.';
      } else {
        errorMessage = e.message;
      }
      throw Exception(errorMessage ?? 'Failed to submit face swap job');
    } catch (e) {
      Logger.e('Unexpected error submitting face swap job', e);
      throw Exception(e.toString());
    }
  }

  /// Poll status from backend (`GET /v1/faceSwapJob/:jobId`)
  Future<FaceSwapJobStatusResponse> pollJobStatus(String jobId) async {
    final token = await _getIdToken();
    try {
      Response response;
      try {
        response = await _dio.get(
          '/v1/faceSwapJob/$jobId',
          options: Options(headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          }),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await _dio.get(
            '/v1/job/$jobId',
            options: Options(headers: {
              if (token != null) 'Authorization': 'Bearer $token',
            }),
          );
        } else {
          rethrow;
        }
      }

      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data as Map<String, dynamic>;

      return FaceSwapJobStatusResponse.fromJson(data);
    } catch (e) {
      Logger.w('Error polling face swap status: $e');
      rethrow;
    }
  }

  /// Realtime Firestore snapshot stream for instant synchronization
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchJobStatus(String jobId) {
    return _firestore.collection('jobs').doc(jobId).snapshots();
  }
}

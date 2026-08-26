import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/api_service.dart';
import '../../../core/utils/logger.dart';
import '../models/interview_models.dart';

class InterviewApiService {
  static String get baseUrl => ApiService.baseUrl;

  /// Helper to get current Firebase Auth Token
  static Future<String?> _getAuthToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      Logger.w('Failed to get Firebase Auth token: $e');
      return null;
    }
  }

  /// 1. POST /v1/interview/generate-sequence
  /// Dispatches the sequence generation job for the interview session.
  static Future<GenerateInterviewSequenceResponse> startInterviewSequence(
      GenerateInterviewSequenceRequest request) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$baseUrl/v1/interview/generate-sequence');

    Logger.i('Submitting interview sequence request to $url');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': '69420',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GenerateInterviewSequenceResponse.fromJson(data);
    } else {
      dynamic errorJson;
      try {
        errorJson = jsonDecode(response.body);
      } catch (_) {}
      final msg = errorJson is Map
          ? (errorJson['detail'] ??
              errorJson['message'] ??
              'Failed to start interview sequence')
          : 'Failed to start interview sequence (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// 2. Stream real-time Firestore document updates for `interviews/{interviewId}`
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamInterview(
      String interviewId) {
    return FirebaseFirestore.instance
        .collection('interviews')
        .doc(interviewId)
        .snapshots();
  }

  /// 3. GET /v1/interview/{interviewId} (HTTP polling fallback)
  static Future<InterviewManifest> getInterviewManifest(
      String interviewId) async {
    final url = Uri.parse('$baseUrl/v1/interview/$interviewId');
    final response = await http.get(
      url,
      headers: {'ngrok-skip-browser-warning': '69420'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return InterviewManifest.fromJson(data);
    } else {
      throw Exception('Failed to fetch interview manifest (${response.statusCode})');
    }
  }
}

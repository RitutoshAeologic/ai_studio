import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/api_service.dart';
import '../models/lip_sync_model.dart';

class LipSyncService {
  /// Backend base URL configured via ApiService
  static String get baseUrl => ApiService.baseUrl;

  /// Helper to get current Firebase Auth Bearer Token
  static Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  /// 1. Upload local video file (.mp4) to Firebase Storage bucket
  static Future<String> uploadVideoToFirebase(File videoFile) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final fileName = 'inputs/$userId/lip_sync_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    final uploadTask = await ref.putFile(
      videoFile,
      SettableMetadata(contentType: 'video/mp4'),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  /// 2. Upload local avatar image file (.jpg/.png) to Firebase Storage bucket
  static Future<String> uploadImageToFirebase(File imageFile) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final ext = imageFile.path.endsWith('.png') ? 'png' : 'jpg';
    final fileName = 'inputs/$userId/lip_sync_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/$ext'),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  /// 3. Submit Lip-Sync / Talking Avatar Job (Deducts 50 Credits)
  static Future<LipSyncJobResponse> submitLipSyncJob({
    String? imageUrl,
    String? videoUrl,
    required String paragraphText,
    required String voiceCode,
  }) async {
    if ((imageUrl == null || imageUrl.isEmpty) && (videoUrl == null || videoUrl.isEmpty)) {
      throw Exception('Either imageUrl (Avatar Photo) or videoUrl (Character Video) must be provided.');
    }

    final token = await _getAuthToken();
    final url = Uri.parse('$baseUrl/v1/video/lip-sync');
    final payload = LipSyncJobRequest(
      params: LipSyncParams(
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        paragraphText: paragraphText,
        voice: voiceCode,
      ),
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': '69420',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return LipSyncJobResponse.fromJson(jsonDecode(response.body));
    } else {
      dynamic errorJson;
      try {
        errorJson = jsonDecode(response.body);
      } catch (_) {}
      final errorMsg = errorJson is Map
          ? (errorJson['detail'] ?? errorJson['message'] ?? 'Failed to submit lip-sync job')
          : 'Failed to submit lip-sync job (${response.statusCode})';
      throw Exception(errorMsg);
    }
  }

  /// 4. Poll Job Status until completed or failed
  static Future<LipSyncStatusResponse> pollJobStatusUntilComplete(
    String jobId, {
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 40,
  }) async {
    final url = Uri.parse('$baseUrl/v1/videoJob/$jobId');
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);
      final response = await http.get(
        url,
        headers: {
          'ngrok-skip-browser-warning': '69420',
        },
      );
      if (response.statusCode == 200) {
        final statusResp = LipSyncStatusResponse.fromJson(jsonDecode(response.body));
        if (statusResp.status == 'completed' || statusResp.status == 'error') {
          return statusResp;
        }
      }
    }
    throw TimeoutException('Lip-Sync generation timed out. Please try again.');
  }
}

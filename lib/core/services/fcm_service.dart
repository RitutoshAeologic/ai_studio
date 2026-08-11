import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/logger.dart';

/// Top-level background message handler — must be a top-level function
/// annotated with @pragma so it survives Dart tree-shaking in release builds.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Logger.i('[FCM Background] Message received: ${message.messageId}');
}

/// FCM push notification service.
///
/// Responsibilities:
/// 1. Request notification permissions on Android launch.
/// 2. Disabled on iOS per project requirement.
/// 3. Register + store the FCM token on the user's Firestore doc.
/// 4. Handle foreground messages with an in-app snackbar.
/// 5. Handle notification taps to deep-link into the relevant result view.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Call once after a successful sign-in.
  /// Requests permission, stores FCM token on the user doc, sets up handlers.
  Future<void> initialize({required String uid}) async {
    // Disable FCM push notifications on iOS per project requirement
    if (GetPlatform.isIOS) {
      Logger.i('[FCM] Push notifications disabled on iOS — skipping initialization');
      return;
    }

    // ── 1. Request permission ─────────────────────────────────────────────────
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    Logger.i('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      Logger.w('[FCM] Notifications denied by user — skipping token registration');
      return;
    }

    // ── 2. Register background handler ────────────────────────────────────────
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ── 3. Get & store FCM token ──────────────────────────────────────────────
    await _registerToken(uid);

    // Listen for token refreshes (e.g. app reinstall, device restore).
    _messaging.onTokenRefresh.listen((newToken) => _storeToken(uid, newToken));

    // ── 4. Foreground message handler ─────────────────────────────────────────
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ── 5. Notification tap handler (app in background/terminated) ────────────
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle the case where the app was launched by tapping a notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    Logger.i('[FCM] Initialized for uid: $uid');
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _registerToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        Logger.w('[FCM] Token is null');
        return;
      }
      await _storeToken(uid, token);
    } catch (e) {
      Logger.w('[FCM] Failed to get FCM token: $e');
    }
  }

  Future<void> _storeToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).set(
        {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      Logger.i('[FCM] Token stored for uid: $uid');
    } catch (e) {
      Logger.w('[FCM] Failed to store FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    Logger.i('[FCM Foreground] ${message.notification?.title}: ${message.notification?.body}');

    final notification = message.notification;
    if (notification == null) return;

    // Show an in-app snackbar — non-intrusive, dismissible.
    Get.rawSnackbar(
      title: notification.title ?? 'AI Studio',
      message: notification.body ?? '',
      duration: const Duration(seconds: 4),
      backgroundColor: const Color(0xFF1E1E1E),
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      icon: const Icon(Icons.notifications_outlined, color: Color(0xFFFF6B35)),
      mainButton: TextButton(
        onPressed: () => _handleNotificationTap(message),
        child: const Text('View', style: TextStyle(color: Color(0xFFFF6B35))),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    Logger.i('[FCM Tap] data: ${message.data}');

    final jobId = message.data['jobId'] as String?;
    if (jobId == null) return;

    Get.toNamed('/home', arguments: {'deepLinkJobId': jobId});
  }

  /// Clean up on sign-out — remove FCM token from Firestore so notifications
  /// are not sent to a signed-out device.
  Future<void> onSignOut() async {
    if (GetPlatform.isIOS) return;

    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).update({'fcmToken': FieldValue.delete()});
      Logger.i('[FCM] Token removed on sign-out for uid: $uid');
    } catch (e) {
      Logger.w('[FCM] Failed to remove token on sign-out: $e');
    }
  }
}

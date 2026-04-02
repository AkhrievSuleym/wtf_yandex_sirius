import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/utils/app_logger.dart';

/// Top-level handler for background/terminated messages (must be top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.i('FCM', 'Background message: ${message.messageId} title=${message.notification?.title}');
}

class NotificationService {
  static const _tag = 'NotificationService';

  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _tokenRefreshSubscription;

  /// Call once from main() before runApp.
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    AppLogger.i('FCM', 'Background handler registered');
  }

  /// Call after user is authenticated.
  Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    AppLogger.i(_tag, 'init');

    // 1. Request permissions (iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.i(_tag, 'permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.w(_tag, 'Notifications denied by user');
      return;
    }

    // 2. Get and save token
    await _saveToken();

    // 3. Listen for token refresh
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      AppLogger.i(_tag, 'FCM token refreshed');
      _saveToken(token: token);
    });

    // 4. Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.i(_tag, 'Foreground message: title=${message.notification?.title}');
      _showInAppBanner(navigatorKey, message);
    });

    // 5. Message opened app from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.i(_tag, 'Message opened app: title=${message.notification?.title}');
      _handleNotificationTap(navigatorKey, message);
    });

    // 6. App opened from terminated via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      AppLogger.i(_tag, 'App opened from terminated: title=${initial.notification?.title}');
      _handleNotificationTap(navigatorKey, initial);
    }
  }

  Future<void> _saveToken({String? token}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLogger.w(_tag, '_saveToken: no authenticated user');
      return;
    }
    final fcmToken = token ?? await _messaging.getToken();
    if (fcmToken == null) {
      AppLogger.w(_tag, '_saveToken: token is null');
      return;
    }
    AppLogger.d(_tag, '_saveToken: uid=$uid token=${fcmToken.substring(0, 20)}...');
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .update({'fcmToken': fcmToken});
  }

  void _showInAppBanner(
    GlobalKey<NavigatorState> navigatorKey,
    RemoteMessage message,
  ) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body.isNotEmpty) Text(body),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Открыть',
          onPressed: () => _handleNotificationTap(navigatorKey, message),
        ),
      ),
    );
  }

  void _handleNotificationTap(
    GlobalKey<NavigatorState> navigatorKey,
    RemoteMessage message,
  ) {
    final data = message.data;
    AppLogger.d(_tag, '_handleNotificationTap: data=$data');

    // Навигация: если есть ownerUid — открыть доску
    final ownerUid = data['ownerUid'] as String?;
    if (ownerUid != null) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/board',
        (route) => false,
      );
    }
  }

  void dispose() {
    AppLogger.d(_tag, 'dispose');
    _tokenRefreshSubscription?.cancel();
  }
}

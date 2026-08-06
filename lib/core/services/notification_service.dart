import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/core/services/navigation_service.dart'
    as navigation_service;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'price_catalog_channel',
    'Price Catalog Notifications',
    description: 'Notifications for Price Catalog App',
    importance: Importance.max,
  );

  // ═══════════════════════════════════════
  // INITIALIZE
  // ═══════════════════════════════════════
  static Future<void> initialize() async {
    await _requestPermission();
    await _initializeLocalNotifications();
    await _createAndroidNotificationChannel();

    // Ensure the device FCM token is saved to the user's document so
    // server-side code or Cloud Functions can target this device.
    try {
      final token = await _fcm.getToken();
      if (token != null && FirebaseService.currentUserId != null) {
        await FirebaseService.usersRef
            .doc(FirebaseService.currentUserId)
            .update({'fcmToken': token});
      }

      // Keep token up to date
      _fcm.onTokenRefresh.listen((newToken) async {
        if (FirebaseService.currentUserId != null) {
          await FirebaseService.usersRef
              .doc(FirebaseService.currentUserId)
              .update({'fcmToken': newToken});
        }
      });
    } catch (e) {
      // Non-fatal: token saving failed — continue without blocking initialization
    }

    // While the app is running, listen for new notification documents for
    // the current user and show a local notification. This helps when
    // another device or user creates a notification while this app is
    // active.
    try {
      final uid = FirebaseService.currentUserId;
      if (uid != null) {
        FirebaseService.notificationsRef(uid).snapshots().listen((snap) {
          for (final change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                final title = data['title'] as String?;
                final message = data['message'] as String?;
                _showNotification(
                  id: change.doc.id.hashCode,
                  title: title ?? 'Notification',
                  body: message ?? '',
                  payload: jsonEncode(data),
                );
              }
            }
          }
        });
      }
    } catch (_) {}

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // When a notification is tapped (app in background / terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      try {
        final payload = jsonEncode(message.data);
        await navigation_service.handleNotificationPayload(payload);
      } catch (_) {}
    });

    // Handle app launched from terminated state via notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final payload = jsonEncode(initialMessage.data);
      await navigation_service.setPendingNotificationPayload(payload);
    }
  }

  static Future<void> _requestPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        await navigation_service.handleNotificationPayload(payload);
      },
      onDidReceiveBackgroundNotificationResponse: (response) async {
        final payload = response.payload;
        await navigation_service.handleNotificationPayload(payload);
      },
    );
  }

  static Future<void> _createAndroidNotificationChannel() async {
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }
  }

  // ═══════════════════════════════════════
  // HANDLE FOREGROUND MESSAGE
  // ═══════════════════════════════════════
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _showNotification(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _showNotification({
    required int id,
    required String? title,
    required String? body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      color: AppColors.adminPrimary.withOpacity(0.8),
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  // No helper here — navigation is handled by navigation_service.handleNotificationPayload

  static Future<void> showNotification({
    required int id,
    required String? title,
    required String? body,
    String? payload,
  }) async {
    await _showNotification(id: id, title: title, body: body, payload: payload);
  }

  // ═══════════════════════════════════════
  // GET FCM TOKEN
  // ═══════════════════════════════════════
  static Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }
}

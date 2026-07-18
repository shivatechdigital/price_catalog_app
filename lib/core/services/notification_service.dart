import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';

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

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
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
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  static Future<void> _createAndroidNotificationChannel() async {
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
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
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> showNotification({
    required int id,
    required String? title,
    required String? body,
    String? payload,
  }) async {
    await _showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  // ═══════════════════════════════════════
  // GET FCM TOKEN
  // ═══════════════════════════════════════
  static Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';

class FlutterLocalNotificationsPlugin {
  Future<void> initialize(InitializationSettings initializationSettings) async {}

  AndroidFlutterLocalNotificationsPlugin? resolvePlatformSpecificImplementation<T>() {
    return null;
  }

  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
  ) async {}
}

class InitializationSettings {
  const InitializationSettings({this.android, this.iOS});

  final AndroidInitializationSettings? android;
  final DarwinInitializationSettings? iOS;
}

class AndroidInitializationSettings {
  const AndroidInitializationSettings(this.icon);

  final String icon;
}

class DarwinInitializationSettings {
  const DarwinInitializationSettings({
    this.requestAlertPermission = false,
    this.requestBadgePermission = false,
    this.requestSoundPermission = false,
  });

  final bool requestAlertPermission;
  final bool requestBadgePermission;
  final bool requestSoundPermission;
}

class AndroidFlutterLocalNotificationsPlugin {
  Future<void> createNotificationChannel(
    AndroidNotificationChannel channel,
  ) async {}
}

class AndroidNotificationChannel {
  const AndroidNotificationChannel(
    this.id,
    this.name, {
    this.description,
    this.importance = Importance.high,
  });

  final String id;
  final String name;
  final String? description;
  final Importance importance;
}

class NotificationDetails {
  const NotificationDetails({this.android, this.iOS});

  final AndroidNotificationDetails? android;
  final DarwinNotificationDetails? iOS;
}

class AndroidNotificationDetails extends NotificationDetails {
  const AndroidNotificationDetails(
    String channelId,
    String channelName, {
    this.importance = Importance.high,
    this.priority = Priority.high,
    this.color,
    this.icon,
  }) : super(android: null, iOS: null);

  final Importance importance;
  final Priority priority;
  final int? color;
  final String? icon;
}

class DarwinNotificationDetails extends NotificationDetails {
  const DarwinNotificationDetails({
    this.presentAlert = true,
    this.presentBadge = true,
    this.presentSound = true,
  }) : super(android: null, iOS: null);

  final bool presentAlert;
  final bool presentBadge;
  final bool presentSound;
}

class Importance {
  static const Importance high = Importance._('high');
  static const Importance defaultImportance = Importance._('default');

  const Importance._(this.value);

  final String value;
}

class Priority {
  static const Priority high = Priority._('high');

  const Priority._(this.value);

  final String value;
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ═══════════════════════════════════════
  // INITIALIZE
  // ═══════════════════════════════════════
  static Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create notification channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'price_catalog_channel',
            'Price Catalog Notifications',
            description: 'Notifications for Price Catalog App',
            importance: Importance.high,
          ),
        );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // ═══════════════════════════════════════
  // HANDLE FOREGROUND MESSAGE
  // ═══════════════════════════════════════
  static Future<void> _handleForegroundMessage(
      RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'price_catalog_channel',
          'Price Catalog Notifications',
          importance: Importance.high,
          priority: Priority.high,
          color: AppColors.adminPrimary.value,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // GET FCM TOKEN
  // ═══════════════════════════════════════
  static Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }
}
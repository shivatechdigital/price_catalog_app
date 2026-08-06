import 'dart:io';

import 'package:flutter/services.dart';

class AppExitService {
  static const MethodChannel _channel = MethodChannel(
    'price_catalog_app/app_exit',
  );

  static Future<void> exitApp() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('exitApp');
        return;
      } catch (_) {
        // Fallback if the platform channel is unavailable.
      }
    }

    await SystemNavigator.pop();
  }
}

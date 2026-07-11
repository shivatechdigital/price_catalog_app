import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  // ═══════════════════════════════════════
  // REQUEST CAMERA PERMISSION
  // ═══════════════════════════════════════
  static Future<bool> requestCameraPermission(
      BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && context.mounted) {
      _showSettingsDialog(
        context,
        'Camera Permission',
        'Camera access is required to take product photos. '
            'Please enable it in Settings.',
      );
    }
    return false;
  }

  // ═══════════════════════════════════════
  // REQUEST STORAGE PERMISSION
  // ═══════════════════════════════════════
  static Future<bool> requestStoragePermission(
      BuildContext context) async {
    Permission permission;

    if (await _isAndroid13OrAbove()) {
      permission = Permission.photos;
    } else {
      permission = Permission.storage;
    }

    final status = await permission.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && context.mounted) {
      _showSettingsDialog(
        context,
        'Storage Permission',
        'Storage access is required to upload product images. '
            'Please enable it in Settings.',
      );
    }
    return false;
  }

  // ═══════════════════════════════════════
  // REQUEST NOTIFICATION PERMISSION
  // ═══════════════════════════════════════
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // ═══════════════════════════════════════
  // CHECK ALL PERMISSIONS AT STARTUP
  // ═══════════════════════════════════════
  static Future<void> requestAllPermissions(
      BuildContext context) async {
    await requestNotificationPermission();
  }

  // ─── HELPERS ────────────────────────────────────────
  static Future<bool> _isAndroid13OrAbove() async {
    try {
      final status = await Permission.photos.status;
      return status != PermissionStatus.permanentlyDenied ||
          true;
    } catch (_) {
      return false;
    }
  }

  static void _showSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
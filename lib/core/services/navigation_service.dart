import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
String? _pendingNotificationPayload;

/// Navigate to requirement detail using the current user's role to
/// choose the correct route (admin vs trader).
Future<void> navigateToRequirementById(String requirementId) async {
  try {
    final uid = FirebaseService.currentUserId;
    if (uid == null) return;

    final doc = await FirebaseService.usersRef.doc(uid).get();
    if (!doc.exists) return;
    final role = (doc.data() as Map<String, dynamic>)['role'] as String?;

    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      _pendingNotificationPayload = jsonEncode({'referenceId': requirementId});
      return;
    }

    if (role == 'admin') {
      GoRouter.of(context).push('/admin/requirements/$requirementId');
    } else {
      GoRouter.of(context).push('/trader/requirements/$requirementId');
    }
  } catch (_) {
    // ignore navigation failures
  }
}

/// Decode a JSON payload and navigate if it contains a requirement id.
Future<void> handleNotificationPayload(String? payload) async {
  if (payload == null || payload.isEmpty) return;
  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    final refId = data['referenceId'] ?? data['requirementId'] ?? data['id'];
    if (refId is String && refId.isNotEmpty) {
      await navigateToRequirementById(refId);
    }
  } catch (_) {
    // ignore malformed payloads
  }
}

Future<void> processPendingNotification() async {
  if (_pendingNotificationPayload == null) return;
  final payload = _pendingNotificationPayload;
  _pendingNotificationPayload = null;
  await handleNotificationPayload(payload);
}

Future<void> setPendingNotificationPayload(String payload) async {
  _pendingNotificationPayload = payload;
}

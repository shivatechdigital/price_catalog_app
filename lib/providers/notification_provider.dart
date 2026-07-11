import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';
import 'package:price_catalog_app/data/models/notification_model.dart';

// ═══════════════════════════════════════
// NOTIFICATION REPOSITORY
// ═══════════════════════════════════════
class NotificationRepository {
  // Watch notifications for a user
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return FirebaseService.notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Watch unread count
  Stream<int> watchUnreadCount(String userId) {
    return FirebaseService.notificationsRef(userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await FirebaseService.notificationsRef(userId)
        .doc(notificationId)
        .update({'read': true});
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    final batch = FirebaseService.firestore.batch();
    final unread = await FirebaseService.notificationsRef(userId)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(
      String userId, String notificationId) async {
    await FirebaseService.notificationsRef(userId)
        .doc(notificationId)
        .delete();
  }
}

// ═══════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════
final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationsStreamProvider =
    StreamProvider.family<List<NotificationModel>, String>(
        (ref, userId) {
  return ref
      .watch(notificationRepositoryProvider)
      .watchNotifications(userId);
});

final unreadCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref
      .watch(notificationRepositoryProvider)
      .watchUnreadCount(userId);
});
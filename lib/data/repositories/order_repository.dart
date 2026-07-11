import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';
import 'package:price_catalog_app/data/models/notification_model.dart';
import 'package:price_catalog_app/data/models/order_model.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';

class OrderRepository {
  final _ref = FirebaseFirestore.instance.collection('orders');

  // ═══════════════════════════════════════
  // SUBMIT NEW ORDER (Trader)
  // ═══════════════════════════════════════
  Future<OrderModel> submitOrder({
    required String traderId,
    required String traderName,
    required String traderBusinessName,
    required String traderPhone,
    required String customerName,
    required String customerPhone,
    required String customerBusinessName,
    required String customerCity,
    String? customerAddress,
    required PaymentType paymentType,
    int? creditDays,
    double? advanceAmount,
    DateTime? deliveryDate,
    String? deliveryLocation,
    String? traderNote,
    required List<OrderItemModel> items,
  }) async {
    final docRef = _ref.doc();

    // Calculate total
    final totalValue = items.fold<double>(
      0,
      (sum, item) => sum + item.itemTotal,
    );

    final order = OrderModel(
      id: docRef.id,
      traderId: traderId,
      traderName: traderName,
      traderBusinessName: traderBusinessName,
      traderPhone: traderPhone,
      customerName: customerName,
      customerPhone: customerPhone,
      customerBusinessName: customerBusinessName,
      customerCity: customerCity,
      customerAddress: customerAddress,
      paymentType: paymentType,
      creditDays: creditDays,
      advanceAmount: advanceAmount,
      deliveryDate: deliveryDate,
      deliveryLocation: deliveryLocation,
      traderNote: traderNote,
      items: items,
      totalItems: items.length,
      approvedCount: 0,
      rejectedCount: 0,
      counterCount: 0,
      pendingCount: items.length,
      orderStatus: OrderStatus.pending,
      totalOrderValue: totalValue,
      approvedOrderValue: 0,
      submittedAt: DateTime.now(),
    );

    await docRef.set(order.toFirestore());

    // Notify admin
    await _notifyAdmin(order);

    return order;
  }

  // ═══════════════════════════════════════
  // ADMIN: UPDATE SINGLE ITEM STATUS
  // ═══════════════════════════════════════
  Future<void> updateItemStatus({
    required String orderId,
    required String itemId,
    required OrderItemStatus newStatus,
    double? counterPrice,
    double? finalPrice,
    String? rejectionReason,
    String? adminNote,
  }) async {
    // Get current order
    final doc = await _ref.doc(orderId).get();
    if (!doc.exists) return;

    final order = OrderModel.fromFirestore(doc);

    // Find and update the specific item
    final updatedItems = order.items.map((item) {
      if (item.itemId == itemId) {
        return item.copyWith(
          status: newStatus,
          counterPrice: counterPrice,
          finalPrice: finalPrice,
          rejectionReason: rejectionReason,
          adminNote: adminNote,
          actionTakenAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    // Recalculate counts
    final approved = updatedItems.where((i) => i.isApproved).length;
    final rejected = updatedItems.where((i) => i.isRejected).length;
    final counter = updatedItems.where((i) => i.isCounterOffer).length;
    final pending = updatedItems.where((i) => i.isPending).length;

    // Recalculate order status
    final newOrderStatus = OrderModel.calculateStatus(updatedItems);

    // Recalculate approved value
    final approvedValue = updatedItems
        .where((i) => i.isApproved)
        .fold<double>(0, (sum, i) => sum + i.approvedTotal);

    // Update Firestore
    await _ref.doc(orderId).update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'approvedCount': approved,
      'rejectedCount': rejected,
      'counterCount': counter,
      'pendingCount': pending,
      'orderStatus': newOrderStatus.name,
      'approvedOrderValue': approvedValue,
      'lastActionAt': FieldValue.serverTimestamp(),
    });

    // Notify trader
    await _notifyTraderItemUpdate(
      traderId: order.traderId,
      orderId: orderId,
      itemName: updatedItems
          .firstWhere((i) => i.itemId == itemId)
          .productName,
      status: newStatus,
      counterPrice: counterPrice,
    );
  }

  // ═══════════════════════════════════════
  // ADMIN: BULK ACTION - Approve All Pending
  // ═══════════════════════════════════════
  Future<void> approveAllPending({
    required String orderId,
    String? adminNote,
  }) async {
    final doc = await _ref.doc(orderId).get();
    if (!doc.exists) return;

    final order = OrderModel.fromFirestore(doc);

    final updatedItems = order.items.map((item) {
      if (item.isPending) {
        return item.copyWith(
          status: OrderItemStatus.approved,
          finalPrice: item.customerDemandedPrice,
          adminNote: adminNote,
          actionTakenAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    final approved = updatedItems.where((i) => i.isApproved).length;
    final rejected = updatedItems.where((i) => i.isRejected).length;
    final counter = updatedItems.where((i) => i.isCounterOffer).length;
    final pending = updatedItems.where((i) => i.isPending).length;
    final newStatus = OrderModel.calculateStatus(updatedItems);
    final approvedValue = updatedItems
        .where((i) => i.isApproved)
        .fold<double>(0, (sum, i) => sum + i.approvedTotal);

    await _ref.doc(orderId).update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'approvedCount': approved,
      'rejectedCount': rejected,
      'counterCount': counter,
      'pendingCount': pending,
      'orderStatus': newStatus.name,
      'approvedOrderValue': approvedValue,
      'adminNote': adminNote,
      'lastActionAt': FieldValue.serverTimestamp(),
    });

    await _notifyTrader(
      traderId: order.traderId,
      title: '✅ All Items Approved!',
      message: 'All ${order.totalItems} items in your order have been approved.',
      type: NotificationType.requirementApproved,
      referenceId: orderId,
    );
  }

  // ═══════════════════════════════════════
  // ADMIN: BULK ACTION - Reject All Pending
  // ═══════════════════════════════════════
  Future<void> rejectAllPending({
    required String orderId,
    required String rejectionReason,
    String? adminNote,
  }) async {
    final doc = await _ref.doc(orderId).get();
    if (!doc.exists) return;

    final order = OrderModel.fromFirestore(doc);

    final updatedItems = order.items.map((item) {
      if (item.isPending) {
        return item.copyWith(
          status: OrderItemStatus.rejected,
          rejectionReason: rejectionReason,
          adminNote: adminNote,
          actionTakenAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    final approved = updatedItems.where((i) => i.isApproved).length;
    final rejected = updatedItems.where((i) => i.isRejected).length;
    final counter = updatedItems.where((i) => i.isCounterOffer).length;
    final pending = updatedItems.where((i) => i.isPending).length;
    final newStatus = OrderModel.calculateStatus(updatedItems);

    await _ref.doc(orderId).update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'approvedCount': approved,
      'rejectedCount': rejected,
      'counterCount': counter,
      'pendingCount': pending,
      'orderStatus': newStatus.name,
      'adminNote': adminNote,
      'lastActionAt': FieldValue.serverTimestamp(),
    });

    await _notifyTrader(
      traderId: order.traderId,
      title: '❌ Order Rejected',
      message: 'Your order with ${order.totalItems} items was not approved.',
      type: NotificationType.requirementRejected,
      referenceId: orderId,
    );
  }

  // ═══════════════════════════════════════
  // TRADER: ACCEPT COUNTER OFFER (Single Item)
  // ═══════════════════════════════════════
  Future<void> acceptItemCounterOffer({
    required String orderId,
    required String itemId,
  }) async {
    final doc = await _ref.doc(orderId).get();
    if (!doc.exists) return;

    final order = OrderModel.fromFirestore(doc);

    final updatedItems = order.items.map((item) {
      if (item.itemId == itemId && item.isCounterOffer) {
        return item.copyWith(
          status: OrderItemStatus.approved,
          finalPrice: item.counterPrice,
          actionTakenAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    await _updateOrderCounts(orderId, updatedItems);
  }

  // ═══════════════════════════════════════
  // TRADER: REJECT COUNTER OFFER (Single Item)
  // ═══════════════════════════════════════
  Future<void> rejectItemCounterOffer({
    required String orderId,
    required String itemId,
  }) async {
    final doc = await _ref.doc(orderId).get();
    if (!doc.exists) return;

    final order = OrderModel.fromFirestore(doc);

    final updatedItems = order.items.map((item) {
      if (item.itemId == itemId && item.isCounterOffer) {
        return item.copyWith(
          status: OrderItemStatus.rejected,
          rejectionReason: 'Counter offer rejected by trader',
          actionTakenAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    await _updateOrderCounts(orderId, updatedItems);
  }

  // ═══════════════════════════════════════
  // TRADER: ACCEPT ALL COUNTER OFFERS
  // ═══════════════════════════════════════
  Future<void> acceptAllCounterOffers({
    required String orderId,
  }) async {
    final doc = await _ref.doc(orderId).get();
    if (!doc.exists) return;

    final order = OrderModel.fromFirestore(doc);

    final updatedItems = order.items.map((item) {
      if (item.isCounterOffer) {
        return item.copyWith(
          status: OrderItemStatus.approved,
          finalPrice: item.counterPrice,
          actionTakenAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    await _updateOrderCounts(orderId, updatedItems);
  }

  // ═══════════════════════════════════════
  // HELPER: Update order counts after item changes
  // ═══════════════════════════════════════
  Future<void> _updateOrderCounts(
    String orderId,
    List<OrderItemModel> updatedItems,
  ) async {
    final approved = updatedItems.where((i) => i.isApproved).length;
    final rejected = updatedItems.where((i) => i.isRejected).length;
    final counter = updatedItems.where((i) => i.isCounterOffer).length;
    final pending = updatedItems.where((i) => i.isPending).length;
    final newStatus = OrderModel.calculateStatus(updatedItems);
    final approvedValue = updatedItems
        .where((i) => i.isApproved)
        .fold<double>(0, (sum, i) => sum + i.approvedTotal);

    await _ref.doc(orderId).update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'approvedCount': approved,
      'rejectedCount': rejected,
      'counterCount': counter,
      'pendingCount': pending,
      'orderStatus': newStatus.name,
      'approvedOrderValue': approvedValue,
      'lastActionAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════
  // STREAMS
  // ═══════════════════════════════════════

  // Admin: Watch all orders
  Stream<List<OrderModel>> watchAllOrders({OrderStatus? status}) {
    Query<Map<String, dynamic>> query =
        _ref.orderBy('submittedAt', descending: true);

    if (status != null) {
      query = query.where('orderStatus', isEqualTo: status.name);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Trader: Watch own orders
  Stream<List<OrderModel>> watchTraderOrders({
    required String traderId,
    OrderStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _ref
        .where('traderId', isEqualTo: traderId)
        .orderBy('submittedAt', descending: true);

    if (status != null) {
      query = _ref
          .where('traderId', isEqualTo: traderId)
          .where('orderStatus', isEqualTo: status.name)
          .orderBy('submittedAt', descending: true);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Admin: Pending count
  Stream<int> watchPendingOrderCount() {
    return _ref
        .where('orderStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ═══════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════
  Future<void> _notifyAdmin(OrderModel order) async {
    try {
      final adminQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final adminDoc in adminQuery.docs) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(adminDoc.id)
            .collection('items')
            .add({
          'title': '🔔 New Multi-Product Order!',
          'message':
              '${order.traderName} submitted order with ${order.totalItems} items for ${order.customerName}. Total: ₹${order.totalOrderValue.toStringAsFixed(0)}',
          'type': 'newRequirement',
          'referenceId': order.id,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<void> _notifyTrader({
    required String traderId,
    required String title,
    required String message,
    required NotificationType type,
    required String referenceId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(traderId)
          .collection('items')
          .add({
        'title': title,
        'message': message,
        'type': type.name,
        'referenceId': referenceId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _notifyTraderItemUpdate({
    required String traderId,
    required String orderId,
    required String itemName,
    required OrderItemStatus status,
    double? counterPrice,
  }) async {
    final (title, message) = switch (status) {
      OrderItemStatus.approved => (
          '✅ Item Approved!',
          '$itemName has been approved in your order.',
        ),
      OrderItemStatus.rejected => (
          '❌ Item Rejected',
          '$itemName was not approved in your order.',
        ),
      OrderItemStatus.counterOffer => (
          '🔄 Counter Offer',
          'Admin suggested ₹${counterPrice?.toStringAsFixed(0)} for $itemName.',
        ),
      OrderItemStatus.pending => (
          '⏳ Item Pending',
          '$itemName is still under review.',
        ),
    };

    await _notifyTrader(
      traderId: traderId,
      title: title,
      message: message,
      type: status == OrderItemStatus.approved
          ? NotificationType.requirementApproved
          : status == OrderItemStatus.rejected
              ? NotificationType.requirementRejected
              : NotificationType.counterOffer,
      referenceId: orderId,
    );
  }
}
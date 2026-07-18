import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';
import 'package:price_catalog_app/data/models/notification_model.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';

class RequirementRepository {
  final _ref = FirebaseService.requirementsRef;

  // ═══════════════════════════════════════
  // SUBMIT NEW REQUIREMENT (Trader) - Single Product
  // ═══════════════════════════════════════
  Future<RequirementModel> submitRequirement({
    required String traderId,
    required String traderName,
    required String traderBusinessName,
    required String traderPhone,
    required String productId,
    required String productName,
    required String productCode,
    String? productImage,
    String? categoryName,
    required String customerName,
    required String customerPhone,
    required String customerBusinessName,
    required String customerCity,
    String? customerAddress,
    required double quantity,
    required String unit,
    required double productCurrentPrice,
    required double customerDemandedPrice,
    required double traderOfferedPrice,
    required PaymentType paymentType,
    int? creditDays,
    double? advanceAmount,
    DateTime? deliveryDate,
    String? deliveryLocation,
    String? traderNote,
  }) async {
    // Create single item for backward compatibility
    final item = RequirementItemModel(
      productId: productId,
      productName: productName,
      productCode: productCode,
      productImage: productImage,
      categoryName: categoryName,
      quantity: quantity,
      unit: unit,
      productCurrentPrice: productCurrentPrice,
      customerDemandedPrice: customerDemandedPrice,
      traderOfferedPrice: traderOfferedPrice,
      traderPhone: traderPhone,
      deliveryLocation: deliveryLocation,
      traderNote: traderNote,
    );

    final requirement = RequirementModel(
      id: '',
      traderId: traderId,
      traderName: traderName,
      traderBusinessName: traderBusinessName,
      items: [item],
      customerName: customerName,
      customerPhone: customerPhone,
      customerBusinessName: customerBusinessName,
      customerCity: customerCity,
      paymentType: paymentType,
      creditDays: creditDays,
      deliveryDate: deliveryDate,
      deliveryLocation: deliveryLocation,
      traderNote: traderNote,
      status: RequirementStatus.pending,
      submittedAt: DateTime.now(),
    );

    return _submitRequirement(requirement);
  }

  // ═══════════════════════════════════════
  // SUBMIT MULTIPLE REQUIREMENTS (Trader) - Bulk Products
  // ═══════════════════════════════════════
  Future<RequirementModel> submitBulkRequirements({
    required String traderId,
    required String traderName,
    required String traderBusinessName,
    required String traderPhone,
    required List<RequirementItemModel> items,
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
  }) async {
    final requirement = RequirementModel(
      id: '',
      traderId: traderId,
      traderName: traderName,
      traderBusinessName: traderBusinessName,
      items: items,
      customerName: customerName,
      customerPhone: customerPhone,
      customerBusinessName: customerBusinessName,
      customerCity: customerCity,
      paymentType: paymentType,
      creditDays: creditDays,
      deliveryDate: deliveryDate,
      deliveryLocation: deliveryLocation,
      traderNote: traderNote,
      status: RequirementStatus.pending,
      submittedAt: DateTime.now(),
    );

    return _submitRequirement(requirement);
  }

  // ═══════════════════════════════════════
  // INTERNAL - Submit Requirement to Firestore
  // ═══════════════════════════════════════
  Future<RequirementModel> _submitRequirement(
    RequirementModel requirement,
  ) async {
    final docRef = _ref.doc();

    final requirementWithId = RequirementModel(
      id: docRef.id,
      traderId: requirement.traderId,
      traderName: requirement.traderName,
      traderBusinessName: requirement.traderBusinessName,
      items: requirement.items,
      customerName: requirement.customerName,
      customerPhone: requirement.customerPhone,
      customerBusinessName: requirement.customerBusinessName,
      customerCity: requirement.customerCity,
      paymentType: requirement.paymentType,
      creditDays: requirement.creditDays,
      deliveryDate: requirement.deliveryDate,
      deliveryLocation: requirement.deliveryLocation,
      traderNote: requirement.traderNote,
      status: RequirementStatus.pending,
      submittedAt: requirement.submittedAt,
    );

    try {
      await docRef.set(requirementWithId.toFirestore());
    } on FirebaseException catch (e) {
      print("===============");
      print(e.code);
      print(e.message);
      print("===============");
    }

    // Notify admin
    await _notifyAdmin(requirementWithId);

    return requirementWithId;
  }

  // ═══════════════════════════════════════
  // NOTIFY ADMIN - New requirement
  // ═══════════════════════════════════════
  Future<void> _notifyAdmin(
    RequirementModel requirement, {
    String? title,
    String? message,
  }) async {
    try {
      final adminQuery = await FirebaseService.usersRef
          .where('role', isEqualTo: 'admin')
          .get();

      for (final adminDoc in adminQuery.docs) {
        final notification = NotificationModel(
          id: '',
          title: title ?? '🔔 New Requirement!',
          message:
              message ??
              '${requirement.traderName} submitted requirement for '
                  '${requirement.productName} at '
                  '₹${requirement.customerDemandedPrice.toStringAsFixed(0)}',
          type: NotificationType.newRequirement,
          referenceId: requirement.id,
          read: false,
          createdAt: DateTime.now(),
        );

        await FirebaseService.notificationsRef(
          adminDoc.id,
        ).add(notification.toFirestore());
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════
  // WATCH ALL REQUIREMENTS (Admin)
  // ═══════════════════════════════════════
  Stream<List<RequirementModel>> watchAllRequirements({
    RequirementStatus? status,
  }) {
    // When a status filter is applied, `where(status) + orderBy(submittedAt)`
    // would need a composite index, so we sort in Dart instead.
    Query<Map<String, dynamic>> query = status != null
        ? _ref.where('status', isEqualTo: status.name)
        : _ref;

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => RequirementModel.fromFirestore(doc))
          .toList();
      items.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return items;
    });
  }

  // ═══════════════════════════════════════
  // WATCH TRADER REQUIREMENTS (Trader)
  // ═══════════════════════════════════════
  Stream<List<RequirementModel>> watchTraderRequirements({
    required String traderId,
    RequirementStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _ref
        .where('traderId', isEqualTo: traderId)
        .orderBy('submittedAt', descending: true);

    if (status != null) {
      query = _ref
          .where('traderId', isEqualTo: traderId)
          .where('status', isEqualTo: status.name)
          .orderBy('submittedAt', descending: true);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => RequirementModel.fromFirestore(doc))
          .toList(),
    );
  }

  // ═══════════════════════════════════════
  // APPROVE REQUIREMENT (Admin)
  // ═══════════════════════════════════════
  Future<void> approveRequirement({
    required String requirementId,
    required String traderId,
    required String productName,
    String? adminNote,
    double? finalPrice,
  }) async {
    await _ref.doc(requirementId).update({
      'status': RequirementStatus.approved.name,
      'adminNote': adminNote,
      'priceDetails.finalApprovedPrice': finalPrice,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });

    // Notify trader
    await _notifyTrader(
      traderId: traderId,
      title: '✅ Requirement Approved!',
      message: 'Your requirement for $productName has been approved.',
      type: NotificationType.requirementApproved,
      referenceId: requirementId,
    );
  }

  // ═══════════════════════════════════════
  // REJECT REQUIREMENT (Admin)
  // ═══════════════════════════════════════
  Future<void> rejectRequirement({
    required String requirementId,
    required String traderId,
    required String productName,
    required String rejectionReason,
    String? adminNote,
  }) async {
    await _ref.doc(requirementId).update({
      'status': RequirementStatus.rejected.name,
      'rejectionReason': rejectionReason,
      'adminNote': adminNote,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });

    // Notify trader
    await _notifyTrader(
      traderId: traderId,
      title: '❌ Requirement Rejected',
      message:
          'Your requirement for $productName was not approved. '
          'Reason: $rejectionReason',
      type: NotificationType.requirementRejected,
      referenceId: requirementId,
    );
  }

  // ═══════════════════════════════════════
  // COUNTER OFFER (Admin)
  // ═══════════════════════════════════════
  Future<void> sendCounterOffer({
    required String requirementId,
    required String traderId,
    required String productName,
    required double counterPrice,
    String? adminNote,
  }) async {
    await _ref.doc(requirementId).update({
      'status': RequirementStatus.counterOffer.name,
      'counterPrice': counterPrice,
      'adminNote': adminNote,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });

    // Notify trader
    await _notifyTrader(
      traderId: traderId,
      title: '🔄 Counter Offer Received',
      message:
          'Admin has suggested ₹${counterPrice.toStringAsFixed(0)} '
          'for $productName. Please review.',
      type: NotificationType.counterOffer,
      referenceId: requirementId,
    );
  }

  // ═══════════════════════════════════════
  // ACCEPT COUNTER OFFER (Trader)
  // ═══════════════════════════════════════
  Future<void> acceptCounterOffer({required String requirementId}) async {
    await _ref.doc(requirementId).update({
      'status': RequirementStatus.approved.name,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════
  // REJECT COUNTER OFFER (Trader)
  // ═══════════════════════════════════════
  Future<void> rejectCounterOffer({required String requirementId}) async {
    await _ref.doc(requirementId).update({
      'status': RequirementStatus.rejected.name,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════
  // NOTIFY TRADER
  // ═══════════════════════════════════════
  Future<void> _notifyTrader({
    required String traderId,
    required String title,
    required String message,
    required NotificationType type,
    required String referenceId,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        title: title,
        message: message,
        type: type,
        referenceId: referenceId,
        read: false,
        createdAt: DateTime.now(),
      );

      await FirebaseService.notificationsRef(
        traderId,
      ).add(notification.toFirestore());
    } catch (_) {}
  }

  // ═══════════════════════════════════════
  // GET REQUIREMENT BY ID
  // ═══════════════════════════════════════
  Future<RequirementModel?> getRequirementById(String requirementId) async {
    final doc = await _ref.doc(requirementId).get();
    if (!doc.exists) return null;
    return RequirementModel.fromFirestore(doc);
  }

  // ═══════════════════════════════════════
  // WATCH REQUIREMENT BY ID (live updates)
  // ═══════════════════════════════════════
  Stream<RequirementModel?> watchRequirementById(String requirementId) {
    return _ref.doc(requirementId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RequirementModel.fromFirestore(doc);
    });
  }

  // ═══════════════════════════════════════
  // UPDATE SINGLE ITEM STATUS (Admin)
  // Per-product approve / reject / counter within a multi-product requirement
  // ═══════════════════════════════════════
  Future<void> updateItemStatus({
    required RequirementModel requirement,
    required int itemIndex,
    required RequirementStatus itemStatus,
    double? counterPrice,
    String? rejectionReason,
    String? adminNote,
  }) async {
    final items = List<RequirementItemModel>.from(requirement.items);
    final item = items[itemIndex];

    items[itemIndex] = item.copyWith(
      itemStatus: itemStatus,
      itemCounterPrice: counterPrice,
      itemRejectionReason: rejectionReason,
      itemAdminNote: adminNote,
      counterOfferBy: itemStatus == RequirementStatus.counterOffer
          ? CounterOfferBy.admin
          : item.counterOfferBy,
      rejectionBy: itemStatus == RequirementStatus.rejected
          ? RejectionBy.admin
          : item.rejectionBy,
    );

    await _ref.doc(requirement.id).update({
      'items': items.map((i) => i.toFirestore()).toList(),
      'status': _overallStatus(items).name,
      'requiresAdminConfirmation': false,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });

    // Notify trader about the per-item action
    final (title, message) = switch (itemStatus) {
      RequirementStatus.approved => (
        '✅ Product Approved!',
        '${item.productName} in your requirement has been approved.',
      ),
      RequirementStatus.rejected => (
        '❌ Product Rejected',
        '${item.productName} in your requirement was not approved.'
            '${rejectionReason != null ? ' Reason: $rejectionReason' : ''}',
      ),
      RequirementStatus.counterOffer => (
        '🔄 Counter Offer Received',
        'Admin suggested ₹${(counterPrice ?? 0).toStringAsFixed(0)} '
            'for ${item.productName}. Please review.',
      ),
      _ => ('Requirement Updated', '${item.productName} status updated.'),
    };

    await _notifyTrader(
      traderId: requirement.traderId,
      title: title,
      message: message,
      type: switch (itemStatus) {
        RequirementStatus.approved => NotificationType.requirementApproved,
        RequirementStatus.rejected => NotificationType.requirementRejected,
        RequirementStatus.counterOffer => NotificationType.counterOffer,
        _ => NotificationType.requirementApproved,
      },
      referenceId: requirement.id,
    );
  }

  // ═══════════════════════════════════════
  // UPDATE ALL ITEMS STATUS (Admin)
  // Approve / Reject / Counter every pending item at once
  // ═══════════════════════════════════════
  Future<void> updateAllItemsStatus({
    required RequirementModel requirement,
    required RequirementStatus itemStatus,
    double? counterPrice,
    String? rejectionReason,
    String? adminNote,
  }) async {
    // Only touch items that are still pending — already-actioned
    // items keep their individual status.
    final items = requirement.items.map((item) {
      if (item.itemStatus != RequirementStatus.pending) return item;
      return item.copyWith(
        itemStatus: itemStatus,
        itemCounterPrice: counterPrice,
        itemRejectionReason: rejectionReason,
        itemAdminNote: adminNote,
        counterOfferBy: itemStatus == RequirementStatus.counterOffer
            ? CounterOfferBy.admin
            : item.counterOfferBy,
        rejectionBy: itemStatus == RequirementStatus.rejected
            ? RejectionBy.admin
            : item.rejectionBy,
      );
    }).toList();

    await _ref.doc(requirement.id).update({
      'items': items.map((i) => i.toFirestore()).toList(),
      'status': _overallStatus(items).name,
      'requiresAdminConfirmation': false,
      'adminNote': adminNote,
      if (counterPrice != null) 'counterPrice': counterPrice,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });

    final productLabel = requirement.items.length > 1
        ? '${requirement.items.length} products'
        : requirement.productName;

    final (title, message, type) = switch (itemStatus) {
      RequirementStatus.approved => (
        '✅ Requirement Approved!',
        'Your requirement for $productLabel has been approved.',
        NotificationType.requirementApproved,
      ),
      RequirementStatus.rejected => (
        '❌ Requirement Rejected',
        'Your requirement for $productLabel was not approved.'
            '${rejectionReason != null ? ' Reason: $rejectionReason' : ''}',
        NotificationType.requirementRejected,
      ),
      RequirementStatus.counterOffer => (
        '🔄 Counter Offer Received',
        'Admin suggested ₹${(counterPrice ?? 0).toStringAsFixed(0)} '
            'for $productLabel. Please review.',
        NotificationType.counterOffer,
      ),
      _ => (
        'Requirement Updated',
        'Your requirement for $productLabel was updated.',
        NotificationType.requirementApproved,
      ),
    };

    await _notifyTrader(
      traderId: requirement.traderId,
      title: title,
      message: message,
      type: type,
      referenceId: requirement.id,
    );
  }

  // ═══════════════════════════════════════
  // OVERALL STATUS from item statuses
  // ═══════════════════════════════════════
  // - any pending      → pending (admin still has work left)
  // - any counterOffer → counterOffer (waiting on trader)
  // - any approved     → approved (at least one product deal done)
  // - else             → rejected (everything rejected)
  RequirementStatus _overallStatus(List<RequirementItemModel> items) {
    if (items.any((i) => i.isAwaitingAdminResponse)) {
      return RequirementStatus.pending;
    }
    if (items.any((i) => i.itemStatus == RequirementStatus.pending)) {
      return RequirementStatus.pending;
    }
    if (items.any((i) => i.isAwaitingTraderResponse)) {
      return RequirementStatus.counterOffer;
    }
    if (items.any((i) => i.itemStatus == RequirementStatus.approved)) {
      return RequirementStatus.approved;
    }
    return RequirementStatus.rejected;
  }

  // ═══════════════════════════════════════
  // TRADER RESPONSES TO A PER-PRODUCT COUNTER OFFER
  // ═══════════════════════════════════════
  Future<void> acceptItemCounterOffer({
    required RequirementModel requirement,
    required int itemIndex,
  }) async {
    final items = List<RequirementItemModel>.from(requirement.items);
    final item = items[itemIndex];
    items[itemIndex] = item.copyWith(itemStatus: RequirementStatus.approved);

    await _ref.doc(requirement.id).update({
      'items': items.map((i) => i.toFirestore()).toList(),
      'status': _overallStatus(items).name,
      'requiresAdminConfirmation': false,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });
    await _notifyAdmin(
      requirement.copyWith(items: items, status: _overallStatus(items)),
      title: '✅ Counter Offer Accepted',
      message: '${item.productName} counter offer was accepted by trader.',
    );
  }

  Future<void> sendTraderItemCounterOffer({
    required RequirementModel requirement,
    required int itemIndex,
    required double counterPrice,
    String? note,
  }) async {
    final items = List<RequirementItemModel>.from(requirement.items);
    final item = items[itemIndex];
    items[itemIndex] = item.copyWith(
      itemStatus: RequirementStatus.counterOffer,
      itemCounterPrice: counterPrice,
      itemTraderResponseNote: note,
      counterOfferBy: CounterOfferBy.trader,
    );

    await _ref.doc(requirement.id).update({
      'items': items.map((i) => i.toFirestore()).toList(),
      'status': _overallStatus(items).name,
      'requiresAdminConfirmation': false,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });
    await _notifyAdmin(
      requirement.copyWith(items: items, status: _overallStatus(items)),
      title: '🔄 Trader Counter Offer',
      message:
          '${item.productName}: trader suggested ₹${counterPrice.toStringAsFixed(0)}.',
    );
  }

  Future<void> rejectItemCounterOffer({
    required RequirementModel requirement,
    required int itemIndex,
    required String reason,
    required bool proceedWithRemaining,
  }) async {
    final items = List<RequirementItemModel>.from(requirement.items);
    final item = items[itemIndex];
    items[itemIndex] = item.copyWith(
      itemStatus: RequirementStatus.rejected,
      itemRejectionReason: reason,
      itemTraderResponseNote: reason,
      rejectionBy: RejectionBy.trader,
    );
    final hasApprovedItems = items.any((i) => i.isApproved);
    final needsConfirmation = proceedWithRemaining && hasApprovedItems;
    if (!proceedWithRemaining && hasApprovedItems) {
      for (var index = 0; index < items.length; index++) {
        if (items[index].isApproved) {
          items[index] = items[index].copyWith(
            itemStatus: RequirementStatus.rejected,
            itemRejectionReason:
                'Trader chose not to proceed with remaining products.',
            rejectionBy: RejectionBy.trader,
          );
        }
      }
    }
    final status = needsConfirmation
        ? RequirementStatus.pending
        : _overallStatus(items);

    await _ref.doc(requirement.id).update({
      'items': items.map((i) => i.toFirestore()).toList(),
      'status': status.name,
      'requiresAdminConfirmation': needsConfirmation,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });
    await _notifyAdmin(
      requirement.copyWith(items: items, status: status),
      title: proceedWithRemaining
          ? '⚠️ Partial Requirement Confirmation Needed'
          : '❌ Trader Rejected Counter Offer',
      message: proceedWithRemaining
          ? '${item.productName} was rejected by trader. Review the remaining approved products.'
          : '${item.productName} was rejected by trader: $reason',
    );
  }

  Future<void> confirmPartialRequirement(RequirementModel requirement) async {
    await _ref.doc(requirement.id).update({
      'status': RequirementStatus.approved.name,
      'requiresAdminConfirmation': false,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });
    await _notifyTrader(
      traderId: requirement.traderId,
      title: '✅ Remaining Products Approved',
      message: 'Admin approved the remaining products in your requirement.',
      type: NotificationType.requirementApproved,
      referenceId: requirement.id,
    );
  }

  // ═══════════════════════════════════════
  // GET PENDING COUNT (Admin Dashboard)
  // ═══════════════════════════════════════
  Stream<int> watchPendingCount() {
    return _ref
        .where('status', isEqualTo: RequirementStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

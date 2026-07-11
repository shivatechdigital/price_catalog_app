import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';
import 'package:price_catalog_app/data/models/notification_model.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';

class RequirementRepository {
  final _ref = FirebaseService.requirementsRef;

  // ═══════════════════════════════════════
  // SUBMIT NEW REQUIREMENT (Trader)
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
    final docRef = _ref.doc();

    final requirement = RequirementModel(
      id: docRef.id,
      traderId: traderId,
      traderName: traderName,
      traderBusinessName: traderBusinessName,
      traderPhone: traderPhone,
      productId: productId,
      productName: productName,
      productCode: productCode,
      productImage: productImage,
      categoryName: categoryName,
      customerName: customerName,
      customerPhone: customerPhone,
      customerBusinessName: customerBusinessName,
      customerCity: customerCity,
      customerAddress: customerAddress,
      quantity: quantity,
      unit: unit,
      productCurrentPrice: productCurrentPrice,
      customerDemandedPrice: customerDemandedPrice,
      traderOfferedPrice: traderOfferedPrice,
      paymentType: paymentType,
      creditDays: creditDays,
      advanceAmount: advanceAmount,
      deliveryDate: deliveryDate,
      deliveryLocation: deliveryLocation,
      traderNote: traderNote,
      status: RequirementStatus.pending,
      submittedAt: DateTime.now(),
    );

    await docRef.set(requirement.toFirestore());

    // Notify admin
    await _notifyAdmin(requirement);

    return requirement;
  }

  // ═══════════════════════════════════════
  // NOTIFY ADMIN - New requirement
  // ═══════════════════════════════════════
  Future<void> _notifyAdmin(RequirementModel requirement) async {
    try {
      final adminQuery = await FirebaseService.usersRef
          .where('role', isEqualTo: 'admin')
          .get();

      for (final adminDoc in adminQuery.docs) {
        final notification = NotificationModel(
          id: '',
          title: '🔔 New Requirement!',
          message:
              '${requirement.traderName} submitted requirement for '
              '${requirement.productName} at '
              '₹${requirement.customerDemandedPrice.toStringAsFixed(0)}',
          type: NotificationType.newRequirement,
          referenceId: requirement.id,
          read: false,
          createdAt: DateTime.now(),
        );

        await FirebaseService.notificationsRef(adminDoc.id)
            .add(notification.toFirestore());
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

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => RequirementModel.fromFirestore(doc))
        .toList());
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
  Future<void> acceptCounterOffer({
    required String requirementId,
  }) async {
    await _ref.doc(requirementId).update({
      'status': RequirementStatus.approved.name,
      'actionTakenAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════
  // REJECT COUNTER OFFER (Trader)
  // ═══════════════════════════════════════
  Future<void> rejectCounterOffer({
    required String requirementId,
  }) async {
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

      await FirebaseService.notificationsRef(traderId)
          .add(notification.toFirestore());
    } catch (_) {}
  }

  // ═══════════════════════════════════════
  // GET REQUIREMENT BY ID
  // ═══════════════════════════════════════
  Future<RequirementModel?> getRequirementById(
      String requirementId) async {
    final doc = await _ref.doc(requirementId).get();
    if (!doc.exists) return null;
    return RequirementModel.fromFirestore(doc);
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
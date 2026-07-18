import 'package:cloud_firestore/cloud_firestore.dart';

enum RequirementStatus { pending, approved, rejected, counterOffer }

enum PaymentType { fullCash, partialPayment, credit }

enum CounterOfferBy { admin, trader }

enum RejectionBy { admin, trader }

// Single product line item within a requirement
class RequirementItemModel {
  final String productId;
  final String productName;
  final String productCode;
  final String? productImage;
  final String? categoryName;
  final double quantity;
  final String unit;
  final double productCurrentPrice;
  final double customerDemandedPrice;
  final double traderOfferedPrice;
  final String? traderPhone;
  final String? deliveryLocation;
  final String? traderNote;

  // NEW: Per-item status for multi-product approvals
  final RequirementStatus itemStatus;
  final double? itemCounterPrice;
  final String? itemRejectionReason;
  final String? itemAdminNote;
  final String? itemTraderResponseNote;
  final CounterOfferBy? counterOfferBy;
  final RejectionBy? rejectionBy;

  const RequirementItemModel({
    required this.productId,
    required this.productName,
    required this.productCode,
    this.productImage,
    this.categoryName,
    required this.quantity,
    required this.unit,
    required this.productCurrentPrice,
    required this.customerDemandedPrice,
    required this.traderOfferedPrice,
    this.traderPhone,
    this.deliveryLocation,
    this.traderNote,
    this.itemStatus = RequirementStatus.pending, // Default to pending
    this.itemCounterPrice,
    this.itemRejectionReason,
    this.itemAdminNote,
    this.itemTraderResponseNote,
    this.counterOfferBy,
    this.rejectionBy,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'productCode': productCode,
      'productImage': productImage,
      'categoryName': categoryName,
      'quantity': quantity,
      'unit': unit,
      'productCurrentPrice': productCurrentPrice,
      'customerDemandedPrice': customerDemandedPrice,
      'traderOfferedPrice': traderOfferedPrice,
      'traderPhone': traderPhone,
      'deliveryLocation': deliveryLocation,
      'traderNote': traderNote,
      // NEW: Save item status
      'itemStatus': itemStatus.name,
      'itemCounterPrice': itemCounterPrice,
      'itemRejectionReason': itemRejectionReason,
      'itemAdminNote': itemAdminNote,
      'itemTraderResponseNote': itemTraderResponseNote,
      'counterOfferBy': counterOfferBy?.name,
      'rejectionBy': rejectionBy?.name,
    };
  }

  factory RequirementItemModel.fromFirestore(Map<String, dynamic> data) {
    return RequirementItemModel(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productCode: data['productCode'] ?? '',
      productImage: data['productImage'],
      categoryName: data['categoryName'],
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      productCurrentPrice: (data['productCurrentPrice'] ?? 0).toDouble(),
      customerDemandedPrice: (data['customerDemandedPrice'] ?? 0).toDouble(),
      traderOfferedPrice: (data['traderOfferedPrice'] ?? 0).toDouble(),
      traderPhone: data['traderPhone'],
      deliveryLocation: data['deliveryLocation'],
      traderNote: data['traderNote'],
      // NEW: Parse item status
      itemStatus: RequirementStatus.values.firstWhere(
        (s) => s.name == data['itemStatus'],
        orElse: () => RequirementStatus.pending,
      ),
      itemCounterPrice: data['itemCounterPrice']?.toDouble(),
      itemRejectionReason: data['itemRejectionReason'],
      itemAdminNote: data['itemAdminNote'],
      itemTraderResponseNote: data['itemTraderResponseNote'],
      counterOfferBy: CounterOfferBy.values.firstWhere(
        (by) => by.name == data['counterOfferBy'],
        orElse: () => CounterOfferBy.admin,
      ),
      rejectionBy: data['rejectionBy'] == null
          ? null
          : RejectionBy.values.firstWhere(
              (by) => by.name == data['rejectionBy'],
              orElse: () => RejectionBy.admin,
            ),
    );
  }

  // Helper to check if item is approved
  bool get isApproved => itemStatus == RequirementStatus.approved;
  bool get isRejected => itemStatus == RequirementStatus.rejected;
  bool get isCounterOffer => itemStatus == RequirementStatus.counterOffer;
  bool get isAwaitingTraderResponse =>
      isCounterOffer && counterOfferBy != CounterOfferBy.trader;
  bool get isAwaitingAdminResponse =>
      isCounterOffer && counterOfferBy == CounterOfferBy.trader;
  double get finalPrice => itemCounterPrice ?? customerDemandedPrice;

  RequirementItemModel copyWith({
    String? productId,
    String? productName,
    String? productCode,
    String? productImage,
    String? categoryName,
    double? quantity,
    String? unit,
    double? productCurrentPrice,
    double? customerDemandedPrice,
    double? traderOfferedPrice,
    String? traderPhone,
    String? deliveryLocation,
    String? traderNote,
    RequirementStatus? itemStatus,
    double? itemCounterPrice,
    String? itemRejectionReason,
    String? itemAdminNote,
    String? itemTraderResponseNote,
    CounterOfferBy? counterOfferBy,
    RejectionBy? rejectionBy,
  }) {
    return RequirementItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      productImage: productImage ?? this.productImage,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      productCurrentPrice: productCurrentPrice ?? this.productCurrentPrice,
      customerDemandedPrice:
          customerDemandedPrice ?? this.customerDemandedPrice,
      traderOfferedPrice: traderOfferedPrice ?? this.traderOfferedPrice,
      traderPhone: traderPhone ?? this.traderPhone,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      traderNote: traderNote ?? this.traderNote,
      itemStatus: itemStatus ?? this.itemStatus,
      itemCounterPrice: itemCounterPrice ?? this.itemCounterPrice,
      itemRejectionReason: itemRejectionReason ?? this.itemRejectionReason,
      itemAdminNote: itemAdminNote ?? this.itemAdminNote,
      itemTraderResponseNote:
          itemTraderResponseNote ?? this.itemTraderResponseNote,
      counterOfferBy: counterOfferBy ?? this.counterOfferBy,
      rejectionBy: rejectionBy ?? this.rejectionBy,
    );
  }
}

class RequirementModel {
  final String id;
  final String traderId;
  final String traderName;
  final String traderBusinessName;
  final List<RequirementItemModel> items; // Multiple products
  final String? traderPhone;
  final String? categoryName;
  final String? customerAddress;
  final double? advanceAmount;

  // Customer Details (shared across all items)
  final String customerName;
  final String customerPhone;
  final String customerBusinessName;
  final String customerCity;

  // Payment (shared across all items)
  final PaymentType paymentType;
  final int? creditDays;

  // Delivery (shared across all items)
  final DateTime? deliveryDate;
  final String? deliveryLocation;

  // Note (for entire requirement)
  final String? traderNote;
  final String? adminNote;

  // Status
  final RequirementStatus status;
  final double? counterPrice;
  final String? rejectionReason;
  final bool requiresAdminConfirmation;

  // Timestamps
  final DateTime submittedAt;
  final DateTime? actionTakenAt;

  const RequirementModel({
    required this.id,
    required this.traderId,
    required this.traderName,
    required this.traderBusinessName,
    required this.items,
    this.traderPhone,
    this.categoryName,
    this.customerAddress,
    this.advanceAmount,
    required this.customerName,
    required this.customerPhone,
    required this.customerBusinessName,
    required this.customerCity,
    required this.paymentType,
    this.creditDays,
    this.deliveryDate,
    this.deliveryLocation,
    this.traderNote,
    this.adminNote,
    required this.status,
    this.counterPrice,
    this.rejectionReason,
    this.requiresAdminConfirmation = false,
    required this.submittedAt,
    this.actionTakenAt,
  });

  bool get isPending => status == RequirementStatus.pending;
  bool get isApproved => status == RequirementStatus.approved;
  bool get isRejected => status == RequirementStatus.rejected;
  bool get isCounterOffer => status == RequirementStatus.counterOffer;
  bool get hasTraderActions =>
      items.any((item) => item.isAwaitingTraderResponse);
  bool get awaitingAdminResponse =>
      requiresAdminConfirmation ||
      items.any((item) => item.isAwaitingAdminResponse);

  // The price the deal is actually settled at. When the admin has sent a
  // counter offer, that counter price is the negotiated/agreed price (it
  // stays set after the trader accepts and status becomes approved).
  // Otherwise the customer's demanded price stands.
  double get agreedPrice =>
      counterPrice ?? items.firstOrNull?.customerDemandedPrice ?? 0;

  // Total value across all items
  double get totalValue => items.fold<double>(
    0,
    (previousSum, item) => previousSum + item.quantity * item.finalPrice,
  );

  // Legacy getters for backward compatibility (single item)
  String get productId => items.isNotEmpty ? items.first.productId : '';
  String get productName => items.isNotEmpty ? items.first.productName : '';
  String get productCode => items.isNotEmpty ? items.first.productCode : '';
  String? get productImage =>
      items.isNotEmpty ? items.first.productImage : null;
  double get quantity => items.isNotEmpty ? items.first.quantity : 0;
  String get unit => items.isNotEmpty ? items.first.unit : '';
  double get productCurrentPrice =>
      items.isNotEmpty ? items.first.productCurrentPrice : 0;
  double get customerDemandedPrice =>
      items.isNotEmpty ? items.first.customerDemandedPrice : 0;
  double get traderOfferedPrice =>
      items.isNotEmpty ? items.first.traderOfferedPrice : 0;

  factory RequirementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsData = data['items'] as List<dynamic>?;

    final items = itemsData != null
        ? itemsData
              .map(
                (item) => RequirementItemModel.fromFirestore(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
        : <RequirementItemModel>[];

    return RequirementModel(
      id: doc.id,
      traderId: data['traderId'] ?? '',
      traderName: data['traderName'] ?? '',
      traderBusinessName: data['traderBusinessName'] ?? '',
      items: items,
      traderPhone: data['traderPhone'],
      categoryName: data['categoryName'],
      customerAddress: data['customerAddress'],
      advanceAmount: data['advanceAmount']?.toDouble(),
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerBusinessName: data['customerBusinessName'] ?? '',
      customerCity: data['customerCity'] ?? '',
      paymentType: PaymentType.values.firstWhere(
        (p) => p.name == data['paymentType'],
        orElse: () => PaymentType.fullCash,
      ),
      creditDays: data['creditDays'],
      deliveryDate: data['deliveryDate'] != null
          ? (data['deliveryDate'] as Timestamp).toDate()
          : null,
      deliveryLocation: data['deliveryLocation'],
      traderNote: data['traderNote'],
      adminNote: data['adminNote'],
      status: RequirementStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => RequirementStatus.pending,
      ),
      counterPrice: data['counterPrice']?.toDouble(),
      rejectionReason: data['rejectionReason'],
      requiresAdminConfirmation:
          data['requiresAdminConfirmation'] as bool? ?? false,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      actionTakenAt: data['actionTakenAt'] != null
          ? (data['actionTakenAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'traderId': traderId,
      'traderName': traderName,
      'traderBusinessName': traderBusinessName,
      'items': items.map((item) => item.toFirestore()).toList(),
      'traderPhone': traderPhone,
      'categoryName': categoryName,
      'customerAddress': customerAddress,
      'advanceAmount': advanceAmount,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerBusinessName': customerBusinessName,
      'customerCity': customerCity,
      'paymentType': paymentType.name,
      'creditDays': creditDays,
      'deliveryDate': deliveryDate != null
          ? Timestamp.fromDate(deliveryDate!)
          : null,
      'deliveryLocation': deliveryLocation,
      'traderNote': traderNote,
      'adminNote': adminNote,
      'status': status.name,
      'counterPrice': counterPrice,
      'rejectionReason': rejectionReason,
      'requiresAdminConfirmation': requiresAdminConfirmation,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'actionTakenAt': actionTakenAt != null
          ? Timestamp.fromDate(actionTakenAt!)
          : null,
    };
  }

  RequirementModel copyWith({
    RequirementStatus? status,
    String? adminNote,
    double? counterPrice,
    String? rejectionReason,
    DateTime? actionTakenAt,
    String? traderPhone,
    String? categoryName,
    String? customerAddress,
    double? advanceAmount,
    List<RequirementItemModel>? items,
    bool? requiresAdminConfirmation,
  }) {
    return RequirementModel(
      id: id,
      traderId: traderId,
      traderName: traderName,
      traderBusinessName: traderBusinessName,
      items: items ?? this.items,
      traderPhone: traderPhone ?? this.traderPhone,
      categoryName: categoryName ?? this.categoryName,
      customerAddress: customerAddress ?? this.customerAddress,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      customerName: customerName,
      customerPhone: customerPhone,
      customerBusinessName: customerBusinessName,
      customerCity: customerCity,
      paymentType: paymentType,
      creditDays: creditDays,
      deliveryDate: deliveryDate,
      deliveryLocation: deliveryLocation,
      traderNote: traderNote,
      adminNote: adminNote ?? this.adminNote,
      status: status ?? this.status,
      counterPrice: counterPrice ?? this.counterPrice,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requiresAdminConfirmation:
          requiresAdminConfirmation ?? this.requiresAdminConfirmation,
      submittedAt: submittedAt,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
    );
  }
}

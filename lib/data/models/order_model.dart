import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:uuid/uuid.dart';

// ═══════════════════════════════════════
// ORDER STATUS
// ═══════════════════════════════════════
enum OrderStatus {
  pending,      // All items pending
  approved,     // All items approved
  rejected,     // All items rejected
  partial,      // Mix of approved/rejected/counter
  counterOffer, // Has counter offers pending
}

// ═══════════════════════════════════════
// ORDER ITEM STATUS (Per Product)
// ═══════════════════════════════════════
enum OrderItemStatus {
  pending,
  approved,
  rejected,
  counterOffer,
}

// ═══════════════════════════════════════
// ORDER ITEM MODEL (Each product in order)
// ═══════════════════════════════════════
class OrderItemModel {
  final String itemId;
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
  final OrderItemStatus status;
  final double? counterPrice;
  final double? finalPrice;
  final String? rejectionReason;
  final String? adminNote;
  final DateTime? actionTakenAt;

  const OrderItemModel({
    required this.itemId,
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
    required this.status,
    this.counterPrice,
    this.finalPrice,
    this.rejectionReason,
    this.adminNote,
    this.actionTakenAt,
  });

  // Helpers
  bool get isPending => status == OrderItemStatus.pending;
  bool get isApproved => status == OrderItemStatus.approved;
  bool get isRejected => status == OrderItemStatus.rejected;
  bool get isCounterOffer => status == OrderItemStatus.counterOffer;

  double get itemTotal => quantity * customerDemandedPrice;
  double get approvedTotal => quantity * (finalPrice ?? customerDemandedPrice);

  // From Map
  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      itemId: map['itemId'] ?? const Uuid().v4(),
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productCode: map['productCode'] ?? '',
      productImage: map['productImage'],
      categoryName: map['categoryName'],
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      productCurrentPrice: (map['productCurrentPrice'] ?? 0).toDouble(),
      customerDemandedPrice: (map['customerDemandedPrice'] ?? 0).toDouble(),
      traderOfferedPrice: (map['traderOfferedPrice'] ?? 0).toDouble(),
      status: OrderItemStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => OrderItemStatus.pending,
      ),
      counterPrice: map['counterPrice']?.toDouble(),
      finalPrice: map['finalPrice']?.toDouble(),
      rejectionReason: map['rejectionReason'],
      adminNote: map['adminNote'],
      actionTakenAt: map['actionTakenAt'] != null
          ? (map['actionTakenAt'] as Timestamp).toDate()
          : null,
    );
  }

  // To Map
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
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
      'status': status.name,
      'counterPrice': counterPrice,
      'finalPrice': finalPrice,
      'rejectionReason': rejectionReason,
      'adminNote': adminNote,
      'actionTakenAt': actionTakenAt != null
          ? Timestamp.fromDate(actionTakenAt!)
          : null,
    };
  }

  // Copy With
  OrderItemModel copyWith({
    OrderItemStatus? status,
    double? counterPrice,
    double? finalPrice,
    String? rejectionReason,
    String? adminNote,
    DateTime? actionTakenAt,
  }) {
    return OrderItemModel(
      itemId: itemId,
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
      status: status ?? this.status,
      counterPrice: counterPrice ?? this.counterPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNote: adminNote ?? this.adminNote,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
    );
  }
}

// ═══════════════════════════════════════
// ORDER MODEL (Parent - Multiple Items)
// ═══════════════════════════════════════
class OrderModel {
  final String id;
  final String traderId;
  final String traderName;
  final String traderBusinessName;
  final String traderPhone;

  // Customer Details
  final String customerName;
  final String customerPhone;
  final String customerBusinessName;
  final String customerCity;
  final String? customerAddress;

  // Payment & Delivery
  final PaymentType paymentType;
  final int? creditDays;
  final double? advanceAmount;
  final DateTime? deliveryDate;
  final String? deliveryLocation;
  final String? traderNote;
  final String? adminNote;

  // Items
  final List<OrderItemModel> items;

  // Counts (denormalized for queries)
  final int totalItems;
  final int approvedCount;
  final int rejectedCount;
  final int counterCount;
  final int pendingCount;

  // Status
  final OrderStatus orderStatus;

  // Values
  final double totalOrderValue;
  final double approvedOrderValue;

  // Timestamps
  final DateTime submittedAt;
  final DateTime? lastActionAt;

  const OrderModel({
    required this.id,
    required this.traderId,
    required this.traderName,
    required this.traderBusinessName,
    required this.traderPhone,
    required this.customerName,
    required this.customerPhone,
    required this.customerBusinessName,
    required this.customerCity,
    this.customerAddress,
    required this.paymentType,
    this.creditDays,
    this.advanceAmount,
    this.deliveryDate,
    this.deliveryLocation,
    this.traderNote,
    this.adminNote,
    required this.items,
    required this.totalItems,
    required this.approvedCount,
    required this.rejectedCount,
    required this.counterCount,
    required this.pendingCount,
    required this.orderStatus,
    required this.totalOrderValue,
    required this.approvedOrderValue,
    required this.submittedAt,
    this.lastActionAt,
  });

  // ═══════════════════════════════════════
  // COMPUTED HELPERS
  // ═══════════════════════════════════════
  bool get isAllPending => pendingCount == totalItems;
  bool get isAllApproved => approvedCount == totalItems;
  bool get isAllRejected => rejectedCount == totalItems;
  bool get hasCounterOffers => counterCount > 0;
  bool get isMixed =>
      approvedCount > 0 && (rejectedCount > 0 || counterCount > 0);

  List<OrderItemModel> get pendingItems =>
      items.where((i) => i.isPending).toList();
  List<OrderItemModel> get approvedItems =>
      items.where((i) => i.isApproved).toList();
  List<OrderItemModel> get rejectedItems =>
      items.where((i) => i.isRejected).toList();
  List<OrderItemModel> get counterItems =>
      items.where((i) => i.isCounterOffer).toList();

  String get statusLabel {
    return switch (orderStatus) {
      OrderStatus.pending => 'Pending',
      OrderStatus.approved => 'All Approved',
      OrderStatus.rejected => 'All Rejected',
      OrderStatus.partial => 'Partially Approved',
      OrderStatus.counterOffer => 'Has Counter Offers',
    };
  }

  // ═══════════════════════════════════════
  // CALCULATE STATUS FROM ITEMS
  // ═══════════════════════════════════════
  static OrderStatus calculateStatus(List<OrderItemModel> items) {
    final approved = items.where((i) => i.isApproved).length;
    final rejected = items.where((i) => i.isRejected).length;
    final counter = items.where((i) => i.isCounterOffer).length;
    final pending = items.where((i) => i.isPending).length;
    final total = items.length;

    if (pending == total) return OrderStatus.pending;
    if (approved == total) return OrderStatus.approved;
    if (rejected == total) return OrderStatus.rejected;
    if (counter > 0) return OrderStatus.counterOffer;
    return OrderStatus.partial;
  }

  // ═══════════════════════════════════════
  // FROM FIRESTORE
  // ═══════════════════════════════════════
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: doc.id,
      traderId: data['traderId'] ?? '',
      traderName: data['traderName'] ?? '',
      traderBusinessName: data['traderBusinessName'] ?? '',
      traderPhone: data['traderPhone']?.toString() ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone']?.toString() ?? '',
      customerBusinessName: data['customerBusinessName'] ?? '',
      customerCity: data['customerCity'] ?? '',
      customerAddress: data['customerAddress'],
      paymentType: PaymentType.values.firstWhere(
        (p) => p.name == data['paymentType'],
        orElse: () => PaymentType.fullCash,
      ),
      creditDays: data['creditDays'],
      advanceAmount: data['advanceAmount']?.toDouble(),
      deliveryDate: data['deliveryDate'] != null
          ? (data['deliveryDate'] as Timestamp).toDate()
          : null,
      deliveryLocation: data['deliveryLocation'],
      traderNote: data['traderNote'],
      adminNote: data['adminNote'],
      items: itemsList,
      totalItems: data['totalItems'] ?? itemsList.length,
      approvedCount: data['approvedCount'] ?? 0,
      rejectedCount: data['rejectedCount'] ?? 0,
      counterCount: data['counterCount'] ?? 0,
      pendingCount: data['pendingCount'] ?? itemsList.length,
      orderStatus: OrderStatus.values.firstWhere(
        (s) => s.name == data['orderStatus'],
        orElse: () => OrderStatus.pending,
      ),
      totalOrderValue: (data['totalOrderValue'] ?? 0).toDouble(),
      approvedOrderValue: (data['approvedOrderValue'] ?? 0).toDouble(),
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActionAt: data['lastActionAt'] != null
          ? (data['lastActionAt'] as Timestamp).toDate()
          : null,
    );
  }

  // ═══════════════════════════════════════
  // TO FIRESTORE
  // ═══════════════════════════════════════
  Map<String, dynamic> toFirestore() {
    return {
      'traderId': traderId,
      'traderName': traderName,
      'traderBusinessName': traderBusinessName,
      'traderPhone': traderPhone,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerBusinessName': customerBusinessName,
      'customerCity': customerCity,
      'customerAddress': customerAddress,
      'paymentType': paymentType.name,
      'creditDays': creditDays,
      'advanceAmount': advanceAmount,
      'deliveryDate':
          deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'deliveryLocation': deliveryLocation,
      'traderNote': traderNote,
      'adminNote': adminNote,
      'items': items.map((i) => i.toMap()).toList(),
      'totalItems': totalItems,
      'approvedCount': approvedCount,
      'rejectedCount': rejectedCount,
      'counterCount': counterCount,
      'pendingCount': pendingCount,
      'orderStatus': orderStatus.name,
      'totalOrderValue': totalOrderValue,
      'approvedOrderValue': approvedOrderValue,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'lastActionAt':
          lastActionAt != null ? Timestamp.fromDate(lastActionAt!) : null,
    };
  }
}
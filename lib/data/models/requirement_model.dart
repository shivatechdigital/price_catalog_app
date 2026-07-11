import 'package:cloud_firestore/cloud_firestore.dart';

enum RequirementStatus { pending, approved, rejected, counterOffer }
enum PaymentType { fullCash, partialPayment, credit }

class RequirementModel {
  final String id;
  final String traderId;
  final String traderName;
  final String traderBusinessName;
  final String productId;
  final String productName;
  final String productCode;
  final String? productImage;
  final String? traderPhone;
  final String? categoryName;
  final String? customerAddress;
  final double? advanceAmount;

  // Customer Details
  final String customerName;
  final String customerPhone;
  final String customerBusinessName;
  final String customerCity;

  // Quantity
  final double quantity;
  final String unit;

  // Price Details
  final double productCurrentPrice;
  final double customerDemandedPrice;
  final double traderOfferedPrice;

  // Payment
  final PaymentType paymentType;
  final int? creditDays;

  // Delivery
  final DateTime? deliveryDate;
  final String? deliveryLocation;

  // Notes
  final String? traderNote;
  final String? adminNote;

  // Status
  final RequirementStatus status;
  final double? counterPrice;
  final String? rejectionReason;

  // Timestamps
  final DateTime submittedAt;
  final DateTime? actionTakenAt;

  const RequirementModel({
    required this.id,
    required this.traderId,
    required this.traderName,
    required this.traderBusinessName,
    required this.productId,
    required this.productName,
    required this.productCode,
    this.productImage,
    this.traderPhone,
    this.categoryName,
    this.customerAddress,
    this.advanceAmount,
    required this.customerName,
    required this.customerPhone,
    required this.customerBusinessName,
    required this.customerCity,
    required this.quantity,
    required this.unit,
    required this.productCurrentPrice,
    required this.customerDemandedPrice,
    required this.traderOfferedPrice,
    required this.paymentType,
    this.creditDays,
    this.deliveryDate,
    this.deliveryLocation,
    this.traderNote,
    this.adminNote,
    required this.status,
    this.counterPrice,
    this.rejectionReason,
    required this.submittedAt,
    this.actionTakenAt,
  });

  bool get isPending => status == RequirementStatus.pending;
  bool get isApproved => status == RequirementStatus.approved;
  bool get isRejected => status == RequirementStatus.rejected;
  bool get isCounterOffer => status == RequirementStatus.counterOffer;

  // The price the deal is actually settled at. When the admin has sent a
  // counter offer, that counter price is the negotiated/agreed price (it
  // stays set after the trader accepts and status becomes approved).
  // Otherwise the customer's demanded price stands.
  double get agreedPrice => counterPrice ?? customerDemandedPrice;

  double get totalValue => quantity * agreedPrice;

  factory RequirementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequirementModel(
      id: doc.id,
      traderId: data['traderId'] ?? '',
      traderName: data['traderName'] ?? '',
      traderBusinessName: data['traderBusinessName'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productCode: data['productCode'] ?? '',
      productImage: data['productImage'],
      traderPhone: data['traderPhone'],
      categoryName: data['categoryName'],
      customerAddress: data['customerDetails']?['address'],
      advanceAmount: data['paymentDetails']?['advanceAmount']?.toDouble(),
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerBusinessName: data['customerBusinessName'] ?? '',
      customerCity: data['customerCity'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      productCurrentPrice: (data['productCurrentPrice'] ?? 0).toDouble(),
      customerDemandedPrice: (data['customerDemandedPrice'] ?? 0).toDouble(),
      traderOfferedPrice: (data['traderOfferedPrice'] ?? 0).toDouble(),
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
      'productId': productId,
      'productName': productName,
      'productCode': productCode,
      'productImage': productImage,
      'traderPhone': traderPhone,
      'categoryName': categoryName,
      'customerAddress': customerAddress,
      'advanceAmount': advanceAmount,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerBusinessName': customerBusinessName,
      'customerCity': customerCity,
      'quantity': quantity,
      'unit': unit,
      'productCurrentPrice': productCurrentPrice,
      'customerDemandedPrice': customerDemandedPrice,
      'traderOfferedPrice': traderOfferedPrice,
      'paymentType': paymentType.name,
      'creditDays': creditDays,
      'deliveryDate':
          deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'deliveryLocation': deliveryLocation,
      'traderNote': traderNote,
      'adminNote': adminNote,
      'status': status.name,
      'counterPrice': counterPrice,
      'rejectionReason': rejectionReason,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'actionTakenAt':
          actionTakenAt != null ? Timestamp.fromDate(actionTakenAt!) : null,
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
  }) {
    return RequirementModel(
      id: id,
      traderId: traderId,
      traderName: traderName,
      traderBusinessName: traderBusinessName,
      productId: productId,
      productName: productName,
      productCode: productCode,
      productImage: productImage,
      traderPhone: traderPhone ?? this.traderPhone,
      categoryName: categoryName ?? this.categoryName,
      customerAddress: customerAddress ?? this.customerAddress,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      customerName: customerName,
      customerPhone: customerPhone,
      customerBusinessName: customerBusinessName,
      customerCity: customerCity,
      quantity: quantity,
      unit: unit,
      productCurrentPrice: productCurrentPrice,
      customerDemandedPrice: customerDemandedPrice,
      traderOfferedPrice: traderOfferedPrice,
      paymentType: paymentType,
      creditDays: creditDays,
      deliveryDate: deliveryDate,
      deliveryLocation: deliveryLocation,
      traderNote: traderNote,
      adminNote: adminNote ?? this.adminNote,
      status: status ?? this.status,
      counterPrice: counterPrice ?? this.counterPrice,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
    );
  }
}
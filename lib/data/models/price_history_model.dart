import 'package:cloud_firestore/cloud_firestore.dart';

class PriceHistoryModel {
  final String id;
  final String productId;
  final String productName;
  final double oldPurchasePrice;
  final double oldSellingPrice;
  final double oldDealerPrice;
  final double newPurchasePrice;
  final double newSellingPrice;
  final double newDealerPrice;
  final String? changeReason;
  final String changedBy;
  final String changedByName;
  final DateTime changedAt;

  const PriceHistoryModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.oldPurchasePrice,
    required this.oldSellingPrice,
    required this.oldDealerPrice,
    required this.newPurchasePrice,
    required this.newSellingPrice,
    required this.newDealerPrice,
    this.changeReason,
    required this.changedBy,
    required this.changedByName,
    required this.changedAt,
  });

  // Price difference helpers
  double get sellingPriceDiff => newSellingPrice - oldSellingPrice;
  bool get isPriceIncreased => sellingPriceDiff > 0;
  bool get isPriceDecreased => sellingPriceDiff < 0;

  factory PriceHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceHistoryModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      oldPurchasePrice: (data['oldPurchasePrice'] ?? 0).toDouble(),
      oldSellingPrice: (data['oldSellingPrice'] ?? 0).toDouble(),
      oldDealerPrice: (data['oldDealerPrice'] ?? 0).toDouble(),
      newPurchasePrice: (data['newPurchasePrice'] ?? 0).toDouble(),
      newSellingPrice: (data['newSellingPrice'] ?? 0).toDouble(),
      newDealerPrice: (data['newDealerPrice'] ?? 0).toDouble(),
      changeReason: data['changeReason'],
      changedBy: data['changedBy'] ?? '',
      changedByName: data['changedByName'] ?? '',
      changedAt: (data['changedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'oldPurchasePrice': oldPurchasePrice,
      'oldSellingPrice': oldSellingPrice,
      'oldDealerPrice': oldDealerPrice,
      'newPurchasePrice': newPurchasePrice,
      'newSellingPrice': newSellingPrice,
      'newDealerPrice': newDealerPrice,
      'changeReason': changeReason,
      'changedBy': changedBy,
      'changedByName': changedByName,
      'changedAt': Timestamp.fromDate(changedAt),
    };
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductAvailability { inStock, outOfStock, limitedStock }

class ProductModel {
  final String id;
  final String name;
  final String productCode;
  final String categoryId;
  final String categoryName;
  final String brand;
  final String description;
  final String unit;
  final List<String> images;
  final ProductAvailability availability;
  final PriceModel currentPrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? subCategoryId;
  final String? subCategoryName;
  final int viewCount;
  final Map<String, String> specifications;
  final List<String> tags;

  const ProductModel({
    required this.id,
    required this.name,
    required this.productCode,
    required this.categoryId,
    required this.categoryName,
    required this.brand,
    required this.description,
    required this.unit,
    required this.images,
    this.subCategoryId,
    this.subCategoryName,
    this.viewCount = 0,
    this.specifications = const {},
    this.tags = const [],
    required this.availability,
    required this.currentPrice,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  String get primaryImage => images.isNotEmpty ? images.first : '';

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      productCode: data['productCode'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      brand: data['brand'] ?? '',
      description: data['description'] ?? '',
      unit: data['unit'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      availability: ProductAvailability.values.firstWhere(
        (a) => a.name == data['availability'],
        orElse: () => ProductAvailability.inStock,
      ),
      currentPrice: PriceModel.fromMap(data['currentPrice'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] is DateTime
              ? data['createdAt'] as DateTime
              : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : data['updatedAt'] is DateTime
              ? data['updatedAt'] as DateTime
              : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      subCategoryId: data['subCategoryId'],
      subCategoryName: data['subCategoryName'],
      viewCount: data['viewCount'] ?? 0,
      specifications: Map<String, String>.from(data['specifications'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'productCode': productCode,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'brand': brand,
      'description': description,
      'unit': unit,
      'images': images,
      'availability': availability.name,
      'currentPrice': currentPrice.toMap(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'subCategoryId': subCategoryId,
      'subCategoryName': subCategoryName,
      'viewCount': viewCount,
      'specifications': specifications,
      'tags': tags,
    };
  }
}

class PriceModel {
  final double purchasePrice;
  final double sellingPrice;
  final double dealerPrice;
  final double? discountPrice;
  final double? minAcceptedPrice;
  final DateTime updatedAt;
  final String updatedBy;

  const PriceModel({
    required this.purchasePrice,
    required this.sellingPrice,
    required this.dealerPrice,
    this.discountPrice,
    this.minAcceptedPrice,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory PriceModel.fromMap(Map<String, dynamic> map) {
    return PriceModel(
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      dealerPrice: (map['dealerPrice'] ?? 0).toDouble(),
      discountPrice: map['discountPrice']?.toDouble(),
      minAcceptedPrice: map['minAcceptedPrice']?.toDouble(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : map['updatedAt'] is DateTime
              ? map['updatedAt'] as DateTime
              : DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'dealerPrice': dealerPrice,
      'discountPrice': discountPrice,
      'minAcceptedPrice': minAcceptedPrice,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }
}
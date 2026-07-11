import 'package:cloud_firestore/cloud_firestore.dart';

class SubCategoryModel {
  final String id;
  final String name;
  final String icon;

  const SubCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory SubCategoryModel.fromMap(Map<String, dynamic> map) {
    return SubCategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '📦',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String? imageUrl;
  final int productCount;
  final bool isActive;
  final int sortOrder;
  final List<SubCategoryModel> subCategories;
  final DateTime createdAt;
  final String createdBy;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.imageUrl,
    required this.productCount,
    required this.isActive,
    required this.sortOrder,
    required this.subCategories,
    required this.createdAt,
    required this.createdBy,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '📦',
      imageUrl: data['imageUrl'],
      productCount: data['productCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
      subCategories: data['subCategories'] is List<dynamic>
          ? (data['subCategories'] as List<dynamic>)
              .map((e) => SubCategoryModel.fromMap(
                  e as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] is DateTime
              ? data['createdAt'] as DateTime
              : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'imageUrl': imageUrl,
      'productCount': productCount,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'subCategories': subCategories.map((s) => s.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  CategoryModel copyWith({
    String? name,
    String? description,
    String? icon,
    String? imageUrl,
    int? productCount,
    bool? isActive,
    int? sortOrder,
    List<SubCategoryModel>? subCategories,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      productCount: productCount ?? this.productCount,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      subCategories: subCategories ?? this.subCategories,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
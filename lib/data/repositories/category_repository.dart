import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';
import 'package:price_catalog_app/data/models/category_model.dart';

class CategoryRepository {
  final _ref = FirebaseService.categoriesRef;

  // ═══════════════════════════════════════
  // GET ALL CATEGORIES - Stream
  // ═══════════════════════════════════════
  Stream<List<CategoryModel>> watchCategories() {
    // Sort in Dart to avoid a `where(isActive) + orderBy(sortOrder)`
    // composite index requirement.
    return _ref
        .where('isActive', isEqualTo: true)
        .snapshots()
        .handleError((e, st) {
          debugPrint('Firestore stream error: $e');
        })
        .map((snapshot) {
      final categories = snapshot.docs
          .map((doc) {
            try {
              return CategoryModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Category parse error for ${doc.id}: $e');
              return null;
            }
          })
          .whereType<CategoryModel>()
          .toList();
      categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return categories;
    });
  }

  // ═══════════════════════════════════════
  // GET ALL CATEGORIES - Future (including inactive)
  // ═══════════════════════════════════════
  Future<List<CategoryModel>> getAllCategories() async {
    final snapshot = await _ref.orderBy('sortOrder').get();
    return snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc))
        .toList();
  }

  // ═══════════════════════════════════════
  // GET SINGLE CATEGORY
  // ═══════════════════════════════════════
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    final doc = await _ref.doc(categoryId).get();
    if (!doc.exists) return null;
    return CategoryModel.fromFirestore(doc);
  }

  // ═══════════════════════════════════════
  // ADD CATEGORY
  // ═══════════════════════════════════════
  Future<CategoryModel> addCategory({
    required String name,
    required String description,
    required String icon,
    String? imageUrl,
    required int sortOrder,
    required String createdBy,
    List<SubCategoryModel>? subCategories,
  }) async {
    final docRef = _ref.doc();

    final category = CategoryModel(
      id: docRef.id,
      name: name.trim(),
      description: description.trim(),
      icon: icon,
      imageUrl: imageUrl,
      productCount: 0,
      isActive: true,
      sortOrder: sortOrder,
      subCategories: subCategories ?? [],
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );

    await docRef.set(category.toFirestore());
    return category;
  }

  // ═══════════════════════════════════════
  // UPDATE CATEGORY
  // ═══════════════════════════════════════
  Future<void> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    String? icon,
    String? imageUrl,
    bool? isActive,
    int? sortOrder,
    List<SubCategoryModel>? subCategories,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name.trim();
    if (description != null) updates['description'] = description.trim();
    if (icon != null) updates['icon'] = icon;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (isActive != null) updates['isActive'] = isActive;
    if (sortOrder != null) updates['sortOrder'] = sortOrder;
    if (subCategories != null) {
      updates['subCategories'] =
          subCategories.map((s) => s.toMap()).toList();
    }

    await _ref.doc(categoryId).update(updates);
  }

  // ═══════════════════════════════════════
  // DELETE CATEGORY
  // ═══════════════════════════════════════
  Future<void> deleteCategory(String categoryId) async {
    await _ref.doc(categoryId).delete();
  }

  // ═══════════════════════════════════════
  // UPDATE PRODUCT COUNT
  // ═══════════════════════════════════════
  Future<void> incrementProductCount(String categoryId) async {
    await _ref.doc(categoryId).update({
      'productCount': FieldValue.increment(1),
    });
  }

  Future<void> decrementProductCount(String categoryId) async {
    await _ref.doc(categoryId).update({
      'productCount': FieldValue.increment(-1),
    });
  }

  // ═══════════════════════════════════════
  // ADD SUBCATEGORY
  // ═══════════════════════════════════════
  Future<void> addSubCategory({
    required String categoryId,
    required String name,
    required String icon,
  }) async {
    final subCategory = SubCategoryModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      icon: icon,
    );

    await _ref.doc(categoryId).update({
      'subCategories': FieldValue.arrayUnion([subCategory.toMap()]),
    });
  }

  // ═══════════════════════════════════════
  // REMOVE SUBCATEGORY
  // ═══════════════════════════════════════
  Future<void> removeSubCategory({
    required String categoryId,
    required SubCategoryModel subCategory,
  }) async {
    await _ref.doc(categoryId).update({
      'subCategories': FieldValue.arrayRemove([subCategory.toMap()]),
    });
  }
}
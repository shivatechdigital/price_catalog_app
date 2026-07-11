import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';
import 'package:price_catalog_app/data/models/price_history_model.dart';
import 'package:price_catalog_app/data/models/product_model.dart';

class ProductRepository {
  final _productsRef = FirebaseService.productsRef;

  // ═══════════════════════════════════════
  // WATCH ALL PRODUCTS - Stream
  // ═══════════════════════════════════════
  Stream<List<ProductModel>> watchAllProducts() {
    // NOTE: `where(isActive) + orderBy(updatedAt)` needs a Firestore composite
    // index. We filter server-side and sort in Dart to avoid that requirement.
    return _productsRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) {
            try {
              return ProductModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Product parse error for ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ProductModel>()
          .toList();
      products.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return products;
    });
  }

  Stream<List<ProductModel>> watchProductsByCategory(String categoryId) {
    // Sort in Dart (see watchAllProducts) to avoid a composite index.
    return _productsRef
        .where('isActive', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) {
            try {
              return ProductModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Product parse error for ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ProductModel>()
          .toList();
      products.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return products;
    });
  }

  // ═══════════════════════════════════════
  // GET PRODUCT BY ID
  // ═══════════════════════════════════════
  Future<ProductModel?> getProductById(String productId) async {
    final doc = await _productsRef.doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(doc);
  }

  // ═══════════════════════════════════════
  // ADD PRODUCT
  // ═══════════════════════════════════════
  Future<ProductModel> addProduct({
    required String name,
    required String productCode,
    required String categoryId,
    required String categoryName,
    String? subCategoryId,
    String? subCategoryName,
    required String brand,
    required String description,
    required String unit,
    required PriceModel price,
    required String createdBy,
    Map<String, String>? specifications,
    List<String>? tags,
  }) async {
    final docRef = _productsRef.doc();

    final product = ProductModel(
      id: docRef.id,
      name: name.trim(),
      productCode: productCode.trim().toUpperCase(),
      categoryId: categoryId,
      categoryName: categoryName,
      subCategoryId: subCategoryId,
      subCategoryName: subCategoryName,
      brand: brand.trim(),
      description: description.trim(),
      unit: unit,
      images: [],
      availability: ProductAvailability.inStock,
      currentPrice: price,
      isActive: true,
      viewCount: 0,
      specifications: specifications ?? {},
      tags: tags ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );

    await docRef.set(product.toFirestore());
    return product;
  }

  // ═══════════════════════════════════════
  // UPDATE PRODUCT
  // ═══════════════════════════════════════
  Future<void> updateProduct({
    required String productId,
    String? name,
    String? productCode,
    String? categoryId,
    String? categoryName,
    String? subCategoryId,
    String? subCategoryName,
    String? brand,
    String? description,
    String? unit,
    ProductAvailability? availability,
    bool? isActive,
    Map<String, String>? specifications,
    List<String>? tags,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name.trim();
    if (productCode != null) {
      updates['productCode'] = productCode.trim().toUpperCase();
    }
    if (categoryId != null) updates['categoryId'] = categoryId;
    if (categoryName != null) updates['categoryName'] = categoryName;
    if (subCategoryId != null) updates['subCategoryId'] = subCategoryId;
    if (subCategoryName != null) {
      updates['subCategoryName'] = subCategoryName;
    }
    if (brand != null) updates['brand'] = brand.trim();
    if (description != null) updates['description'] = description.trim();
    if (unit != null) updates['unit'] = unit;
    if (availability != null) updates['availability'] = availability.name;
    if (isActive != null) updates['isActive'] = isActive;
    if (specifications != null) updates['specifications'] = specifications;
    if (tags != null) updates['tags'] = tags;

    await _productsRef.doc(productId).update(updates);
  }

  // ═══════════════════════════════════════
  // UPDATE PRICE
  // ═══════════════════════════════════════
  Future<void> updatePrice({
    required String productId,
    required String productName,
    required PriceModel newPrice,
    required PriceModel oldPrice,
    required String updatedBy,
    required String updatedByName,
    String? changeReason,
  }) async {
    final batch = FirebaseService.firestore.batch();

    // Update product current price
    batch.update(_productsRef.doc(productId), {
      'currentPrice': newPrice.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add price history
    final historyRef = FirebaseService.priceHistoryRef(productId).doc();
    final history = PriceHistoryModel(
      id: historyRef.id,
      productId: productId,
      productName: productName,
      oldPurchasePrice: oldPrice.purchasePrice,
      oldSellingPrice: oldPrice.sellingPrice,
      oldDealerPrice: oldPrice.dealerPrice,
      newPurchasePrice: newPrice.purchasePrice,
      newSellingPrice: newPrice.sellingPrice,
      newDealerPrice: newPrice.dealerPrice,
      changeReason: changeReason,
      changedBy: updatedBy,
      changedByName: updatedByName,
      changedAt: DateTime.now(),
    );

    batch.set(historyRef, history.toFirestore());

    await batch.commit();
  }

  // ═══════════════════════════════════════
  // UPLOAD PRODUCT IMAGE
  // ═══════════════════════════════════════
  Future<String> uploadProductImage({
    required String productId,
    required File imageFile,
    required int index,
  }) async {
    // Compress image first
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      '${imageFile.path}_compressed.jpg',
      quality: 75,
      minWidth: 800,
      minHeight: 800,
    );

    final fileToUpload = compressedFile != null
        ? File(compressedFile.path)
        : imageFile;

    final fileName =
        '${productId}_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final storageRef = FirebaseService.productImagesRef(productId, fileName);

    final uploadTask = await storageRef.putFile(
      fileToUpload,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Update product images array
    await _productsRef.doc(productId).update({
      'images': FieldValue.arrayUnion([downloadUrl]),
      'primaryImage': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return downloadUrl;
  }

  // ═══════════════════════════════════════
  // DELETE PRODUCT IMAGE
  // ═══════════════════════════════════════
  Future<void> deleteProductImage({
    required String productId,
    required String imageUrl,
  }) async {
    // Delete from storage
    try {
      final storageRef =
          FirebaseService.storage.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (_) {}

    // Remove from product
    await _productsRef.doc(productId).update({
      'images': FieldValue.arrayRemove([imageUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════
  // DELETE PRODUCT
  // ═══════════════════════════════════════
  Future<void> deleteProduct(String productId) async {
    // Soft delete
    await _productsRef.doc(productId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════
  // INCREMENT VIEW COUNT
  // ═══════════════════════════════════════
  Future<void> incrementViewCount(String productId) async {
    await _productsRef.doc(productId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // ═══════════════════════════════════════
  // SEARCH PRODUCTS
  // ═══════════════════════════════════════
  Future<List<ProductModel>> searchProducts(String query) async {
    final queryLower = query.toLowerCase().trim();

    final snapshot = await _productsRef
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .where((doc) {
          final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
          final name = (data['name'] ?? '').toString().toLowerCase();
          final productCode = (data['productCode'] ?? '').toString().toLowerCase();
          final brand = (data['brand'] ?? '').toString().toLowerCase();
          final tags = List<String>.from(data['tags'] ?? []);

          return name.contains(queryLower) ||
              productCode.contains(queryLower) ||
              brand.contains(queryLower) ||
              tags.any((tag) => tag.toLowerCase().contains(queryLower));
        })
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList();
  }

  // ═══════════════════════════════════════
  // WATCH PRICE HISTORY
  // ═══════════════════════════════════════
  Stream<List<PriceHistoryModel>> watchPriceHistory(String productId) {
    return FirebaseService.priceHistoryRef(productId)
        .orderBy('changedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PriceHistoryModel.fromFirestore(doc))
            .toList());
  }
}
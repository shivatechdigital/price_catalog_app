import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:price_catalog_app/data/models/category_model.dart';
import 'package:price_catalog_app/data/repositories/category_repository.dart';

// ═══════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

// ═══════════════════════════════════════
// WATCH ALL CATEGORIES - Stream
// ═══════════════════════════════════════
final categoriesStreamProvider =
    StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

// ═══════════════════════════════════════
// CATEGORY ACTIONS NOTIFIER
// ═══════════════════════════════════════
class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repo;

  CategoryNotifier(this._repo) : super(const AsyncValue.data(null));

  // Add Category
  Future<bool> addCategory({
    required String name,
    required String description,
    required String icon,
    String? imageUrl,
    required int sortOrder,
    required String createdBy,
    List<SubCategoryModel>? subCategories,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addCategory(
        name: name,
        description: description,
        icon: icon,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
        createdBy: createdBy,
        subCategories: subCategories,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Update Category
  Future<bool> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    String? icon,
    String? imageUrl,
    bool? isActive,
    int? sortOrder,
    List<SubCategoryModel>? subCategories,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        icon: icon,
        imageUrl: imageUrl,
        isActive: isActive,
        sortOrder: sortOrder,
        subCategories: subCategories,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Delete Category
  Future<bool> deleteCategory(String categoryId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteCategory(categoryId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Add SubCategory
  Future<bool> addSubCategory({
    required String categoryId,
    required String name,
    required String icon,
  }) async {
    try {
      await _repo.addSubCategory(
        categoryId: categoryId,
        name: name,
        icon: icon,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  return CategoryNotifier(ref.watch(categoryRepositoryProvider));
});
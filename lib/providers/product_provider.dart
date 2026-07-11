import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/data/repositories/product_repository.dart';

// ═══════════════════════════════════════
// SORT OPTIONS
// ═══════════════════════════════════════
enum SortOption { nameAsc, nameDesc, priceAsc, priceDesc, recent }

final sortOptionProvider =
    StateProvider<SortOption>((ref) => SortOption.recent);

final availabilityFilterProvider =
    StateProvider<ProductAvailability?>((ref) => null);

// ═══════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ═══════════════════════════════════════
// WATCH ALL PRODUCTS
// ═══════════════════════════════════════
final productsStreamProvider =
    StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).watchAllProducts();
});

// ═══════════════════════════════════════
// WATCH PRODUCTS BY CATEGORY
// ═══════════════════════════════════════
final productsByCategoryProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, categoryId) {
  return ref
      .watch(productRepositoryProvider)
      .watchProductsByCategory(categoryId);
});

// ═══════════════════════════════════════
// SEARCH QUERY PROVIDER
// ═══════════════════════════════════════
final searchQueryProvider = StateProvider<String>((ref) => '');

// ═══════════════════════════════════════
// SELECTED CATEGORY FILTER
// ═══════════════════════════════════════
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

// ═══════════════════════════════════════
// FILTERED PRODUCTS WITH SORT & AVAILABILITY
// ═══════════════════════════════════════
final filteredProductsProvider =
    Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryFilterProvider);
  final sortOption = ref.watch(sortOptionProvider);
  final availabilityFilter = ref.watch(availabilityFilterProvider);

  return productsAsync.whenData((products) {
    var filtered = products;

    // Filter by category
    if (selectedCategory != null) {
      filtered = filtered
          .where((p) => p.categoryId == selectedCategory)
          .toList();
    }

    // Filter by availability
    if (availabilityFilter != null) {
      filtered = filtered
          .where((p) => p.availability == availabilityFilter)
          .toList();
    }

    // Filter by search
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.productCode.toLowerCase().contains(query) ||
              p.brand.toLowerCase().contains(query))
          .toList();
    }

    // Apply sorting
    switch (sortOption) {
      case SortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.priceAsc:
        filtered.sort((a, b) =>
            a.currentPrice.sellingPrice
                .compareTo(b.currentPrice.sellingPrice));
        break;
      case SortOption.priceDesc:
        filtered.sort((a, b) =>
            b.currentPrice.sellingPrice
                .compareTo(a.currentPrice.sellingPrice));
        break;
      case SortOption.recent:
        // Already sorted by updatedAt from stream
        break;
    }

    return filtered;
  });
});

// ═══════════════════════════════════════
// PRICE HISTORY
// ═══════════════════════════════════════
final priceHistoryProvider = StreamProvider.family(
  (ref, String productId) => ref
      .watch(productRepositoryProvider)
      .watchPriceHistory(productId),
);
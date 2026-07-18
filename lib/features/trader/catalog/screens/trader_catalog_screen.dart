import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/features/trader/catalog/screens/trader_product_detail_screen.dart';
import 'package:price_catalog_app/features/trader/requirements/screens/select_products_screen.dart';
import 'package:price_catalog_app/providers/category_provider.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/shimmer_loading.dart';

class TraderCatalogScreen extends ConsumerStatefulWidget {
  const TraderCatalogScreen({super.key});

  @override
  ConsumerState<TraderCatalogScreen> createState() =>
      _TraderCatalogScreenState();
}

class _TraderCatalogScreenState
    extends ConsumerState<TraderCatalogScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProductsAsync = ref.watch(filteredProductsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

    // ✅ FIX: selectedItems ko provider se lelo, not from undefined variable
    final selectedItems = ref.watch(selectedRequirementItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            elevation: innerBoxIsScrolled ? 2 : 0,
            title: Text(
              'Product Catalog',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              // ✅ FIX: Grid/List toggle button add kiya
              IconButton(
                onPressed: () =>
                    setState(() => _isGridView = !_isGridView),
                icon: Icon(
                  _isGridView
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  color: AppColors.textSecondary,
                  size: 22.sp,
                ),
              ),

              // ✅ FIX: Cart button - selectedItems from provider
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SelectProductsScreen(),
                  ),
                ),
                icon: Badge(
                  label: Text(
                    '${selectedItems.length}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  isLabelVisible: selectedItems.isNotEmpty,
                  backgroundColor: AppColors.rejected,
                  child: Icon(
                    Iconsax.shopping_cart,
                    color: AppColors.textPrimary,
                    size: 22.sp,
                  ),
                ),
              ),

              SizedBox(width: 8.w),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(116.h),
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildCategoryChips(),
                ],
              ),
            ),
          ),
        ],
        body: filteredProductsAsync.when(
          loading: () => _isGridView
              ? _buildGridShimmer()
              : _buildListShimmer(),
          error: (_, __) => const Center(
            child: Text('Failed to load products'),
          ),
          data: (products) {
            if (products.isEmpty) {
              return _buildEmpty(
                searchQuery.isNotEmpty || selectedCategory != null,
              );
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(productsStreamProvider),
              color: AppColors.traderPrimary,
              child: _isGridView
                  ? _buildGrid(products)
                  : _buildList(products),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      child: TextField(
        controller: _searchController,
        onChanged: (v) =>
            ref.read(searchQueryProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: 'Search products, brands...',
          prefixIcon: Icon(
            Iconsax.search_normal,
            size: 20.sp,
            color: AppColors.textHint,
          ),
          suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    ref
                        .read(searchQueryProvider.notifier)
                        .state = '';
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: AppColors.textHint,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CATEGORY CHIPS
  // ═══════════════════════════════════════
  Widget _buildCategoryChips() {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory =
        ref.watch(selectedCategoryFilterProvider);

    return Container(
      color: AppColors.white,
      height: 48.h,
      child: categoriesAsync.when(
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
        data: (categories) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => Gap(8.w),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildCategoryChip(
                '📦',
                'All',
                selectedCategory == null,
                () => ref
                    .read(
                      selectedCategoryFilterProvider.notifier,
                    )
                    .state = null,
              );
            }
            final cat = categories[index - 1];
            return _buildCategoryChip(
              cat.icon,
              cat.name,
              selectedCategory == cat.id,
              () => ref
                  .read(
                    selectedCategoryFilterProvider.notifier,
                  )
                  .state = cat.id,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.traderPrimary
              : AppColors.background,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.traderPrimary
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: 12.sp)),
            Gap(4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: isSelected
                    ? AppColors.white
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // GRID VIEW
  // ═══════════════════════════════════════
  Widget _buildGrid(List<ProductModel> products) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _TraderProductCard(
          product: product,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TraderProductDetailScreen(
                product: product,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 60),
              duration: 300.ms,
            )
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.0, 1.0),
            );
      },
    );
  }

  // ═══════════════════════════════════════
  // LIST VIEW
  // ═══════════════════════════════════════
  Widget _buildList(List<ProductModel> products) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
      itemCount: products.length,
      separatorBuilder: (_, __) => Gap(10.h),
      itemBuilder: (context, index) {
        final product = products[index];
        return _TraderProductListTile(
          product: product,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TraderProductDetailScreen(
                product: product,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 60),
            )
            .slideX(begin: 0.05, end: 0);
      },
    );
  }

  // ═══════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════
  Widget _buildEmpty(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Iconsax.search_normal : Iconsax.box,
            size: 52.sp,
            color: AppColors.textHint,
          ),
          Gap(16.h),
          Text(
            hasFilters
                ? 'No products found'
                : 'No products available',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (hasFilters) ...[
            Gap(12.h),
            TextButton(
              onPressed: () {
                _searchController.clear();
                ref
                    .read(searchQueryProvider.notifier)
                    .state = '';
                ref
                    .read(
                      selectedCategoryFilterProvider.notifier,
                    )
                    .state = null;
              },
              child: Text(
                'Clear Filters',
                style: TextStyle(
                  color: AppColors.traderPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // SHIMMER LOADERS
  // ═══════════════════════════════════════
  Widget _buildGridShimmer() {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => ShimmerLoading(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 16.r,
      ),
    );
  }

  Widget _buildListShimmer() {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: 6,
      separatorBuilder: (_, __) => Gap(10.h),
      itemBuilder: (_, __) => ShimmerLoading(
        width: double.infinity,
        height: 88.h,
        borderRadius: 14.r,
      ),
    );
  }
}

// ═══════════════════════════════════════
// TRADER PRODUCT CARD (Grid)
// ═══════════════════════════════════════
class _TraderProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _TraderProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Image Section ───────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16.r),
                    ),
                    child: product.primaryImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.primaryImage,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.traderPrimary
                                  .withOpacity(0.06),
                            ),
                            errorWidget: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                  // Availability Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _availabilityBadge(
                      product.availability,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Info Section ────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.categoryName,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.traderPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(2.h),
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'per ${product.unit}',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Add to cart button
                        Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            gradient: AppColors.traderGradient,
                            borderRadius:
                                BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.traderPrimary
                                    .withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 16.sp,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.traderPrimary.withOpacity(0.06),
      child: Center(
        child: Icon(
          Iconsax.box,
          size: 36.sp,
          color: AppColors.traderPrimary.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _availabilityBadge(ProductAvailability availability) {
    final (color, text) = switch (availability) {
      ProductAvailability.inStock => (
          AppColors.approved,
          'In Stock',
        ),
      ProductAvailability.outOfStock => (
          AppColors.rejected,
          'Out of Stock',
        ),
      ProductAvailability.limitedStock => (
          AppColors.counter,
          'Limited',
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 7.w,
        vertical: 3.h,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.sp,
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// TRADER PRODUCT LIST TILE
// ═══════════════════════════════════════
class _TraderProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _TraderProductListTile({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ─── Image ───────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: SizedBox(
                width: 70.w,
                height: 70.w,
                child: product.primaryImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.primaryImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.traderPrimary
                              .withOpacity(0.06),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.traderPrimary
                              .withOpacity(0.08),
                          child: Icon(
                            Iconsax.box,
                            color: AppColors.traderPrimary
                                .withOpacity(0.4),
                            size: 28.sp,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.traderPrimary
                            .withOpacity(0.08),
                        child: Icon(
                          Iconsax.box,
                          color: AppColors.traderPrimary
                              .withOpacity(0.4),
                          size: 28.sp,
                        ),
                      ),
              ),
            ),

            Gap(12.w),

            // ─── Info ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(3.h),
                  Text(
                    '${product.brand} • ${product.categoryName}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(6.h),
                  Row(
                    children: [
                      Text(
                        '₹${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.traderPrimary,
                        ),
                      ),
                      Text(
                        '/${product.unit}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Gap(8.w),

            // ─── Availability + Arrow ─────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _availabilityDot(product.availability),
                Gap(12.h),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.sp,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _availabilityDot(ProductAvailability availability) {
    final color = switch (availability) {
      ProductAvailability.inStock => AppColors.approved,
      ProductAvailability.outOfStock => AppColors.rejected,
      ProductAvailability.limitedStock => AppColors.counter,
    };

    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}